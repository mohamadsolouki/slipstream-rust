# Server Setup Guide

This guide covers deploying the Slipstream server on Linux.

## Prerequisites

- Linux server (Ubuntu, Debian, CentOS, Rocky, Fedora)
- Root access
- Domain name with proper DNS configuration
- Open UDP port 53

## DNS Configuration

Before installing the server, configure your domain's DNS:

### Example Setup

For domain `example.com` with server IP `203.0.113.2`:

| Type | Name | Value |
|------|------|-------|
| A | `ns.example.com` | `203.0.113.2` |
| NS | `s.example.com` | `ns.example.com` |

**Important:** Wait for DNS propagation (up to 24 hours).

### Verify DNS

```bash
# From another machine
dig NS s.example.com
# Should return ns.example.com

dig @203.0.113.2 s.example.com
# Should get a response from your server
```

## Quick Installation

### One-Command Deploy

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mohamadsolouki/slipstream-rust/main/scripts/deploy/deploy-server.sh)
```

This interactive script will:
1. Install all dependencies (Rust, cmake, OpenSSL)
2. Build slipstream-server from source
3. Generate TLS certificates
4. Configure firewall and iptables
5. Set up systemd service
6. Optionally configure SOCKS proxy (Dante)

### Manual Installation

```bash
# Clone repository
git clone https://github.com/mohamadsolouki/slipstream-rust.git
cd slipstream-rust

# Install dependencies (Ubuntu/Debian)
sudo apt update
sudo apt install -y cmake pkg-config libssl-dev build-essential

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Build
git submodule update --init --recursive
cargo build --release -p slipstream-server

# Install
sudo cp target/release/slipstream-server /usr/local/bin/
```

## Configuration

### Generate Certificates

```bash
sudo mkdir -p /etc/slipstream

# Generate self-signed certificate
sudo openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /etc/slipstream/key.pem \
    -out /etc/slipstream/cert.pem \
    -days 365 \
    -subj "/CN=slipstream"

# Set permissions
sudo chmod 600 /etc/slipstream/key.pem
sudo chmod 644 /etc/slipstream/cert.pem
```

### Configure iptables

Redirect DNS traffic from port 53 to the server:

```bash
# Get network interface
IFACE=$(ip route | grep default | awk '{print $5}')

# Redirect port 53 to 5300
sudo iptables -I INPUT -p udp --dport 5300 -j ACCEPT
sudo iptables -t nat -I PREROUTING -i $IFACE -p udp --dport 53 -j REDIRECT --to-ports 5300

# Save rules (Debian/Ubuntu)
sudo apt install iptables-persistent
sudo netfilter-persistent save

# Save rules (CentOS/Rocky)
sudo service iptables save
```

### Create Service User

```bash
sudo useradd -r -s /bin/false slipstream
sudo chown -R slipstream:slipstream /etc/slipstream
```

### Install systemd Service

```bash
# Copy service file
sudo cp configs/server/slipstream-server.service /etc/systemd/system/

# Edit configuration
sudo nano /etc/systemd/system/slipstream-server.service
# Update domain, paths as needed

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable slipstream-server
sudo systemctl start slipstream-server
```

## Tunnel Modes

### SOCKS Mode (Default)

Install Dante SOCKS proxy to provide full internet proxy:

```bash
# Ubuntu/Debian
sudo apt install dante-server

# Configure /etc/danted.conf
sudo tee /etc/danted.conf << 'EOF'
logoutput: syslog
user.privileged: root
user.unprivileged: nobody

internal: 127.0.0.1 port = 1080
external: eth0

socksmethod: none
clientmethod: none

client pass {
    from: 127.0.0.0/8 to: 0.0.0.0/0
}

socks pass {
    from: 127.0.0.0/8 to: 0.0.0.0/0
    command: bind connect udpassociate
}
EOF

# Start Dante
sudo systemctl enable danted
sudo systemctl start danted
```

Server configuration for SOCKS mode:
```bash
--target-address 127.0.0.1:1080
```

### SSH Mode

Tunnel traffic directly to SSH for secure shell access:

```bash
--target-address 127.0.0.1:22
```

## Command Line Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--dns-listen-port` | `-l` | UDP port for DNS | 53 |
| `--target-address` | `-a` | Forward address | 127.0.0.1:5201 |
| `--domain` | `-d` | Domain(s) to handle | Required |
| `--cert` | `-c` | TLS certificate path | Required |
| `--key` | `-k` | TLS private key path | Required |
| `--debug-streams` | | Log stream details | False |
| `--debug-commands` | | Log command counts | False |

### Multiple Domains

```bash
slipstream-server \
    --dns-listen-port 5300 \
    --domain s.example.com \
    --domain tunnel.example.com \
    --target-address 127.0.0.1:1080 \
    --cert /etc/slipstream/cert.pem \
    --key /etc/slipstream/key.pem
```

## Management

### Service Commands

```bash
# Status
sudo systemctl status slipstream-server

# Logs
sudo journalctl -u slipstream-server -f

# Restart
sudo systemctl restart slipstream-server

# Stop
sudo systemctl stop slipstream-server
```

### Monitoring

```bash
# Check listening ports
sudo ss -tulnp | grep -E "(53|5300|1080)"

# Monitor connections
sudo watch -n1 'ss -s'

# Resource usage
top -p $(pgrep slipstream-server)
```

## Firewall Configuration

### UFW (Ubuntu)

```bash
sudo ufw allow 53/udp
sudo ufw allow 5300/udp
```

### firewalld (CentOS/Rocky)

```bash
sudo firewall-cmd --permanent --add-port=53/udp
sudo firewall-cmd --permanent --add-port=5300/udp
sudo firewall-cmd --reload
```

## Security Considerations

1. **Certificate Management**: Rotate certificates periodically
2. **Firewall**: Only expose necessary ports
3. **Updates**: Keep the server updated
4. **Monitoring**: Watch for unusual traffic patterns
5. **Logging**: Enable appropriate log levels

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues.
