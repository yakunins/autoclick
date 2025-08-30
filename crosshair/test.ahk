#Requires AutoHotkey v2.0
#SingleInstance Force

; Minimal AHK v2 script to test dx9_overlay.dll
; Assumes dx9_overlay.dll is in a "lib" folder in the same directory as this script
; and you have the required dependencies (e.g., DX9 runtime)
; Run this while PUBG is in fullscreen (DX9 mode if possible)
; Press F1 to toggle overlay visibility

PATH_OVERLAY := A_ScriptDir . "\lib\dx9_overlay.dll"

; Load the DLL
hModule := DllCall("LoadLibrary", "Str", PATH_OVERLAY, "Ptr")
if (!hModule) {
    MsgBox("Failed to load dx9_overlay.dll")
    ExitApp
}

; Function pointers (adjust based on actual API; assuming common overlay API)
; Example: CreateOverlay (void* hwnd, int x, int y, int w, int h)
pCreateOverlay := NumGet(hModule + 0, "Ptr")  ; Offset 0 example; check actual exports
; Add more as needed, e.g., pRenderText, etc.

; Hook into game window (find PUBG window)
WinWait("ahk_exe TslGame.exe")  ; PUBG executable
hwnd := WinExist("ahk_exe TslGame.exe")

; Initialize overlay (example call)
if (pCreateOverlay)
    DllCall(pCreateOverlay, "Ptr", hwnd, "Int", 100, "Int", 100, "Int", 200, "Int", 100)

; Toggle hotkey
F1::{
    static visible := false
    visible := !visible
    ; Call toggle function if available
    ; DllCall(pToggleOverlay)
    ToolTip("Overlay " . (visible ? "ON" : "OFF"))
    SetTimer(() => ToolTip(), -2000)
}

; Cleanup on exit
OnExit(ExitFunc)
ExitFunc(*) {
    DllCall("FreeLibrary", "Ptr", hModule)
}
