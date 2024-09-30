#Requires AutoHotkey v2.0
#SingleInstance Force

#Include lib/interceptor/AutoHotInterception.ahk
#Include lib/Log.ahk
#Include lib/Jsons.ahk

*^Esc:: ExitApp
AHI := AutoHotInterception() ; https://github.com/evilC/AutoHotInterception

keyboardId := 5 ; 3
; keyboardId := AHI.GetKeyboardId(0x046D, 0xC52B)
mouseId := AHI.GetMouseId(0x3554, 0xF57C) ; keysona aztec
; mouseId := AHI.GetMouseId(0x3554, 0xF58E) ; vxe r1

cfg := {
    jumpWhilePeek: "up", ; "jump"
    wait: { ; random waiting settings
        min: 6, ; 165hz = 6ms per frame
        max: 24,
    },
    overlayTimeout: 1000, ; suppress aiming and wheel scroll handling
    aimIdleTimeout: 1000, ; suppress aiming on RButton if no keyboard action in period
    wheelKeypressPeriod: 333, ; wheel to keypress period
    debug: false,
}
if (cfg.debug)
    SetTimer Debug, 200

; script state
s := {
    timestamp: A_TickCount,
    key: -1,
    prevKey: -1,
    overlayTick: 0,
}

; actions to buttons mapping (in-game key bindings)
acts := {
    menu: "Esc",
    settings: '``',
    peek: "a", ; walk, peek mode on
    peekleft: "z", ; unhandled
    peekright: "c", ; unhandled
    left: "s",
    right: "f",
    forward: "e",
    back: "d",
    run: "Shift", ; blocked
    jump: "Space", ; blocked
    crouch: "b", ; blocked
    prone: "x",
    inventory: "n",
    map: "m",
    fire: "LButton",
    ads: "RButton", ; aim down sights
    aim: "NumpadMult", ; unhandled
    grenades: "7", ; unhandled, throwable wheel (to wheel up)
    heals: "8", ; unhandled, healing wheel (to wheel down)
}
keys := InvertObject(acts)
codes := MapObject(acts, Code)
codeToAct := InvertObject(codes)
real := MapObject(keys, (v) => 0) ; real keys status
sent := MapObject(keys, (v) => 0) ; fake keys sending status

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
    AHI.SubscribeKeyboard(keyboardId, false, HandleOther)
    AHI.SubscribeKey(keyboardId, codes.left, false, HandleLeft)
    AHI.SubscribeKey(keyboardId, codes.right, false, HandleRight)
    AHI.SubscribeKey(keyboardId, codes.back, false, HandleBack)
    AHI.SubscribeKey(keyboardId, codes.forward, false, HandleForward)
    AHI.SubscribeKey(keyboardId, codes.inventory, false, HandleInventory)
    AHI.SubscribeKey(keyboardId, codes.map, false, HandleMap)
    AHI.SubscribeKey(keyboardId, codes.prone, false, HandleProne)
    AHI.SubscribeKey(keyboardId, codes.settings, false, HandleSettings)
    AHI.SubscribeKey(keyboardId, codes.menu, false, HandleMenu)
    ; blocked keys
    AHI.SubscribeKey(keyboardId, codes.peek, true, HandlePeek) ; block, walk + peek mode
    AHI.SubscribeKey(keyboardId, codes.run, true, HandleRun) ; block
    AHI.SubscribeKey(keyboardId, codes.jump, true, HandleJump) ; block
    AHI.SubscribeKey(keyboardId, codes.crouch, true, HandleCrouch) ; block
    ; mouse
    AHI.SubscribeMouseButton(mouseId, mouseCodes.%acts.fire%, false, HandleFire)
    AHI.SubscribeMouseButton(mouseId, mouseCodes.%acts.ads%, false, HandleADS)
    AHI.SubscribeMouseButton(mouseId, mouseCodes.Wheel, false, HandleWheel)
}

HandleOther(code, state) {
    SetTimestamp("other")
}

; peek mode
HandlePeek(dir) {
    real.%acts.peek% := dir
    SetTimestamp(acts.peek)

    if (dir == 1) { ; press
        Down(acts.crouch)
        ; peeking
        if (real.%acts.left% == 1)
            Down(acts.peekleft)
        if (real.%acts.right% == 1)
            Down(acts.peekright)
        if (real.%acts.forward% == 1) {
            Up(acts.run) ; stop run
            if (real.%acts.right% == 0 and real.%acts.left% == 0 and real.%acts.back% == 0)
                return
        }
        Down(acts.peek)
    }
    if (dir == 0) { ; release
        Up(acts.peek)
        Up(acts.peekleft)
        Up(acts.peekright)
        if (real.%acts.crouch% == 0) ; stop crouch
            Up(acts.crouch)
        if (real.%acts.forward% == 1 and real.%acts.run% == 0) ; start run
            Down(acts.run)
    }
}

HandleLeft(dir) {
    real.%acts.left% := dir
    SetTimestamp(acts.left)

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1)
            Down(acts.peek)
        if (real.%acts.peek% == 1 and real.%acts.right% == 0) {
            Up(acts.peekright)
            Down(acts.peekleft)
        }
    }
    if (dir == 0) { ; release
        if isMoving()
            Up(acts.peekleft)
        if (real.%acts.peek% == 1 and real.%acts.right% == 1)
            Down(acts.peekright)
    }
}

HandleRight(dir) {
    real.%acts.right% := dir
    SetTimestamp(acts.right)

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1)
            Down(acts.peek)
        if (real.%acts.peek% == 1 and real.%acts.left% == 0) {
            Up(acts.peekleft)
            Down(acts.peekright)
        }
    }
    if (dir == 0) { ; release
        if isMoving()
            Up(acts.peekright)
        if (real.%acts.peek% == 1 and real.%acts.left% == 1)
            Down(acts.peekleft)
    }
}

HandleForward(dir) {
    real.%acts.forward% := dir
    SetTimestamp(acts.forward)

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1) {
            Down(acts.peek)
            Up(acts.crouch)
        }
        if (real.%acts.run% == 0 and real.%acts.peek% == 0) {
            Down(acts.run)
            return
        }
    }
    if (dir == 0) { ; release
        Up(acts.run)
    }
}

HandleBack(dir) {
    real.%acts.back% := dir
    SetTimestamp(acts.back)

    if (dir == 1) { ; press
        if (real.%acts.peek% == 1) {
            Down(acts.peek)
            Down(acts.crouch)
        }
    }
}

; invert shift
HandleRun(dir) {
    real.%acts.run% := dir
    SetTimestamp(acts.run)

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
    SetTimestamp(acts.crouch)

    if (dir == 1) { ; press
        if (real.%acts.peek% == 0)
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
    SetTimestamp(acts.jump)

    if (dir == 1) { ; press
        if (real.%acts.peek% == 0 and
            real.%acts.ads% == 0)
            Down(acts.jump) ; no jump while ads'ing or peeking
        if (cfg.jumpWhilePeek == "up" and real.%acts.peek% == 1)
            Up(acts.crouch)
    }
    if (dir == 0) { ; release
        Up(acts.jump)
        if (cfg.jumpWhilePeek == "up" and real.%acts.peek% == 1)
            Down(acts.crouch)
    }
}

HandleInventory(dir) {
    real.%acts.inventory% := dir
    SetTimestamp(acts.inventory)

    ; to prevent aiming
    if (dir == 0) { ; release
        s.overlayTick := A_TickCount
        SetTimer HandleOverlayTimeout, cfg.overlayTimeout * -1
    }
}

HandleMap(dir) {
    real.%acts.map% := dir
    SetTimestamp(acts.map)

    ; to prevent aiming
    if (dir == 0) {  ; release
        s.overlayTick := A_TickCount
        SetTimer HandleOverlayTimeout, cfg.overlayTimeout * -1
    }
}

HandleMenu(dir) {
    real.%acts.menu% := dir
    SetTimestamp(acts.menu)

    ; to prevent aiming
    if (dir == 0) {  ; release
        s.overlayTick := A_TickCount
        SetTimer HandleOverlayTimeout, cfg.overlayTimeout * -1
    }
}

HandleSettings(dir) {
    real.%acts.settings% := dir
    SetTimestamp(acts.settings)

    ; to prevent aiming
    if (dir == 0) { ; release
        s.overlayTick := A_TickCount
        SetTimer HandleOverlayTimeout, cfg.overlayTimeout * -1
    }
}

HandleProne(dir) {
    real.%acts.prone% := dir
    SetTimestamp(acts.prone)
}

HandleFire(dir) {
    real.%acts.fire% := dir
    SetTimestamp(acts.fire)

    if (dir == 1) { ; press
        if (real.%acts.ads% == 0 and isOverlay() == 0)
            Down(acts.aim)
    }
    if (dir == 0) { ; release
        Up(acts.aim)
    }
}

HandleADS(dir) {
    real.%acts.ads% := dir
    SetTimestamp(acts.ads)
}

_wheelScrollUp := A_TickCount
_wheelScrollDown := A_TickCount
HandleWheel(state) {
    if (state == 1) { ; wheel up
        real.wheelScrollUp := 1
        SetTimestamp("wheelScrollUp")
        if (sent.%acts.heals% == 1 or isOverlay())
            return
        Down(acts.grenades)
        _wheelScrollUp := A_TickCount
        SetTimer WheelUpKeyUp, cfg.wheelKeypressPeriod * -1
    }
    if (state == -1) { ; wheel down
        real.wheelScrollDown := 1
        SetTimestamp("wheelScrollDown")
        if (sent.%acts.grenades% == 1 or isOverlay())
            return
        Down(acts.heals)
        _wheelScrollDown := A_TickCount
        SetTimer WheelDownKeyUp, cfg.wheelKeypressPeriod * -1
    }
}

WheelUpKeyUp() {
    real.wheelScrollUp := 0
    if (TimeSince(_wheelScrollUp) > cfg.wheelKeypressPeriod - 10) {
        Up(acts.grenades)
    } else {
        SetTimer WheelUpKeyUp, cfg.wheelKeypressPeriod * -1
    }
}
WheelDownKeyUp() {
    real.wheelScrollDown := 0
    if (TimeSince(_wheelScrollDown) > cfg.wheelKeypressPeriod - 10) {
        Up(acts.heals)
    } else {
        SetTimer WheelDownKeyUp, cfg.wheelKeypressPeriod * -1
    }
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

SetTimestamp(key := -1, time := -1) {
    if (s.timestamp == -1)
        time := A_TickCount
    s.timestamp := time
    if (key != -1 and s.key != key) {
        s.prevKey := s.key
        s.key := key
    }
}
TimeSince(moment := s.timestamp) {
    return A_TickCount - moment
}

isOverlayKey(k) {
    if (k == acts.settings or
        k == acts.map or
        k == acts.inventory or
        k == acts.menu or
        k == "wheelScrollUp" or
        k == "wheelScrollDown")
        return 1
    return 0
}
isOverlayActionKey(k) {
    if (k == acts.fire or
        k == "wheelScrollUp" or
        k == "wheelScrollDown")
        return 1
    return 0
}
isOverlay() {
    if (s.overlayTick > 0)
        return 1
    if isOverlayKey(s.key)
        return 1
    if isOverlayKey(s.prevKey) {
        if (isOverlayActionKey(s.key))
            return 1
    }
    return 0
}
HandleOverlayTimeout() {
    if (TimeSince(s.overlayTick) > cfg.overlayTimeout - 10)
        s.overlayTick := 0
}

isMovingX() {
    if (real.%acts.right% == 1 and real.%acts.left% == 1)
        return 0
    if (real.%acts.right% == 1 or real.%acts.left% == 1)
        return 1
    return 0
}
isMovingY() {
    if (real.%acts.forward% == 1 and real.%acts.back% == 1)
        return 0
    if (real.%acts.forward% == 1 or real.%acts.back% == 1)
        return 1
    return 0
}
isMoving() {
    if (isMovingX() or isMovingY())
        return 1
    return 0
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
    Log('isOverlay():' isOverlay() '`n---- kbdid:' keyboardId '`n---- real:`n' rl '`n---- sent:`n' st) ; '`n----`n codes:' cds)
}