#Include %A_ScriptDir%\lib\zlog.ahk

; basic op: copy select, cursor
DoCopyCtrlC(waitTimeout:=True) {
    clipboardSaved := ClipboardAll ; save clipboard
    Clipboard := ""  ; 必须清空, 才能检测是否有效.
    MaxCtrlCTryCount := waitTimeout ? 5 : 1
    i := 0
    while(i<MaxCtrlCTryCount) {
        SendInput ^c
        ClipWait 0.5
        If (Clipboard != "") {
            break
        }
        i++
    }
    If (i>0) {
        z_log("WARN", " copy try counts i=" i)
    }
    str := Clipboard
    Clipboard := clipboardSaved
    If (str = "") {
        z_log("ERROR", " ctrl-C copy fail. i=" i ",MaxCtrlCTryCount=" MaxCtrlCTryCount)
    }
    Return str
}

SleepBeforeSelection() {
    Sleep 100  ; wait for render because shortcut keystroke cause re-rendering
}

SleepAfterSelection() {
    Sleep 300  ; wait for selection because of re-rendering. CSDN is really slow rendering
}

SelectAndCopy(selectAction:="", postAction:="", waitTimeout:=True) {
    If (selectAction = "") {
        z_log("INFO", "selectAction is NULL, User Selection should be already done first")
    } Else {
        SleepBeforeSelection()
        SendInput %selectAction%
    }
    SleepAfterSelection()
    str := DoCopyCtrlC(waitTimeout)
    If (str = "") {
        z_log("ERROR", " copy time out for " selectAction)
    } Else {
        SendInput %postAction%  ; do sth after select copy.
    }
    ; SendInput {right}   ; cursor back to what we start.
    Return str
}

GetCursorPostionInLine() {
    ; no wait copy ok because empty line will wait too long.
    selectedStr := SelectAndCopy("{Shift Down}{Home}{Shift Up}","{Right}",waitTimeout:=false)
    pos := StrLen(selectedStr)
    return pos
}

GetCurrentLine(ByRef posInLine:=0) {
    selectedStr1 := SelectAndCopy("{Shift Down}{Home}{Shift Up}","{Right}", false)
    selectedStr2 := SelectAndCopy("{Shift Down}{End}{Shift Up}", "{left}", false)
    posInLine := StrLen(selectedStr1)
    z_log("DEBUG","selectedStr1=" selectedStr1 ",selectedStr2=" selectedStr2)
    return selectedStr1 . selectedStr2
}

EmptyCurrentLine() {
    ; avoid empty line already
    SendInput {Home}{Shift Down}{End}{Shift Up}{Space}{Backspace}
}

DeleteCurrentLine() {
    ; avoid empty line already
    SendInput {Home}{Shift Down}{End}{Shift Up}{Space}{Backspace}{Delete}
}

; copy range [upLine, downLine], current line is 0
; CopyCursorDirection(dir,upLineBound:=0,downLineBound:=0) {
CopyCursorDirection(dir,upCnt:=0,downCnt:=0) {
    Switch dir {
    Case "Left":
        selectedStr := SelectAndCopy("{Shift Down}{Home}{Shift Up}","{Right}",False)
    Case "Right":
        selectedStr := SelectAndCopy("{Shift Down}{End}{Shift Up}","{Left}",False)
    Case "Up":
        selectAction = {Shift Down}{Up %cnt%}{Home}{Shift Up}
        selectedStr := SelectAndCopy(selectAction,"{Right}")
    Case "Down":
        selectAction = {Shift Down}{Down %cnt%}{End}{Shift Up}
        selectedStr := SelectAndCopy(selectAction, "{Left}")
    Case "Around":
        selectedStr1 := SelectAndCopy("{Shift Down}{Up " upCnt "}{Home}{Shift Up}","{Right}")
        selectedStr2 := SelectAndCopy("{Shift Down}{Down " downCnt "}{End}{Shift Up}","{left}")
        selectedStr := selectedStr1 . selectedStr2
    Default:
        z_log("ERROR","unknow direction " dir)
        Return
    }
    Return selectedStr

}

; CopyCursorAroundlines(upCnt,downCnt) {
;     selectedStr1 := SelectAndCopy("{Shift Down}{Up %upCnt%}{Home}{Shift Up}","{Right}")
;     selectedStr2 := SelectAndCopy("{Shift Down}{Down %upCnt%}{Home}{Shift Up}","{left}")
;     return selectedStr1 . selectedStr2
; }

DeleteCursorAroundlines(upCnt,downCnt) {
    cnt := upCnt + downCnt
    SendInput {Up %upCnt%}{Home}{Shift Down}{Down %cnt%}{End}{Shift Up}{Backspace}
}

LineSelectAndCopyUtil(dir,IsLineWeNoWant) {
    LineSelectAndCopyWhile(dir,!IsLineWeWant)
}

LineSelectAndCopyWhile(dir,IsLineWeWant) {
    If(dir="Up") {
        lineSide := "Home"
        postAction  := "{Right}"
    } Else If(dir="Down") {
        lineSide := "End"
        postAction  := "{Left}"
    } Else {
        z_log("ERROR", "unknow dir " dir)
        Return
    }
    ; jump to border, narrow down the range which contains the table border
    ; expand to approach the border
    cnt := 0
    MaxTryCount := 10
    step := 4
    cond := True
    While (cond && cnt<MaxTryCount) { ; mock do-while style
        doDir := !!cnt * step  ; do select increamently
        SendInput {Shift Down}{%dir% %doDir%}{%lineSide%}{Shift Up}
        ; only copy timeout at text head or tail theoritically
        str := DoCopyCtrlC()
        cond := %IsLineWeWant%(str)
        cnt += step
    }
    z_log("DEBUG", " final cnt=" cnt)
    If(cnt>=MaxTryCount) {
        logstr = Markdown Table %borderType% line need more than %MaxTryCount% $Dir$
        z_log("WARN",logstr)
        Return cnt
    }
    ; post action
    SendInput %postAction%
    ; satify condition line range [matchCnt-1, cursor line] . i.e [-4, 0]
    return matchCnt-1
}

;maxLimit := 2.5
;offset   := 0.3
;ratio    := 0.002

SleepBasedOnTextByATan(text,ratio:=0.005,offset:=0.4,maxLimit:=2.5,dryRun:=false) {

    maxLimit := 1.5
    offset   := 0.1
    ratio    := 0.01

    If (dryRun) {
        cntLines := text
    } Else {
        cntLines := StrLen(text) / 60  ; assume one line has 50 char
    }
    sleepTime := offset + maxLimit * ATan(cntLines * ratio)
    z_log("DEBUG", " cntLines=" cntLines ",sleep time" sleepTime)
    If (dryRun) {
        Return
    }
    Sleep % sleepTime*1000
}

; Timewait for copy
; Timewait for render in playstage. Such as Typora rendering
SleepBasedOnText(text, ratio:="Normal", offset:=0.3, maxLimit:=2.5) {
    Return SleepBasedOnTextByATan(text)
    ; t := 0.3 + 

    cntLines := StrLen(text) / 60  ; assume one line has 50 char
    MsecPerLine := 10
    sleepTime := MsecPerLine * cntLines
    ; sleepTime := (StrLen(text) / 2000 + 0.1 ) * 1000 ; dynamic sleep time
    sleepTime := min(sleepTime,maxLimit)
    Switch ratio {
    Case "Short":
        sleepTime *= 0.5
    Case "Normal":
        sleepTime *= 1
    Case "Long":
        sleepTime *= 2
    Default:
        If ratio is number
        {
            sleepTime = sleepTime * ratio + offset
        }
        Else
        {
            z_log("ERROR", " unknow parameter ratio=" ratio)
            Return
        }
    }
    z_log("DEBUG", " sleep time => " sleepTime)
    Sleep % sleepTime
}

SleepForCtrlVDone() {
    SleepBasedOnText(text, 1)  ; wait for clipboard in win10 ready ??
}

; Input long text by paste is faster
SendByPaste(text,vimlike:=false) {
    If (text = "") {
        z_log("ERROR", " text is null")
        return 0
    }
    If (vimlike) {
        SendInput {End}`n
    }
    clipboardSaved := ClipboardAll ; save clipboard
    Clipboard := ""  ; clear clipoard
    Clipboard := text
    ClipWait 2
    If (Clipboard = "") {
        z_log("ERROR", " copy time out for text=" text)
        Clipboard := clipboardSaved
        Return
    }
    ; SleepBasedOnText(text, 1)  ; wait for clipboard in win10 ready ??
    ; Sleep 800
    SendInput ^v  ; paste  ctrl-v
    ; Sleep 300  ; wait for ctrl-v completed. Otherwise may cause reorder of execution.
    ; SleepForCtrlVDone()
    ; Sleep 1000
    SleepBasedOnTextByATan(text)
    ; Sleep 500
    Clipboard := clipboardSaved
    Return
}

; split hotStringMap =>hotStringMap1 hotStringMap2, because of error: expression too long
MergeVar(varName, type:="Map") {
    i := 1
    while(i<10) {
        If (!IsSet(%varName%%i%)) {
            ; logstr = var %varName%%i% is not defined
            ; z_log("DEBUG", " " logstr)
            Break
        }
        Switch type {
        Case "String":
            %varName% .= %varName%%i%
        Case "Map":
            For key,val in %varName%%i% {
                %varName%[key] := val
                ; logstr =  key=%key%,val=%val%
                ; z_log("WARN", " " logstr)
            }
        Default:
            z_log("ERROR", " unknow type=" type)
            return
        }
        i++
    }
    i--
    ; logstr = merged %i% sub elements for varName=%varName% type=%type%
    ; z_log("DEBUG", " " logstr)
}

