# Windows 11 on Docker + Cloudflare Tunnel (PowerShell Version)

Write-Host "=== 🔧 Checking Docker Environment ==="
if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH. Please install Docker Desktop for Windows."
    exit 1
}

Write-Host "=== 📂 Creating working directory ==="
$WorkDir = "C:\dockercom"
if (-not (Test-Path $WorkDir)) {
    New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
}
Set-Location $WorkDir

Write-Host "=== 🧾 Creating windows.yml ==="
$ComposeContent = @"
version: "3.9"
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "11"
      USERNAME: "MASTER"
      PASSWORD: "admin@123"
      RAM_SIZE: "7G"
      CPU_CORES: "4"
    devices:
      - /dev/kvm
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    volumes:
      - ./storage:/storage
    restart: always
    stop_grace_period: 2m
"@
Set-Content -Path "windows.yml" -Value $ComposeContent

Write-Host "=== 🚀 Starting Windows 11 container ==="
docker-compose -f windows.yml up -d

Write-Host "=== ☁️  Setting up Cloudflare Tunnel ==="
$CloudflaredUrl = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
$CloudflaredExe = "$WorkDir\cloudflared.exe"

if (-not (Test-Path $CloudflaredExe)) {
    Write-Host "Downloading cloudflared..."
    Invoke-WebRequest -Uri $CloudflaredUrl -OutFile $CloudflaredExe
}

Write-Host "=== 🌍 Creating public tunnels ==="
# Kill existing cloudflared processes to avoid conflicts
Stop-Process -Name "cloudflared" -ErrorAction SilentlyContinue

# Start Tunnels
Start-Process -FilePath $CloudflaredExe -ArgumentList "tunnel --url http://localhost:8006" -RedirectStandardOutput "$WorkDir\cloudflared_web.log" -RedirectStandardError "$WorkDir\cloudflared_web.log" -WindowStyle Hidden
Start-Process -FilePath $CloudflaredExe -ArgumentList "tunnel --url tcp://localhost:3389" -RedirectStandardOutput "$WorkDir\cloudflared_rdp.log" -RedirectStandardError "$WorkDir\cloudflared_rdp.log" -WindowStyle Hidden

Write-Host "=== ⏳ Waiting for Cloudflare Tunnels (Max 30s) ==="
$attempt = 0
while ($attempt -lt 15) {
    Start-Sleep -Seconds 2
    
    $WebLog = Get-Content "$WorkDir\cloudflared_web.log" -ErrorAction SilentlyContinue
    $RdpLog = Get-Content "$WorkDir\cloudflared_rdp.log" -ErrorAction SilentlyContinue
    
    $CF_WEB = $WebLog | Select-String -Pattern "https://[-a-zA-Z0-9]*\.trycloudflare\.com" | Select-Object -First 1
    $CF_RDP = $RdpLog | Select-String -Pattern "tcp://[-a-zA-Z0-9]*\.trycloudflare\.com:[0-9]*" | Select-Object -First 1

    if ($CF_WEB -and $CF_RDP) {
        break
    }
    Write-Host -NoNewline "."
    $attempt++
}
Write-Host ""

Write-Host "=============================================="
Write-Host "🎉 Installation Complete!"
Write-Host ""
Write-Host "🌍 Local Access:"
Write-Host "    Web: http://localhost:8006"
Write-Host "    RDP: localhost:3389"
Write-Host ""

if ($CF_WEB) {
    Write-Host "🌍 Public Web Console (NoVNC / UI):"
    Write-Host "    $($CF_WEB.Matches.Value)"
} else {
    Write-Host "⚠️  Could not find Web Cloudflare link. Check logs at $WorkDir\cloudflared_web.log"
}

if ($CF_RDP) {
    Write-Host ""
    Write-Host "🖥️  Public Remote Desktop (RDP):"
    Write-Host "    $($CF_RDP.Matches.Value)"
} else {
    Write-Host "⚠️  Could not find RDP Cloudflare link. Check logs at $WorkDir\cloudflared_rdp.log"
}

Write-Host ""
Write-Host "🔑 Username: MASTER"
Write-Host "🔒 Password: admin@123"
Write-Host "=============================================="
