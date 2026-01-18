# Slipstream-Rust

🚀 **High-performance DNS tunnel with cross-platform client and server support**

A complete DNS tunnel implementation in Rust with deployment automation for Linux servers and pre-built clients for Windows, macOS, and Linux.

## Features

- **High Performance**: Built on QUIC protocol with picoquic
- **Cross-Platform**: Clients for Windows, macOS, Linux (x64 & ARM64)
- **Easy Deployment**: One-command server installation
- **Secure**: TLS encryption with optional certificate pinning
- **Flexible**: SOCKS proxy or SSH tunnel modes

---

## 🚀 Quick Start: Complete Deployment Guide

This step-by-step guide will help you deploy a complete slipstream DNS tunnel.

### Prerequisites

Before you begin, you need:
- A **VPS/server** with a public IP address (Ubuntu/Debian recommended)
- A **domain name** you control
- **Root/sudo access** on the server

---

### Step 1: Configure Your Domain's DNS Records

Before installing the server, set up your DNS records:

**Example Setup:**
- Your domain: `example.com`
- Your server IP: `203.0.113.2`
- Tunnel subdomain: `s.example.com`

**Add these DNS records at your domain registrar:**

| Type | Name | Value/Points to | TTL |
|------|------|-----------------|-----|
| **A** | `ns.example.com` | `203.0.113.2` | 3600 |
| **NS** | `s.example.com` | `ns.example.com` | 3600 |

> ⚠️ **Important**: Wait 15-30 minutes for DNS propagation. You can verify with:
> ```bash
> dig NS s.example.com
> ```

---

### Step 2: Deploy the Server (One-Command Install)

SSH into your server and run:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mohamadsolouki/slipstream-rust/main/scripts/deploy/deploy-server.sh)
```

**The script will interactively ask you:**

1. **Domain name** - Enter your tunnel domain (e.g., `s.example.com`)
2. **Tunnel mode** - Choose `socks` (recommended) or `ssh`
3. **Install Dante SOCKS proxy?** - Yes if you chose SOCKS mode

**What the script does:**
- ✅ Installs all build dependencies (Rust, CMake, OpenSSL, etc.)
- ✅ Clones and builds slipstream-server from source
- ✅ Generates TLS certificates
- ✅ Configures iptables rules for DNS redirection
- ✅ Sets up systemd service for auto-start
- ✅ Optionally installs Dante SOCKS5 proxy

---

### Step 3: Verify Server Installation

After installation completes, verify everything is running:

```bash
# Check slipstream-server status
sudo systemctl status slipstream-server

# Check if ports are listening
sudo ss -tulnp | grep -E "(53|5300|1080)"

# View server logs
sudo journalctl -u slipstream-server -f
```

**Expected output:**
- slipstream-server should be `active (running)`
- Ports 53 (DNS) and 5300 (internal) should be listening
- Port 1080 if SOCKS mode is enabled

---

### Step 4: Download and Set Up the Client

Download the client for your operating system from [Releases](https://github.com/mohamadsolouki/slipstream-rust/releases):

| Platform | Download |
|----------|----------|
| Linux x64 | `slipstream-linux-x64.tar.gz` |
| macOS Intel | `slipstream-macos-x64.tar.gz` |
| macOS Apple Silicon | `slipstream-macos-arm64.tar.gz` |

> **Note**: Windows users can build from source using the PowerShell build script.

**Extract the client:**

```bash
# Linux/macOS
tar -xzf slipstream-*.tar.gz
```

---

### Step 5: Connect with the Client

Run the client to connect to your server:

```bash
./slipstream-client \
  --tcp-listen-port 7000 \
  --resolver YOUR_SERVER_IP:53 \
  --domain s.example.com
```

Replace:
- `YOUR_SERVER_IP` with your server's public IP address
- `s.example.com` with your tunnel domain

**Windows:**
```powershell
.\slipstream-client.exe --tcp-listen-port 7000 --resolver YOUR_SERVER_IP:53 --domain s.example.com
```

---

### Step 6: Configure Your Applications

The client creates a local SOCKS5 proxy. Configure your applications to use:

| Setting | Value |
|---------|-------|
| Proxy Type | SOCKS5 |
| Host | `127.0.0.1` |
| Port | `7000` |

**Browser Configuration (Firefox):**
1. Settings → Network Settings → Manual proxy configuration
2. SOCKS Host: `127.0.0.1`, Port: `7000`
3. Select "SOCKS v5"
4. Check "Proxy DNS when using SOCKS v5"

**System-wide (Linux):**
```bash
export ALL_PROXY=socks5://127.0.0.1:7000
```

---

### Step 7: (Optional) Run Client as a Service

**Linux (systemd):**
```bash
# Copy and edit the service file
sudo cp configs/client/slipstream-client.service /etc/systemd/system/
sudo nano /etc/systemd/system/slipstream-client.service
# Update the ExecStart line with your settings

sudo systemctl daemon-reload
sudo systemctl enable slipstream-client
sudo systemctl start slipstream-client
```

**Windows (using Task Scheduler):**
1. Open Task Scheduler
2. Create Basic Task → "Slipstream Client"
3. Trigger: "When the computer starts"
4. Action: Start a program
5. Program: Path to `slipstream-client.exe`
6. Arguments: `--tcp-listen-port 7000 --resolver YOUR_SERVER_IP:53 --domain s.example.com`

---

## 📁 Repository Structure

```
slipstream-rust/
├── crates/                   # Rust source code
│   ├── slipstream-client/    # Client implementation
│   ├── slipstream-server/    # Server implementation
│   ├── slipstream-core/      # Shared core library
│   ├── slipstream-dns/       # DNS protocol handling
│   └── slipstream-ffi/       # FFI bindings for picoquic
├── vendor/                   # picoquic submodule
├── scripts/
│   ├── deploy/              # Server deployment
│   ├── build/               # Build scripts
│   └── patches/             # Platform compatibility patches
├── configs/                  # Configuration templates
│   ├── client/              # Client service files
│   └── server/              # Server service files
├── fixtures/                 # Test certificates
├── docs/                     # Documentation
├── .github/workflows/        # CI/CD pipelines
├── Cargo.toml
└── LICENSE
```

## 🔧 Advanced Configuration

### Client Options

| Option | Description | Default |
|--------|-------------|---------|
| `--tcp-listen-port` | Local TCP port to listen on | 5201 |
| `--resolver` | DNS resolver address (server IP) | Required |
| `--domain` | Domain name for tunnel | Required |
| `--cert` | Path to server certificate for pinning | None |
| `--keep-alive-interval` | Keep-alive interval in ms | 400 |
| `--congestion-control` | CC algorithm: `bbr` or `dcubic` | Auto |

### Server Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dns-listen-port` | UDP port for DNS | 53 |
| `--target-address` | Target address for tunneled traffic | 127.0.0.1:5201 |
| `--domain` | Domain(s) to handle | Required |
| `--cert` | Path to TLS certificate | Required |
| `--key` | Path to TLS private key | Required |

---

## 🔨 Building from Source

### Prerequisites

- Rust toolchain (stable)
- CMake
- pkg-config
- OpenSSL development headers
- C compiler (GCC/Clang)

### Build Commands

```bash
# Clone and initialize
git clone https://github.com/mohamadsolouki/slipstream-rust.git
cd slipstream-rust
git submodule update --init --recursive

# Build picoquic dependencies
bash scripts/build_picoquic.sh

# Build both client and server
cargo build --release -p slipstream-client -p slipstream-server

# Binaries will be in target/release/
```

---

## 🐛 Troubleshooting

### Common Issues

**Server not starting:**
```bash
sudo journalctl -u slipstream-server -n 50 --no-pager
```

**DNS not resolving:**
```bash
dig @YOUR_SERVER_IP s.example.com
```

**Connection timeout:**
- Verify firewall allows UDP port 53
- Check if DNS records are propagated
- Ensure server is running: `sudo systemctl status slipstream-server`

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more details.

---

## 📚 Documentation

- [Client Setup Guide](docs/CLIENT_SETUP.md)
- [Server Setup Guide](docs/SERVER_SETUP.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

---

## 🙏 Acknowledgments

This project builds upon excellent work by others:

- [slipstream-rust](https://github.com/Mygod/slipstream-rust) by Mygod - Core Rust implementation
- [slipstream-rust-deploy](https://github.com/AliRezaBeigy/slipstream-rust-deploy) by AliRezaBeigy - Deployment scripts
- [slipstream](https://github.com/EndPositive/slipstream) by Jop Zitman - Original C implementation
- [picoquic](https://github.com/private-octopus/picoquic) - QUIC protocol implementation
- [dnstt](https://www.bamsoftware.com/software/dnstt/) by David Fifield - DNS tunnel inspiration

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.