; https://github.com/rcmdnk/vim_ahk/blob/master/lib/util/vim_ime.ahk
; Set IME, SetSts=0: Off, 1: On, return 0 for success, others for non-success
IMC_SetOpenStatus(SetSts=0, WinTitle="A"){   ; work for sogou and qq-pinyin
  ControlGet, hwnd, HWND, , , %WinTitle%
  if(WinActive(WinTitle)){
    ptrSize := !A_PtrSize ? 4 : A_PtrSize
    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
    NumPut(cbSize, stGTI, 0, "UInt") ; DWORD cbSize;
    hwnd := DllCall("GetGUIThreadInfo", Uint, 0, Uint, &stGTI)
        ? NumGet(stGTI, 8+PtrSize, "UInt") : hwnd
  }

  Return DllCall("SendMessage"
    , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint, hwnd)
    , UInt, 0x0283  ;Message : WM_IME_CONTROL
    ,  Int, 0x006   ;wParam  : IMC_SETOPENSTATUS
    ,  Int, SetSts) ;lParam  : 0 or 1
}

; Get IME Status. 0: Off, 1: On
IMC_GetOpenStatus(WinTitle="A"){  ; open input, work for sogou and qq-pinyin
  ControlGet,hwnd,HWND,,,%WinTitle%
  if(WinActive(WinTitle)){
    ptrSize := !A_PtrSize ? 4 : A_PtrSize
    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
    NumPut(cbSize, stGTI, 0, "UInt") ; DWORD cbSize;
    hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint, &stGTI)
        ? NumGet(stGTI, 8+PtrSize, "UInt") : hwnd
  }

  Return DllCall("SendMessage"
      , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint, hwnd)
      , UInt, 0x0283  ;Message : WM_IME_CONTROL
      ,  Int, 0x0005  ;wParam  : IMC_GETOPENSTATUS
      ,  Int, 0)      ;lParam  : 0
}

; lang: 1024 - CN , 1025 - EN
IMC_SetConversionMode(lang=1025, WinTitle="A") {   ; work for MS-pinyin
  ControlGet,hwnd,HWND,,,%WinTitle%
  if(WinActive(WinTitle)){
    ptrSize := !A_PtrSize ? 4 : A_PtrSize
    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
    NumPut(cbSize, stGTI, 0, "UInt") ; DWORD cbSize;
    hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint, &stGTI)
        ? NumGet(stGTI, 8+PtrSize, "UInt") : hwnd
  }

  Return DllCall("SendMessage"
      , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint, hwnd)
      , UInt, 0x0283  ;Message : WM_IME_CONTROL
      ,  Int, 0x0002   ;wParam  : IMC_SetConversionMode
	  ,  Int, lang)   ;lParam  : 1025 - CN; 1024 - EN
}

IMC_GetConversionMode(WinTitle="A"){
  ControlGet,hwnd,HWND,,,%WinTitle%
  if(WinActive(WinTitle)){
    ptrSize := !A_PtrSize ? 4 : A_PtrSize
    VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
    NumPut(cbSize, stGTI, 0, "UInt") ; DWORD cbSize;
    hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint, &stGTI)
        ? NumGet(stGTI, 8+PtrSize, "UInt") : hwnd
  }

  ; 1024 - CN , 1025 - EN
  langCode := DllCall("SendMessage"
      , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint, hwnd)
      , UInt, 0x0283  ;Message : WM_IME_CONTROL
      ,  Int, 0x0001  ;wParam  : IMC_GETCONVERSIONMODE
      ,  Int, 0)      ;lParam  : 0
  return langCode
}

global lastIMCOpenStatus     := 0
global lastIMCConversionMode := 0

SwitchInputToEnglish() {
    global lastIMCOpenStatus
    global lastIMCConversionMode
    lastIMCOpenStatus     := IMC_GetOpenStatus()
    lastIMCConversionMode := IMC_GetConversionMode()
    ; z_log("DEBUG", "lastIMCOpenStatus=" lastIMCOpenStatus ", lastIMCConversionMode=" lastIMCConversionMode)
    ; curIMCOpenStatus  := IMC_GetOpenStatus()
    ; curConversionMode := IMC_GetConversionMode()
    ; z_log("DEBUG", "curIMCOpenStatus=" curIMCOpenStatus ", curConversionMode=" curConversionMode)

    IMC_SetOpenStatus(0)  ; Notice: set this for MS-pinyin, result in openStatus=1 and conversionMode=0
    IMC_SetConversionMode(1025)   ; lang: 1024 - CN , 1025 - EN
}

SwitchInputToOrigin() {
    global lastIMCOpenStatus
    global lastIMCConversionMode
    ; curIMCOpenStatus  := IMC_GetOpenStatus()
    ; curConversionMode := IMC_GetConversionMode()
    ; z_log("DEBUG", "curIMCOpenStatus=" curIMCOpenStatus ", curConversionMode=" curConversionMode)
    ; if (curIMCOpenStatus=1) { ; Should be 0. 1 means previous SwitchInputToEnglish fails, we are using official MS-pinyin.
    ;     ; MS-pinyin use ConversionMode to set language.
    ;     IMC_SetConversionMode(lastIMCConversionMode)
    ; }
    ; z_log("DEBUG", "lastIMCOpenStatus=" lastIMCOpenStatus ", lastIMCConversionMode=" lastIMCConversionMode)
    ; Restore the last imc state
    IMC_SetOpenStatus(lastIMCOpenStatus)
    IMC_SetConversionMode(lastIMCConversionMode)   ; lang: 1024 - CN , 1025 - EN
}
