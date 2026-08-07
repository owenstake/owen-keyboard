#SingleInstance force
#NoEnv
; #MaxHotkeysPerInterval 200
; #MenuMaskKey vkE8

; #Include %A_ScriptDir%\lib
#include %A_LineFile%\..\etc\key-conf.ahk
#include %A_LineFile%\..\lib\functionStr.ahk
#include %A_LineFile%\..\lib\lib-keyremap.ahk
#include *i %A_LineFile%\..\custom.ahk

SendMode Input
SetCapsLockState, AlwaysOff

;========================================================
;====== Main ============================================
;========================================================
; Global keymap setting
; key => vim move hjkl
For key, value in KeySendMap {
    Hotkey, %key%, DoKeySend
}

global CtrlMGroup
global NornalModeGroup

; App keymap setting
For appExe, conf in AppsConf {
    appMatcher := GetAppMatcher(appExe)
    ; Key => app . Register App hotkey
    key := conf["shortcut"]
    Hotkey, %key%, DoKeyToApp
    ; Normal Mode
    If (conf["KeyMapInNoramalMode"]) {
        AppsConf[appExe]["NormalEnabled"] := true
        GroupAdd, NornalModeGroup, %appMatcher%
        Hotkey, If, WinActiveAndInInsertMode("ahk_group NornalModeGroup")
            Hotkey, ~Esc, EnterNormalMode
            Hotkey, ^[,   EnterNormalMode
        Hotkey, If
        Hotkey, If, WinActiveAndInNormalMode("ahk_group NornalModeGroup")
            Hotkey, i, EnterInsertMode
        Hotkey, If
        Hotkey, If, WinActiveAndInNormalMode("ahk_group NornalModeGroup")
            keyMapStr := conf["KeyMapInNoramalMode"]
            If (keyMapStr) {
                keyMap  := %keyMapStr%
                moveKey := keyMap["MoveKey"]
                For key, in moveKey  {
                    Hotkey, %key%, KeyMapHandler
                }
                editKey := keyMap["EditKey"]
                For key, in editKey  {
                    Hotkey, %key%, KeyMapHandler
                }
            }
        Hotkey, If
    }
    ; Control M
    If (conf["DefaultControl"]) {
        GroupAdd, CtrlMGroup, %appMatcher%
        Hotkey, If, WinActiveAndCapsDown("ahk_group CtrlMGroup")
            Hotkey, ^m, CtrlMHandler
        Hotkey, If
    }
}

ToggleAppInAltTabList() {
    Winget, id, id, A
    ; Toggle
    WinSet, ExStyle, ^0x80, A ; 0x80 is WS_EX_TOOLWINDOW

    ; Get current state
    WinGet, ExStyle, ExStyle, A ; 0x80 is WS_EX_TOOLWINDOW
    If (ExStyle & 0x80) {
       MsgBox The window is remove from alt-tab list.
    } else {
       MsgBox The window is add to alt-tab list.
    }
}

; hotkeys threads
Launch_Mail::LongPressedSpeedUp("Volume_Down")
Browser_Home::LongPressedSpeedUp("Volume_Up")
CapsLock::LCtrl
RAlt::Esc
!+p::ToggleAppInAltTabList()

#If, WinActiveAndCapsDown("ahk_group CtrlMGroup")
#If

; Normal mode
#If, WinActiveAndInNormalMode("ahk_group NornalModeGroup")  ; For "hotkey, If"
#If

; Insert mode
#If, WinActiveAndInInsertMode("ahk_group NornalModeGroup")  ; For "hotkey, If"
#If

#If MouseIsOverTaskbar()
	WheelUp::Send  {Volume_Up}     ; Wheel over taskbar: increase/decrease volume.  One space after send is important
	WheelDown::Send {Volume_Down}
#If

#If WinActive("Explorer.exe") and GetKeyState("CapsLock", "P")
    u::send {PgUp}
    d::send {PgDn}
#If

