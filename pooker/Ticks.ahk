#Requires AutoHotkey v2.0

counter := 0

Ticks() {
    DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
    DllCall("QueryPerformanceCounter", "Int64*", &counter := 0)

    return Floor(counter / (freq / 1000))
}


Delay(D := 0.001) { ; High Resolution Delay ( High CPU Usage ) by SKAN | CD: 13/Jun/2009
    static F ; frequency
    critical
    F ? F : DllCall("QueryPerformanceFrequency", Int64P, F)
    DllCall("QueryPerformanceCounter", Int64P, pTick)
    cTick := pTick
    while(((Tick := (pTick-cTick)/F)) < D) {
        DllCall( "QueryPerformanceCounter", Int64P,pTick )
        Sleep -1
    }
    return Round(Tick, 3)
}