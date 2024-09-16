#Requires AutoHotkey v2.0
;#include Jsons.ahk

; return deep copy of o1 merged with o2, props of o2 to override those of o1
MergeObjects(o1, o2) {
	if (IsPrimitive(o1) and IsPrimitive(o2)) {
		return o2
	}
	
	if (IsPrimitive(o1)) {
		return MergeObjects({}, o2)
	}

	if (IsPrimitive(o2)) {
		return MergeObjects(o1, {})
	}
	
	_o1 := MapToObj(o1).Clone()
	_o2 := MapToObj(o2).Clone()
	result := _o1

	For p, v in _o2.OwnProps() {
		if (_o1.HasOwnProp(p)) {
			; override prop
			if !(IsPrimitive(v)) {
				result.%p% := MergeObjects(_o1.%p%, v)
			} else {
				result.%p% := v
			}
		} else {
			; append prop
			result.%p% := v
		}
	}
	return result
}

IsPrimitive(v) {
	if (IsObject(v)) {
		if (v is Array) {
			return 1
		}
		return 0
	}
	return 1
}

MapToObj(m) {
	if !(m is Map) {
		return m
	}
	converted := {}
	for p, v in m {
		if (v is Map) {
			converted.%p% := MapToObj(v)
		} else if v.base.__Class != "BoundFunc" {
			converted.%p% := v
		}
	}
	return converted
}


/*
o1 := { a: "o1.a", b: [1,1,1], d: { a: "o1.d.a", b: "o1.d.b", d: [1,1,1] }}
o2 := { b: "o2.b", c: "o2.c", d: { b: "o2.d.b", c: "o2.d.c", d: [2,2] }}
o3 := AppendObject(o1, o2)
o4 := AppendObject(o2, o1)

MsgBox(Jsons.Dump(o3))
MsgBox(Jsons.Dump(o4))
*/
