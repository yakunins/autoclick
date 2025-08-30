; ================================
; Minimal AHK v2 Overlay Test
; ================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; Path to your DLL (adjust if needed)
dllPath := "C:\My\Dev\crosshair\lib\d3d9_overlay_imgui.dll"

; PNG image path
imgPath := "C:\My\Dev\crosshair\overlay.png"

; Load DLL
hDLL := DllCall("LoadLibrary", "Str", dllPath, "Ptr")

if !hDLL {
    MsgBox "Failed to load DLL!"
    ExitApp
}

; Simple function to draw PNG via DLL
DrawOverlay() {
    global imgPath
    ; Assuming your DLL exposes a function like: DrawPNG(char* path)
    ; Adjust function name / calling convention to your DLL
    DllCall("d3d9_overlay_imgui.dll\DrawPNG", "Str", imgPath)
}

; Hotkey to toggle overlay
F1::DrawOverlay()

; Exit
F12::ExitApp
