#Include %A_ScriptDir%\lib\lib.ahk

global GuiTableWidth  := 0
global GuiTableHeight := 0

; markdown table
MarkdownTableCreate() {
    ; global
    local vGuiTableWidth
    local vGuiTableHeight
    Gui, Add, Text,, Please enter table width:
    Gui, Add, Edit, vGuiTableWidth, 4
    Gui, Add, Text,, Please enter table height:
    Gui, Add, Edit, vGuiTableHeight, 3
    Gui, Add, Button, Default, TableCreateOK
    Gui, Show
    return
ButtonTableCreateOK:
    Gui, Submit  ; Save the input from the user to each control's associated variable.
    z_log("DEBUG", "GuiTableWidth="  GuiTableWidth)
    z_log("DEBUG", "GuiTableHeight=" GuiTableHeight)
    output := DoMarkdownTableCreate(GuiTableWidth,GuiTableHeight)
    SendInput {Raw}%output%
    Gui, Destroy   ; important
    Return
; GuiClose:
;     Gui, Submit  ; Save the input from the user to each control's associated variable.
;     return
}

MarkdownTableDelete() {
    output := DoMarkdownTableCreate(GuiTableWidth,GuiTableHeight)
    MarkdownTableForamt(,,deleteTable:=True)
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
    ; header := GenerateMarkdownTableHeader(width)
    ; output := header
    output := ""
    Loop % height
    {
        output .= GenerateMarkdownTableRow("    ",width)
        If (A_Index=1) {
            output .= GenerateMarkdownTableRow("----",width)
        }
    }
    return output
}

; 0 means no match, 1 meas at the start of line
IsMarkdownTableRow() {
    ; copy from cursor to the begin of line.
    selectedStr := CopyCursorDirection("Left")
    ; z_log("DEBUG", "strCursorLeft" strCursorLeft)
    ; lenCursorLeft := StrLen(selectedStr)
    posInLine := StrLen(selectedStr) + 1
    if(selectedStr = "") {  ; cursor is at the begin of line
        ; copy from cursor to the end of line
        selectedStr := CopyCursorDirection("Right")
        ; z_log("DEBUG", "str right " selectedStr)
        ; lenCursorRight := StrLen(selectedStr)
        If (selectedStr = "") {
            z_log("INFO", "it is an empty line")
            return 0  ; here means empty line
        }
    }
    ; firstChar := SubStr(selectedStr,1,1)
    ; Return matchCnt
    matched := RegExMatch(selectedStr,"^[ `t]*\|")
    If (matched) {
        Return posInLine
    } Else {
        z_log("INFO", "cursor is not in a markdown table row.")
        z_log("INFO", "selectedStr=" selectedStr "matched=" matched)
        Return 0
    }
}

GenerateNewRow(row) {
    newRow := ""
    Loop, Parse, row
    {
        If (A_LoopField = "|") {
            newRow .= A_LoopField
        } Else {
            If (IsCharChinease(A_LoopField)) {
                newRow .= A_Space A_Space
            } Else {
                newRow .= A_Space
            }
        }
    }
    return newRow
}

MarkdownTableRowAdd() {
    If (!IsMarkdownTableRow()) { ; means start with "|"
        z_log("INFO", "cursor is not in a markdown table row")
        SendInput {Raw}|`n
        Return
    }
    row := SelectAndCopy("{Home}{Shift Down}{End}{Shift Up}",,False) ; copy row
    SendInput {End}
    ; row := RegExReplace(row,"[^\|]"," ")
    row := GenerateNewRow(row)
    SendInput {Raw}`n%row%
    SendInput {Home}{Right 2}
    ; JumpToAnchorWithHomeUp(1)
}

MarkdownTableRowDel() {
    If (!IsMarkdownTableRow()) { ; means start with "|"
        z_log("INFO", "cursor is not in a markdown table row")
        Return
    }
    SendInput {Home}{Shift Down}{End}{Right}{Shift Up}{Backspace}
}

MarkdownTableColumnAdd() {
    str := CopyCursorDirection("Left")
    StrReplace(str, "|", "", colNum)
    If (!colNum) {
        z_log("INFO", "cursor is not in a markdown table row")
        Return
    }
    MarkdownTableForamt(colNum)
}

MarkdownTableColumnDel() {
    str := CopyCursorDirection("Left")
    StrReplace(str, "|", "", colNum)
    If (!colNum) {
        z_log("INFO", "cursor is not in a markdown table row")
        Return
    }
    MarkdownTableForamt(,colNum)
}

inMarkdownTable(dir,text) {
    switch dir {
    case "Up":
    regexPatern := "(^[ `t]*\||`n)"
    case "Down":
    regexPatern := "(`n|\|\s*$)"
    Default:
        z_log("ERROR", "unknow direction")
    }
    RegExReplace(text,regexPatern,"",matchCnt)
    logstr = cnt=%cnt%,matchCnt%matchCnt%
    z_log("DEBUG", logstr)
    If (matchCnt != cnt+1) {
    ; TODO
    }
}

; Swap()

ReverseArray(arr){
    local o := []
    i := arr.count()
    While(i) {
        o.push(arr[i])
        i--
    }
    Return o
}

DetectMarkdownTable(text, ByRef output, ByRef meetBorder, maxMatchCnt, dirTo:="Up") {
    regexPat := "^\s*\|.*\|\s*$" ; table line regex patter
    arrRows := StrSplit(text, "`n")
    len := arrRows.Count()
    matchCnt:=0
    output := ""

    Switch dirTo {
    Case "Down":
    Case "Up":
        arrRows := ReverseArray(arrRows)
    Default:
        z_log("ERROR", "unknow parameter " dirTo)
        Return 0
    }
    i := 2
    while(i<=len) {
        ret := RegExMatch(arrRows[i],regexPat)
        If (!ret) {
            Break
        }
        matchCnt++
        i++
    }
    If (i>len && matchCnt==maxMatchCnt) { 
        meetBorder := false
    } Else{
        meetBorder := true
    }
    If (meetBorder) {
        ; here need output sth, because we reach the border
        while(i<=len) {
            arrRows.Pop()
            i++
        }
        Switch dirTo {
        Case "Down":
        Case "Up":
            arrRows := ReverseArray(arrRows)
        Default:
            z_log("ERROR", "unknow parameter " dirTo)
            Return 0
        }
        output := ""
        For i,row in arrRows {
            output .= row
            If (i!=arrRows.Count()) {
                output .= "`n"
            }
        }
    }
    Return matchCnt
}

CopyMarkdownTableToBorderLine(borderType, ByRef textMarkdownTable, alreadyInMarkdownTableRow:=False) {
    ; return LineSelectAndCopyWhile()
    Switch borderType {
    Case "begin":
        dir         := "Up"
        lineSide    := "Home"
        postAction  := "{Right}"
    Case "end":
        dir         := "Down"
        lineSide    := "End"
        postAction  := "{Left}"
    Default:
        z_log("ERROR","unknow borderType " borderType)
        Return
    }
    ; check if we are in markdown table line
    If (!alreadyInMarkdownTableRow && !IsMarkdownTableRow()) {
        z_log("INFO", "cursor is not in a markdown table row")
        return -1
    }
    ; jump to border, narrow down the range which contains the table border
    ; expand to approach the border
    MaxTryCountLines := 500
    StepDir := 7
    cnt := StepDir
    While (cnt <= MaxTryCountLines) {
        If(cnt >= 30) {
            StepDir := 20
        }
        ; 1. select without return
        SleepBeforeSelection()
        SendInput {Shift Down}{%dir% %StepDir%}{%lineSide%}{Shift Up}
        SleepAfterSelection()
        ; 2. copy
        text := DoCopyCtrlC()
        ; 3. analyze
        matchCnt := DetectMarkdownTable(text, output, meetBorder, cnt, dir)
        If (meetBorder) { 
            ; Border can be the start or end of article
            break
        }
        ; here means we are in table
        cnt += StepDir
    }
    If(cnt>MaxTryCountLines) {
        logstr = Markdown Table is too big, %borderType% line need more than %MaxTryCountLines% %Dir%
        z_log("WARN",logstr)
        Return cnt
    }
    textMarkdownTable .= output
    ; post action
    SendInput %postAction%
    return matchCnt
}

MarkdownTableForamt(insertAtColumn := 0, deleteColumn :=0, deleteTable := false) {
    ; Return test
    posInLine := IsMarkdownTableRow()
    If (!posInLine) {
        z_log("INFO", "cursor is not in a markdown table row. Stop table format")
        Return
    }
    text := ""
    upCnt     := CopyMarkdownTableToBorderLine("begin",text,True)
    downCnt   := CopyMarkdownTableToBorderLine("end",  text,True)
    z_log("DEBUG", "upCnt=" upCnt ",downCnt=" downCnt ",posInLine=" posInLine)
    z_log("DEBUG", "text =>`n" text)
    DeleteCursorAroundlines(upCnt,downCnt)
    ; SleepBasedOnText()
    If(deleteTable) {
        z_log("DEBUG", "delete table")
        return
    }
    z_log("DEBUG", "insertAtColumn=" insertAtColumn ",deleteColumn=" deleteColumn)
    text := Tablize(text, insertAtColumn, deleteColumn)
    z_log("DEBUG", "text after format =>`n" text)
    SendByPaste(text)  ; faster for long text than raw text input
    ; back to what cursor start
    backUpCnt    := downCnt + 1
    backRightCnt := posInLine
    ; z_log("DEBUG", "backUpCnt=" backUpCnt ",posInLine=" posInLine)
    SendInput {Up %backUpCnt%}{Right %backRightCnt%}
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

; [Unicode中文和特殊字符的编码范围 及部分正则_标准中文码_chvalrous的博客-CSDN博客](https://blog.csdn.net/chivalrousli/article/details/77412329 )
; 其实，游戏内大部分的玩家名都取自：中日韩统一表意文字（CJK Unified Ideographs），外加一些特殊的字符；用 [ \u2E80-\uFE4F]+基本都涵盖了 
IsCharChinease(char) {
    charCode := Ord(char)
    If (0x2E80 <= charCode && charCode<=0xFE4F) {
        return true
    } else {
        return false
    }
}

StrLenWithChinease(str) {
    len := StrLen(str)
    Loop, Parse, % str
    {
        If (IsCharChinease(A_LoopField)) {
            len++
        }
    }
    Return len
}

; ============================================
; ========== Table ===========================
; ============================================
PadStr(str, size,alignMode:="Left") {
    diff := size - StrLenWithChinease(str)
    If (diff<0) {
        logstr = strlen %str% is bigger than %size%
        z_log("ERROR",logstr)
        Return ""
    }
    Switch alignMode {
    Case "Left", "Default":
        Loop % diff
           str .= A_Space
    Case "Right":
        Loop % diff
           str := A_Space . str
    Case "Center":
        Loop % Floor(diff/2)
           str := A_Space . str
        Loop % Ceil(diff/2)
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

ParseMarkdownTableRow(rowStr) {
    arrElementsInRow := StrSplit(rowStr, "|"," `t") ; Trim space
    ; remove first and last element
    arrElementsInRow.pop()
    arrElementsInRow.RemoveAt(1)
    return arrElementsInRow
}

Tablize(text, insertAtColumn:=0, deleteColumn := 0) {
    ; parse text to 2-D arr
    ; parse rows
    arrRows := StrSplit(text, "`n"," `t")
    ; parse columns
    arr := {}
    For index, row in arrRows {
        arrElementsInRow := ParseMarkdownTableRow(row)
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
            ; [Unicode中文和特殊字符的编码范围 及部分正则_标准中文码_chvalrous的博客-CSDN博客](https://blog.csdn.net/chivalrousli/article/details/77412329 )
            ; 其实，游戏内大部分的玩家名都取自：中日韩统一表意文字（CJK Unified Ideographs），外加一些特殊的字符；用 [ \u2E80-\uFE4F]+基本都涵盖了 
            len := StrLenWithChinease(arr[j][i])
            If (columnMaxLength < len ) {
                columnMaxLength := len
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

OutputRow(arrRow, arrColumnMaxLength, arrColumnAlignMode) {
    output .= "|"
    ; TODO
}



