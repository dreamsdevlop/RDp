const express = require('express');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const AlertSystem = require('./alerts');

const app = express();
const server = require('http').createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3000;
const METRICS_FILE = '/tmp/backup_metrics.json';
const LOG_FILE = '/var/log/backup_enhanced.log';
const HISTORY_FILE = '/tmp/metrics_history.json';

// Initialize alert system
const alertSystem = new AlertSystem();

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

// Dashboard route
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API endpoints
app.get('/api/metrics', (req, res) => {
    try {
        const metrics = JSON.parse(fs.readFileSync(METRICS_FILE, 'utf8'));
        res.json(metrics);
    } catch (error) {
        res.json({
            status: 'unknown',
            last_sync: 'Never',
            storage_used_gb: 0,
            timestamp: new Date().toISOString()
        });
    }
});

app.get('/api/health', (req, res) => {
    const health = {
        docker: checkDocker(),
        cloudflare: checkCloudflare(),
        tailscale: checkTailscale(),
        storage: checkStorage(),
        timestamp: new Date().toISOString()
    };
    res.json(health);
});

app.get('/api/logs', (req, res) => {
    try {
        const logs = fs.readFileSync(LOG_FILE, 'utf8')
            .split('\n')
            .filter(line => line.trim())
            .slice(-100) // Last 100 lines
            .reverse();
        res.json(logs);
    } catch (error) {
        res.json(['No logs available']);
    }
});

// Alert API endpoints
app.get('/api/alerts', (req, res) => {
    res.json({
        active: alertSystem.getActiveAlerts(),
        history: alertSystem.getAlertHistory(20)
    });
});

app.post('/api/alerts/acknowledge/:id', (req, res) => {
    const alertId = req.params.id;
    const acknowledged = alertSystem.acknowledgeAlert(alertId);
    res.json({ success: acknowledged });
});

app.get('/api/history', (req, res) => {
    try {
        const history = JSON.parse(fs.readFileSync(HISTORY_FILE, 'utf8'));
        res.json(history.slice(-100)); // Last 100 data points
    } catch (error) {
        res.json([]);
    }
});

// WebSocket for real-time updates
wss.on('connection', (ws) => {
    console.log('Client connected to dashboard');

    // Send initial data
    ws.send(JSON.stringify({
        type: 'initial',
        data: {
            metrics: getMetrics(),
            health: getHealth()
        }
    }));

    // Send updates every 30 seconds
    const interval = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
            const metrics = getMetrics();
            const health = getHealth();

            // Check for alerts
            const newAlerts = alertSystem.checkAlerts(health, metrics);

            // Log to history
            logToHistory(metrics, health);

            ws.send(JSON.stringify({
                type: 'update',
                data: {
                    metrics: metrics,
                    health: health,
                    alerts: newAlerts
                }
            }));
        } else {
            clearInterval(interval);
        }
    }, 30000);

    ws.on('close', () => {
        console.log('Client disconnected from dashboard');
    });
});

// Historical logging function
function logToHistory(metrics, health) {
    try {
        let history = [];
        if (fs.existsSync(HISTORY_FILE)) {
            history = JSON.parse(fs.readFileSync(HISTORY_FILE, 'utf8'));
        }

        const entry = {
            timestamp: new Date().toISOString(),
            metrics: metrics,
            health: health
        };

        history.push(entry);

        // Keep only last 1000 entries
        if (history.length > 1000) {
            history = history.slice(-1000);
        }

        fs.writeFileSync(HISTORY_FILE, JSON.stringify(history, null, 2));
    } catch (error) {
        console.error('Failed to write history:', error.message);
    }
}

// Helper functions
function getMetrics() {
    try {
        return JSON.parse(fs.readFileSync(METRICS_FILE, 'utf8'));
    } catch (error) {
        return {
            status: 'unknown',
            last_sync: 'Never',
            storage_used_gb: 0,
            timestamp: new Date().toISOString()
        };
    }
}

function getHealth() {
    return {
        docker: checkDocker(),
        cloudflare: checkCloudflare(),
        tailscale: checkTailscale(),
        storage: checkStorage(),
        timestamp: new Date().toISOString()
    };
}

function checkDocker() {
    return new Promise((resolve) => {
        const child = spawn('docker', ['ps', '--format', '{{.Names}}']);
        let output = '';

        child.stdout.on('data', (data) => {
            output += data.toString();
        });

        child.on('close', (code) => {
            resolve({
                status: code === 0 ? 'running' : 'stopped',
                containers: output.trim().split('\n').filter(Boolean),
                timestamp: new Date().toISOString()
            });
        });

        child.on('error', () => {
            resolve({
                status: 'error',
                containers: [],
                timestamp: new Date().toISOString()
            });
        });
    });
}

function checkCloudflare() {
    return new Promise((resolve) => {
        // Check if cloudflared processes are running
        const child = spawn('pgrep', ['-f', 'cloudflared']);
        let output = '';

        child.stdout.on('data', (data) => {
            output += data.toString();
        });

        child.on('close', (code) => {
            resolve({
                status: code === 0 ? 'running' : 'stopped',
                tunnels: output.trim().split('\n').filter(Boolean).length,
                timestamp: new Date().toISOString()
            });
        });

        child.on('error', () => {
            resolve({
                status: 'error',
                tunnels: 0,
                timestamp: new Date().toISOString()
            });
        });
    });
}

function checkTailscale() {
    return new Promise((resolve) => {
        const child = spawn('tailscale', ['status', '--json']);
        let output = '';

        child.stdout.on('data', (data) => {
            output += data.toString();
        });

        child.on('close', (code) => {
            if (code === 0) {
                try {
                    const status = JSON.parse(output);
                    resolve({
                        status: status.BackendState === 'Running' ? 'running' : 'stopped',
                        ip: status.Self?.TailscaleIPs?.[0] || 'unknown',
                        timestamp: new Date().toISOString()
                    });
                } catch (e) {
                    resolve({
                        status: 'error',
                        ip: 'unknown',
                        timestamp: new Date().toISOString()
                    });
                }
            } else {
                resolve({
                    status: 'stopped',
                    ip: 'unknown',
                    timestamp: new Date().toISOString()
                });
            }
        });

        child.on('error', () => {
            resolve({
                status: 'error',
                ip: 'unknown',
                timestamp: new Date().toISOString()
            });
        });
    });
}

function checkStorage() {
    return new Promise((resolve) => {
        const child = spawn('du', ['-sh', '/tmp/windows-storage/data']);
        let output = '';

        child.stdout.on('data', (data) => {
            output += data.toString();
        });

        child.on('close', (code) => {
            if (code === 0) {
                const match = output.match(/(\d+(\.\d+)?)\s*([KMGT]?)/);
                resolve({
                    status: 'ok',
                    usage: output.trim(),
                    timestamp: new Date().toISOString()
                });
            } else {
                resolve({
                    status: 'error',
                    usage: 'unknown',
                    timestamp: new Date().toISOString()
                });
            }
        });

        child.on('error', () => {
            resolve({
                status: 'error',
                usage: 'unknown',
                timestamp: new Date().toISOString()
            });
        });
    });
}

// Start server
server.listen(PORT, () => {
    console.log(`Dashboard server running on http://localhost:${PORT}`);
    console.log(`WebSocket server running on ws://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('Shutting down dashboard server...');
    server.close(() => {
        process.exit(0);
    });
});
