
Z_LOG_STRINGS := ["DEBUG","INFO","WARN","ERROR","END"]
LOG_PREFIX_STR := "Z_LOG_LEVEL_"
; generateLogLevel() {
; 	global
; 	local level,val
; }
For level,val in Z_LOG_STRINGS { 
	%LOG_PREFIX_STR%%val% := level
}
;generateLogLevel()

Z_CUR_TOOLTIP_LOG_LEVEL := %LOG_PREFIX_STR%DEBUG
Z_CUR_FILE_LOG_LEVEL    := %LOG_PREFIX_STR%DEBUG
; global Z_CUR_FILE_LOG_LEVEL    := Z_LOG_DEBUG
Z_LOGFILE := A_ScriptDir "\ahk_z.log"
FileDelete, %Z_LOGFILE%

; z_log("ERROR", "Z_CUR_TOOLTIP_LOG_LEVEL:" Z_CUR_TOOLTIP_LOG_LEVEL ".")
; z_log("ERROR", "Z_CUR_FILE_LOG_LEVEL:" Z_CUR_FILE_LOG_LEVEL ".")
; z_log("ERROR", "level:" level ".")

z_log(logLevelStr, log) {
	global  ; for default ref global var like Z_LOG_LEVEL_*
	local log_level, logstr   ; avoid to become gobal

	log_level := %LOG_PREFIX_STR%%logLevelStr%
	If !(%LOG_PREFIX_STR%DEBUG<=log_level && log_level<=%LOG_PREFIX_STR%ERROR) {
		z_log("ERROR", "logLevelStr is illegal " logLevelStr)
		return
	}

    funcName := Exception("", -2).what
    logstr := Z_LOG_STRINGS[log_level] " | " funcName " " log

    ; log to file
    If (log_level >= Z_CUR_FILE_LOG_LEVEL) {
        FormatTime, TimeString,, yyyy-MM-dd HH:mm:ss
        logstrTofile := TimeString " | " logstr
        FileAppend, %logstr%`n, %Z_LOGFILE%
    }
    ; log to tooltip
    If (log_level >= Z_CUR_TOOLTIP_LOG_LEVEL) {
        tooltip % logstr
        SetTimer, RemoveToolTip, 5000
    }
    return

    RemoveToolTip:    ; remove tooltip after 5s
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}
