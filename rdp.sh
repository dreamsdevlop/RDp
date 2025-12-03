#!/bin/bash
# ============================================
# 🚀 Auto Installer: Windows 11 on Docker + Cloudflare Tunnel
# ============================================

set -e

echo "=== 🔧 Menjalankan sebagai root ==="
if [ "$EUID" -ne 0 ]; then
  echo "Script ini butuh akses root. Jalankan dengan: sudo bash install-windows11-cloudflare.sh"
  exit 1
fi

echo
echo "=== 📦 Docker pre-installed on GitHub runner ==="

# No need to install - already available

echo
echo "=== 📂 Membuat direktori kerja dockercom ==="
mkdir -p /root/dockercom
cd /root/dockercom

echo
echo "=== 🧾 Membuat file windows.yml ==="
# Cek KVM
if [ -e /dev/kvm ]; then
  echo "✅ KVM detected (Performance optimized)"
  KVM_CONFIG="- /dev/kvm"
else
  echo "⚠️  KVM NOT detected! Windows will be very slow."
  KVM_CONFIG=""
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
      RAM_SIZE: "2G"
      CPU_CORES: "1"
    shm_size: 1g
    privileged: true
    ports:
      - "0.0.0.0:8006:8006"
      - "0.0.0.0:3389:3389/tcp"
      - "0.0.0.0:3389:3389/udp"
    volumes:
      - /tmp/windows-storage:/storage
    restart: always
    stop_grace_period: 2m

EOF

echo
echo "=== ✅ File windows.yml berhasil dibuat ==="
cat windows.yml

echo
echo "=== 🚀 Menjalankan Windows 11 container ==="
docker compose -f windows.yml up -d

echo "⏳ Waiting for Windows ports 8006(NoVNC)/3389(RDP) ready..."

for i in {1..60}; do
  if (echo > /dev/tcp/localhost/8006) >/dev/null 2>&1 && (echo > /dev/tcp/localhost/3389) >/dev/null 2>&1; then
    echo "✅ Ports ready after ${i}x30s!"
    break
  fi
  echo "Still booting... ($i/60)"
  sleep 30
done || echo "⚠️ Ports not ready after 30min - check docker logs windows"

echo "=== 🔧 RDP NLA/Firewall disable + enable ==="
docker exec windows powershell -Command "
netsh advfirewall set allprofiles state off;
Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -name 'fDenyTSConnections' -Value 0;
Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp' -name 'UserAuthentication' -Value 0;
Restart-Service TermService -Force
"

sleep 60

echo "Waiting RDP listener..."
for attempt in {1..10}; do
  if docker exec windows powershell \"netstat -an | findstr :3389\" 2>/dev/null | grep -q LISTENING; then
    echo "✅ RDP listening!"
    break
  fi
  sleep 30
done

echo
echo "=== ☁️ Instalasi Cloudflare Tunnel ==="
if [ ! -f "/usr/local/bin/cloudflared" ]; then
  wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared
  chmod +x /usr/local/bin/cloudflared
fi

echo
echo "=== 🌍 Membuat tunnel publik untuk akses web & RDP ==="
nohup cloudflared tunnel --url http://localhost:8006 > /var/log/cloudflared_web.log 2>&1 &
nohup cloudflared tunnel --url tcp://localhost:3389 > /var/log/cloudflared_rdp.log 2>&1 &
sleep 6

CF_WEB=$(grep -o "https://[a-zA-Z0-9.-]*\.trycloudflare\.com" /var/log/cloudflared_web.log | head -n 1)
CF_RDP=$(grep -o "tcp://[a-zA-Z0-9.-]*\.trycloudflare\.com:[0-9]*" /var/log/cloudflared_rdp.log | head -n 1)

echo
echo "=============================================="
echo "🎉 Instalasi Selesai!"
echo
if [ -n "$CF_WEB" ]; then
  echo "🌍 Web Console (NoVNC / UI):"
  echo "    ${CF_WEB}"
else
  echo "⚠️ Tidak menemukan link web Cloudflare (port 8006)"
  echo "    Cek log: tail -f /var/log/cloudflared_web.log"
fi

if [ -n "$CF_RDP" ]; then
  echo
  echo "🖥️  Remote Desktop (RDP) melalui Cloudflare:"
  echo "    ${CF_RDP}"
else
  echo "⚠️ Tidak menemukan link RDP Cloudflare (port 3389)"
  echo "    Cek log: tail -f /var/log/cloudflared_rdp.log"
fi

echo
echo "🔑 Username: MASTER"
echo "🔒 Password: admin@123"
echo
echo "Untuk melihat status container:"
echo "  docker ps"
echo
echo "Untuk menghentikan VM:"
echo "  docker stop windows"
echo
echo "Untuk melihat log Windows:"
echo "  docker logs -f windows"
echo
echo "Untuk melihat link Cloudflare:"
echo "  grep 'trycloudflare' /var/log/cloudflared_*.log"
echo
echo "=== ✅ Windows 11 di Docker siap digunakan! ==="
echo "=============================================="

# Keep Alive Loop (Essential for 24/7 in some environments)
echo "🔄 Entering Keep-Alive mode..."
echo "    Press Ctrl+C to stop."
while true; do
  sleep 60
  # Optional: Check if processes are still running and restart if needed
  if ! pgrep -x "cloudflared" > /dev/null; then
      echo "⚠️ Cloudflared stopped! Restarting..."
      nohup cloudflared tunnel --url http://localhost:8006 > /var/log/cloudflared_web.log 2>&1 &
      nohup cloudflared tunnel --url tcp://localhost:3389 > /var/log/cloudflared_rdp.log 2>&1 &
  fi
done

