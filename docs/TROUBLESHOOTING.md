# Troubleshooting Guide

Common issues and solutions for Slipstream.

## Quick Diagnostics

```bash
# Server status
sudo systemctl status slipstream-server

# Server logs
sudo journalctl -u slipstream-server -n 50

# Check ports
sudo ss -tulnp | grep -E "(53|5300|1080)"

# Test DNS
dig @YOUR_SERVER_IP s.example.com
```

## Server Issues

### Service Won't Start

**Symptoms:** `systemctl start` fails or service exits immediately.

**Check logs:**
```bash
sudo journalctl -u slipstream-server -n 100 --no-pager
```

**Common causes:**

1. **Certificate issues:**
   ```bash
   # Verify certificates exist
   ls -la /etc/slipstream/*.pem
   
   # Check permissions
   sudo chmod 600 /etc/slipstream/key.pem
   sudo chmod 644 /etc/slipstream/cert.pem
   sudo chown slipstream:slipstream /etc/slipstream/*.pem
   ```

2. **Port already in use:**
   ```bash
   # Check what's using port 5300
   sudo ss -tulnp | grep 5300
   
   # Kill conflicting process if needed
   sudo kill $(sudo lsof -t -i:5300)
   ```

3. **Binary not found:**
   ```bash
   # Verify binary exists
   ls -la /usr/local/bin/slipstream-server
   
   # Rebuild if needed
   cargo build --release -p slipstream-server
   sudo cp target/release/slipstream-server /usr/local/bin/
   ```

### DNS Not Responding

**Symptoms:** `dig` commands timeout or get no response.

**Check:**

1. **iptables rules:**
   ```bash
   sudo iptables -t nat -L PREROUTING -n -v
   # Should show redirect from 53 to 5300
   
   # Re-add if missing
   IFACE=$(ip route | grep default | awk '{print $5}')
   sudo iptables -t nat -I PREROUTING -i $IFACE -p udp --dport 53 -j REDIRECT --to-ports 5300
   ```

2. **Firewall:**
   ```bash
   # UFW
   sudo ufw status
   sudo ufw allow 53/udp
   
   # firewalld
   sudo firewall-cmd --list-all
   sudo firewall-cmd --add-port=53/udp --permanent
   sudo firewall-cmd --reload
   ```

3. **Service listening:**
   ```bash
   sudo ss -ulnp | grep 5300
   # Should show slipstream-server
   ```

### Build Failures

**Missing dependencies:**
```bash
# Ubuntu/Debian
sudo apt install cmake pkg-config libssl-dev build-essential

# CentOS/Rocky
sudo dnf install cmake pkg-config openssl-devel gcc gcc-c++ make

# Verify
cmake --version
pkg-config --version
pkg-config --exists openssl && echo "OpenSSL found"
```

**Submodule issues:**
```bash
git submodule update --init --recursive
# If still failing:
git submodule deinit -f .
git submodule update --init --recursive
```

## Client Issues

### Connection Refused

**Symptoms:** Client can't connect to server.

**Check:**

1. **Server is running:**
   ```bash
   # On server
   sudo systemctl status slipstream-server
   ```

2. **DNS resolves correctly:**
   ```bash
   # Test from client
   dig @YOUR_SERVER_IP s.example.com
   ```

3. **Network connectivity:**
   ```bash
   # Test UDP port 53
   nc -zuv YOUR_SERVER_IP 53
   ```

### Certificate Errors

**Symptoms:** TLS handshake failures in logs.

**Solutions:**

1. **Regenerate certificates:**
   ```bash
   sudo openssl req -x509 -newkey rsa:2048 -nodes \
       -keyout /etc/slipstream/key.pem \
       -out /etc/slipstream/cert.pem \
       -days 365 -subj "/CN=slipstream"
   sudo systemctl restart slipstream-server
   ```

2. **Update client certificate:**
   ```bash
   # Copy new cert from server
   scp user@server:/etc/slipstream/cert.pem ./server-cert.pem
   ```

### Slow Performance

**Check:**

1. **Network latency:**
   ```bash
   ping YOUR_SERVER_IP
   mtr YOUR_SERVER_IP
   ```

2. **Server resources:**
   ```bash
   top -p $(pgrep slipstream)
   free -h
   ```

3. **Try different congestion control:**
   ```bash
   slipstream-client --congestion-control bbr ...
   # or
   slipstream-client --congestion-control dcubic ...
   ```

### Windows Build Issues

**OpenSSL not found:**
```powershell
# Install via vcpkg
vcpkg install openssl:x64-windows-static
$env:OPENSSL_DIR = "C:\vcpkg\installed\x64-windows-static"
$env:OPENSSL_STATIC = "1"
```

**Visual Studio tools missing:**
- Download Build Tools from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
- Select "Desktop development with C++"

## SOCKS Proxy Issues (Server)

### Dante Not Starting

```bash
# Check config
sudo danted -f /etc/danted.conf -d

# Common fixes:
# 1. Verify external interface name
ip link show
# Update 'external:' in /etc/danted.conf

# 2. Check permissions
sudo chmod 644 /etc/danted.conf
```

### Connections Through SOCKS Fail

```bash
# Test locally
curl --socks5 127.0.0.1:1080 http://httpbin.org/ip

# Check Dante logs
sudo journalctl -u danted -f
```

## DNS Propagation Issues

**Symptoms:** DNS works from some locations but not others.

**Check propagation:**
- Use: https://www.whatsmydns.net
- Query: NS record for `s.example.com`

**Wait time:** Can take up to 24-48 hours for full propagation.

## Getting Help

1. **Enable debug logging:**
   ```bash
   # Server
   RUST_LOG=debug slipstream-server ...
   
   # Client
   RUST_LOG=debug slipstream-client ...
   ```

2. **Collect information:**
   - OS version
   - Slipstream version
   - Relevant log output
   - Network configuration

3. **Open an issue:** https://github.com/mohamadsolouki/slipstream-rust/issues
