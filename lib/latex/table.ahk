#Include %A_ScriptDir%\lib\lib.ahk

global GuiTableWidth  := 0
global GuiTableHeight := 0

; markdown table
MarkdownTableCreate() {
    ; global
    Gui, Add, Text,, Please enter table width:
    Gui, Add, Edit, vGuiTableWidth, 4
    Gui, Add, Text,, Please enter table height:
    Gui, Add, Edit, vGuiTableHeight, 3
    Gui, Add, Button, Default, OK
    Gui, Show
    return
ButtonOK:
    Gui, Submit  ; Save the input from the user to each control's associated variable.
    z_log("DEBUG","GuiTableWidth="  GuiTableWidth)
    z_log("DEBUG","GuiTableHeight=" GuiTableHeight)
    output := DoMarkdownTableCreate(GuiTableWidth,GuiTableHeight)
    SendInput {Raw}%output%
    Gui, Destroy
    Return
}

MarkdownTableDelete() {
    output := DoMarkdownTableCreate(GuiTableWidth,GuiTableHeight)
    MarkdownTableForamt(,,True)
}

GenerateMarkdownTableRow(elem, size) {
    row := "|"
    Loop % size
    {
        row .= elem "|"
    }
    row .= "`n"
    Return row
}

GenerateMarkdownTableHeader(width) {
    header := GenerateMarkdownTableRow("<++>",width)
    header .= GenerateMarkdownTableRow("----",width)
    return header
}

DoMarkdownTableCreate(width,height) {
    header := GenerateMarkdownTableHeader(width)
    output := header
    Loop % height
        output .= GenerateMarkdownTableRow("    ",width)
    return output
}

IsMarkdownTableRow() {
    ; copy from cursor to the begin of line.
    selectedStr := CopyCursorDirection("Left")
    ; z_log("DEBUG", "strCursorLeft" strCursorLeft)
    lenCursorLeft := StrLen(selectedStr)
    if(!lenCursorLeft) {  ; cursor is at the begin of line
        ; copy from cursor to the end of line
        selectedStr := CopyCursorDirection("Right")
        ; z_log("DEBUG", "str right " selectedStr)
        lenCursorRight := StrLen(selectedStr)
        If (!lenCursorRight) {
            return False  ; here means empty line
        }
    }
    ; firstChar := SubStr(selectedStr,1,1)
    RegExReplace(selectedStr,"^\s*\|","",matchCnt)
    Return matchCnt
}

MarkdownTableRowAdd() {
    If (!IsMarkdownTableRow()) { ; means start with "|"
        z_log("INFO","This line is not table row")
        Return
    }
    row := SelectAndCopy("{Home}{Shift Down}{End}{Shift Up}")
    Send {Home}
    row := RegExReplace(row,"[^\|]"," ")
    ; row := RegExReplace(row,"[^\|]\s*(\|)","<++>|")
    SendInput {Raw}%Row%`n
    JumpToAnchorWithHomeUp(1)
}

MarkdownTableRowDel() {
    If (!IsMarkdownTableRow()) { ; means start with "|"
        z_log("INFO","This line is not table row")
        Return
    }
    SendInput {Home}{Shift Down}{End}{Right}{Shift Up}{Backspace}
}

MarkdownTableColumnAdd() {
    str := CopyCursorDirection("Left")
    StrReplace(str, "|", "", colNum)
    MarkdownTableForamt(colNum)
}

MarkdownTableColumnDel() {
    str := CopyCursorDirection("Left")
    StrReplace(str, "|", "", colNum)
    MarkdownTableForamt(,colNum)
}

inMarkdownTable(dir,text) {
    switch dir {
    case "Up":
    regexPatern := "(^\s*\||`n)"
    case "Down":
    regexPatern := "(`n|\|\s*$)"
    Default:
        z_log("ERROR", "unknow direction")
    }
    RegExReplace(text,regexPatern,"",matchCnt)
    logstr = cnt=%cnt%,matchCnt%matchCnt%
    z_log("DEBUG", logstr)
    If (matchCnt != cnt+1) {
}

GetMarkdownTableBorderLineByContinueSelect(borderType) {
    Switch borderType {
    Case "begin":
        return LineSelectAndCopyWhile()

        dir         := "Up"
        lineSide    := "Home"
        postAction  := "{Right}"
        regexPatern := "(^\s*\||`n)"
    Case "end":
        dir         := "Down"
        lineSide    := "End"
        postAction  := "{Left}"
        regexPatern := "(`n|\|\s*$)"
    Default:
        z_log("ERROR","unknow borderType " borderType)
        Return
    }
    ; jump to border, narrow down the range which contains the table border
    ; expand to approach the border
    cnt := 0
    MaxTryCount := 10
    step := 4
    While (cnt<MaxTryCount) {
        doDir := !!cnt * step
        SendInput {Shift Down}{%dir% %doDir%}{%lineSide%}{Shift Up}
        ; Sleep 200
        str := DoCopy()
        RegExReplace(str,regexPatern,"",matchCnt)
        logstr = cnt=%cnt%,matchCnt%matchCnt%
        z_log("DEBUG", logstr)
        If (matchCnt != cnt+1) {
            break
        }
        ; here means we are in table
        cnt += step
    }
    z_log("DEBUG", "final cnt=" cnt)
    If(cnt==MaxTryCount) {
        logstr = Markdown Table %borderType% line need more than 10 $Dir$
        z_log("WARN",logstr)
        Return cnt
    }
    ; post action
    SendInput %postAction%
    return matchCnt-1
}

GetMarkdownTableBorderLineByResetSelect(borderType, ByRef pos) {
    cnt := 0
    While (cnt<10) {
        Switch borderType {
        Case "begin":
            selectAction = {Shift Down}{Up %cnt%}{Home}{Shift Up}
            selectedStr := SelectAndCopy(selectAction,"{Right}")
            RegExReplace(selectedStr, "(^\s*\||`n)","",matchCnt)
        Case "end":
            selectAction = {Shift Down}{Down %cnt%}{End}{Shift Up}
            selectedStr := SelectAndCopy(selectAction,"{Left}")
            RegExReplace(selectedStr, "(`n|\|\s*$)","",matchCnt)
        Default:
            z_log("ERROR","unknow borderType " borderType)
            Return
        }
        ; z_log("DEBUG", "cnt => " cnt)
        ; z_log("DEBUG", "matchCnt => " matchCnt)
        If (matchCnt != cnt+1) {
            break
        }
        ; here means we are in table
        cnt++
    }
    ; z_log("DEBUG", "cnt => " cnt)
    If(cnt==10) {
        logstr = Table %borderType% line need more than 10 {Up/Down}
        z_log("WARN",logstr)
        Return cnt
    }
    return cnt-1
}

GetMarkdownTableBorderLine(borderType) {
    Return GetMarkdownTableBorderLineByContinueSelect(borderType)
    ; Return GetMarkdownTableBorderLineByResetSelect(borderType, ByRef pos)
}

; Input faster for long text
SendByPaste(text) {   
    clipboardSaved := ClipboardAll ; save clipboard
    Clipboard := text
    MaxTryCount := 2
    i := 1
    while(i<=MaxTryCount) {
        ClipWait 1
        If (Clipboard != "") {
            break
        }
        i++
    }
    If (i>1) {
        z_log("WARN", "i=" i)
    }
    If (Clipboard = "") {
        z_log("ERROR", "copy time out for " selectAction)
        Return
    }
    time := (StrLen(text) / 2000 + 0.1 ) * 1000 
    z_log("DEBUG", "sleep time => " time)
    ; Sleep % time
    SendInput ^v
    Sleep % time  ; wait for clipboard in win10 ready
    Clipboard := clipboardSaved
    Return
}

GetPositionInLine() {
    selectedStr := SelectAndCopy("{Shift Down}{Home}{Shift Up}","{Right}")
    Return StrLen(selectedStr)
}

MarkdownTableForamt(insertAtColumn := 0, deleteColumn :=0, deleteTable := false) {
    upCnt   := GetMarkdownTableBorderLine("begin")
    downCnt := GetMarkdownTableBorderLine("end")
    posInLine := GetPositionInLine()
    z_log("DEBUG", "upCnt => " upCnt)
    z_log("DEBUG", "downCnt => " downCnt)
    text := CopyCursorDirection("Around",upCnt,downCnt)
    z_log("DEBUG", "text =>`n" text)
    DeleteCursorAroundlines(upCnt,downCnt)
    If(deleteTable) {
        return
    }
    z_log("DEBUG", "insertAtColumn=> " insertAtColumn)
    z_log("DEBUG", "deleteColumn=> " deleteColumn)
    text := Tablize(text, insertAtColumn, deleteColumn)
    z_log("DEBUG", "text after format =>`n" text)
    SendByPaste(text)  ; faster for long text
    ; SendInput {Raw}%text%
    ; back to what we start
    backUpCnt := downCnt + 1
    SendInput {Up %backUpCnt%}{Right %posInLine%}
}

DoMarkdownTable(action) {
    Switch action {
    Case "Create":
        MarkdownTableCreate()
        Return
    Case "Delete":
        MarkdownTableDelete()
        Return
    Case "RowAdd":
        MarkdownTableRowAdd()
        Return
    Case "RowDel":
        MarkdownTableRowDel()
        Return
    Case "ColAdd":
        MarkdownTableColumnAdd()
        Return
    Case "ColDel":
        MarkdownTableColumnDel()
        Return
    Case "Format":
        MarkdownTableForamt()
        Return
    Default:
        z_log("ERROR","unknow table action " action)
        Return
    }
    z_log("ERROR","we should not be here. " action)
}

; ============================================
; ========== table ===========================
; ============================================
PadStr(str, size,alignMode:="Left") {
    diff := size-StrLen(str)
    If (diff<0) {
        logstr = strlen %str% is bigger than %size%
        z_log("ERROR",logstr)
        return ""
    }
    Switch alignMode {
    Case "Left", "Default":
        loop % diff
           str .= A_Space
    Case "Right":
        loop % diff
           str := A_Space . str
    Case "Center":
        loop % Floor(diff/2)
           str := A_Space . str
        loop % Ceil(diff/2)
           str := str . A_Space
        ; return ""
    Default:
        z_log("ERROR", "unknow align mode " alignMode)
        Return ""
    }
    return str

}

global alignStrMap := 
    ( Join
    {
     "Default" : {"RegexPattern":"^-+$",  "leftMarker":"-", "rightMarker":"-"} ,
     "Left"    : {"RegexPattern":"^:-+$", "leftMarker":":", "rightMarker":"-"} ,
     "Right"   : {"RegexPattern":"^-+:$", "leftMarker":"-", "rightMarker":":"} ,
     "Center"  : {"RegexPattern":"^:-+:$",  "leftMarker":":", "rightMarker":":"}
    }
    )

GetAlignMode(str) {
    alignMode := ""
    If (str = "") Return "Default"
    ; z_log("DEBUG", "in GetAlignMode")
    For mode,val in alignStrMap {
        RegExMatch(str,val["RegexPattern"],alignMode)
        If(alignMode != "") {
            ; z_log("DEBUG", str " match ok " mode pattern)
            Return mode
        }
    }
    z_log("ERROR", "no one match " str ". set Default align")
    Return "Default"
}

FormatAlignStr(mode,width) {
    If (!alignStrMap[mode]) {
        z_log("ERROR", "unknow align mode " mode)
        return ""
    }
    baseStr := ""
    Loop % width-2
        baseStr .= "-"
    Return alignStrMap[mode]["leftMarker"] . baseStr alignStrMap[mode]["rightMarker"]
}

Tablize(text, insertAtColumn:=0, deleteColumn := 0) {
    ; parse text to 2-D arr
    ; parse rows
    arrRows := StrSplit(text, "`n"," `t")
    ; parse columns
    arr := {}
    For index, row in arrRows {
        arrElementsInRow := StrSplit(row, "|"," `t") ; Trim space
        ; remove first and last element
        arrElementsInRow.pop()
        arrElementsInRow.RemoveAt(1)
        If (insertAtColumn) {
            arrElementsInRow.InsertAt(insertAtColumn, "")
        }
        If (deleteColumn) {
            arrElementsInRow.RemoveAt(deleteColumn)
        }
        arr.Push(arrElementsInRow)
    }
    ; height := arr.Count()
    height := arr.MaxIndex()
    width  := arr[1].MaxIndex()
    ; get max length in one column
    arrColumnMaxLength := []
    arrColumnAlignMode := []
    i:=1
    While(i<=width) {
        columnMaxLength := 2  ; default width 2
        j:=1
        While(j<=height) {
            If (j=2) {  ; skip header line
                j++
                continue
            }
            If (columnMaxLength < StrLen(arr[j][i])) {
                columnMaxLength := StrLen(arr[j][i])
            }
            ; z_log("DEBUG", "i=" i "j=" j ",columnMaxLength=" columnMaxLength)
            j++
        }
        arrColumnMaxLength.Push(columnMaxLength)
        i++
    }
    ; get align mode and format second line
    For index,elem In arr[2] {
        alignMode := GetAlignMode(elem)
        If (alignMode = "") {
            z_log("ERROR","alignMode is null. " elem)
            Return
        }
        arr[2][index] := FormatAlignStr(alignMode,arrColumnMaxLength[index])
        ; z_log("DEBUG","elem => " arr[2][index])
        arrColumnAlignMode.Push(alignMode) ; for output later
    }

    ; output as markdown table format
    output := ""
    i:=1
    While(i<=height) {
        output .= "|"
        j:=1
        While(j<=width) {
            alignMode := arrColumnAlignMode[j]
            arr[i][j] := A_Space PadStr(arr[i][j],arrColumnMaxLength[j],alignMode) A_Space
            output .= arr[i][j] . "|"
            j++
        }
        output .= i==height ? "":"`n"
        i++
    }
    Return output
}

