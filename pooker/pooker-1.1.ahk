#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib/interceptor/AutoHotInterception.ahk
#Include lib/Log.ahk
#Include lib/Jsons.ahk

*^Esc:: ExitApp

AHI := AutoHotInterception() ; https://github.com/evilC/AutoHotInterception
mouseId := 11 ; AHI.GetMouseId(...)
keyboardId := 2 ; AHI.GetKeyboardId(0x046D, 0xC52B)

cfg := {
    wait: {
        min: 6, ; 165hz = 6ms per frame
        max: 24,
    },
    debug: false,
}

; actions to buttons mapping (in-game key bindings)
acts := {
    peek: "a",
    peekleft: "z",
    peekright: "c",
    left: "s",
    right: "f",
    forward: "e",
    back: "d",
    run: "Shift", ; blocked
    crouch: "b",
    prone: "x",
    inventory: "n",
    map: "m",
    jump: "Space", ; blocked
    aim: "NumpadMult",
    ads: "RButton", ; aim down sights
    fire: "LButton",
}
keys := InvertObject(acts)
codes := MapObject(acts, Code)
real := MapObject(keys, (v) => 0) ; real keys status
real._timestamp := A_TickCount
sent := MapObject(keys, (v) => 0) ; fake keys sending status

mouseCodes := {
    LButton: 0,
    RButton: 1,
    MButton: 2,
    XButton1: 3,
    XButton2: 4,
    WheelDown: 5,
    WheelUp: 6,
}

if (cfg.debug)
    SetTimer Debug, 200

Bind()
Bind() {
    AHI.SubscribeKeyboard(keyboardId, false, MarkTime)
    AHI.SubscribeKey(keyboardId, codes.peek, false, HandlePeek)
    AHI.SubscribeKey(keyboardId, codes.left, true, HandleLeft) ; block
    AHI.SubscribeKey(keyboardId, codes.right, true, HandleRight) ; block
    AHI.SubscribeKey(keyboardId, codes.forward, true, HandleForward) ; block
    AHI.SubscribeKey(keyboardId, codes.back, true, HandleBack) ; block
    AHI.SubscribeKey(keyboardId, codes.run, true, HandleRun) ; block
    AHI.SubscribeKey(keyboardId, codes.jump, true, HandleJump) ; block
    AHI.SubscribeKey(keyboardId, codes.crouch, false, HandleCrouch)
    AHI.SubscribeKey(keyboardId, codes.inventory, false, HandleInventory)
    AHI.SubscribeKey(keyboardId, codes.map, false, HandleMap)
    ; mouse
    AHI.SubscribeMouseButton(mouseId, mouseCodes.%acts.fire%, false, HandleFire)
    AHI.SubscribeMouseButton(mouseId, mouseCodes.%acts.ads%, false, HandleADS)
}

MarkTime(code := -1, state := -1) {
    real._timestamp := A_TickCount
}

HandlePeek(dir) {
    real.%acts.peek% := dir
    MarkTime()

    if (dir == 1) { ; press
        Up(acts.run)
        if (real.%acts.left% == 1)
            Down(acts.peekleft)
        if (real.%acts.right% == 1)
            Down(acts.peekright)
    }
    if (dir == 0) { ; release
        Up(acts.peekleft)
        Up(acts.peekright)
        if (real.%acts.forward% == 1 and real.%acts.run% == 0) ; run after peeking
            Down(acts.run)
        if (real.%acts.forward% == 1) ; after peeking
            Down(acts.forward)
        if (real.%acts.back% == 1) ; after peeking
            Down(acts.back)
        if (real.%acts.left% == 1) ; after peeking
            Down(acts.left)
        if (real.%acts.right% == 1) ; after peeking
            Down(acts.right)
    }
}

HandleLeft(dir) {
    real.%acts.left% := dir
    MarkTime()

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1) {
            Down(acts.peekleft)
            if (real.%acts.forward% == 1 or real.%acts.back% == 1) {
                Up(acts.forward)
                Up(acts.back)
            } else {
                Down(acts.left)
            }
        } else {
            Down(acts.left)
        }
    }
    if (dir == 0) { ; release
        Up(acts.left)
        Up(acts.peekleft)
        if (real.%acts.forward% == 1)
            Down(acts.forward)
        if (real.%acts.back% == 1)
            Down(acts.back)
    }
}

HandleRight(dir) {
    real.%acts.right% := dir
    MarkTime()

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1) {
            Down(acts.peekright)
            if (real.%acts.forward% == 1 or real.%acts.back% == 1) {
                Up(acts.forward)
                Up(acts.back)
            } else {
                Down(acts.right)
            }
        } else {
            Down(acts.right)
        }
    }
    if (dir == 0) { ; release
        Up(acts.right)
        Up(acts.peekright)
        if (real.%acts.forward%)
            Down(acts.forward)
        if (real.%acts.back% == 1)
            Down(acts.back)
    }
}

HandleForward(dir) {
    real.%acts.forward% := dir
    MarkTime()

    if (dir == 1) { ; press
        if (real.%acts.run% == 1) { ; inverted sprint button (shift)
            Down(acts.forward)
        } else if (real.%acts.peek% == 1) { ; peeking
            if (real.%acts.left% == 1 or real.%acts.right% == 1) { ; no forward if left/right
                Up(acts.left)
                Up(acts.right)
            } else {
                Down(acts.forward)
            }
        } else { ; sprint if no modifiers pressed
            Down(acts.forward)
            Down(acts.run)
        }
    }
    if (dir == 0) { ; release
        Up(acts.forward)
        Up(acts.run)
        if (real.%acts.left% == 1)
            Down(acts.left)
        if (real.%acts.right% == 1)
            Down(acts.right)
    }
}

HandleBack(dir) {
    real.%acts.back% := dir
    MarkTime()

    if (dir == 1) { ; press
        if (real.%acts.run% == 1) { ; just move backward (shift on)
            Down(acts.back)
        } else if (real.%acts.peek% == 1) { ; peeking on
            if (real.%acts.left% == 1 or real.%acts.right% == 1) { ; no move back, only crouch
                Down(acts.crouch)
                Up(acts.left)
                Up(acts.right)
            } else {
                Down(acts.back)
                Down(acts.crouch)
            }
        } else { ; back if no modifiers pressed
            Down(acts.back)
        }
    }
    if (dir == 0) { ; release
        Up(acts.back)
        Up(acts.crouch)
        if (real.%acts.left% == 1)
            Down(acts.left)
        if (real.%acts.right% == 1)
            Down(acts.right)
    }
}

; invert shift action
HandleRun(dir) {
    real.%acts.run% := dir
    MarkTime()

    if (dir == 1) { ; press
        Up(acts.run)
    }
    if (dir == 0) { ; release
        if (real.%acts.forward% == 1) ; forward release to stop running
            Down(acts.run)
    }
}

HandleCrouch(dir) {
    real.%acts.crouch% := dir
    MarkTime()
}

; suppress jump when it's unnecessary
HandleJump(dir) {
    real.%acts.jump% := dir
    MarkTime()
    if (dir == 1) { ; press
        if (real.%acts.peek% == 0 and
            real.%acts.crouch% == 0 and
            real.%acts.ads% == 0)
            Down(acts.jump)
    }
    if (dir == 0) { ; release
        Up(acts.jump)
    }
}

HandleInventory(dir) {
    real.%acts.left% := dir
    MarkTime()
}
HandleMap(dir) {
    real.%acts.map% := dir
    MarkTime()
}

aimIdleTimeout := 1000 ; suppressed after no keyboard action in period
HandleFire(dir) {
    real.%acts.fire% := dir

    if (dir == 1) { ; press
        if (real.%acts.ads% == 0 and
            real.%acts.inventory% == 0 and
            real.%acts.map% == 0 and
            TimeSince(real._timestamp) < aimIdleTimeout
        ) {
            Down(acts.aim)
            MarkTime()
        }
    }
    if (dir == 0) { ; release
        Up(acts.aim)
    }
}

HandleADS(dir) {
    real.%acts.ads% := dir
    MarkTime()
}

; helpers
Down(key) {
    if (sent.%key% == 1)
        return

    Sleep Rnd()
    AHI.SendKeyEvent(keyboardId, Code(key), 1)
    sent.%key% := 1
}

Up(key) {
    if (sent.%key% == 0)
        return

    Sleep Rnd()
    AHI.SendKeyEvent(keyboardId, Code(key), 0)
    sent.%key% := 0
}

; utils
Code(char) {
    return GetKeySC(char)
}

Rnd() {
    return Random(cfg.wait.max - cfg.wait.min) + cfg.wait.min
}

TimeSince(moment := 0) {
    return A_TickCount - moment
}

InvertObject(obj) {
    result := {}
    For p, v in obj.OwnProps() {
        result.%v% := p ; append 'inverted' prop
    }
    return result
}

MapObject(obj, callback) {
    result := {}
    For p, v in obj.OwnProps() {
        result.%p% := callback(v) ; append 'mapped' prop
    }
    return result
}

Debug() {
    ;config := Jsons.Dump(cfg, "  ")
    ;actions := Jsons.Dump(acts, "  ")
    ;kn := Jsons.Dump(keys, "  ")
    ; cds := Jsons.Dump(codes, "  ")
    rl := Jsons.Dump(real, "  ")
    st := Jsons.Dump(sent, "  ")
    Log('kbdid:' keyboardId '`n---- real:`n' rl '`n---- sent:`n' st) ; '`n----`n codes:' cds)
}
