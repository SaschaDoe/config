param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [Parameter(Mandatory=$true)]
    [string]$RepoName
)

# Function to verify if a command is available in PATH
function Test-CommandExists {
    param (
        [string]$Command
    )
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        return $true
    }
    return $false
}

# Function to handle editor selection and verification
function Get-EditorChoice {
    Write-Host "`nWhich editor would you like to use?" -ForegroundColor Yellow
    Write-Host "1. Visual Studio Code" -ForegroundColor Cyan
    Write-Host "2. Neovim (via WezTerm)" -ForegroundColor Cyan
    Write-Host "Enter your choice (1 or 2):" -ForegroundColor Yellow
    
    $choice = Read-Host
    
    switch ($choice) {
        "1" {
            if (Test-CommandExists "code") {
                return @{
                    Editor = "vscode"
                    IsValid = $true
                    Command = "code"
                    Args = @("-n", "`"$Path`"")
                }
            } else {
                Write-Log "Visual Studio Code not found in PATH. Please install VS Code or add it to PATH." "Red" $true
                return @{
                    Editor = "vscode"
                    IsValid = $false
                }
            }
        }
        "2" {
            $nvimExists = Test-CommandExists "nvim"
            $wezExists = Test-CommandExists "wezterm"
            
            if ($nvimExists -and $wezExists) {
                return @{
                    Editor = "nvim"
                    IsValid = $true
                    Command = "wezterm"
                    Args = @("start", "--", "nvim", "`"$Path`"")
                }
            } else {
                $missing = @()
                if (-not $nvimExists) { $missing += "Neovim" }
                if (-not $wezExists) { $missing += "WezTerm" }
                Write-Log "Missing required programs: $($missing -join ', '). Defaulting to VS Code..." "Yellow" $true
                
                if (Test-CommandExists "code") {
                    return @{
                        Editor = "vscode"
                        IsValid = $true
                        Command = "code"
                        Args = @("-n", "`"$Path`"")
                    }
                } else {
                    Write-Log "Visual Studio Code not found in PATH. Please install an editor." "Red" $true
                    return @{
                        Editor = "vscode"
                        IsValid = $false
                    }
                }
            }
        }
        default {
            Write-Log "Invalid choice. Defaulting to VS Code..." "Yellow" $true
            if (Test-CommandExists "code") {
                return @{
                    Editor = "vscode"
                    IsValid = $true
                    Command = "code"
                    Args = @("-n", "`"$Path`"")
                }
            } else {
                Write-Log "Visual Studio Code not found in PATH. Please install VS Code or add it to PATH." "Red" $true
                return @{
                    Editor = "vscode"
                    IsValid = $false
                }
            }
        }
    }
}

# Function to log with timestamp and pause
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

# Add this function near the top with other functions
function Get-GitHubUsername {
    try {
        $output = & "C:\Program Files\GitHub CLI\gh.exe" api user 2>&1
        if ($output) {
            $userInfo = $output | ConvertFrom-Json
            return $userInfo.login
        }
    } catch {
        Write-Log "Error getting GitHub username. Please enter manually." "Yellow"
        Write-Host "Enter your GitHub username:" -ForegroundColor Yellow
        return Read-Host
    }
}

# Function to check for admin rights
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to handle GitHub authentication
function Ensure-GitHubAuth {
    Write-Log "Starting GitHub authentication check..." "Yellow" $true
    try {
        $authOutput = & "C:\Program Files\GitHub CLI\gh.exe" auth status 2>&1
        Write-Log "Auth status output: $authOutput" "Cyan"
        
        if ($authOutput -like "*not logged into*") {
            Write-Log "Not authenticated. Starting web login process..." "Yellow" $true
            Write-Log "Running: gh auth login --web" "Cyan"
            
            $loginOutput = & "C:\Program Files\GitHub CLI\gh.exe" auth login --web --git-protocol https
            Write-Log "Login output: $loginOutput" "Cyan"
            
            # Verify authentication after login attempt
            $verifyOutput = & "C:\Program Files\GitHub CLI\gh.exe" auth status 2>&1
            Write-Log "Verification output: $verifyOutput" "Cyan"
            
            if ($verifyOutput -like "*not logged into*") {
                Write-Log "Authentication failed!" "Red" $true
                return $false
            }
            
            Write-Log "Authentication successful!" "Green" $true
            return $true
        }
        
        Write-Log "Already authenticated with GitHub" "Green" $true
        return $true
    } catch {
        Write-Log "Error during authentication: $_" "Red" $true
        return $false
    }
}

# Function to get valid repository name
function Get-ValidRepoName {
    param(
        [string]$DefaultName
    )
    Write-Host "`nCurrent directory name: $DefaultName" -ForegroundColor Cyan
    Write-Host "Would you like to use a different name for the repository? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host

    if ($response -eq 'Y' -or $response -eq 'y') {
        do {
            Write-Host "`nEnter new repository name (only letters, numbers, hyphens and underscores):" -ForegroundColor Yellow
            $newName = Read-Host
            # Sanitize name: replace spaces and special chars with single hyphen
            $newName = $newName -replace '[^\w]+', '-'    # Replace sequences of invalid chars with single hyphen
            $newName = $newName -replace '^-+|-+$', ''    # Remove leading/trailing hyphens
            if ($newName) {
                return $newName
            }
            Write-Host "Invalid name. Please try again." -ForegroundColor Red
        } while ($true)
    }
    
    # Sanitize default name the same way
    $sanitizedDefault = $DefaultName -replace '[^\w]+', '-'
    $sanitizedDefault = $sanitizedDefault -replace '^-+|-+$', ''
    return $sanitizedDefault
}

# Start script execution
Write-Log "Script started" "Cyan" $true
Write-Log "Current directory: $Path" "Cyan"

# Get and validate repository name
$sanitizedRepoName = Get-ValidRepoName $RepoName
Write-Log "Using repository name: $sanitizedRepoName" "Cyan" $true

# Check for GitHub CLI
$ghPath = "C:\Program Files\GitHub CLI\gh.exe"
if (-not (Test-Path $ghPath)) {
    Write-Log "GitHub CLI not found at: $ghPath" "Red" $true
    Exit 1
}

# Verify GitHub CLI works
try {
    $versionOutput = & $ghPath --version
    Write-Log "GitHub CLI version: $versionOutput" "Green" $true
} catch {
    Write-Log "Error running GitHub CLI: $_" "Red" $true
    Exit 1
}

# Change to the specified directory
try {
    Set-Location $Path
    Write-Log "Changed to directory: $Path" "Green" $true
} catch {
    Write-Log "Failed to change directory: $_" "Red" $true
    Exit 1
}

# Ensure GitHub authentication
if (-not (Ensure-GitHubAuth)) {
    Write-Log "Failed to authenticate with GitHub. Exiting..." "Red" $true
    Exit 1
}

Write-Log "Preparing to create repository: $sanitizedRepoName" "Cyan" $true

# Initialize git if needed
if (-not (Test-Path .git)) {
    Write-Log "Initializing git repository..." "Yellow"
    try {
        $gitInitOutput = git init 2>&1
        Write-Log "Git init output: $gitInitOutput" "Cyan"
        
        $gitAddOutput = git add . 2>&1
        Write-Log "Git add output: $gitAddOutput" "Cyan"
        
        # Configure git user if not already configured
        $userEmail = git config --global user.email
        $userName = git config --global user.name
        
        if (-not $userEmail -or -not $userName) {
            Write-Log "Git user not configured. Please enter your details:" "Yellow"
            if (-not $userEmail) {
                Write-Host "Enter your GitHub email:" -ForegroundColor Yellow
                $email = Read-Host
                git config --global user.email $email
            }
            if (-not $userName) {
                Write-Host "Enter your GitHub username:" -ForegroundColor Yellow
                $name = Read-Host
                git config --global user.name $name
            }
        }
        
        # Check if there are any files to commit
        $status = git status --porcelain
        if ($status) {
            $gitCommitOutput = git commit -m "Initial commit" 2>&1
            Write-Log "Git commit output: $gitCommitOutput" "Cyan"
        } else {
            # Create a dummy file if directory is empty
            Write-Log "No files to commit. Creating README.md..." "Yellow"
            "# $sanitizedRepoName`nInitial repository setup" | Out-File -FilePath "README.md" -Encoding UTF8
            git add README.md
            $gitCommitOutput = git commit -m "Initial commit with README" 2>&1
            Write-Log "Git commit output: $gitCommitOutput" "Cyan"
        }
        
        Write-Log "Git repository initialized successfully" "Green" $true
    } catch {
        Write-Log "Failed to initialize git repository: $_" "Red" $true
        Exit 1
    }
} else {
    Write-Log "Git repository already exists" "Green" $true
}

# Create GitHub repository
try {
    Write-Log "Creating GitHub repository..." "Yellow" $true
    
    # Get GitHub username
    $githubUsername = Get-GitHubUsername
    Write-Log "Using GitHub username: $githubUsername" "Cyan" $true
    
    # Create the repository
    Write-Log "Running: gh repo create $sanitizedRepoName --public" "Cyan"
    $createOutput = & $ghPath repo create $sanitizedRepoName --public 2>&1
    Write-Log "Create output: $createOutput" "Cyan" $true
    
    # Set up remote and push
    Write-Log "Setting up git remote..." "Yellow"
    # Remove existing origin if it exists
    git remote remove origin 2>$null
    $remoteOutput = git remote add origin "https://github.com/$githubUsername/$sanitizedRepoName.git" 2>&1
    Write-Log "Remote output: $remoteOutput" "Cyan"
    
    Write-Log "Setting up main branch..." "Yellow"
    $branchOutput = git branch -M main 2>&1
    Write-Log "Branch output: $branchOutput" "Cyan"
    
    Write-Log "Pushing to GitHub..." "Yellow"
    $pushOutput = git push -u origin main 2>&1
    Write-Log "Push output: $pushOutput" "Cyan" $true
    
    Write-Log "Repository setup completed!" "Green"
    Write-Log "You can view your repository at: https://github.com/$githubUsername/$sanitizedRepoName" "Cyan" $true

    # Open VS Code
   Write-Log "Opening editor..." "Yellow"
    $editorChoice = Get-EditorChoice
    if ($editorChoice.IsValid) {
        try {
            Start-Process $editorChoice.Command -ArgumentList $editorChoice.Args
            Write-Log "$($editorChoice.Editor) opened successfully" "Green" $true
        } catch {
            Write-Log "Failed to open $($editorChoice.Editor): $_. Please open it manually." "Red" $true
        }
    } else {
    Write-Log "No suitable editor found. Please install VS Code or Neovim+WezTerm." "Red" $true
}

} catch {
    Write-Log "Failed during repository creation: $_" "Red" $true
    Exit 1
}

Write-Log "Script completed successfully" "Green" $true