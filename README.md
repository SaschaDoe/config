powershell.exe -ExecutionPolicy Bypass -File .\setup-sync-command.ps1

after that: 

# Basic usage
Sync-Config

# Preview mode
Sync-Config -WhatIf

# Custom config file
Sync-Config -ConfigFile "my-paths.txt"