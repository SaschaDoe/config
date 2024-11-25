# setup-sync-command.ps1

# Function to ensure directory exists
function Ensure-Directory {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Host "Created directory: $Path" -ForegroundColor Green
    }
}

# Function to add command to PowerShell profile
function Add-ToProfile {
    param(
        [string]$ScriptPath
    )
    
    # Create PowerShell profile if it doesn't exist
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
        Write-Host "Created PowerShell profile: $PROFILE" -ForegroundColor Green
    }
    
    # Add the function to the profile
    $commandText = @"

# Sync-Config command
function Sync-Config {
    param(
        [switch]`$WhatIf,
        [string]`$ConfigFile
    )
    
    `$scriptPath = "$ScriptPath"
    if (-not (Test-Path `$scriptPath)) {
        Write-Host "Error: Sync script not found at `$scriptPath" -ForegroundColor Red
        return
    }
    
    `$params = @()
    if (`$WhatIf) { `$params += "-WhatIf" }
    if (`$ConfigFile) { `$params += "-ConfigFile `"`$ConfigFile`"" }
    
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `$scriptPath @params
}

# Add tab completion for Sync-Config
Register-ArgumentCompleter -CommandName Sync-Config -ParameterName ConfigFile -ScriptBlock {
    param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)
    
    Get-ChildItem -Path . -Filter "*.txt" |
        Where-Object { `$_.Name -like "`$wordToComplete*" } |
        ForEach-Object { `$_.Name } |
        Sort-Object
}
"@
    
    # Check if the function is already in profile
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not $profileContent -or -not $profileContent.Contains("function Sync-Config")) {
        Add-Content $PROFILE $commandText
        Write-Host "Added Sync-Config command to PowerShell profile" -ForegroundColor Green
    } else {
        Write-Host "Sync-Config command already exists in profile" -ForegroundColor Yellow
    }
}

# Function to create PowerShell module
function Create-Module {
    param(
        [string]$ScriptPath
    )
    
    # Create module directory
    $modulesPath = "$HOME\Documents\PowerShell\Modules\SyncConfig"
    Ensure-Directory $modulesPath
    
    # Create module manifest
    $manifestPath = Join-Path $modulesPath "SyncConfig.psd1"
    $moduleScript = Join-Path $modulesPath "SyncConfig.psm1"
    
    # Create module script
    $moduleContent = @"
function Sync-Config {
    param(
        [switch]`$WhatIf,
        [string]`$ConfigFile
    )
    
    `$scriptPath = "$ScriptPath"
    if (-not (Test-Path `$scriptPath)) {
        Write-Host "Error: Sync script not found at `$scriptPath" -ForegroundColor Red
        return
    }
    
    `$params = @()
    if (`$WhatIf) { `$params += "-WhatIf" }
    if (`$ConfigFile) { `$params += "-ConfigFile `"`$ConfigFile`"" }
    
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File `$scriptPath @params
}

# Add tab completion for Sync-Config
Register-ArgumentCompleter -CommandName Sync-Config -ParameterName ConfigFile -ScriptBlock {
    param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameters)
    
    Get-ChildItem -Path . -Filter "*.txt" |
        Where-Object { `$_.Name -like "`$wordToComplete*" } |
        ForEach-Object { `$_.Name } |
        Sort-Object
}

Export-ModuleMember -Function Sync-Config
"@
    
    $moduleContent | Out-File -FilePath $moduleScript -Encoding UTF8
    
    # Create module manifest
    New-ModuleManifest -Path $manifestPath `
        -RootModule "SyncConfig.psm1" `
        -ModuleVersion "1.0.0" `
        -Author $env:USERNAME `
        -Description "Config synchronization command" `
        -PowerShellVersion "5.1" `
        -FunctionsToExport @('Sync-Config')
    
    Write-Host "Created PowerShell module at: $modulesPath" -ForegroundColor Green
}

# Main setup
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path $scriptPath -Parent
$syncScriptPath = Join-Path $scriptDir "sync-config.ps1"

# Verify sync script exists
if (-not (Test-Path $syncScriptPath)) {
    Write-Host "Error: sync-config.ps1 not found in the same directory as this setup script" -ForegroundColor Red
    exit 1
}

Write-Host "Setting up Sync-Config command..." -ForegroundColor Cyan

# Add to profile
Add-ToProfile -ScriptPath $syncScriptPath

# Create module
Create-Module -ScriptPath $syncScriptPath

Write-Host "`nSetup completed! To use the command:" -ForegroundColor Green
Write-Host "1. Restart PowerShell or run: . `$PROFILE" -ForegroundColor Yellow
Write-Host "2. Run 'Sync-Config' from any directory" -ForegroundColor Yellow
Write-Host "   Optional parameters:" -ForegroundColor Yellow
Write-Host "   - Sync-Config -WhatIf" -ForegroundColor Yellow
Write-Host "   - Sync-Config -ConfigFile 'my-paths.txt'" -ForegroundColor Yellow