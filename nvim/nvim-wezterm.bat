@echo off
setlocal

REM You can hardcode the WezTerm path if you prefer
set WEZTERM_PATH="C:\Program Files\WezTerm\wezterm.exe"

REM Check if WezTerm exists
if not exist %WEZTERM_PATH% (
    echo WezTerm not found at %WEZTERM_PATH%
    echo Falling back to default terminal...
    nvim %*
    exit /b
)

REM Launch WezTerm with Neovim without showing the command prompt
%WEZTERM_PATH% start -- nvim %*