#Requires AutoHotkey v2.0
; Global variables
global currentLayer := 1
global activeTooltips := Map()  ; Track active tooltips

; Disable normal CapsLock behavior
SetCapsLockState "AlwaysOff"

; Function to switch back to layer 1 after key press
SwitchToLayer1() {
    global currentLayer
    if (currentLayer = 2) {
        currentLayer := 1
        ShowTooltip("Layer 1 (Default)", 1000)
    }
}

; CapsLock as layer switch
CapsLock:: {
    global currentLayer
    currentLayer := 2
    ShowTooltip("Layer 2 (Programming)", 1000)
}

; Improved tooltip function with proper cleanup
ShowTooltip(text, duration := 10000) {
    static tooltipCounter := 0
    
    ; Clean up any existing tooltips that should have expired
    CleanupTooltips()
    
    ; Use modulo to keep tooltip numbers within bounds (1-20)
    tooltipCounter := Mod(tooltipCounter + 1, 20) + 1
    
    ; Show the tooltip
    ToolTip(text, 0, 0, tooltipCounter)
    
    ; Store the tooltip info
    activeTooltips[tooltipCounter] := A_TickCount + duration
    
    ; Set timer to remove this specific tooltip
    SetTimer () => RemoveTooltip(tooltipCounter), -duration
}

; Function to remove a specific tooltip
RemoveTooltip(tooltipNumber) {
    ToolTip(,,,tooltipNumber)
    activeTooltips.Delete(tooltipNumber)
}

; Function to clean up any lingering tooltips
CleanupTooltips() {
    currentTime := A_TickCount
    
    ; Check each active tooltip
    for tooltipNumber, expiryTime in activeTooltips.Clone() {
        if (currentTime > expiryTime) {
            RemoveTooltip(tooltipNumber)
        }
    }
}

; Function to get the current directory
GetCurrentDirectory() {
    ; Try to get Explorer window path first
    explorerHwnd := WinExist("A")
    if (WinActive("ahk_class CabinetWClass") || WinActive("ahk_class ExploreWClass")) {
        try {
            for window in ComObject("Shell.Application").Windows {
                try {
                    if (window.HWND = explorerHwnd) {
                        return window.Document.Folder.Self.Path
                    }
                }
            }
        } catch as err {
            return { error: "Failed to get Explorer path: " . err.Message }
        }
    }
    
    ; If not Explorer, try to get from Command Prompt or PowerShell
    if (WinActive("ahk_class ConsoleWindowClass") || WinActive("ahk_exe powershell.exe") || WinActive("ahk_exe WindowsTerminal.exe")) {
        try {
            ; Send CD command and retrieve output
            prevClipboard := A_Clipboard
            A_Clipboard := ""  ; Clear clipboard
            Send "cd{Enter}"  ; Send CD command
            Sleep 100  ; Wait a bit longer
            Send "^c"  ; Copy current directory
            if !ClipWait(2) {  ; Wait up to 2 seconds for clipboard
                throw Error("Clipboard timeout")
            }
            currentDir := Trim(A_Clipboard, "`r`n")  ; Remove newlines
            A_Clipboard := prevClipboard  ; Restore clipboard
            return currentDir
        } catch as err {
            return { error: "Failed to get Terminal path: " . err.Message }
        }
    }
    
    ; If nothing else works, return current working directory
    return A_WorkingDir
}

; Layer 1 (Default) mappings - all alphabet characters stay the same
#HotIf currentLayer = 1
q::Send "q"
+q::Send "Q"
w::Send "w"
+w::Send "W"
e::Send "e"
+e::Send "E"
r::Send "r"
+r::Send "R"
t::Send "t"
+t::Send "T"
z::Send "z"
+z::Send "Z"
u::Send "u"
+u::Send "U"
i::Send "i"
+i::Send "I"
o::Send "o"
+o::Send "O"
p::Send "p"
+p::Send "P"
ü::Send "ü"
+ü::Send "Ü"
a::Send "a"
+a::Send "A"
s::Send "s"
+s::Send "S"
d::Send "d"
+d::Send "D"
f::Send "f"
+f::Send "F"
g::Send "g"
+g::Send "G"
h::Send "h"
+h::Send "H"
j::Send "j"
+j::Send "J"
k::Send "k"
+k::Send "K"
l::Send "l"
+l::Send "L"
ö::Send "ö"
+ö::Send "Ö"
ä::Send "ä"
+ä::Send "Ä"
<::Send "<"
+<::Send ">"
y::Send "y"
+y::Send "Y"
x::Send "x"
+x::Send "X"
c::Send "c"
+c::Send "C"
v::Send "v"
+v::Send "V"
b::Send "b"
+b::Send "B"
n::Send "n"
+n::Send "N"
m::Send "m"
+m::Send "M"
,::Send ","
+,::Send ";"
.::Send "."
+.::Send ":"
-::Send "-"
+-::Send "_"

; Layer 2 (Programming Symbols) mappings
#HotIf currentLayer = 2
; Added command list tooltip for 1
1:: {
    ShowTooltip("Available Commands:`n2: CreateGithubRepo")
}

2:: {
    try {
        currentDir := GetCurrentDirectory()
        
        ; Check if we got an error object
        if (Type(currentDir) = "Object" && HasProp(currentDir, "error")) {
            throw Error(currentDir.error)
        }
        
        if !currentDir {
            throw Error("Could not determine current directory")
        }
        
        ; Check if the script exists
        scriptPath := A_ScriptDir "\CreateGithubRepo.ps1"
        if !FileExist(scriptPath) {
            throw Error("CreateGithubRepo.ps1 not found at: " scriptPath)
        }
        
        ; Get the directory name to use as repo name
        repoName := SubStr(currentDir, InStr(currentDir, "\", , -1) + 1)
        
        ; Show initial message
        ShowTooltip("Creating Github repo in: " currentDir "`nRepo name: " repoName "`nPlease wait...")
        
        ; Run the script without hiding the window and pass the repo name
        command := Format('powershell.exe -NoExit -ExecutionPolicy Bypass -File "{1}" -Path "{2}" -RepoName "{3}"', scriptPath, currentDir, repoName)
        RunWait(command)
        
        ; Show completion message
        ShowTooltip("Github repo creation completed for:`n" repoName "`nin directory:`n" currentDir)
        
    } catch as err {
        ; Show error in tooltip for 10 seconds
        ShowTooltip("Error creating Github repo:`n" err.Message "`n`nDirectory: " currentDir)
    }
}
#HotIf currentLayer = 2
; Number keys and punctuation don't switch back
q:: {
    Send "1"
}
+q:: {
    Send "!"
}
w:: {
    Send "2"
}
+w:: {
    Send "`""
}
e:: {
    Send "3"
}
+e:: {
    Send "§"
}
r:: {
    Send "4"
}
+r:: {
    Send "$"
}
t:: {
    Send "5"
}
+t:: {
    Send "%"
}
z:: {
    Send "6"
}
+z:: {
    Send "&"
}
u:: {
    Send "7"
}
+u:: {
    Send "|"
}
i:: {
    Send "8"
}
+i:: {
    Send "("
}
o:: {
    Send "9"
}
+o:: {
    Send ")"
}
p:: {
    Send "0"
}
+p:: {
    Send "="
}
,:: {
    Send ","
}
+,:: {
    Send ";"
}
.:: {
    Send "."
}
+.:: {
    Send ":"
}

; All other keys switch back to layer 1 after pressing
ü:: {
    Send "ß"
    SwitchToLayer1()
}
+ü:: {
    Send "?"
    SwitchToLayer1()
}
a:: {
    Send "@"
    SwitchToLayer1()
}
+a:: {
    Send "~"
    SwitchToLayer1()
}
s:: {
    Send "{#}"
    SwitchToLayer1()
}
+s:: {
    Send "'"
    SwitchToLayer1()
}
d:: {
    Send "$"
    SwitchToLayer1()
}
+d:: {
    Send "``"
    SwitchToLayer1()
}
f:: {
    Send "%"
    SwitchToLayer1()
}
+f:: {
    Send "^"
    SwitchToLayer1()
}
g:: {
    Send "/"
    SwitchToLayer1()
}
+g:: {
    Send "{F1}"
    SwitchToLayer1()
}
h:: {
    Send "{Left}"
}
+h:: {
    Send "{F2}"
    SwitchToLayer1()
}
j:: {
    Send "{Down}"
}
+j:: {
    Send "{F3}"
    SwitchToLayer1()
}
k:: {
    Send "{Up}"
}
+k:: {
    Send "{F4}"
    SwitchToLayer1()
}
l:: {
    Send "{Right}"
}
+l:: {
    Send "{F5}"
    SwitchToLayer1()
}
ö:: {
    Send ";"
    SwitchToLayer1()
}
+ö:: {
    Send "{F6}"
    SwitchToLayer1()
}
ä:: {
    Send ":"
    SwitchToLayer1()
}
+ä:: {
    Send "{F7}"
    SwitchToLayer1()
}
SC035:: {
    Send ";"
    SwitchToLayer1()
}
+SC035:: {
    Send "</"
    SwitchToLayer1()
}
<:: {
    Send "<"
    SwitchToLayer1()
}
+<:: {
    Send ">"
    SwitchToLayer1()
}
y:: {
    Send "/"
    SwitchToLayer1()
}
+y:: {
    Send "{{}}"
    SwitchToLayer1()
}
x:: {
    Send "?"
    SwitchToLayer1()
}
+x:: {
    Send "{}}"
    SwitchToLayer1()
}
c:: {
    Send "{[}"
    SwitchToLayer1()
}
+c:: {
    Send "{]}"
    SwitchToLayer1()
}
v:: {
    Send "{]}"
    SwitchToLayer1()
}
+v:: {
    Send "{]}"
    SwitchToLayer1()
}
b:: {
    SendText "{"
    SwitchToLayer1()
}
+b:: {
    SendText "{"
    SwitchToLayer1()
}
n:: {
    SendText "}"
    SwitchToLayer1()
}
+n:: {
    SendText "}"
    SwitchToLayer1()
}
m:: {
    Send "|"
    SwitchToLayer1()
}
+m:: {
    Send "\"
    SwitchToLayer1()
}
-:: {
    Send "-"
    SwitchToLayer1()
}
+-:: {
    Send "_"
    SwitchToLayer1()
}

; Keep the Alt+navigation combinations
!h::Send "{Alt down}{Left}{Alt up}"
!j::Send "{Alt down}{Down}{Alt up}"
!k::Send "{Alt down}{Up}{Alt up}"
!l::Send "{Alt down}{Right}{Alt up}"

#HotIf
