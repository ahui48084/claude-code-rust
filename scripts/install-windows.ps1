# Claude Code Rust - Windows Installation Script

param(
    [string]$InstallDir = "$env:LOCALAPPDATA\claude-code"
)

Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " Claude Code Rust - Windows Installation" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check all dependencies BEFORE modifying PATH
Write-Host "[1/5] Checking dependencies..." -ForegroundColor Yellow

$cargoHome = if ($env:CARGO_HOME) { $env:CARGO_HOME } else { "$env:USERPROFILE\.cargo" }
$rustBinDir = Join-Path $cargoHome "bin"
$msys2BinDir = "C:\msys64\mingw64\bin"

if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Rust not installed. Please install from https://rustup.rs/" -ForegroundColor Red
    exit 1
}
Write-Host "      Rust: $(rustc --version)" -ForegroundColor Gray

# Try to find git: first by PATH, then by common install locations
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
$gitExe = $null
if ($gitCmd) {
    $gitExe = $gitCmd.Source
} else {
    # Fallback: check common Git install paths
    $commonPaths = @(
        "D:\Dong_zhihui\software\Git\bin\git.exe",
        "D:\Dong_zhihui\software\Git\mingw64\bin\git.exe",
        "C:\Program Files\Git\bin\git.exe",
        "C:\Program Files (x86)\Git\bin\git.exe"
    )
    foreach ($p in $commonPaths) {
        if (Test-Path $p) {
            $gitExe = $p
            break
        }
    }
}
if (-not $gitExe) {
    Write-Host "Error: Git not found in PATH." -ForegroundColor Red
    exit 1
}
Write-Host "      Git: & '$gitExe' --version" -ForegroundColor Gray
Write-Host "      Git: $((& $gitExe --version) -replace '\r?\n')" -ForegroundColor Gray

if (-not (Test-Path (Join-Path $msys2BinDir "dlltool.exe"))) {
    Write-Host "Error: MSYS2 MinGW not found. Please run:" -ForegroundColor Red
    Write-Host "         pacman -Sy --needed base-devel mingw-w64-x86_64-toolchain" -ForegroundColor Cyan
    exit 1
}
Write-Host "      MSYS2 MinGW: $msys2BinDir" -ForegroundColor Gray
Write-Host ""

# Step 2: Configure MSYS2 MinGW environment
Write-Host "[2/5] Configuring MSYS2 MinGW environment..." -ForegroundColor Yellow

# Clean PATH: remove EIDE and MSYS usr/bin interference, keep everything else
$pathParts = $env:PATH -split ";"
$cleanPath = @()
foreach ($part in $pathParts) {
    if (($part -notlike "*eide*") -and ($part -notlike "*msys\usr*") -and ($part -ne $rustBinDir) -and ($part -notlike "*msys64*")) {
        if ($part -ne "") {
            $cleanPath += $part
        }
    }
}

# Restore git path if found
if ($gitExe) {
    $gitBinDir = Split-Path $gitExe
    $cleanPath = @($gitBinDir) + $cleanPath | Select-Object -Unique
}

# Final PATH: Rust -> MSYS2 MinGW -> git -> Windows system -> rest
$cleanPath = @("C:\Windows\System32", "C:\Windows") + $cleanPath | Select-Object -Unique
$env:PATH = "$rustBinDir;$msys2BinDir;" + ($cleanPath -join ";")
$env:CC = "gcc"
$env:CXX = "g++"

rustup default stable-x86_64-pc-windows-gnu | Out-Null
rustup target add x86_64-pc-windows-gnu 2>$null | Out-Null
Write-Host "      Environment configured" -ForegroundColor Green
Write-Host ""

# Step 3: Configure .env
Write-Host "[3/5] Configuring API Key..." -ForegroundColor Yellow
$sourceDir = Split-Path $PSScriptRoot

$envFile = Join-Path $sourceDir ".env"
if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $sourceDir ".env.example") $envFile -Force
    Write-Host "      Created .env file. Please fill in your ANTHROPIC_API_KEY" -ForegroundColor Cyan
    notepad $envFile
    exit 0
}

$envContent = Get-Content $envFile -Raw -ErrorAction SilentlyContinue
if ($envContent -notmatch "ANTHROPIC_API_KEY\s*=\s*sk-") {
    Write-Host "      No valid ANTHROPIC_API_KEY found in .env" -ForegroundColor Cyan
    notepad $envFile
    exit 0
}
Write-Host "      API Key configured" -ForegroundColor Green
Write-Host ""

# Step 4: Build
Write-Host "[4/5] Building project..." -ForegroundColor Yellow
Set-Location $sourceDir

Write-Host "      Cleaning old build..." -ForegroundColor Gray
cargo clean 2>$null | Out-Null

Write-Host "      Building claude-code.exe..." -ForegroundColor Gray
cargo build --release --target x86_64-pc-windows-gnu --bin claude-code
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "      Main binary built successfully" -ForegroundColor Green

Write-Host "      Building GUI binary (optional)..." -ForegroundColor Gray
cargo build --release --target x86_64-pc-windows-gnu --bin claude-code-gui --features gui-egui 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "      GUI binary built successfully" -ForegroundColor Green
}
Write-Host ""

# Step 5: Install
Write-Host "[5/5] Installing binaries..." -ForegroundColor Yellow

$binDir = Join-Path $InstallDir "bin"
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

$mainExe = Join-Path $sourceDir "target\x86_64-pc-windows-gnu\release\claude-code.exe"
Copy-Item $mainExe (Join-Path $binDir "claude-code.exe") -Force
Write-Host "      Installed: $binDir\claude-code.exe" -ForegroundColor Green

$guiExe = Join-Path $sourceDir "target\x86_64-pc-windows-gnu\release\claude-code-gui.exe"
if (Test-Path $guiExe) {
    Copy-Item $guiExe (Join-Path $binDir "claude-code-gui.exe") -Force
    Write-Host "      Installed: $binDir\claude-code-gui.exe" -ForegroundColor Green
}

$configDir = Join-Path $InstallDir "config"
if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
Write-Host ""

# Done
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " Installation complete!" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Binaries:" -ForegroundColor White
Write-Host "  $binDir\claude-code.exe      (CLI)" -ForegroundColor Gray
Write-Host "  $binDir\claude-code-gui.exe (GUI)" -ForegroundColor Gray
Write-Host ""
Write-Host "Usage:" -ForegroundColor White
Write-Host "  $binDir\claude-code.exe --help" -ForegroundColor Gray
Write-Host "  $binDir\claude-code.exe repl" -ForegroundColor Gray
Write-Host ""
Write-Host "Tip: Add $binDir to your PATH" -ForegroundColor Cyan
Write-Host ""

Set-Location $sourceDir
