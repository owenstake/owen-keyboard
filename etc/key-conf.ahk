; Env
global APPDATA, ProgramData
EnvGet, APPDATA, APPDATA
EnvGet, ProgramData, ProgramData
EnvGet, WEIYUN, WEIYUN
EnvGet, OwenHome, OwenHome

global mynote
loop files, %WEIYUN%\*, DR
{
    If (A_LoopFileName = "my_note") {
        mynote := A_LoopFileFullPath
    }
}

torbrowserPath := APPDATA . "\Microsoft\Windows\Start Menu\Programs\Scoop Apps\Tor Browser.lnk" 

; Reverse "hjkl "for move.
; Reverse "fb" for terminal move.
; Remain usable key "agy"
global KeySendMap := { "!j"  : "{Down}"
    , "!k"  : "{Up}"    
    , "!h"  : "{Left}"  
    , "!l"  : "{Right}" 
    , "!;"  : "{Home}" 
    , "!'"  : "{End}" 
    , "!u"  : "{PgUp}"  
    , "!d"  : "{PgDn}"  
    , "!+j" : "^+{Tab}" 
    , "!+k" : "^{Tab}"  }

; global HotkeyAppMap :=
global AppsConf := { "hh.exe":{"Shortcut":"!+a","ExePath":"C:\Windows\hh.exe"       }
    ,"chrome.exe"          : {"Shortcut" : "!c"
                            , "DefaultControl" : "Chrome_RenderWidgetHostHWND1"    }
    ,"Draw.io.exe"         : {"Shortcut" : "!g"                                    }
    ,"Explorer.exe"        : {"Shortcut" : "!e"
                            , "Match"               : "ahk_class CabinetWClass"
                            , "ExePath"             : "C:\Windows\explorer.exe"
                            , "DefaultControl"      : "DirectUIHWND3"
                            , "KeyMapInNoramalMode" : "ExplorerKeymapInNornalMode" }
    ,"obsidian.exe"        : {"Shortcut" : "!i"                                    }
    ,"mobaxterm.exe"       : {"Shortcut" : "!m"                                    }
    ,"WindowsTerminal.exe" : {"Shortcut" : "!n"                                    }
    ,"wezterm-gui.exe"     : {"Shortcut" : "!+n"                                    }
    ,"firefox.exe"         : {"Shortcut" : "!o"                                    
                            , "DefaultControl" : "MozillaCompositorWindowClass1"    }
    ,"wpp.exe"             : {"Shortcut" : "!p"                                    }
    ,"qq.exe"              : {"Shortcut" : "!q"                                    }
    ,"weixin.exe"          : {"Shortcut" : "!r"                                    }
    ,"FoxitPDFReader.exe"  : {"Shortcut" : "!s"
                            , "DefaultControl" : "FoxitDocWnd1"
                            , "KeyMapInNoramalMode" : "FoxitKeymapInNormalMode"    }
    ,"typora.exe"          : {"Shortcut" : "!a"                                    }
    ,"code.exe"            : {"Shortcut" : "!v"                                    }
    ,"wps.exe"             : {"Shortcut" : "!w"
                            , "ExePath"  : "C:\Program Files\Kingsoft\WPS Office\ksolaunch.exe" }
    ,"zotero.exe"          : {"Shortcut" : "!z"                                    }
    ,"msedge.exe"          : {"Shortcut" : "!+c"
                            , "DefaultControl" : "Chrome_RenderWidgetHostHWND1"    }
    ,"Everything.exe"      : {"Shortcut" : "!+e"                                   }
    ,"secUI.exe"           : {"Shortcut" : "!+s"                                   }
    ,"kwmusic.exe"         : {"Shortcut" : "!+u"                                   }
    ,"v2rayN.exe"          : {"Shortcut" : "!+v"                                   }
    ,"et.exe"              : {"Shortcut" : "!x"                                   } }

    ; ,"xshell.exe"          : {"Shortcut" : "!x"
    ;                         , "KeyMapInNoramalMode" : "XshellKeymapInNormalMode"   }

global FoxitKeymapInNormalMode := { "EditKey" : { "t"  : {"Action":"{Alt}rd2", "help":"Text box"} }
    , "MoveKey" : { "j"  : {"Action":"{Down}"    , "help":""  }
        , "k"  : {"Action":"{Up}"      , "help":""                      }
        , "u"  : {"Action":"{PgUp}"    , "help":""                      }
        , "e"  : {"Action":"{PgUp}"    , "help":""                      }
        , "d"  : {"Action":"{PgDn}"    , "help":""                      }
        , "g"  : {"Action":"^{Home}"   , "help":""                      }
        , "+g" : {"Action":"^{End}"    , "help":""                      }
        , "-"  : {"Action":"^{-}"      , "help":"zoom in"               }
        , "="  : {"Action":"^{=}"      , "help":"zoom out"              }
        , "+j" : {"Action":"^+{Tab}"   , "help":"Navigate to Left tab"  }
        , "+k" : {"Action":"^{Tab}"    , "help":"Navigate to Right tab" }
        , "+h" : {"Action":"!{Left}"   , "help":"History previous"      }
        , "+l" : {"Action":"!{Right}"  , "help":"History next"          }
        , "h"  : {"Action":"+h"        , "help":"highlight"             }
        , "l"  : {"Action":"{Alt}re1f" , "help":"Pencil line"           }
        , "o"  : {"Action":"{Alt}re1a" , "help":"Rectangle"             }
        , "q"  : {"Action":"{Esc}"     , "help":""                      }
        , "s"  : {"Action":"+s"        , "help":"delete line"           }
        , "v"  : {"Action":"{Alt}ha2a" , "help":"select"           }
        , "w"  : {"Action":"^u"        , "help":"underline"             } }
    , "CustomHandler" : "FoxitCustomKeymapHandler" }

FoxitCustomKeymapHandler(){

}
; SendMode Input
global ExplorerKeymapInNornalMode := { "MoveKey" : { "j" : {"Action":"{Down}", "help":"" }
        ,"k"     : {"Action":"{Up}"                              , "help":""                      }
        ,"h"     : {"Action":"!{Up}"                             , "help":"Up to Dir"             }
        ,"l"     : {"Action":"{Enter}"                           , "help":"Open"                  }
        ,"+h"    : {"Action":"!{Left}"                           , "help":"History previous"      }
        ,"+l"    : {"Action":"!{Right}"                          , "help":"History next"          }
        ,"g"     : {"Action":"{Home}"                            , "help":""                      }
        ,"+G"    : {"Action":"{End}"                             , "help":""                      }
        ,"+A"    : {"Action":"{Alt}hr"                           , "help":"Rename file"           }
        ,"+C"    : {"Action":"{Alt}ht"                           , "help":"Cut file"              }
        ,"+D"    : {"Action":"DeleteFile()"                      , "help":"Delete file"           }
        ,"+Y"    : {"Action":"{Alt}hco"                          , "help":"Copy file"             }
        ,"+P"    : {"Action":"{Alt}hv"                           , "help":"Paste file"            }
        ,"+X"    : {"Action":"ExtractFile()"                     , "help":"Extract file"          }
        ,"+Z"    : {"Action":"CompressFile()"                    , "help":"Compress file"         }
        ,"y & p" : {"Action":"{Alt}hcp"                          , "help":"Copy file path"        }
        ,"z & d" : {"Action":"ExplorerNavigate(""~\Downloads"")" , "help":"Go to Downloads"       }
        ,"z & h" : {"Action":"ExplorerNavigate(""~\"")"          , "help":"Go to Home"            }
        ,"z & n" : {"Action":"ExplorerNavigate(""" mynote """)"  , "help":"Go to note"            }
        ,"z & o" : {"Action":"ExplorerNavigate(""" OwenHome """)", "help":"Go to OwenHome"        }
        ,"z & r" : {"Action":"ExplorerNavigate(""~\Desktop"")"   , "help":"Go to Desktop"         }
        ,"z & w" : {"Action":"ExplorerNavigate(""" WEIYUN """)"  , "help":"Go to Weiyun"          } } }

global XshellKeymapInNormalMode := { "MoveKey" : { "f12" : {"Action":"TMOUT=0{enter}",  "help":"" } } }

