; Combo macro: on XButton1 press, performs f+RButton combo
; 1. f down → 2. wait 10-30ms → 3. RButton down → 4. wait 10-30ms → 5. f up
; On XButton1 release: RButton up

#Requires AutoHotkey v2.0
#SingleInstance Force

#include lib/Jsons.ahk
#include lib/UseBase64TrayIcon.ahk
#include lib/RemoveTrayTooltip.ahk
#include lib/Log.ahk

A_HotkeyInterval := 1000
A_MaxHotkeysPerInterval := 200

config := {
	hotkey: "XButton2",
	key1: "f",
	key2: "RButton",
	debug: false,
	exitHotkey: "#F12", ; ^=ctrl, !=alt, +=shift, #=win, *=any of (ctrl+alt+shift+win)
	delayMin: 10, ; min delay between steps in ms
	delayMax: 30, ; max delay between steps in ms
	trayIcon: "fire", ; one of "fire", "click", "transparent" or path to local file ("./ico/radar.ico")
}

SetTrayIcon(config.trayIcon)
RemoveTrayTooltip()
Hotkey config.exitHotkey, Quit, "On"

; computed values
downHotkey := AddAsterisk(config.hotkey)
upHotkey := AddAsterisk(config.hotkey) . " up"

Bind()
Bind() {
	Hotkey downHotkey, Keydown, "On"
	Hotkey upHotkey, Keyup, "On"
}

Unbind() {
	Hotkey downHotkey, Keydown, "Off"
	Hotkey upHotkey, Keyup, "Off"
}

RandomDelay() {
	return Random(config.delayMin, config.delayMax)
}

Keydown(key := 0) {
	; 1. key1 down
	Send "{Blind}{" . config.key1 . " down}"
	; 2. random wait
	Sleep RandomDelay()
	; 3. key2 down
	Send "{Blind}{" . config.key2 . " down}"
	; 4. random wait
	Sleep RandomDelay()
	; 5. key1 up
	Send "{Blind}{" . config.key1 . " up}"
}

Keyup(key := 0) {
	; 6. key2 up on hotkey release
	Send "{Blind}{" . config.key2 . " up}"
}

Quit(key := 0) {
	if config.debug {
		pause := 3000
		Log(Jsons.Dump(config, "  "), , , pause)
		SetTimer ExitApp, -1 * pause
	} else {
		ExitApp
	}
}

SetTrayIcon(nameOrPath) {
	if (InStr(nameOrPath, ".")) {
		if FileExist(nameOrPath)
			TraySetIcon(nameOrPath)
	} else {
		UseBase64TrayIcon(config.trayIcon)
	}
}

AddAsterisk(str) {
	if (InStr(str, "*"))
		return str
	return "*" . str
}
