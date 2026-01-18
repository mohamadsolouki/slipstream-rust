# Client Setup Guide

This guide covers setting up the Slipstream client on various platforms.

## Prerequisites

Before setting up the client, ensure:
1. Your server is running and configured
2. DNS records are properly set up
3. You have the server's domain name

## Installation

### Pre-built Binaries (Recommended)

Download from [Releases](https://github.com/mohamadsolouki/slipstream-rust/releases):

| Platform | File |
|----------|------|
| Linux x64 | `slipstream-linux-x64.tar.gz` |
| Linux ARM64 | `slipstream-linux-arm64.tar.gz` |
| macOS Intel | `slipstream-macos-x64.tar.gz` |
| macOS Apple Silicon | `slipstream-macos-arm64.tar.gz` |
| Windows x64 | `slipstream-windows-x64.zip` |

#### Linux/macOS Installation

```bash
# Download and extract (example for Linux x64)
curl -LO https://github.com/mohamadsolouki/slipstream-rust/releases/latest/download/slipstream-linux-x64.tar.gz
tar -xzf slipstream-linux-x64.tar.gz

# Install
sudo mv slipstream-client /usr/local/bin/
sudo chmod +x /usr/local/bin/slipstream-client

# Verify
slipstream-client --help
```

#### Windows Installation

1. Download `slipstream-windows-x64.zip`
2. Extract to a folder (e.g., `C:\Program Files\Slipstream`)
3. Add the folder to your PATH environment variable
4. Open a new terminal and verify: `slipstream-client --help`

### Build from Source

See [Building from Source](#building-from-source) section.

## Configuration

### Basic Usage

```bash
slipstream-client \
    --tcp-listen-port 7000 \
    --resolver YOUR_SERVER_IP:53 \
    --domain s.example.com
```

### Command Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--tcp-listen-port` | `-l` | Local TCP port for SOCKS | 5201 |
| `--resolver` | `-r` | Server IP:port | Required |
| `--domain` | `-d` | Tunnel domain | Required |
| `--cert` | | Server certificate path | None |
| `--keep-alive-interval` | `-t` | Keep-alive (ms) | 400 |
| `--congestion-control` | `-c` | `bbr` or `dcubic` | Auto |
| `--authoritative` | | Authoritative mode | False |

### Certificate Pinning (Recommended)

For enhanced security, pin the server's certificate:

```bash
# First, get the certificate from your server
scp user@server:/etc/slipstream/cert.pem ./server-cert.pem

# Use with client
slipstream-client \
    --tcp-listen-port 7000 \
    --resolver YOUR_SERVER_IP:53 \
    --domain s.example.com \
    --cert ./server-cert.pem
```

## Running as a Service

### Linux (systemd)

```bash
# Create slipstream user
sudo useradd -r -s /bin/false slipstream

# Copy service file
sudo cp configs/client/slipstream-client.service /etc/systemd/system/

# Edit configuration
sudo nano /etc/systemd/system/slipstream-client.service

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable slipstream-client
sudo systemctl start slipstream-client

# Check status
sudo systemctl status slipstream-client
```

### macOS (launchd)

Create `~/Library/LaunchAgents/com.slipstream.client.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.slipstream.client</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/slipstream-client</string>
        <string>--tcp-listen-port</string>
        <string>7000</string>
        <string>--resolver</string>
        <string>YOUR_SERVER_IP:53</string>
        <string>--domain</string>
        <string>s.example.com</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Load with: `launchctl load ~/Library/LaunchAgents/com.slipstream.client.plist`

### Windows (NSSM)

```powershell
# Install NSSM (using Chocolatey)
choco install nssm

# Install as service
nssm install slipstream-client "C:\Program Files\Slipstream\slipstream-client.exe"
nssm set slipstream-client AppParameters "--tcp-listen-port 7000 --resolver YOUR_SERVER_IP:53 --domain s.example.com"
nssm set slipstream-client DisplayName "Slipstream Client"
nssm set slipstream-client Start SERVICE_AUTO_START

# Start
nssm start slipstream-client
```

## Using the Tunnel

Once the client is running, configure your applications:

### SOCKS5 Proxy

- **Host**: `127.0.0.1`
- **Port**: `7000` (or your configured port)
- **Type**: SOCKS5

### Browser Configuration

**Firefox:**
1. Settings → Network Settings → Settings
2. Select "Manual proxy configuration"
3. SOCKS Host: `127.0.0.1`, Port: `7000`
4. Select SOCKS v5

**Chrome (with extension):**
Use SwitchyOmega or similar extension.

### Command Line Tools

```bash
# curl
curl --socks5 127.0.0.1:7000 https://example.com

# git
git config --global http.proxy socks5://127.0.0.1:7000

# ssh
ssh -o ProxyCommand="nc -x 127.0.0.1:7000 %h %p" user@host
```

## Building from Source

### Linux

```bash
# Install dependencies
sudo apt install cmake pkg-config libssl-dev build-essential git

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build
cd slipstream-rust
git submodule update --init --recursive
bash scripts/build/build-client.sh
```

### macOS

```bash
# Install dependencies
brew install cmake pkg-config openssl@3

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build
cd slipstream-rust
git submodule update --init --recursive
bash scripts/build/build-client.sh
```

### Windows

```powershell
# Install Visual Studio Build Tools
# Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/

# Install CMake
choco install cmake

# Install Rust
# Download from: https://rustup.rs

# Build
cd slipstream-rust
git submodule update --init --recursive
.\scripts\build\build-client.ps1
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues.
