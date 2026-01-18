# PowerShell Build Script for Slipstream Client on Windows
# Requires: Visual Studio Build Tools, CMake, Git

param(
    [switch]$Debug,
    [switch]$SkipDeps,
    [string]$Target = "x86_64-pc-windows-msvc"
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Status { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$BuildDir = Join-Path $RootDir "build"

Write-Status "Slipstream Client Build Script for Windows"
Write-Status "Root directory: $RootDir"

# Check for required tools
function Test-Command {
    param($cmd)
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

# Install Rust if needed
if (-not (Test-Command "rustc")) {
    Write-Status "Installing Rust..."
    Invoke-WebRequest -Uri "https://win.rustup.rs/x86_64" -OutFile "$env:TEMP\rustup-init.exe"
    & "$env:TEMP\rustup-init.exe" -y --default-toolchain stable
    $env:PATH = "$env:USERPROFILE\.cargo\bin;$env:PATH"
}

Write-Status "Rust version: $(rustc --version)"
Write-Status "Cargo version: $(cargo --version)"

# Check for CMake
if (-not (Test-Command "cmake")) {
    Write-Err "CMake not found. Please install CMake and add it to PATH."
    Write-Status "Download from: https://cmake.org/download/"
    exit 1
}

# Check for Visual Studio Build Tools
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsPath = & $vsWhere -latest -property installationPath
    if ($vsPath) {
        Write-Status "Visual Studio found at: $vsPath"
    }
} else {
    Write-Warn "Visual Studio Build Tools may not be installed."
    Write-Status "Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/"
}

# Navigate to root
Set-Location $RootDir

# Initialize submodules
Write-Status "Initializing submodules..."
git submodule update --init --recursive

# Apply Windows patches
$patchScript = Join-Path $RootDir "scripts\patches\apply_windows_socket_patch.sh"
if (Test-Path $patchScript) {
    Write-Status "Applying Windows compatibility patches..."
    if (Test-Command "bash") {
        bash $patchScript
    } else {
        Write-Warn "Bash not available. Windows patches may need to be applied manually."
    }
}

# Set build mode
$BuildFlags = @("-p", "slipstream-client", "-p", "slipstream-server")
if (-not $Debug) {
    $BuildFlags += "--release"
    Write-Status "Building in RELEASE mode..."
} else {
    Write-Status "Building in DEBUG mode..."
}

$BuildFlags += "--target"
$BuildFlags += $Target

# Build
Write-Status "Building slipstream..."
cargo build @BuildFlags

if ($LASTEXITCODE -ne 0) {
    Write-Err "Build failed!"
    exit 1
}

# Copy binaries
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$releaseDir = if ($Debug) { "debug" } else { "release" }
$binPath = Join-Path $RootDir "target\$Target\$releaseDir"

Copy-Item (Join-Path $binPath "slipstream-client.exe") $BuildDir -Force
Copy-Item (Join-Path $binPath "slipstream-server.exe") $BuildDir -Force

Write-Status "Build successful!"
Write-Status "Binaries located at: $BuildDir"
Get-ChildItem $BuildDir -Filter "*.exe" | Format-Table Name, Length, LastWriteTime
