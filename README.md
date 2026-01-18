# Slipstream-Rust

🚀 **High-performance DNS tunnel with cross-platform client and server support**

A complete DNS tunnel implementation in Rust with deployment automation for Linux servers and pre-built clients for Windows, macOS, and Linux.

## Features

- **High Performance**: Built on QUIC protocol with picoquic
- **Cross-Platform**: Clients for Windows, macOS, Linux (x64 & ARM64)
- **Easy Deployment**: One-command server installation
- **Secure**: TLS encryption with optional certificate pinning
- **Flexible**: SOCKS proxy or SSH tunnel modes

## Repository Structure

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

## Quick Start

### Server Setup (Linux)

**One-command installation:**
```bash
bash <(curl -Ls https://raw.githubusercontent.com/mohamadsolouki/slipstream-rust/main/scripts/deploy/deploy-server.sh)
```

### Client Setup

#### Pre-built Releases (Recommended)

Download from [Releases](https://github.com/mohamadsolouki/slipstream-rust/releases):

| Platform | Download |
|----------|----------|
| Windows x64 | `slipstream-windows-x64.zip` |
| macOS x64 (Intel) | `slipstream-macos-x64.tar.gz` |
| macOS ARM64 (Apple Silicon) | `slipstream-macos-arm64.tar.gz` |
| Linux x64 | `slipstream-linux-x64.tar.gz` |
| Linux ARM64 | `slipstream-linux-arm64.tar.gz` |

#### Build from Source

**Linux/macOS:**
```bash
bash scripts/build/build-client.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\build\build-client.ps1
```

## DNS Domain Setup

Before using slipstream, configure your domain's DNS records:

### Example Configuration
- **Your domain**: `example.com`
- **Server IP**: `203.0.113.2`
- **Tunnel subdomain**: `s.example.com`
- **Server hostname**: `ns.example.com`

### Required DNS Records

| Type | Name | Points to |
|------|------|-----------|
| A | `ns.example.com` | `203.0.113.2` |
| NS | `s.example.com` | `ns.example.com` |

⚠️ **Wait for DNS propagation (up to 24 hours) before testing.**

## Client Usage

### Basic Usage

```bash
# Connect to your slipstream server
slipstream-client \
  --tcp-listen-port 7000 \
  --resolver YOUR_SERVER_IP:53 \
  --domain s.example.com
```

### With Certificate Pinning (Recommended)

```bash
slipstream-client \
  --tcp-listen-port 7000 \
  --resolver YOUR_SERVER_IP:53 \
  --domain s.example.com \
  --cert /path/to/server-cert.pem
```

### Using as SOCKS Proxy

After starting the client, configure your applications to use:
- **SOCKS5 Proxy**: `127.0.0.1:7000`

### Running as a Service

**Linux (systemd):**
```bash
sudo cp configs/client/client-systemd.service /etc/systemd/system/slipstream-client.service
# Edit the service file with your configuration
sudo systemctl daemon-reload
sudo systemctl enable slipstream-client
sudo systemctl start slipstream-client
```

**Windows (as a service):**
```powershell
# Using NSSM (Non-Sucking Service Manager)
nssm install slipstream-client "C:\path\to\slipstream-client.exe"
nssm set slipstream-client AppParameters "--tcp-listen-port 7000 --resolver SERVER_IP:53 --domain s.example.com"
nssm start slipstream-client
```

## Server Deployment

### Interactive Setup

```bash
bash scripts/server/deploy-server.sh
```

This will:
1. Install all build dependencies
2. Build slipstream-server from source
3. Generate TLS certificates
4. Configure firewall and iptables
5. Set up systemd service
6. Optionally configure Dante SOCKS proxy

### Tunnel Modes

**SOCKS Mode:**
- Integrated Dante SOCKS5 proxy
- Full internet proxy capabilities
- Listens on `127.0.0.1:1080`

**SSH Mode:**
- Tunnels DNS traffic to SSH service
- Automatically detects SSH port
- Perfect for secure shell access

## Configuration Options

### Client Options

| Option | Description | Default |
|--------|-------------|---------|
| `--tcp-listen-port` | Local TCP port to listen on | 5201 |
| `--resolver` | DNS resolver address (server IP) | Required |
| `--domain` | Domain name for tunnel | Required |
| `--cert` | Path to server certificate for pinning | None |
| `--keep-alive-interval` | Keep-alive interval in ms | 400 |
| `--congestion-control` | CC algorithm: `bbr` or `dcubic` | Auto |
| `--authoritative` | Use authoritative mode | False |

### Server Options

| Option | Description | Default |
|--------|-------------|---------|
| `--dns-listen-port` | UDP port for DNS | 53 |
| `--target-address` | Target address for tunneled traffic | 127.0.0.1:5201 |
| `--domain` | Domain(s) to handle | Required |
| `--cert` | Path to TLS certificate | Required |
| `--key` | Path to TLS private key | Required |

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues.

### Quick Diagnostics

**Check server status:**
```bash
sudo systemctl status slipstream-server
sudo journalctl -u slipstream-server -f
```

**Test DNS resolution:**
```bash
dig @YOUR_SERVER_IP s.example.com
```

**Check ports:**
```bash
sudo ss -tulnp | grep -E "(5300|53|1080)"
```

## Building from Source

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

# Build both client and server
cargo build --release -p slipstream-client -p slipstream-server

# Binaries will be in target/release/
```

## Documentation

- [Client Setup Guide](docs/CLIENT_SETUP.md)
- [Server Setup Guide](docs/SERVER_SETUP.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

This project builds upon excellent work by others:

- [slipstream-rust](https://github.com/Mygod/slipstream-rust) by Mygod - Core Rust implementation
- [slipstream-rust-deploy](https://github.com/AliRezaBeigy/slipstream-rust-deploy) by AliRezaBeigy - Deployment scripts
- [slipstream](https://github.com/EndPositive/slipstream) by Jop Zitman - Original C implementation
- [picoquic](https://github.com/private-octopus/picoquic) - QUIC protocol implementation
- [dnstt](https://www.bamsoftware.com/software/dnstt/) by David Fifield - DNS tunnel inspiration

## License

MIT License. See [LICENSE](LICENSE) for details.