; Best way to deal with string containing space.
Quote(string) {
	return """" string """"
}

ExecWinCmd(cmd, Byref stdout) {
    exec := ComObjCreate("WScript.Shell").Exec(cmd)
    stdout := exec.StdOut.ReadAll()  ; strip tailing "`r`n" in win
	stdout := Trim(stdout, " `r`n")
	stderr := exec.StdErr.ReadAll()
    return stderr
}

GetExplorerSelectedItem() {
    arr := []
    hwnd := WinExist("A")
    for Window in ComObjCreate("Shell.Application").Windows {
        if (window.hwnd==hwnd) {
          Selection := Window.Document.SelectedItems
          for Items in Selection
              Path_to_Selection := Items.path
        }
    }
    ; Only select one item
    return Path_to_Selection
}

ExplorerNavigate(FullPath) {
    EnvGet,USERPROFILE,USERPROFILE
    FullPath     := RegExReplace(FullPath,"^~", USERPROFILE)
	explorerHwnd := WinActive("ahk_class CabinetWClass")
	For pExp in ComObjCreate("Shell.Application").Windows
	{
		if (pExp.hwnd = explorerHwnd) {	; matching window found
			pExp.Navigate("file:///" FullPath)
			return
		}
	}
}

ExtractFile() {
    fullFileName := GetExplorerSelectedItem()
    SplitPath, fullFileName, name, dir, ext, name_no_ext, drive
    qFullFileName := Quote(fullFileName)
    qDir := Quote(dir)
    run, cmd.exe /c cd %qDir% && ouch.exe decompress %qFullFileName% || pause  ; ok
    ; run, %ComSpec% /c cd ""%dir%"" `& ouch.exe decompress ""%FullFileName%"" `& pause  ; fail
    ; run, 7z x ""%FullFileName%"" -o""%dir%\%name_no_ext%""
}

CompressFile() {
    fullFileName := GetExplorerSelectedItem()
    SplitPath, fullFileName, name, dir, ext, name_no_ext, drive
    qFullFileName := Quote(fullFileName)
    qDir := Quote(dir)
    run, cmd.exe /c cd %qDir% && ouch.exe compress %qFullFileName%  %qFullFileName%.tgz || pause ; ok
    ; run, cmd.exe /c cd """"%dir%"""" && ouch.exe compress """"%fullFileName%""""  """"%fullFileName%.tgz"""" || pause ; fail
    ; run, cmd.exe /c echo %FullFilename% & cd %dir% & ouch.exe compress '%FullFileName%'  ""%FullFileName%.tgz"" & pause   ; fail
}

DeleteFile() {
    keywait shift ; avoid trigger shift+delete
    SendInput {Delete}
}

GetActiveExplorerPath()
{
	explorerHwnd := WinActive("ahk_class CabinetWClass")
	if (explorerHwnd)
	{
		for window in ComObjCreate("Shell.Application").Windows
		{
			if (window.hwnd==explorerHwnd)
			{
				return window.Document.Folder.Self.Path
			}
		}
	}
}

GetAppPath(app) {
    global APPDATA,ProgramData
	AppSearchPath := [   ProgramData . "\Microsoft\Windows\Start Menu\Programs\*.lnk"
			, APPDATA . "\Microsoft\Windows\Start Menu\Programs\*.lnk" ]

	Loop , % AppSearchPath.Length()
	{
		p := AppSearchPath[A_Index]
		Loop Files, %p%, R  ; Recurse into subfolders.
		{
            lnkFile := A_LoopFileFullPath
			; Get targetFile From LnkFile
			FileGetShortcut, %lnkFile%, targetFile
			; LnkFile compare
            SplitPath, lnkFile,,,, basenameInLnk
			If (basenameInLnk = app) {
				return lnkFile
			}
			; targetFile compare
            SplitPath, targetFile,,,, basenameInOutTarget
			If (basenameInOutTarget = app) {
				; return targetFile
				return lnkFile
			}
		}
	}
	return
}

GetAppNameByShortcut() {
    For app, conf in AppsConf {
        If (conf["shortcut"] = A_ThisHotkey) {
            return app
        }
    }
}

GetAppMatcher(app) {
    conf := AppsConf[app]
    If (conf["match"]) {
        match := conf["match"]
    } else {
        match := "ahk_exe " app
    }
    return match
}

IsWindow(hWnd){
    WinGet, dwStyle, Style, ahk_id %hWnd%
    if ((dwStyle&0x08000000) || !(dwStyle&0x10000000)) {
        ; 0x08000000 is WS_DISABLED.
        ; 0x10000000 is WS_VISIBLE.
        return false
    }
    WinGet, dwExStyle, ExStyle, ahk_id %hWnd%
    if (dwExStyle & 0x00000080) {
        ; 0x80 is WS_EX_TOOLWINDOW.
        return false
    }
    WinGetClass, szClass, ahk_id %hWnd%
    if (szClass = "TApplication") {
        return false
    }
    return true
}

InMainScreen(this_id) {
    WinGet, WinState, MinMax, ahk_id %this_id%
    if (WinState == -1) {
        return true
    }
    WinGetPos, x, y, , , ahk_id %this_id%
    return x > -100  ;if your primary screen is 0 >..
    ; if (x > -100) {    ;if your primary screen is 0 >..
    ;     ; WinSet, Bottom,, ahk_id %this_id%
    ; }
}

OwenAltTab(match) {
    WinGet, ids, list, %match%
    ; WinGet, id, list
    Loop, %ids%
    {
        this_id := ids%A_Index%
        WinGetTitle, this_title, ahk_id %this_id%
        ; msgbox, %this_id% %this_title%
        ; skip current active win
        IfWinActive, ahk_id %this_id%
            continue
        If (!IsWindow(WinExist("ahk_id" . this_id))) {
            continue
        }
        If (!InMainScreen(this_id)) {
            continue
        }
        WinActivate, ahk_id %this_id%
        break
    }
}

DoKeyToApp() {
    keywait alt ; avoid trigger alt for app
    appName := GetAppNameByShortcut()
    conf    := AppsConf[appName]
    match   := GetAppMatcher(appName)
    if WinExist(match) {  ; This will be expanded because it is a expression
        if WinActive(match) {
            ; OwenAltTab("")
            ; OwenAltTab(match)
            Send !{Esc}
            return
        } else {
            OwenAltTab(match)
            ; WinActivate, %match%
        }
    } else {
        if (conf["ExePath"]) {
            run_exe := conf["ExePath"]
        } else {
			appBasename := RegExReplace(appName,"(\w+)\.exe","$1")
            file := GetAppPath(appBasename)
			If (file = "") {
                MsgBox No found appPath for %appName% in system. Please specified a ExePath.
                return
            } else {
                run_exe := file
            }
        }
        Run,%run_exe%
    }
    return
}

DoKeySend() {
    cmd := KeySendMap[A_ThisHotkey]
    Send, %cmd%
    return
}

MouseIsOver(WinTitle) {
    MouseGetPos,,, Win
    Return WinExist(WinTitle . " ahk_id " . Win)
}

MouseIsOverTaskbar() {
	return MouseIsOver("ahk_class Shell_TrayWnd") or MouseIsOver("ahk_class Shell_SecondaryTrayWnd")
}

InInsertMode() {
	ControlGetFocus, OutputVar, A
	return InStr(OutputVar, "Edit")  ; in normal mode
}


InNormalMode() {
    WinGet, appExe, ProcessName, A    ; get current window ahk_exe
	ControlGetFocus, curCtrl, A
    ctrl := AppsConf[appExe]["DefaultControl"]
	; return true && InStr(curCtrl, ctrl)    ; in normal mode
	return AppsConf[appExe]["NormalEnabled"] && InStr(curCtrl, ctrl)    ; in normal mode
}

LongPressedSpeedUp(targetKey) {
	sleepTime := 400
	While GetKeyState(A_ThisHotkey) {
		sleep %sleepTime%
		If (sleepTime > 30) { 
			sleepTime := sleepTime / 2
		}
		send {%targetKey%}
	}
	return
}

; ; 【关键修复】强制让脚本的所有坐标（包括显示、鼠标等）都以屏幕左上角为原点
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen

; 函数：在屏幕指定位置绘制临时圆圈
DrawCircle(x, y, radius, color := "Red", thickness := 3, displayTime := 2000) {
    dia := radius * 2
    winX := x - radius
    winY := y - radius
    
    ; 【核心修复】加上 -DPIScale，彻底禁用 Windows 的缩放干扰，还原真实物理像素位置
    Gui, CircleGui:New, +AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale +HwndhWnd
    Gui, CircleGui:Color, %color%
    
    ; 创建外圆区域
    outerRegion := DllCall("CreateEllipticRgn", "Int", 0, "Int", 0, "Int", dia, "Int", dia, "Ptr")
    
    ; 创建内圆区域（用于挖空中心）
    innerDia := dia - (thickness * 2)
    innerRegion := DllCall("CreateEllipticRgn", "Int", thickness, "Int", thickness, "Int", thickness + innerDia, "Int", thickness + innerDia, "Ptr")
    
    ; 组合两个区域 (RGN_XOR = 3)，从而只留下边框
    DllCall("CombineRgn", "Ptr", outerRegion, "Ptr", outerRegion, "Ptr", innerRegion, "Int", 3)
    
    ; 应用区域到窗口
    DllCall("SetWindowRgn", "Ptr", hWnd, "Ptr", outerRegion, "Int", True)
    DllCall("DeleteObject", "Ptr", innerRegion)
    
    ; 用底层 Windows API 移动并显示窗口，不占用焦点
    DllCall("MoveWindow", "Ptr", hWnd, "Int", winX, "Int", winY, "Int", dia, "Int", dia, "Int", 1)
    DllCall("ShowWindow", "Ptr", hWnd, "Int", 4) ; SW_SHOWNOACTIVATE = 4
    
    ; 设置定时器自动销毁
    SetTimer, DestroyCircle, -%displayTime%
    return

    DestroyCircle:
        Gui, CircleGui:Destroy
    return
}

/**
 * Creates a semi-transparent, round highlight circle relative to a specific window control.
 * 
 * @param hwnd             The unique ID (HWND) of the target window.
 * @param controlClassNN   The ClassNN identifier of the target control (e.g., "Edit1").
 * @param relX             Horizontal offset (pixels) relative to the control's top-left corner.
 * @param relY             Vertical offset (pixels) relative to the control's top-left corner.
 * @param colorHex         Hexadecimal color code of the circle (Default: "FFFF33" - Light Yellow).
 * @param radius           Radius of the circle in pixels (Default: 20).
 * @param alpha            Transparency layer level (0 to 255, where 0 is invisible, 255 is solid. Default: 140).
 * @param duration         Time in milliseconds before the circle auto-destroys (Default: 1500).
 * @return                 Returns the unique HWND handle of the created circle GUI.
 */
HighlightControlCircle(hwnd, controlClassNN, relX, relY, colorHex:="FFFF33", radius:=20, alpha:=140, duration:=1500) {
    diameter := radius * 2
    
    ; 1. Retrieve coordinates of the window and the control
    WinGetPos, winX, winY, , , ahk_id %hwnd%
    ControlGetPos, cX, cY, , , %controlClassNN%, ahk_id %hwnd%
    if (ErrorLevel)
        return 0 
        
    ; 2. Calculate the centered absolute screen coordinates
    screenX := winX + cX + relX - radius
    screenY := winY + cY + relY - radius

    ; 3. Instantiate a new dynamic GUI layer
    Gui, New, +HwndhGuiCircle -Caption +AlwaysOnTop +ToolWindow -SysMenu +E0x20
    Gui, %hGuiCircle%: Color, %colorHex% ; Set the window color directly to the highlight color
    
    ; 4. Render the canvas first (NoActivate) so Windows can register its size
    Gui, %hGuiCircle%: Show, x%screenX% y%screenY% w%diameter% h%diameter% NoActivate

    ; 5. FIX: Force Windows to crop the square GUI into a perfect circle using Region command
    ; "E" at the end tells Windows to make it an ellipse/circle
    WinSet, Region, 0-0 W%diameter% H%diameter% E, ahk_id %hGuiCircle%
    
    ; 6. Set the transparency layer level
    WinSet, Transparent, %alpha%, ahk_id %hGuiCircle%

    ; 7. Timer destruction using a BoundFunc object
    if (duration > 0) {
        timerObj := Func("DestroyCircleHL").Bind(hGuiCircle)
        SetTimer, % timerObj, % -duration
    }
    
    return hGuiCircle 
}

; Internal helper function to clean up the specific GUI instance
DestroyCircleHL(hGui) {
    Gui, %hGui%: Destroy
}


;====== Handler ============================================
CtrlMHandler() {
    WinGet, appExe, ProcessName, A    ; get current window ahk_exe
    ctrl := AppsConf[appExe]["DefaultControl"]

    ControlGetPos, CtrlX ,CtrlY, ControlWidth, ControlHeight, %ctrl%, A
    WinGetPos, WinX, WinY,,, A
    ; click right bottom conner
    ; Controlclick, %ctrl%, A,,,, NA x1000 y100
    
    Py := WinY +CtrlY  + ControlHeight-30
    Px := WinX +CtrlX  + ControlWidth -30

    ; ToolTip, control click %ctrl% %appExe%, %ControlWidth%, %ControlHeight%
    ToolTip, control click %ctrl% %appExe% %Px% %Py%, %Px%, %Py%
    SetTimer, RemoveToolTip, -3000 ; Hides after 3 seconds

    ErrorLevel := 0

    Cx := ControlWidth -20
    Cy := ControlHeight -20

    ; ControlFocus, %ctrl%, A   ; failed in chrome/firefox, ok in Foxit/Explorer
    ControlClick, %ctrl%, A,,,, NA x%Cx% y%Cy%  ; Most ok but fail in firefox 
    ; Click, %Px% %Py%   ; fail in chrome/firefox

    ; Click, 500,500
    HighlightControlCircle(WinExist("A"),ctrl,Cx,Cy)
    ; Send, {F6}{F6} ; only work for chrome
    ; send, {esc 3}
    ; 检查执行结果
    if (ErrorLevel) {
        MsgBox, 16, error错误, 找不到该控件或窗口！请检查控件名是否正确。
    } else {
        ToolTip, ok焦点已成功切换！
        SetTimer, RemoveToolTip, -1500
    }

      return

      RemoveToolTip:
      ToolTip
      return
}

; AnyKeyWait() { 
  ;    Input, L, L1 
    ; }

PlayAltKeySequence(seq) {
    If (!RegExMatch(seq, "iP)^{*alt}", matchObjLen)) {
        ; msgbox It is not alt key sequence
        return
    }
    len := strlen(seq)
    curPos := 1
    ; AnyKeyWait()
    ; BlockInput On
    ; keywait, control
    sleep 300    ; wait for hotkey key release, otherwise alt will disturb.
    ; keywait, shift
    ; send {Lalt} 
    send % substr(seq, 1, matchObjLen)
    curPos += matchObjlen
    while (curPos<=len) {
        remainSeq := substr(seq,curPos,len)
        If (RegExMatch(remainSeq, "iP)^\D\d*", matchObjLen)) {
            sleep 400
            send % substr(remainSeq, 1, matchObjLen)
            ; msgbox % remainSeq " " matchObjLen
            curPos += matchObjLen
        } else {
            msgbox % "Error alt key seq " seq " remain is " remainSeq
            return -1
        }
    }
    ; BlockInput off
    return
}

KeyMapHandler() {
    WinGet, appExe, ProcessName, A    ; get current window ahk_exe
    mapVarName := AppsConf[appExe]["KeyMapInNoramalMode"]
    map        := %mapVarName%
    key        := A_ThisHotkey
    ; move keymap
    If (!GetKeyState("CapsLock", "P") && action := map["MoveKey"][key]["Action"]) {
        zFuncCallPattern := "^(\w+)\((.*)\)$"
        If (IsFuncCallStr(action)) {
            ret := ParseFuncAndEval(action)
            return ret
        }
        ; long alt key sequence, need slow down for no missing
        If (InStr(action, "{alt}")) {
            PlayAltKeySequence(action)
        } else {
            send % action
        }
        return
    }
    If (action := map["EditKey"][key]["Action"]) {
        send % action
        AppsConf[appExe]["NormalEnabled"] := false  ; enter insert mode
        return
    }
    If (map["CustomHandler"]) {
        return
    }

    sendinput % key
    return
}

WinActiveAndCapsDown(winPattern) {
    return WinActive(winPattern) && GetKeyState("CapsLock", "P") ; capslock + m
}

WinActiveAndInNormalMode(pattern) {
    return WinActive(pattern) && InNormalMode() && !GetKeyState("CapsLock", "P")  ; capslock is remaped
}

WinActiveAndInInsertMode(pattern) {
    return WinActive(pattern) && !InNormalMode() && !GetKeyState("CapsLock", "P")  ; capslock is remaped
}

EnterNormalMode() {
    WinGet, appExe, ProcessName, A    ; get current window ahk_exe
	AppsConf[appExe]["NormalEnabled"] := true
}

EnterInsertMode() {
    WinGet, appExe, ProcessName, A    ; get current window ahk_exe
	AppsConf[appExe]["NormalEnabled"] := false
    mouseclick,,,,2
}

