#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib/interceptor/AutoHotInterception.ahk
#Include lib/Log.ahk
#Include lib/Jsons.ahk

AHI := AutoHotInterception() ; https://github.com/evilC/AutoHotInterception
keyboardId := AHI.GetKeyboardId(0x046D, 0xC52B)
;keyboardId := AHI.GetKeyboardIdFromHandle("HID\VID_046D&PID_C52B&REV_1211&MI_00")

cfg := {
    waitMin: 4,
    waitMax: 16,
    debug: true
}
keys := {
    peek: "a", ; pseudo
    peekleft: "z",
    peekright: "c",
    shift: "shift", ; pseudo
    left: "s",
    right: "f",
    forward: "e",
    back: "d",
}
keynames := InvertObject(keys)
real := { ; real state of buttons pressed
    peek: 0,
    left: 0,
    right: 0,
    forward: 0,
    shift: 0,
}
sending := {
    peekleft: 0,
    peekright: 0,
    shift: 0
}

if (cfg.debug)
    SetTimer Debug, 200

Bind()
Bind() {
    AHI.SubscribeKey(keyboardId, Code(keys.peek), false, HandlePeek)
    AHI.SubscribeKey(keyboardId, Code(keys.left), false, HandleLeft)
    AHI.SubscribeKey(keyboardId, Code(keys.right), false, HandleRight)
    AHI.SubscribeKey(keyboardId, Code(keys.forward), false, HandleForward)
    AHI.SubscribeKey(keyboardId, Code(keys.shift), true, HandleShift) ; block
}

HandlePeek(dir) {
    if (dir == 1) { ; press
        real.peek := 1
        Up(keys.shift)
        if (real.left == 1)
            Down(keys.peekleft)
        if (real.right == 1)
            Down(keys.peekright)
    }
    if (dir == 0) { ; release
        real.peek := 0
        Up(keys.peekleft)
        Up(keys.peekright)
        if (real.forward == 1 and real.shift == 0)
            Down(keys.shift)
    }
}

HandleLeft(dir) {
    if (dir == 1) { ; press
        real.left := 1
        if (real.peek == 1)
            Down(keys.peekleft)
    }
    if (dir == 0) { ; release
        real.left := 0
        Up(keys.peekleft)
    }
}

HandleRight(dir) {
    if (dir == 1) { ; press
        real.right := 1
        if (real.peek == 1)
            Down(keys.peekright)
    }
    if (dir == 0) { ; release
        real.right := 0
        Up(keys.peekright)
    }
}

HandleForward(dir) {
    if (dir == 1) { ; press
        real.forward := 1
        if (real.shift == 0 and real.peek == 0)
            Down(keys.shift)
    }
    if (dir == 0) { ; release
        real.forward := 0
        Up(keys.shift)
    }
}

; invert shift
HandleShift(dir) {
    if (dir == 1) { ; press
        real.shift := 1
        Up(keys.shift)
    }
    if (dir == 0) { ; release
        real.shift := 0
        if (real.forward == 1)
            Down(keys.shift)
    }
}

Down(key) {
    keyname := keynames.%key%
    if (sending.%keyname% == 1)
        return

    Sleep Rnd()
    AHI.SendKeyEvent(keyboardId, Code(key), 1)
    sending.%keyname% := 1
}

Up(key) {
    keyname := keynames.%key%
    if (sending.%keyname% == 0)
        return

    Sleep Rnd()
    AHI.SendKeyEvent(keyboardId, Code(key), 0)
    sending.%keyname% := 0
}

Code(char) {
    return GetKeySC(char)
}

Rnd() {
    return Random(cfg.waitMax - cfg.waitMin) + cfg.waitMin
}

InvertObject(obj) {
    result := {}
    For p, v in obj.OwnProps() {
        result.%v% := p ; append 'inverted' prop
    }
    return result
}

Debug() {
    ;r := Jsons.Dump(real, "  ")
    ;c := Jsons.Dump(cfg, "  ")
    ;k := Jsons.Dump(keys, "  ")
    ;kn := Jsons.Dump(keynames, "  ")
    rl := Jsons.Dump(real, "  ")
    st := Jsons.Dump(sending, "  ")
    Log(rl '----' st)
}

*^Esc:: ExitApp