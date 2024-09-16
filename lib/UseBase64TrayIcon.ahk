#Requires AutoHotkey v2.0
#include ImagePut.ahk

; embed tray icons as base64 string into AHK script
UseBase64TrayIcon(name := "transparent", debug := false) {
	icons := {
		fire: "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAdNJREFUWEftlttxwkAMRaV1E5k4H1BBTAdQCVBJoBKgEtwBTgVZZuJMmvAqI8KCWeR9wAA/+I/xGh097tUiPPjBB8eHJ8DVFdjAS08pNTaI20FTL1NbehXAJssnSLDgoGSa/gB+9d0ANvA2REVrG7Aw9UXJXPSRG5wh7gpQqZzcUpPB0QC+y5u34FO9fhDgzA2EQLN38zO/OUCl8i8A6AmBdGHq/k0AWGo84VLvnYDLwtTTFIjgEFqdc3nbsvME0WSaUawkgwAV5mtSsGKT6eq/1I5YCC+AzZgQph4ANh9xJsjgNKQMLwBnDwhDO+HSDDAcGhjzuUsG0w9g9U5QFlSPeB5QZayCw8MA0DQlqoxdUaqEdzA7AZxstS2na0LH6uzgJAivPGMBOGNNCHO7fI4l+K8O/5YqFFpUKQCy8vbtsS8rlfN2nJy0yWPTHoDzfndo/6THklf4VnWUCnzO5i4huQLdd4UoH+gAOAymfS/OgNOi8yXmSW//h53yItPMreXuzmK2cP3AmlhXmKAVByDaV7BzDwhkz1BBAJ+8Alsvaj1HARwghBJLECmXk2iA9qDxNZwIh61+ayDQiFQaY1axqzi6BSkXjNSzyRVIDRA6/wT4A2EVBjBNInfQAAAAAElFTkSuQmCC",
		click: "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAgdJREFUWEe9l21uwjAMhhM+7gEnGZxkIDVInAI4BRJFgp1kvcm4Bx9ZX9ZUmeXEaVa2X1NSx09eO7bRKuPveDyerLULmBpjdMYRrUmW8b8B7Pf7yXq9vtAbpgCEbOlZQQXKsvzUWk+u1+ucQkgAztZauzTGVLEQsQCHw2GhtT7BUGt9oRAxADhXSs0ap9XtdltyKjooFgDyjUaj9/qjLQcRAvCdAzxbAThlIM5FUSyxB4UGg8Eb/vfXfNVSnD8vF4uPBzEzxsyl51aW5aa++SLVuQjglIjFkEKlZn80B6Sb9rnfhgDkw+HQZe8vH/f7vUpVAfnBASIpuSfZAvhPjx6AmK5Wq7Nbd7D+mtur88AGANok9vezANwz5GpENkCXEPh1gEJkh6BLYvkArlA9Ho8dFxLp3D93w/Y5/VS+c92ed5JTNgdCRk1jubiKh++oAsR22wUiqgBpLO3BAgB4qpTKGa2EscaSAMB2UfZ5cos0y2ltTwFwySn1hVg7PmEg4Q5IBfAggskZzAHUBRwgjWQdMp5Nzt6eoQSCglUUxZR+91KAZirCUIvR7INT86UASql51lAqydkhCcV60JcCGL3ZWUJSoQ+ALeJbT9FfAeWiKmQBNFPxxq8RobBI43kWAHfTZoJmVagVmoZGut4AAEWa17MfZJVi6RWE9qHCeDzGTzMlOXZnfAOVwscw9z7djQAAAABJRU5ErkJggg==",
		transparent: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=",
	}

	if icons.HasOwnProp(name) {
		iconHandler := Base64ToIcon(icons.%name%, debug)
		if (iconHandler) {
			e := false
			try {
				TraySetIcon("HICON:*" hICON := iconHandler)
			} catch Error as e {
				if (debug)
					MsgBox e.message
			}
		}
	}
}

Base64ToIcon(base64string, debug := false) {
	try {
		iconHandler := ImagePutHIcon({ image: CleanBase64(base64string) })
	} catch Error as e {
		if (debug)
			MsgBox e.message
		return false
	}

	return iconHandler
}

CleanBase64(b64str) {
	if InStr(b64str, ",") {
		parts := StrSplit(b64str, ",", 2)
		if parts.Length == 2 and InStr(parts[1], "data") and StrLen(parts[2]) > 2
			return parts[2]
	}
	return b64str
}