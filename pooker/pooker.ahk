#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib/interceptor/AutoHotInterception.ahk
#Include lib/Log.ahk
#Include lib/Jsons.ahk

*^Esc:: ExitApp

AHI := AutoHotInterception() ; https://github.com/evilC/AutoHotInterception
mouseId := 14 ; 13 ; 11 ; AHI.GetMouseId(...)
keyboardId := 2 ; AHI.GetKeyboardId(0x046D, 0xC52B)

cfg := {
    wait: {
        min: 6, ; 165hz = 6ms per frame
        max: 24,
    },
    aimIdleTimeout: 1000, ; suppressed aiming on RButton if no keyboard action in period
    wheelKeypressPeriod: 333, ; wheel to keypress period
    debug: false,
}

if (cfg.debug)
    SetTimer Debug, 200

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
    jump: "Space", ; blocked
    crouch: "b",
    prone: "x",
    inventory: "n",
    map: "m",
    aim: "NumpadMult",
    ads: "RButton", ; aim down sights
    fire: "LButton",
    grenades: "7", ; throwable wheel (to wheel up)
    heals: "8", ; healing wheel (to wheel down)
}
keys := InvertObject(acts)
codes := MapObject(acts, Code)
real := MapObject(keys, (v) => 0) ; real keys status
sent := MapObject(keys, (v) => 0) ; fake keys sending status

_timestamp := A_TickCount

mouseCodes := {
    LButton: 0,
    RButton: 1,
    MButton: 2,
    XButton1: 3,
    XButton2: 4,
    Wheel: 5, ; up: state == 1, down: state == -1
    WheelHorizontal: 6,
}

Bind()
Bind() {
    AHI.SubscribeKeyboard(keyboardId, false, SetTimestamp)
    AHI.SubscribeKey(keyboardId, codes.peek, false, HandlePeek) ; peek mode
    AHI.SubscribeKey(keyboardId, codes.left, false, HandleLeft)
    AHI.SubscribeKey(keyboardId, codes.right, false, HandleRight)
    AHI.SubscribeKey(keyboardId, codes.back, false, HandleBack)
    AHI.SubscribeKey(keyboardId, codes.forward, false, HandleForward)
    AHI.SubscribeKey(keyboardId, codes.run, true, HandleRun) ; block
    AHI.SubscribeKey(keyboardId, codes.jump, true, HandleJump) ; block
    AHI.SubscribeKey(keyboardId, codes.crouch, true, HandleCrouch) ; block
    AHI.SubscribeKey(keyboardId, codes.inventory, false, HandleInventory)
    AHI.SubscribeKey(keyboardId, codes.map, false, HandleMap)
    ; mouse
    AHI.SubscribeMouseButton(mouseId, mouseCodes.%acts.fire%, false, HandleFire)
    AHI.SubscribeMouseButton(mouseId, mouseCodes.%acts.ads%, false, HandleADS)
    AHI.SubscribeMouseButton(mouseId, mouseCodes.Wheel, false, HandleWheel)
}

; peek mode
HandlePeek(dir) {
    real.%acts.peek% := dir
    SetTimestamp()

    if (dir == 1) { ; press
        Down(acts.crouch)
        if (real.%acts.forward% == 1)
            Up(acts.run)
        if (real.%acts.left% == 1)
            Down(acts.peekleft)
        if (real.%acts.right% == 1)
            Down(acts.peekright)
    }
    if (dir == 0) { ; release
        Up(acts.peekleft)
        Up(acts.peekright)
        if (real.%acts.crouch% == 0)
            Up(acts.crouch)
        if (real.%acts.forward% == 1 and real.%acts.run% == 0) ; restore run
            Down(acts.run)
    }
}

HandleLeft(dir) {
    real.%acts.left% := dir
    SetTimestamp()

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1 and real.%acts.right% == 0)
            Down(acts.peekleft)
    }
    if (dir == 0) { ; release
        Up(acts.peekleft)
        if (real.%acts.peek% == 1 and real.%acts.right%)
            Down(acts.peekright)
    }
}

HandleRight(dir) {
    real.%acts.right% := dir
    SetTimestamp()

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1 and real.%acts.left% == 0)
            Down(acts.peekright)
    }
    if (dir == 0) { ; release
        Up(acts.peekright)
        if (real.%acts.peek% == 1 and real.%acts.left%)
            Down(acts.peekleft)
    }
}

HandleForward(dir) {
    real.%acts.forward% := dir
    SetTimestamp()

    if (dir == 1) { ; press
        if (real.%acts.run% == 0 and real.%acts.peek% == 0)
            Down(acts.run)
    }
    if (dir == 0) { ; release
        Up(acts.run)
    }
}

HandleBack(dir) {
    real.%acts.back% := dir
    SetTimestamp()
}

; invert shift
HandleRun(dir) {
    real.%acts.run% := dir
    SetTimestamp()

    if (dir == 1) { ; press
        Up(acts.run)
    }
    if (dir == 0) { ; release
        if (real.%acts.forward% == 1)
            Down(acts.run)
    }
}

HandleCrouch(dir) {
    real.%acts.crouch% := dir
    SetTimestamp()

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1) {
            Up(acts.crouch)
            return
        }
        Down(acts.crouch)
    }
    if (dir == 0) { ; release
        if (real.%acts.peek% == 0)
            Up(acts.crouch)
    }
}

; suppress jump when it's unnecessary
HandleJump(dir) {
    real.%acts.jump% := dir
    SetTimestamp()
    if (dir == 1) { ; press
        if (real.%acts.peek% == 0 and
            real.%acts.crouch% == 0 and
            real.%acts.ads% == 0)
            Down(acts.jump)
        if (real.%acts.peek% == 1) {
            Up(acts.crouch)
        }
    }
    if (dir == 0) { ; release
        Up(acts.jump)
        if (real.%acts.peek% == 1) {
            Down(acts.crouch)
        }
    }
}

HandleInventory(dir) {
    real.%acts.left% := dir
    SetTimestamp(0) ; prevent aiming
}

HandleMap(dir) {
    real.%acts.map% := dir
    SetTimestamp(0) ; prevent aim
}

HandleFire(dir) {
    real.%acts.fire% := dir

    if (dir == 1) { ; press
        if (real.%acts.ads% == 0 and
            real.%acts.inventory% == 0 and
            real.%acts.map% == 0 and
            TimeSince() < cfg.aimIdleTimeout
        ) {
            Down(acts.aim)
            SetTimestamp()
        }
    }
    if (dir == 0) { ; release
        Up(acts.aim)
    }
}

HandleADS(dir) {
    real.%acts.ads% := dir
    SetTimestamp()
}

wheel := {
    wheelUpAt: 0,
    wheelDownAt: 0,
}
HandleWheel(state) {
    SetTimestamp()
    if (state == 1) { ; wheel up
        if (sent.%acts.heals% == 1)
            return
        Down(acts.grenades)
        wheel.wheelUpAt := A_TickCount
        SetTimer WheelUpKeyUp, cfg.wheelKeypressPeriod * -1
    }
    if (state == -1) { ; wheel down
        if (sent.%acts.grenades% == 1)
            return
        Down(acts.heals)
        wheel.wheelDownAt := A_TickCount
        SetTimer WheelDownKeyUp, cfg.wheelKeypressPeriod * -1
    }
}

WheelUpKeyUp() {
    if (TimeSince(wheel.wheelUpAt) > cfg.wheelKeypressPeriod - 1)
        Up(acts.grenades)
}
WheelDownKeyUp() {
    if (TimeSince(wheel.wheelDownAt) > cfg.wheelKeypressPeriod - 1)
        Up(acts.heals)
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

TimeSince(moment := _timestamp) {
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

SetTimestamp(time := A_TickCount) {
    _timestamp := time
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