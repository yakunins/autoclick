#Requires AutoHotkey v2.0
#SingleInstance Force

; Minimal AHK v2 script to test dx9_overlay.dll
; Assumes dx9_overlay.dll is in a "lib" folder in the same directory as this script
; Press F1 to toggle overlay visibility

; Define DLL path
PATH_OVERLAY := A_ScriptDir . "\lib\dx9_overlay.dll"

; Check if DLL file exists
if (!FileExist(PATH_OVERLAY)) {
    MsgBox("Error: dx9_overlay.dll not found at " . PATH_OVERLAY)
    ExitApp
}

; Load the DLL
hModule := DllCall("LoadLibrary", "Str", PATH_OVERLAY, "Ptr")
if (!hModule) {
    errorCode := A_LastError
    MsgBox("Failed to load dx9_overlay.dll. Error code: " . errorCode . "`nPossible reasons:`n- DLL is corrupted or incompatible.`n- Missing dependencies (e.g., DirectX runtime).`n- Insufficient permissions.")
    ExitApp
}

; Function pointers (adjust based on actual API; assuming common overlay API)
; Example: CreateOverlay (void* hwnd, int x, int y, int w, int h)
pCreateOverlay := NumGet(hModule + 0, "Ptr")  ; Offset 0 is a placeholder; check actual exports
if (!pCreateOverlay) {
    MsgBox("Failed to get CreateOverlay function pointer. Check DLL exports.")
    DllCall("FreeLibrary", "Ptr", hModule)
    ExitApp
}

; Hook into game window (find PUBG window)
WinWait("ahk_exe TslGame.exe",, 30)  ; Wait up to 30 seconds
if (!WinExist("ahk_exe TslGame.exe")) {
    MsgBox("Error: PUBG window not found. Ensure PUBG is running.")
    DllCall("FreeLibrary", "Ptr", hModule)
    ExitApp
}
hwnd := WinExist("ahk_exe TslGame.exe")

; Initialize overlay (example call)
DllCall(pCreateOverlay, "Ptr", hwnd, "Int", 100, "Int", 100, "Int", 200, "Int", 100, "Cdecl")
if (A_LastError) {
    MsgBox("Failed to initialize overlay. Error code: " . A_LastError)
}

; Toggle hotkey
F1::{
    static visible := false
    visible := !visible
    ; Call toggle function if available (replace with actual function if known)
    ; DllCall(pToggleOverlay)
    ToolTip("Overlay " . (visible ? "ON" : "OFF"))
    SetTimer(() => ToolTip(), -2000)
}

; Cleanup on exit
OnExit(ExitFunc)
ExitFunc(*) {
    if (hModule)
        DllCall("FreeLibrary", "Ptr", hModule)
}
