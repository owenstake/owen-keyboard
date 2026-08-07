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
    }
    Return ret
}

EvalFunc(funcName, arrParams) {
    If (!IsFunc(funcName)) {
        logstr = funcName %funcName% do not exists!
        Return -1
    }
    fn := Func(funcName)
    arrCount := arrParams.Count()
    If (arrCount < fn.MinParams Or arrCount > arrParams.Count()) {
        logstr = %arrCount% not correct for %funcName%!
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
            If ( arg!= "Clipboard") {
                If (!IsSet(%arg%)) {
                    logstr = parameter var %arg% is not defined
                }
            }
        }
        Return ret
    } Else {
        Return function.Call(params*)
    }
}
