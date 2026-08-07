#Include %A_ScriptDir%\lib\zlog.ahk

JumpToAnchorByRegExMatch(str,hiddenEmptyLine:=true) {
    lengthMatch := 0
    IfWinActive ahk_exe Typora.exe 
    {
        str := StrReplace(str, "`r`n`r`n", " ") ; empty line as one char
        str := StrReplace(str, "`n`n", " ")     ; empty line as one char
    }
    str := StrReplace(str, "`r`n", " ")  ; `r`n should treat as one char
    ; getpos <++> or《++》 [^<] avoid greed match for <++.*>
    ; P) means position mode (output match position in lengthMatch) 
    ; U) for no-greedy match, such as <++><++>
    ; [^<] for this situation <11<++>
    FoundPos := RegExMatch(str,"PU)<[^<]*\+\+>|《\+\+》",lengthMatch)
    If (FoundPos) {
        FoundPos += lengthMatch-1   ; FoundPos is start from 1 not 0
        ; jump to anchor and select it
        SendInput {Right %FoundPos%}{Shift Down}{Left %lengthMatch%}{Shift Up}  
        ; if match <++>, then delete it. we only keep <info++> information.
        If (lengthMatch = 4) {  
            SendInput {BackSpace}
        }
    }
}

JumpToAnchor(waitForCopySth:=False, dir:="Down") {
    ; clipboardSaved := ClipboardAll ; save clipboard
    ; Clipboard    := ""  ; 必须清空, 才能检测是否有效.
    ; select a detection region for anchor
    action = {shift down}{%dir% 4}{end}{shift up}   
    str := SelectAndCopy(action, "{Left}",waitForCopySth)
    JumpToAnchorByRegExMatch(str)
    Return
}


JumpToAnchorWithLeft(leftCnt:=0) {
    SendInput {Left %leftCnt%}
    JumpToAnchor(waitForCopySth:=True) ; This true is for we can copy sth
}

JumpToAnchorWithHomeUp(upCnt:=0) {
    SendInput {Home}{Up %upCnt%}
    JumpToAnchor(waitForCopySth:=True)
}

DoOneLineSnippet(str) {
    ; app:= GetActiveApp()
    ; If (app = "Typora") {
    ;     ; against typora auto-completion when typora render slow
    ;     strPlay := RegExReplace(str,"</.*>","</>")
    ; }
    ; SendInput {Raw}%strPlay%
    SendInput {Raw}%str%
    JumpToAnchorWithLeft(StrLen(str))
}

global zFuncCallPattern := "^(\w+)\((.*)\)$"

IsFuncCallStr(callFuncStr) {
    Return RegExMatch(callFuncStr,"O)" zFuncCallPattern,matchObj)
}

EvalStrArgs(argsStr) {  ; we only can eval string expression
    args := []
    argStrArray := StrSplit(argsStr, "," , " `t")
    Return argStrArray
}

ParseFuncAndEval(funcCallStr) {
    ; startPattern jw
    ; FoundPos := RegExMatch(callFuncStr,"O)(^(?:Get|Do)[^(]*)\((.*)\)",matchObj)
    FoundPos := RegExMatch(funcCallStr,"O)" zFuncCallPattern,matchObj)
    If (!FoundPos) {
        Return -1
    }
    funcName := matchObj[1]
    args := EvalStrArgs(matchObj[2])
    ret := EvalFunc(funcName,args)
    If (ret == -1) {
        logstr = funcName %funcName% do not exists! funcCallStr=%funcCallStr%
        z_log("ERROR", logstr)
    }
    Return ret
}

EvalFunc(funcName, arrParams) {
    If (!IsFunc(funcName)) {
        logstr = funcName %funcName% do not exists!
        z_log("ERROR", logstr)
        Return -1
    }
    fn := Func(funcName)
    arrCount := arrParams.Count()
    If (arrCount < fn.MinParams Or arrCount > arrParams.Count()) {
        logstr = %arrCount% not correct for %funcName%!
        z_log("ERROR", logstr)
        Return -1
    }
    Return DoEvalFunc(fn,arrParams)
}

DoEvalFunc(function, arr, params*) {
    len:=arr.length()
    IF (len) {
        ; arg := arr[len] ; arr.RemoveAt(len)
        arg := arr.Pop()
        ; remove arg asignment first . i.e func(arg1:="hello") => func("hello")
        arg := RegExReplace(arg,"^.*(:=|=)","") ; eval string

        ; try to remove str with double-quote. i.e. "hello" => hello
        arg := RegExReplace(arg,"^""(.*)""$","$1",replaceCount) ; eval string
        If (replaceCount) { 
            ; arg is simple plain string with double-quote i.e "test"
            ret := DoEvalFunc(function,arr,arg,params*)
        } Else If (arg="") {
            ; use default parameter. i.e func(,,)
            ret := DoEvalFunc(function,arr,,params*) 
        } Else If (RegExMatch(arg,"^[-+]?\d*\.?\d*$")) {
            ; arg is number(integer or float). i.e -123.456
            ret := DoEvalFunc(function,arr,arg+0,params*)  ; +0 for convert str to number
        } Else {   
            ; dereference var. func(varname)
            ret := DoEvalFunc(function,arr,%arg%,params*) ; Eval var
            ; varExist := VarSetCapacity(%arg%)
            ; If (!varExist) {
            z_log("INFO", arg)
            If ( arg!= "Clipboard") {
                If (!IsSet(%arg%)) {
                    logstr = parameter var %arg% is not defined
                    z_log("WARN", logstr)
                }
            }
        }
        Return ret
    } Else {
        Return function.Call(params*)
    }
}
