#Requires AutoHotkey v2.0
#SingleInstance Force

#include lib/Jsons.ahk
#include lib/MergeObjects.ahk
#include lib/UseBase64TrayIcon.ahk
#include lib/RemoveTrayTooltip.ahk
#include lib/Log.ahk

A_HotkeyInterval := 1000
A_MaxHotkeysPerInterval := 200

config := {
	click: "LButton",
	clicksPerSecond: 13, ; CPS, average clicks per second, world record is 14.1 CPS
	debug: false,
	exitHotkey: "#F12", ; ^=ctrl, !=alt, +=shift, #=win, *=any of (ctrl+alt+shift+win)
	hotkey: "MButton",
	localConfig: "./config.json", ; localConfig > config
	timingDeviationPercentage: 10, ; +/- % of clicksPerSecond
	trayIcon: "click", ; one of "fire", "click", "transparent" or path to local file ("./ico/radar.ico")
}
config := MergeObjects(config, ReadJson(config.localConfig)) ; local config to take pecedence

SetTrayIcon(config.trayIcon)
RemoveTrayTooltip()
Hotkey config.exitHotkey, Quit, "On"

; computed values
msPerClick := Floor(1000 / config.clicksPerSecond)
msDeviation := Floor((config.timingDeviationPercentage / 100) * msPerClick)
downHotkey := AddAsterisk(config.hotkey)
upHotkey := AddAsterisk(config.hotkey) . " up"

state := {
	isHotkeyDown: false,
	storedTimestamp: TickCount(),
	periodBetweenClicks: msPerClick, ; initial value, to be randomized later
	clicksCount: 0,
}

Bind()
Bind() {
	Hotkey downHotkey, Keydown, "On"
	Hotkey upHotkey, Keyup, "On"
}

Unbind() {
	Hotkey downHotkey, Keydown, "Off"
	Hotkey upHotkey, Keyup, "Off"
}

Keydown(key := 0) {
	state.isHotkeyDown := true

	if !RealClick() {
		Send "{Blind}{" . config.click . " down}"
	}

	state.storedTimestamp := TickCount()
	state.periodBetweenClicks := RandomPeriodBetweenClicks()
	Sleep Floor(state.periodBetweenClicks / 2)
	Keyup(key)
}

Keyup(key := 0) {
	state.isHotkeyDown := false

	if !RealClick() {
		Send "{Blind}{" . config.click . " up}"
	}

	sleptTime := TickCount() - state.storedTimestamp
	unsleptTime := state.periodBetweenClicks - sleptTime
	Sleep unsleptTime

	if GetKeyState(config.hotkey, "P")
		Keydown() ; schedule next click
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

RealClick() {
	return GetKeyState(config.click, "P")
}

RandomPeriodBetweenClicks() {
	period := msPerClick + Random(msDeviation * 2) - msDeviation
	return period > 1 ? period : 1
}

TickCount() {
	DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
	DllCall("QueryPerformanceCounter", "Int64*", &counter := 0)
	return Floor(counter / (freq / 1000))
}

ReadJson(path, fileReadOptions := "UTF-8") {
	if !FileExist(path) {
		if (config.debug)
			MsgBox('json file not found: ' path)
		return {}
	}

	text := FileRead(path, fileReadOptions)
	obj := Jsons.Load(&text)
	return MergeObjects({}, obj)
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

; yet unused
Suspend() {
	if (state.isSuspended) {
		Bind()
		state.isSuspended := false
	} else {
		Unbind()
		state.isSuspended := true
	}
}