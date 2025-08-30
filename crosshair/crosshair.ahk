#Requires AutoHotkey v2.0
#SingleInstance Force

#include lib/UseBase64TrayIcon.ahk
#include lib/RemoveTrayTooltip.ahk
#include lib/Log.ahk
#include lib/ImagePut.ahk

global cfg := {
    windowTitle: "Cross",
    forceWindowOnTop: 1,
    imagePath: "red-angle-crosshair.svg",
    imagePath: "red-circle-crosshair.svg",
    useMonitor: 1,
    pos: [50, 0], ; offset from center of the screen
    size: [64, 64],
    exitHotkey: ["~^Esc Up"],
    hideHotkey: ["~*RButton"],
    showHotkey: ["~*RButton Up"],
}
global state := {
    hidden: true,
    hwnd: 0
}

if !FileExist(cfg.imagePath) {
    MsgBox "File (" . cfg.imagePath . ") was not found."
    ExitApp
}

Init()
Init() {
    state.monitorCount := MonitorGetCount()
    MonitorGet(cfg.useMonitor, &Left, &Top, &Right, &Bottom)
    state.center := {}
    state.center.x := (Right - Left) / 2
    state.center.y := (Bottom - Top) / 2

    try {
        state.pos := []
        state.pos.Push(state.center.x + cfg.pos[1])
        state.pos.Push(state.center.y + cfg.pos[2])
        state.pos.Push(cfg.size[1], cfg.size[2])

        ; Layered + Transparent (click-through) + Topmost
        styleEx := 0x00080000 | 0x00000020 | 0x00000008
        state.hwnd := ImageShow(cfg.imagePath, cfg.windowTitle, state.pos, , styleEx)
        ShowCross()
    } catch as err {
        MsgBox "Error displaying image: " . err.Message
    }

    ; exit bindings
    if (cfg.exitHotkey) {
        if (IsArray(cfg.exitHotkey)) {
            for key in cfg.exitHotkey {
                Hotkey(key, HandleExit)
            }
        } else {
            Hotkey(cfg.exitHotkey, HandleExit)
        }
    }

    ; show/hide bindings
    if (cfg.hideHotkey) {
        if (IsArray(cfg.hideHotkey)) {
            for key in cfg.hideHotkey {
                Hotkey(key, HideCross)
            }
        } else {
            Hotkey(cfg.hideHotkey, HideCross)
        }
    }
    if (cfg.showHotkey) {
        if (IsArray(cfg.showHotkey)) {
            for key in cfg.showHotkey {
                Hotkey(key, ShowCross)
            }
        } else {
            Hotkey(cfg.showHotkey, ShowCross)
        }
    }

    ; Force window to stay on top of full-screen apps
    if (cfg.forceWindowOnTop) {
        SetTimer(TryOnTop, 100)
    }
}


HandleExit(thishotkey := 0) {
    ExitApp
}

ShowCross(thishotkey := 0) {
    try {
        WinShow(state.hwnd)
        state.hidden := false
        return
    }
    try {
        WinShow(cfg.windowTitle)
        state.hidden := false
        return
    }
}

HideCross(thishotkey := 0) {
    try {
        WinHide(state.hwnd)
        state.hidden := true
        return
    }
    try {
        WinHide(cfg.windowTitle)
        state.hidden := true
        return
    }
}

TryOnTop() {
    try {
        WinSetAlwaysOnTop 1, cfg.windowTitle
    }
}

IsArray(val) {
    return IsObject(val) && val is Array
}