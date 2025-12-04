#!/bin/bash
# ============================================
# 🚀 Auto Installer: Windows 11 on Docker + Cloudflare Tunnel
# Works on: GitHub Actions, Google Cloud Platform (GCP), VPS
# ============================================

set -e

echo "=== 🔧 Checking Root Access ==="
if [ "$EUID" -ne 0 ]; then
  echo "❌ This script requires root access. Please run with sudo."
  echo "   Usage: sudo bash rdp.sh"
  exit 1
fi

echo
echo "=== 📦 Checking Docker Installation ==="
if ! command -v docker &> /dev/null; then
    echo "⚠️ Docker not found. Installing Docker..."
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker installed successfully."
else
    echo "✅ Docker is already installed."
fi

# Ensure docker compose command works (v2)
if ! command -v docker-compose &> /dev/null; then
    # Try to alias docker compose if plugin is installed
    if docker compose version &> /dev/null; then
        echo "✅ Docker Compose (v2) detected."
    else
        echo "⚠️ Installing Docker Compose..."
        apt-get install -y docker-compose-plugin
    fi
fi

echo
echo "=== 📂 Setting up Workspace ==="
mkdir -p /root/dockercom
cd /root/dockercom

echo
echo "=== 🔋 Disabling Windows Sleep/Hibernate ==="
mkdir -p oem
cat > oem/install.bat <<EOF
powercfg /change monitor-timeout-ac 0
powercfg /change standby-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /h off
EOF

echo
echo "=== ⚙️  Calculating Resources ==="
# Get total RAM in GB (rounded down)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(($TOTAL_RAM_KB / 1024 / 1024))
# Reserve 1GB for Host/Docker overhead
VM_RAM_GB=$(($TOTAL_RAM_GB - 1))
if [ "$VM_RAM_GB" -lt 2 ]; then
    VM_RAM_GB=2 # Minimum 2GB
fi

# Get total Cores
TOTAL_CORES=$(nproc)
# Reserve 1 Core for Host if we have many, otherwise use all for performance (Docker shares CPU well)
if [ "$TOTAL_CORES" -gt 2 ]; then
    VM_CORES=$(($TOTAL_CORES - 1))
else
    VM_CORES=$TOTAL_CORES
fi

echo "   Host RAM: ${TOTAL_RAM_GB} GB | VM RAM: ${VM_RAM_GB} GB"
echo "   Host CPU: ${TOTAL_CORES} Cores | VM CPU: ${VM_CORES} Cores"

echo
echo "=== 🧾 Generating windows.yml ==="
# Check KVM
if [ -e /dev/kvm ]; then
  echo "✅ KVM detected (Performance optimized)"
  KVM_DEVICES="
    devices:
      - /dev/kvm
      - /dev/net/tun"
else
  echo "⚠️  KVM NOT detected! Windows will be very slow."
  KVM_DEVICES=""
fi

cat > windows.yml <<EOF
version: "3.9"
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "11"
      USERNAME: "MASTER"
      PASSWORD: "admin@123"
      RAM_SIZE: "${VM_RAM_GB}G"
      CPU_CORES: "${VM_CORES}"
      ARGUMENTS: "-cpu host"
    privileged: true
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    volumes:
      - /tmp/windows-storage:/storage
      - /root/dockercom/oem:/oem
    mem_limit: ${VM_RAM_GB}G
    memswap_limit: $((${VM_RAM_GB} * 2))G
    shm_size: 2G
    restart: unless-stopped
    stop_grace_period: 2m
    ${KVM_DEVICES}

EOF

echo
echo "=== ✅ windows.yml Created ==="
cat windows.yml

echo
echo "=== 🚀 Starting Windows 11 Container ==="
docker compose -f windows.yml up -d

echo "⏳ Waiting for Windows ports 8006(NoVNC)/3389(RDP) ready..."
echo "   This may take 5-10 minutes on the first boot."

for i in {1..60}; do
  # Check if NoVNC is actually responding (not just port open)
  if curl -s -o /dev/null -w "%{http_code}" http://localhost:8006 | grep -q "200\|301\|302" && \
     (echo > /dev/tcp/localhost/3389) >/dev/null 2>&1; then
    echo "✅ Services ready after ${i}x30s!"
    break
  fi
  echo "Still booting... ($i/60)"
  sleep 30
done || echo "⚠️ Services not ready after 30min - check docker logs windows"

# Additional wait for Windows to fully stabilize
echo "⏳ Waiting for Windows to fully stabilize..."
sleep 30

echo
echo "=== 🔐 Installing Tailscale ==="
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
else
    echo "✅ Tailscale is already installed."
fi

echo
echo "=== 🔗 Connecting to Tailscale ==="
# Check if already logged in
if tailscale status > /dev/null 2>&1; then
    echo "✅ Already connected to Tailscale."
else
    if [ -n "$TAILSCALE_AUTH_KEY" ]; then
        echo "🔑 Authenticating with provided key..."
        tailscale up --authkey="$TAILSCALE_AUTH_KEY" --ssh
    else
        echo "⚠️  TAILSCALE_AUTH_KEY not found."
        echo "   To connect manually, run: sudo tailscale up"
    fi
fi

TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")

echo
echo "=== ☁️ Installing Cloudflare Tunnel ==="
if [ ! -f "/usr/local/bin/cloudflared" ]; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
fi

echo
echo "=== 🌍 Creating Public Tunnels ==="
# Kill old tunnels if any
pkill -f cloudflared || true

nohup cloudflared tunnel --url http://localhost:8006 > /var/log/cloudflared_web.log 2>&1 &
nohup cloudflared tunnel --url tcp://localhost:3389 > /var/log/cloudflared_rdp.log 2>&1 &

echo "⏳ Waiting for Cloudflare tunnels to initialize..."
CF_WEB=""
CF_RDP=""
for i in {1..30}; do
  CF_WEB=$(grep -o "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" /var/log/cloudflared_web.log 2>/dev/null | head -n 1)
  CF_RDP=$(grep -o "tcp://[a-zA-Z0-9.-]*\.trycloudflare\.com:[0-9]*" /var/log/cloudflared_rdp.log 2>/dev/null | head -n 1)
  
  if [ -n "$CF_WEB" ] && [ -n "$CF_RDP" ]; then
    echo "✅ Cloudflare tunnels ready after ${i}s!"
    break
  fi
  sleep 1
done

echo
echo "=============================================="
echo "🎉 Installation Complete!"
echo
if [ -n "$CF_WEB" ]; then
  echo "🌍 Web Console (NoVNC / UI):"
  echo "    ${CF_WEB}"
else
  echo "⚠️ Web Link not found (Check logs)"
fi

if [ -n "$CF_RDP" ]; then
  echo
  echo "🖥️  Remote Desktop (RDP) via Cloudflare:"
  echo "    ${CF_RDP}"
else
  echo "⚠️ RDP Link not found (Check logs)"
fi

if [ -n "$TAILSCALE_IP" ]; then
  echo
  echo "🔐 Tailscale IP (Internal RDP):"
  echo "    ${TAILSCALE_IP}:3389"
else
  echo
  echo "⚠️ Tailscale not connected (or no IP found)"
fi

echo
echo "🔑 Username: MASTER"
echo "🔒 Password: admin@123"
echo
echo "To view logs: docker logs -f windows"
echo "To stop: docker stop windows"
echo
echo "=== ✅ Windows 11 is Ready! ==="
echo "=============================================="

# Keep Alive Loop (Essential for 24/7 in some environments)
echo "🔄 Entering Keep-Alive mode..."
while true; do
  sleep 60
  if ! pgrep -x "cloudflared" > /dev/null; then
      echo "⚠️ Cloudflared stopped! Restarting..."
      nohup cloudflared tunnel --url http://localhost:8006 > /var/log/cloudflared_web.log 2>&1 &
      nohup cloudflared tunnel --url tcp://localhost:3389 > /var/log/cloudflared_rdp.log 2>&1 &
  fi
  
  if ! pgrep -x "tailscaled" > /dev/null; then
      echo "⚠️ Tailscale stopped! Restarting..."
      sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &
      sleep 2
      if [ -n "$TAILSCALE_AUTH_KEY" ]; then
         tailscale up --authkey="$TAILSCALE_AUTH_KEY" --ssh
      fi
  fi
done


