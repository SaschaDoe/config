; Define the hotkey: Ctrl + Alt + W
^!w:: {
    ; Check if an Explorer window is active
    if WinExist("ahk_class CabinetWClass") {
        activeHwnd := WinActive("A")
        ; Retrieve the directory path from the active Explorer window
        for window in ComObject("Shell.Application").Windows {
            ; Check if the window object has an Hwnd property
            try hwnd := window.Hwnd
            catch
                continue
            ; Compare the window's Hwnd with the active window's Hwnd
            if (hwnd = activeHwnd) {
                path := window.Document.Folder.Self.Path
                break
            }
        }
        ; Open WezTerm at the retrieved path
        if path {
            Run '"C:\Program Files\WezTerm\wezterm-gui.exe" start --cwd "' path '"'
        } else {
            MsgBox "Could not retrieve path from the active Explorer window."
        }
    } else {
        MsgBox "No active Explorer window found."
    }
}
