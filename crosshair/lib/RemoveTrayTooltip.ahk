; ahk v1 by Dart Vanya, see https://www.autohotkey.com/boards/viewtopic.php?p=507971#p507971
#Requires AutoHotkey v2.0

RemoveTrayTooltip() {
	SetTimer RemoveTooltip, -200 ; delayed run to prevent interferrence with SetTrayIcon()
}

RemoveTooltip(uId := 0x404) {
	NID := Buffer(szNID := A_PtrSize * 5 + 40 + 448, 0) ; if 'NID' is a UTF-16 string, use 'VarSetStrCapacity(&NID, szNID := A_PtrSize*5 + 40 + 448)' and replace all instances of 'NID.Ptr' with 'StrPtr(NID)'

	NumPut("UInt", szNID, NID.Ptr)
	NumPut("Ptr", A_ScriptHwnd, NID.Ptr + A_PtrSize)
	NumPut("UInt", uId, NID.Ptr + A_PtrSize * 2) ; NIF_TIP = 0x4
	NumPut("UInt", 0x4, NID.Ptr + A_PtrSize * 2 + 4) ; NIM_MODIFY := 0x1

	DllCall("Shell32.dll\Shell_NotifyIconA", "UInt", 0x1, "UPtr", NID.Ptr)
}