# sync-config.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "sync-paths.txt",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

# Enable verbose output
$VerbosePreference = "Continue"
$ErrorActionPreference = "Stop"

# Function to log with timestamp
function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "White",
        [bool]$Pause = $false
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
    if ($Pause) {
        Write-Host "Press Enter to continue..." -ForegroundColor Yellow
        Read-Host
    }
}

# Function to verify git repository
function Test-GitRepository {
    Write-Log "Checking git repository..." "Yellow"
    Write-Log "Current directory: $(Get-Location)" "Cyan"
    
    try {
        # Check if .git exists
        if (-not (Test-Path ".git")) {
            Write-Log "Initializing new git repository..." "Yellow"
            git init
            if ($LASTEXITCODE -ne 0) { throw "Git init failed" }
        }
        
        # Check if git is properly initialized
        $status = git status 2>&1
        if ($LASTEXITCODE -ne 0) { throw "Git status failed: $status" }
        
        # Check for remote repository
        $remotes = git remote
        if (-not $remotes) {
            Write-Log "No remote repository configured!" "Yellow"
            Write-Log "Please set up a remote repository with:" "Yellow"
            Write-Log "git remote add origin YOUR_REPO_URL" "Cyan"
            throw "No remote repository configured"
        }
        
        Write-Log "Git repository verified successfully" "Green"
        return $true
    }
    catch {
        Write-Log "Git repository check failed: $_" "Red"
        return $false
    }
}

# Function to show what will be copied
function Show-CopyPreview {
    param (
        [string]$SourcePath,
        [string]$DestinationPath,
        [int]$IndentLevel = 0
    )
    
    $indent = "  " * $IndentLevel
    try {
        if (Test-Path $SourcePath) {
            $item = Get-Item $SourcePath
            
            if ($item.PSIsContainer) {
                Write-Log "$indent[DIR] $($item.Name) -> $(Split-Path $DestinationPath -Leaf)" "Cyan"
                Get-ChildItem $SourcePath -Force | ForEach-Object {
                    $newDest = Join-Path $DestinationPath $_.Name
                    Show-CopyPreview -SourcePath $_.FullName -DestinationPath $newDest -IndentLevel ($IndentLevel + 1)
                }
            } else {
                Write-Log "$indent[FILE] $($item.Name) -> $(Split-Path $DestinationPath -Leaf)" "White"
            }
        } else {
            Write-Log "$indent[NOT FOUND] $SourcePath" "Red"
        }
    }
    catch {
        Write-Log "$indent[ERROR] Failed to process $SourcePath : $_" "Red"
    }
}

# Function to copy files and directories
function Copy-ConfigFiles {
    param (
        [string[]]$Paths
    )
    
    $copyCount = 0
    
    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace($path) -or $path.StartsWith("#")) {
            continue
        }
        
        $expandedPath = [Environment]::ExpandEnvironmentVariables($path.Trim())
        Write-Log "Processing: $expandedPath" "Yellow"
        
        if (Test-Path $expandedPath) {
            $item = Get-Item $expandedPath
            $destination = Join-Path $PWD $item.Name
            
            Write-Log "Found: $expandedPath" "Green"
            if ($WhatIf) {
                Show-CopyPreview -SourcePath $expandedPath -DestinationPath $destination
                continue
            }
            
            try {
                if ($item.PSIsContainer) {
                    Write-Log "Copying directory: $expandedPath" "Cyan"
                    Write-Log "-> $destination" "DarkCyan"
                    Copy-Item -Path $expandedPath -Destination $destination -Recurse -Force
                    
                    $fileCount = (Get-ChildItem -Path $destination -Recurse -File).Count
                    $dirCount = (Get-ChildItem -Path $destination -Recurse -Directory).Count
                    Write-Log "Copied $fileCount files in $dirCount directories" "Green"
                    $copyCount += $fileCount
                } else {
                    Write-Log "Copying file: $expandedPath" "Cyan"
                    Write-Log "-> $destination" "DarkCyan"
                    Copy-Item -Path $expandedPath -Destination $destination -Force
                    Write-Log "File copied successfully" "Green"
                    $copyCount++
                }
            } catch {
                Write-Log "Error copying $expandedPath : $_" "Red"
                throw $_
            }
        } else {
            Write-Log "Path not found: $expandedPath" "Red"
            throw "Path not found: $expandedPath"
        }
    }
    
    return $copyCount
}

# Main script execution
try {
    Write-Log "Script started" "Cyan"
    Write-Log "Current directory: $(Get-Location)" "White"
    
    # Verify git repository
    if (-not (Test-GitRepository)) {
        throw "Git repository verification failed"
    }
    
    # Check if config file exists
    Write-Log "Checking for config file: $ConfigFile" "Yellow"
    if (-not (Test-Path $ConfigFile)) {
        throw "Config file not found: $ConfigFile"
    }
    
    # Read and validate config file
    Write-Log "Reading config file..." "Yellow"
    $paths = Get-Content $ConfigFile
    $validPaths = $paths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and -not $_.StartsWith('#') }
    Write-Log "Found $($validPaths.Count) valid paths in config file" "Green"
    
    if ($validPaths.Count -eq 0) {
        throw "No valid paths found in config file"
    }
    
    # Display paths found
    Write-Log "Configured paths:" "Cyan"
    $validPaths | ForEach-Object {
        Write-Log "  $_" "White"
    }
    
    if ($WhatIf) {
        Write-Log "`nPREVIEW MODE: Showing what would be copied..." "Yellow"
        Copy-ConfigFiles -Paths $validPaths
        Write-Log "`nThis was a preview. Run without -WhatIf to make actual changes." "Yellow"
    } else {
        Write-Log "`nStarting file sync..." "Cyan"
        $copyCount = Copy-ConfigFiles -Paths $validPaths
        Write-Log "Total files copied: $copyCount" "Green"
        
        if ($copyCount -gt 0) {
            Write-Log "Starting git operations..." "Cyan"
            git add .
            git commit -m "Updated config files (copied $copyCount files)"
            git push
            Write-Log "Git operations completed" "Green"
        } else {
            Write-Log "No files were copied, skipping git operations" "Yellow"
        }
    }
    
    Write-Log "Script completed successfully" "Green"
    exit 0
    
} catch {
    Write-Log "Script failed with error: $_" "Red"
    Write-Log "Error details:" "Red"
    Write-Log $_.Exception.Message "Red"
    Write-Log $_.ScriptStackTrace "Red"
    exit 1
}