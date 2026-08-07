#SingleInstance force
; #Include %A_ScriptDir%\lib\zlog.ahk
; #Include %A_ScriptDir%\lib\anchor.ahk
#Include %A_ScriptDir%\lib\
; #Include %A_ScriptDir%\lib\lib.ahk
#Include %A_ScriptDir%\lib\markdown\table.ahk

SetTitleMatchMode 2    ; 2 is instr mode

; pattern contains three subPattern: begin, content, end
; ?: is for no-name
global formatRegexPattern :=
  ( Join
  {
  "html"              : "^(<.*[^\+]>`n)+" . "(.*)" . "(`n(?:</.*>)*" . "(?:`n<\+\+>)*" . ")$" ,
  "formationMarkdown" : "^(\$\$`n)" . "(.*)" . "(`n\$\$" . "(?:`n<\+\+>)*" . ")$" ,
  "codeblockMarkdown" : "^(``````.*`n)" . "(.*)" . "(`n``````" . "(?:`n<\+\+>)*" . ")$" ,
  "latex"             : "^(\\begin.*`n)" . "(.*)" . "(`n\\end.*"    . "(?:`n<\+\+>)*" . ")$" ,
  "end"                 : "It`s no sense string"
  }
  )

; key name must be contained in WinPattern
; key name must be contained in win title

global appsConfig := 
  ( Join
  {
  "Typora"   : {"Style":"Markdown" , "PlayEnd":False , "WinPattern":"ahk_exe Typora.exe"} ,
  "Obsidian" : {"Style":"Markdown" , "PlayEnd":True  , "WinPattern":"ahk_exe Obsidian.exe"} ,
  "CSDN"     : {"Style":"Markdown" , "PlayEnd":True  , "WinPattern":"CSDN ahk_exe chrome.exe"} ,
  "Cmd"      : {"Style":"Markdown" , "PlayEnd":True  , "WinPattern":"Cmd Markdown ahk_exe chrome.exe"} ,
  "Code"     : {"Style":"Markdown" , "PlayEnd":True  , "WinPattern":".md ahk_exe Code.exe"} ,
  "知乎"     : {"Style":"Markdown" , "PlayEnd":True  , "WinPattern":"知乎 ahk_exe chrome.exe"} ,
  "坚果"     : {"Style":"Markdown" , "PlayEnd":True  , "WinPattern":"坚果 ahk_exe chrome.exe"} ,
  "腾讯文档" : {"Style":"Markdown" , "PlayEnd":True  , "WinPattern":"腾讯文档 ahk_exe chrome.exe"} ,
  "Overleaf" : {"Style":"Latex"    , "PlayEnd":True  , "WinPattern":"Overleaf ahk_exe chrome.exe"} ,
  "end"      : {}
  }
  )

  ; Generate appsRegexPattern for match
  ; appsRegexPattern := "i)"
  global appsRegexPattern := ""
  For app, value in appsConfig {
      appsRegexPattern .= app "|"
  }
  appsRegexPattern := RegExReplace(appsRegexPattern,"\|$")
  
  global zEditors
  ; Generate zEditors for WinActive
  For app, value in appsConfig {
      win := appsConfig[app]["WinPattern"]
      If (win) {
          GroupAdd, zEditors , %win%
      }
  }
  ; z_log("DEBUG","")


figureCaptionMarkdownStr =
    ( LTrim
    `<div><center style="-typora-class:FigCnt;font-size:15px;color:#999">
    `<a name="fig:<++>"><>++>
    `</a></center></div>
    `<++>
    )

tableCaptionMarkdownStr =
    ( LTrim
    `<div><center style="-typora-class:TableCnt;font-size:15px;color:#999">
    `<a name="tbl:<++>">  <>content++>
    `</a></center></div>
    `<++>
    )

markerMarkdown1 :=
    ( LTrim Join
    {
    "help"           : "DoHelpShow()"                                         ,
    "JumpToAnchor"   : "DoJumpToAnchor()"                                     ,
    "JumpToAnchorUp" : "DoJumpToAnchor(""Up"")"                               ,
    "titleIncrease"  : "DoTitle(""Increase"")"                                   ,
    "titleDecrease"  : "DoTitle(""Decrease"")"                                   ,
    "titleRemove"    : "DoTitle(""Remove"")"                                   ,
    "title1"         : "DoTitle(""Set"",1)"                                   ,
    "title2"         : "DoTitle(""Set"",2)"                                   ,
    "title3"         : "DoTitle(""Set"",3)"                                   ,
    "title4"         : "DoTitle(""Set"",4)"                                   ,
    "title5"         : "DoTitle(""Set"",5)"                                   ,
    "bold"           : "**<++>**<++>"                                         ,
    "italic"         : "*<++>*<++>"                                           ,
    "underline"      : "<u><++></u><++>"                                      ,
    "red"            : "<font color='red'><++></font><++>"                    ,
    "deleteline"     : "~~<++>~~<++>"                                         ,
    "highlight"      : "==<++>==<++>"                                         ,
    "backquote"      : "``<++>``<++>"                                         ,
    "figure"         : "![<title++>](<path++>) <++>"                          ,
    "figureCaption"  : figureCaptionMarkdownStr                 ,
    "tableCaption"   : tableCaptionMarkdownStr,
    "figureRef" : "<a href=#fig:<++>>fig</a> <++>" ,
    "tableRef" : "<a href=#tbl:<++> <++>"
    }
    )

markerMarkdown2 :=
    ( LTrim Join
    {
    "cutLine"        : "DoCopyCurrentLine(doCut:=true)"                       ,
    "pasteLine"      : "SendByPaste(Clipboard,true)"                          ,
    "hyperlink"      : "[<title++>](<url++>) <++>"                            ,
    "checkbox"       : "DoCheckbox()"                                         ,
    "checkboxDel"    : "DoCheckbox(""Del"")"                                  ,
    "list"           : "- <++>"                                               ,
    "ref"            : "$\eqref{<++>}$<++>"                                   ,
    "keyboard"       : "<kbd><++></kbd><++>"                                  ,
    "equetion"       : "GetSnippetEquationStr()"                              ,
    "info"           : "GetSnippetWarnStr(""ℹ"" , ""#EEFFFF"" , ""#88bbFF"")" ,
    "warn"           : "GetSnippetWarnStr(""⚠"",  ""#FFFFCC"" , ""#FFCC66"")" ,

    "codeblockC"                : "GetCodeblockStr(""c"")"                           ,
    "codeblockBash"             : "GetCodeblockStr(""bash"")"                        ,
    "codeblockMermaidFlowchart" : "GetCodeblockStr(""mermaid"",mermaidFlowchartStr)" ,
    "codeblockMermaidGantt"     : "GetCodeblockStr(""mermaid"",mermaidGanttStr)"     ,
    "codeblockMermaidPie"       : "GetCodeblockStr(""mermaid"",mermaidPieStr)"       ,
    "codeblockMermaidJourney"   : "GetCodeblockStr(""mermaid"",mermaidJourneyStr)"   ,
    "codeblockMermaidSquence"   : "GetCodeblockStr(""mermaid"",mermaidSequenceStr)"  ,

    "tableCreate"    : "DoMarkdownTable(""Create"")" ,
    "tableRowAdd"    : "DoMarkdownTable(""RowAdd"")" ,
    "tableRowDel"    : "DoMarkdownTable(""RowDel"")" ,
    "tableColumnAdd" : "DoMarkdownTable(""ColAdd"")" ,
    "tableColumnDel" : "DoMarkdownTable(""ColDel"")" ,
    "tableDelete"    : "DoMarkdownTable(""Delete"")" ,
    "TableFormat"    : "DoMarkdownTable(""Format"")" ,

    "end"            : ""
    }
    )
    ; "codeblockMermaid"      : "``````mermaid`ngraph LR`n`ta-->b"           ,

    ; MsgBox You entered "%FirstName% %LastName%".
    ; ExitApp

global markerMarkdown := {}

MergeVar("markerMarkdown")

mermaidFlowchartStr =
    ( LTrim
   `%`%[Flowcharts Syntax | Mermaid](https://mermaid.js.org/syntax/flowchart.html )`%`%
   `Flowchart LR
   `    a-->b
    )

mermaidGanttStr =
    ( LTrim
   `%`%[Flowcharts Syntax | Mermaid](https://mermaid.js.org/syntax/gantt.html )`%`%
   `gantt
   `    title <title++>
   `    dateFormat  M-D
   `    axisFormat `%m-`%d
   `    section <section++>
   `    <task++>       : active,4-19,4-22
    )

mermaidPieStr =
    ( LTrim
   `pie title <title++>
   `    "<1++>" : 386
   `    "<2++>" : 85
   `    "<3++>" : 15
    )

mermaidSequenceStr =
    ( LTrim
   `sequenceDiagram
   `    actor Alice
   `    actor Bob
   `    Alice->>+Bob: Hi Bob
   `    Bob->>-Alice: Hi Alice
    )

mermaidJourneyStr =
    ( LTrim
   `journey
   `    title My working day
   `    section Go to work
   `      Make tea: 5: Me
   `      Go upstairs: 3: Me
   `      Do work: 1: Me, Cat
   `    section Go home
   `      Go downstairs: 5: Me
   `      Sit down: 5: Me
    )

DoCopyCurrentLine(doCut:=false) {
    line := GetCurrentLine(posInLine)
    Clipboard := ""
    Clipboard := line
    ClipWait 2
    If (Clipboard = "") {
        z_log("ERROR", "copy time out for text=" text)
        Return
    }
    if (doCut) {
        DeleteCurrentLine()
    }
}

DoCheckbox(action:="") {
    checkboxStr := "- [ ] "
    checkboxRegexPattern := "^(\s*- \[)(.)(\] )"
    line := GetCurrentLine(posInLine)
    pos := RegExMatch(line,"O)" checkboxRegexPattern,subPat) ; match "- [ ] "

    Switch action {
    Case "Del":
        If (pos) {
            ; delete checkbox
            line := RegExReplace(line,checkboxRegexPattern,"")
            posInLine -= StrLen(checkboxStr)
        } Else {
            z_log("INFO", "Delete fail, this line not contains a checkbox")
        }
    Default:
        If (pos) {
            ; toggle checkbox status: undo <==> done
            checkboxStatusStr := subPat[2]==" " ? "x" : " "
            line := RegExReplace(line,checkboxRegexPattern,"$1" checkboxStatusStr "$3")
        } Else {
            ; add checkbox
            line := checkboxStr . line
            posInLine += StrLen(checkboxStr)
        }
    }
    EmptyCurrentLine()
    ; SendByPaste(line) ; this is too slow
    SendInput {Raw}%line%
    SendInput {Home}{Right %posInLine%}
}

GetCodeblockStr(language, content:="<++>") {
    str =
    ( LTrim
    ``````%language%
    %content%
    ``````
    <++>
    )
    z_log("DEBUG", "test=" test)
    return str
}


; Tailing space behind \centering is for avoiding triggering auto-completion
figureLatexStr =
    ( LTrim
    `\begin{figure}[htbp!]
    `  \centering `
    `  \includegraphics[height=2 in]{<path++>}
    `  \caption{<caption++>}
    `  \label{fig:<++>}
    `\end{figure}
    `<++>
    )

listLatexStr =
    ( LTrim Join`n
   `\begin{itemize}
   `  \item <++>
   `\end{itemize}
   `<++>
    )

equationLatexStr =
    ( LTrim
   `\begin{equation}\begin{aligned}
   `  <++>
   `  \label{eq:<++>}
   `\end{aligned}\end{equation}
   `<++>
    )

global markerLatex :=
    ( Join
    {
    "help"         : "DoHelpShow()"     ,
    "JumpToAnchor" : "DoJumpToAnchor()" ,
    "bold"      : "\textbf{<++>}<++>"             ,
    "italic"    : "\textit{<++>}<++>"             ,
    "underline" : "\uline{<++>}<++>"              ,
    "red"       : "\textcolor{red}{<++>}<++>"     ,
    "deleteline"     : "\sout{<++>}<++>"               ,
    "highlight" : "\hl{<++>}<++>"                 ,
    "backquote" : "``<++>``<++>"                  ,
    "figure"    : figureLatexStr                  ,
    "hyperlink" : "\href{<url++>}{<title++>}<++>" ,
    "checkbox"  : "- [ ] "                        ,
    "list"      : listLatexStr                    ,
    "ref"       : "\ref{<label++>}<++>"           ,
    "equetion"  : "GetSnippetEquationStr()"       ,
    "info"      : "GetSnippetWarnStr(""information"",""blue!5"",""blue!20"")",
    "warn"      : "GetSnippetWarnStr(""warning"",""yellow!20"",""yellow!80"")",
    "tableCreate"    : "DoLatexTable(""Create"")" ,
    "tableRowAdd"    : "DoLatexTable(""RowAdd"")" ,
    "tableRowDel"    : "DoLatexTable(""RowDel"")" ,
    "tableColumnAdd" : "DoLatexTable(""ColAdd"")" ,
    "tableColumnDel" : "DoLatexTable(""ColDel"")" ,
    "tableDelete"    : "DoLatexTable(""Delete"")" ,
    "TableFormat"    : "DoLatexTable(""Format"")" ,
    "end"       : ""
    }
    )

; split hotStringMap =>hotStringMap1 hotStringMap2, because of error: expression too long
hotStringMap1 :=
    ( Join
    {

    ":X*?:;??"  : {"Action":"help"            , "HelpMsg":""} ,
    ":X*?:;f"   : {"Action":"JumpToAnchor"    , "HelpMsg":""} ,
    ":Xc*?:;F"   : {"Action":"JumpToAnchorUp" , "HelpMsg":""} ,
    ":X*?:;b"   : {"Action":"bold"            , "HelpMsg":""} ,
    ":X*?:;i"   : {"Action":"italic"          , "HelpMsg":""} ,
    ":X*?:;u"   : {"Action":"underline"       , "HelpMsg":""} ,
    ":X*?:;r"   : {"Action":"red"             , "HelpMsg":""} ,
    ":X*?:;s"   : {"Action":"deleteline"      , "HelpMsg":""} ,
    ":X*?:;h"   : {"Action":"highlight"       , "HelpMsg":""} ,
    ":X*?:;q"   : {"Action":"backquote"       , "HelpMsg":""} ,
    ":X*?:;o"   : {"Action":"ref"             , "HelpMsg":""} ,
    ":X*?:;k"   : {"Action":"keyboard"        , "HelpMsg":""} ,

    ":X*?:;tt"   : {"Action":"titleIncrease"  , "HelpMsg":""} ,
    ":X*?:;td"   : {"Action":"titleDecrease"  , "HelpMsg":""} ,
    ":X*?:;tr"   : {"Action":"titleRemove"    , "HelpMsg":""} ,
    ":X*?:;t0"   : {"Action":"titleRemove"    , "HelpMsg":""} ,
    ":X*?:;t1"   : {"Action":"title1"         , "HelpMsg":""} ,
    ":X*?:;t2"   : {"Action":"title2"         , "HelpMsg":""} ,
    ":X*?:;t3"   : {"Action":"title3"         , "HelpMsg":""} ,
    ":X*?:;t4"   : {"Action":"title4"         , "HelpMsg":""} ,
    ":X*?:;t5"   : {"Action":"title5"         , "HelpMsg":""}
    }
    )

; keymap
hotStringMap2 :=
    ( Join
    {
    ":X*?:;aa"   : {"Action":"hyperlink"                 , "HelpMsg":""} ,
    ":X*:;af"    : {"Action":"figureRef"                    , "HelpMsg":""} ,
    ":X*:;at"    : {"Action":"tableRef"                    , "HelpMsg":""} ,

    ":X*:;cf"   : {"Action":"figureCaption"             , "HelpMsg":""} ,
    ":X*:;ct"   : {"Action":"tableCaption"             , "HelpMsg":""} ,
    ":X*?:;dd"  : {"Action":"cutLine"                  , "HelpMsg":""} ,
    ":X*?:;pp"  : {"Action":"pasteLine"                  , "HelpMsg":""} ,
    ":X*?:;xx"  : {"Action":"checkbox"                  , "HelpMsg":""} ,
    ":X*?:;xd"  : {"Action":"checkboxDel"               , "HelpMsg":""} ,
    ":X*:;l"    : {"Action":"list"                      , "HelpMsg":""} ,
    ":X*:;e"    : {"Action":"equetion"                  , "HelpMsg":""} ,
    ":X*:;cc"   : {"Action":"codeblockBash"             , "HelpMsg":""} ,
    ":X*:;cb"   : {"Action":"codeblockC"                , "HelpMsg":""} ,
    ":X*:;mm"   : {"Action":"codeblockMermaidFlowchart" , "HelpMsg":""} ,
    ":X*:;mg"   : {"Action":"codeblockMermaidGantt"     , "HelpMsg":""} ,
    ":X*:;mp"   : {"Action":"codeblockMermaidPie"       , "HelpMsg":""} ,
    ":X*:;mj"   : {"Action":"codeblockMermaidJourney"   , "HelpMsg":""} ,
    ":X*:;ms"   : {"Action":"codeblockMermaidSquence"   , "HelpMsg":""} ,
    ":X*:;wi"   : {"Action":"info"                      , "HelpMsg":""} ,
    ":X*:;ww"   : {"Action":"warn"                      , "HelpMsg":""} ,
    ":X*:;tc"   : {"Action":"tableCreate"               , "HelpMsg":""} ,
    ":X*?:;tf"  : {"Action":"TableFormat"               , "HelpMsg":""} ,
    ":X*?:;tar" : {"Action":"TableRowAdd"               , "HelpMsg":""} ,
    ":X*?:;tdr" : {"Action":"TableRowDel"               , "HelpMsg":""} ,
    ":X*:`n|"   : {"Action":"TableRowAdd"               , "HelpMsg":""} ,
    ":X*?:;tac" : {"Action":"TableColumnAdd"            , "HelpMsg":""},
    ":X*?:;tdc" : {"Action":"TableColumnDel"            , "HelpMsg":""},
    ":X*?:;tdd" : {"Action":"TableDelete"               , "HelpMsg":""}
    }
    )
    ; "end"       :  ""

global hotStringMap := {}

MergeVar("hotStringMap")

DoHelpShow() {
    text := "Hotstring`t`tAction`n=====================`n"
    For key,val in hotStringMap {
        keyname := RegExReplace(key,":.*:")
        action := val["Action"]
        line = %keyname%`t`t%action%`n
        text .= line
    }
    MsgBox %text%
}

SnippetAll() {
    act := hotStringMap[A_ThisHotkey]["Action"]
    If (!act) {
        logstr = hot string %A_ThisHotkey% do not has action in hotStringMap.
        z_log("ERROR", logstr)
        Return
    }
    SwitchInputToEnglish()
    Snippet(act)
    SwitchInputToOrigin()
}

RegisterHotstringMap() {
    local key,val
    For key,val in hotStringMap {
        Hotstring(key,"SnippetAll")
    }
}

Snippet(action) {
    app := GetActiveApp() ; apps: Typora,Obsidian,Overleaf,CSDN
    markerStyle := GetActiveMarkerStyle() ; type: latex or markdown
    If (markerStyle="") {
        logstr = The markerStyle of "%app%" is empty!
        z_log("ERROR", logstr)
        Return
    }
    ; check interface is implemented. i.e SnippetLatexOverleaf
    funcName := "Snippet" . action . app
    If (IsFunc(funcName)) {
        logstr = Call func %funcName%
        z_log("DEBUG", logstr)
        Return %funcName%()
    } Else If (marker%markerStyle%[action]) {
        formatStr := marker%markerStyle%[action]
        Return DoFormatStr(formatStr)  ; Maybe eval str to function
    } Else {
        logstr =
        ( LTrim
        Chain check.
        %funcName% is non-exists.
        marker%markerStyle%[%action%] is non-exists!
        %A_ThisFunc% () fail
        )
        z_log("ERROR", logstr)
        Return
    }
    Return
}

DoSnippet(str) {
    StrReplace(str,"`n", "`n",lineCnt)
    if (lineCnt=0) {  ; short snippet
        ret := DoOneLineSnippet(str)
    } Else {          ; long snippet
        ret := DoLongSnippet(str)
    }
    Return ret
}

DoTitle(action:="Increase",level:=1) {
    titleLevelPattern := "^#+ "
    line := GetCurrentLine(posInLine)
    pos := RegExMatch(line,titleLevelPattern, matchStr) ; match "- [ ] "
    Switch action {
    Case "Delete":
        If (pos) {
            ; delete checkbox
            line := RegExReplace(line,titleLevelPattern,"")
            posInLine -= StrLen(matchStr)
        } Else {
            z_log("INFO", "Delete fail, this line not contains a checkbox")
        }
    Case "Increase":
        If (pos) {
            line := "#" . line
            posInLine ++
        } Else { ; no title and new it
            line := "# " . line
            posInLine += 2
        }
    Case "Decrease":
        If (pos) {
            line := RegExReplace(line,"^#","") ; remove one #
            posInLine --
        } Else { ; no title and do nothing
            ; line := line
        }
    Case "Remove":
        pos := RegExMatch(line,"P)" titleLevelPattern, subPat) ; match "- [ ] "
        If (pos) {
            line := RegExReplace(line,titleLevelPattern,"")
            posInLine -= StrLen(matchStr)
        } Else { ; no title and do nothing
            ; line := line
        }
    Case "Set":
        Loop % level
        {
            titleLevelStr .= "#"
        }
        titleLevelStr .= " "

        If (pos) {
            line := RegExReplace(line,"O)" titleLevelPattern,titleLevelStr)
            z_log("INFO", "has title")
            posInLine += StrLen(titleLevelStr) - StrLen(subPat[1])
        } Else { ; no title and do nothing
            z_log("INFO", "no title")
            line := titleLevelStr . line
            posInLine += StrLen(titleLevelStr)
        }
    Default:
        z_log("ERROR", "unknow action=" action)
        Return
    }
    EmptyCurrentLine()
    ; SendByPaste(line) ; this is too slow
    SendInput {Raw}%line%
    SendInput {Home}{Right %posInLine%}
}

DoJumpToAnchor(dir:="Down") {
    JumpToAnchor(0,dir)
}

DoFormatStr(str) {
    ; Call self-define function
    ; FoundPos := RegExMatch(str,"O)(^Do[^(]*)\(.*\)",subPat)
    formatStr := str
    isFuncCall := IsFuncCallStr(str)
    If (isFuncCall) { ; is func
        FoundPos := RegExMatch(str,"^Get")
        If FoundPos { ; Get str by func Getxxxx()
            ; getXXXStr return str for DoSnippet
            logstr = call func %str%
            z_log("DEBUG", logstr)
            formatStr := ParseFuncAndEval(str)
        } Else {
            Return ParseFuncAndEval(str)
        }
    }
    ret := DoSnippet(formatStr)
    Return ret
}

GetSnippetEquationStrMarkdown() {
    Return "$$`n<++>`n$$`n<++>"
}

GetSnippetEquationStrTypora() {
    FormatTime, CurrentTime,, HHmmss
    strTypora =
    ( LTrim
    `$$
    `\begin{equation}\begin{aligned}
    `  <++>
    `  \label{eq:<%CurrentTime%++>}
    `\end{aligned}\end{equation}
    `$$
    `<++>
    )
    Return strTypora
}

GetSnippetEquationStrLatex() {
    FormatTime, CurrentTime,, HHmmss
    strLatex = 
    ( LTrim
    `\begin{equation}\begin{aligned}
    `  <++>
    `  \label{eq:<%CurrentTime%++>}
    `\end{aligned}\end{equation}
    `<++>
    )
    return strLatex
}

CallInterface(funcName, args*) {
    app   := GetActiveApp()
    style := GetActiveMarkerStyle()
    funcNameApp   = %funcName%%app%
    funcNameStyle = %funcName%%style%
    If IsFunc(funcNameApp) {
        z_log("DEBUG","call "funcNameApp)
        ret := %funcName%%app%(args*)
    } Else if IsFunc(funcNameStyle) {
        z_log("DEBUG","call "funcNameStyle)
        ret := %funcName%%style%(args*)
    } Else {
        logstr = %A_ThisFunc% %args% fail
        z_log("ERROR",logstr)
    }
    Return ret
}

GetSnippetEquationStr() {
    Return CallInterface("GetSnippetEquationStr")
}

GetSnippetFigureCaptionStr() {
    str =
    ( LTrim
   `<div>
   `<center style="font-size:15px;color:#999"><a name="fig:<++>">
   `Fig. <>++>
   `</center></div>
   `<++>
    )
    Return str
}

GetSnippetWarnStr(emoji, backGroundColor, borderColor) {
    ; SendInput {Raw}GetSnippetWarnStr %emoji% %backGroundColor% %borderColor%`n
    ; <div style=''> for trigger typora render. Avoid long <div> delay too much.
    strMarkdown =
    ( Join LTrim
    <div style=''>`n
    <div style='background-color:%backGroundColor%;border-color:%borderColor%;
        border-radius:4px;
        border-width:2px;
        border-style:solid;
        margin:1em'>
    <ul style='list-style-type:"%emoji%";
        list-style-position:outside;
        margin:0em;
        padding-left:1.8em;'>
    <li style='padding-left:0.3em'><nobr>`n
    <>content++>`n
    </li></ul></div></div>`n
    <++>
    )

    strLatex =
    ( LTrim
    `\begin{mdframed}[backgroundcolor=%backGroundColor%,linecolor=%borderColor%,linewidth=2pt,roundcorner=4pt]
    `  \begin{itemize}[leftmargin=*]    `% no leftmargin
    `  \item[\emoji{%emoji%}]
    `    <warn++>
    `  \end{itemize}
    `\end{mdframed}
    `<++>
    )

    type := GetActiveMarkerStyle()
    Return str%type%
}

DoLongSnippet(str) {
    stages := ParseStrToThreeAction(str)
    playedLineCnt := StagePlayCommon(stages)
    ; Jump to the second line of playedText. Such as the next line of $$.
    JumpToAnchorWithHomeUp( playedLineCnt-2 )
    Return
}

DoParseStrToThreeAction(str, regexPattern) {
    stages := []
    FoundPos := RegExMatch(str,"UO)" . regexPattern, matchObj) ; `n triger a html render
    If (!FoundPos) {
        return []
    }
    If (FoundPos and matchObj.Count()==3) {
        Loop, 3
        {
            stages.Push(matchObj[A_Index])
        }
    } else {
        logstr =
        ( LTrim
        fail parse stages in regex match!
        matchObj count = %cnt%
        FoundPos       = %FoundPos%
        regexPatern    = %regexPatern%
        str =>
        %str%
        )
        z_log("DEBUG", logstr)
    }
    return stages
}

ParseStrToThreeAction(str) {
    For key,value In formatRegexPattern {
        stages := DoParseStrToThreeAction(str,value)
        If (stages.Count() = 3) {
            return stages
        }
    }
    logstr =
    ( LTrim
    fail parse stages based on array formatRegexPattern. str =>
    %str%
    )
    z_log("ERROR", logstr)
    return []
}

GetActiveApp() {
    WinGetTitle, title, A
    RegExMatch(title,appsRegexPattern,app)
    If (app = "") {
        logstr = This title is not in allowed app list. %title%
        z_log("ERROR", logstr)
    }
    Return app
}

GetActiveMarkerStyle() {
    app := GetActiveApp()
    Return appsConfig[app]["Style"]
}

; Trim space except the first line.
; Because editor has auto leading space at new line
FormatContentLeadingSpace(content) {
    Return RegExReplace(content, "`n[ `t]+", "`n")
}

; Prepare for trim last-line leading space later
FormatEndStageTrimFirstReturn(str) {
    return RegExReplace(str,"^`n")
}

PlayStages(text) {
    firstLineLen := 0
    arr := StrSplit(text, "`n")
    For index,line in arr {
        If (index = 1) {
            ; SendInput {Raw}%line%
            firstLineLen := StrLen(line)
        } Else {
            SendInput `n
            If (index = 2) {
                ; wait for render time
                timeSleep := Format("{1:.2f}", firstLineLen / 200 + 0.2)  ; second
                Sleep % timeSleep*1000
                logstr = timeSleep %timeSleep%s for render
                z_log("DEBUG", logstr)
            }
            ; Space for avoid backspace empty line
            SendInput {Space}^{Backspace}
            ; SendInput {Space}^{Backspace}{Raw}%line%
        }
        SendInput {Raw}%line%
    }
}

StagePlayCommon(stages) {
    app     := GetActiveApp()
    endPlay := appsConfig[app]["PlayEnd"]
    IF (endPlay = "") {
        z_log("ERROR", "PlayEnd is empty for " app)
        Return 0
    }

    beginStage   := stages[1]
    contentStage := stages[2]
    endStage     := stages[3]

    playedText := beginStage . contentStage
    If (endPlay) {
        playedText .= endStage
    }
    PlayStages(playedText)
    If (playedText = "") {
        playedLineCnt := 0  ; played nothing
    } Else {
        StrReplace(playedText,"`n", "`n", playedLineCnt)
        playedLineCnt++
    }
    Return playedLineCnt
}

; main
Hotkey, IfWinActive, ahk_group zEditors
RegisterHotstringMap()
Hotkey, IfWinActive

