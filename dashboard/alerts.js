const fs = require('fs');
const path = require('path');

class AlertSystem {
    constructor() {
        this.alerts = [];
        this.alertHistory = [];
        this.lastAlerts = new Map();
        this.config = this.loadConfig();
    }

    loadConfig() {
        const configPath = path.join(__dirname, 'config.json');
        const defaultConfig = {
            alerts: {
                docker_down: { enabled: true, cooldown: 300 },
                cloudflare_down: { enabled: true, cooldown: 300 },
                tailscale_down: { enabled: true, cooldown: 300 },
                storage_full: { enabled: true, threshold: 90 },
                backup_failed: { enabled: true, cooldown: 600 }
            },
            notifications: {
                email: { enabled: false, smtp: {}, recipients: [] },
                slack: { enabled: false, webhook_url: '' },
                webhook: { enabled: false, url: '' }
            }
        };

        try {
            if (fs.existsSync(configPath)) {
                const userConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
                return this.mergeConfig(defaultConfig, userConfig);
            }
        } catch (error) {
            console.warn('Failed to load config, using defaults:', error.message);
        }

        return defaultConfig;
    }

    mergeConfig(defaultConfig, userConfig) {
        const merged = JSON.parse(JSON.stringify(defaultConfig));

        // Deep merge alerts
        if (userConfig.alerts) {
            Object.keys(userConfig.alerts).forEach(key => {
                if (merged.alerts[key]) {
                    merged.alerts[key] = { ...merged.alerts[key], ...userConfig.alerts[key] };
                }
            });
        }

        // Deep merge notifications
        if (userConfig.notifications) {
            Object.keys(userConfig.notifications).forEach(key => {
                if (merged.notifications[key]) {
                    merged.notifications[key] = { ...merged.notifications[key], ...userConfig.notifications[key] };
                }
            });
        }

        return merged;
    }

    checkAlerts(health, metrics) {
        const now = Date.now();
        const newAlerts = [];

        // Check Docker status
        if (this.config.alerts.docker_down.enabled && health.docker.status !== 'running') {
            const alert = this.createAlert('docker_down', 'Docker container is not running', 'critical');
            if (this.shouldSendAlert('docker_down', now)) {
                newAlerts.push(alert);
                this.lastAlerts.set('docker_down', now);
            }
        }

        // Check Cloudflare status
        if (this.config.alerts.cloudflare_down.enabled && health.cloudflare.status !== 'running') {
            const alert = this.createAlert('cloudflare_down', 'Cloudflare tunnels are not running', 'warning');
            if (this.shouldSendAlert('cloudflare_down', now)) {
                newAlerts.push(alert);
                this.lastAlerts.set('cloudflare_down', now);
            }
        }

        // Check Tailscale status
        if (this.config.alerts.tailscale_down.enabled && health.tailscale.status !== 'running') {
            const alert = this.createAlert('tailscale_down', 'Tailscale VPN is not connected', 'warning');
            if (this.shouldSendAlert('tailscale_down', now)) {
                newAlerts.push(alert);
                this.lastAlerts.set('tailscale_down', now);
            }
        }

        // Check storage usage
        if (this.config.alerts.storage_full.enabled) {
            const storagePercentage = (metrics.storage_used_gb / 10) * 100;
            if (storagePercentage >= this.config.alerts.storage_full.threshold) {
                const alert = this.createAlert('storage_full', `Storage usage is ${storagePercentage.toFixed(1)}%`, 'warning');
                if (this.shouldSendAlert('storage_full', now)) {
                    newAlerts.push(alert);
                    this.lastAlerts.set('storage_full', now);
                }
            }
        }

        // Check backup status
        if (this.config.alerts.backup_failed.enabled && metrics.status === 'cloud_error') {
            const alert = this.createAlert('backup_failed', 'Backup synchronization failed', 'critical');
            if (this.shouldSendAlert('backup_failed', now)) {
                newAlerts.push(alert);
                this.lastAlerts.set('backup_failed', now);
            }
        }

        // Send new alerts
        newAlerts.forEach(alert => {
            this.sendAlert(alert);
        });

        return newAlerts;
    }

    createAlert(type, message, severity) {
        return {
            id: `${type}_${Date.now()}`,
            type,
            message,
            severity,
            timestamp: new Date().toISOString(),
            acknowledged: false
        };
    }

    shouldSendAlert(type, now) {
        const lastAlert = this.lastAlerts.get(type);
        const cooldown = this.config.alerts[type]?.cooldown || 300;

        if (!lastAlert) return true;

        return (now - lastAlert) / 1000 > cooldown;
    }

    async sendAlert(alert) {
        console.log(`🚨 Alert: ${alert.severity.toUpperCase()} - ${alert.message}`);

        // Add to current alerts
        this.alerts.push(alert);
        if (this.alerts.length > 50) {
            this.alerts.shift();
        }

        // Add to history
        this.alertHistory.push({ ...alert, sent_at: new Date().toISOString() });
        if (this.alertHistory.length > 1000) {
            this.alertHistory.shift();
        }

        // Send notifications
        if (this.config.notifications.email.enabled) {
            await this.sendEmailAlert(alert);
        }

        if (this.config.notifications.slack.enabled) {
            await this.sendSlackAlert(alert);
        }

        if (this.config.notifications.webhook.enabled) {
            await this.sendWebhookAlert(alert);
        }
    }

    async sendEmailAlert(alert) {
        // Email implementation would go here
        // Requires nodemailer or similar library
        console.log(`📧 Email alert would be sent: ${alert.message}`);
    }

    async sendSlackAlert(alert) {
        if (!this.config.notifications.slack.webhook_url) return;

        const payload = {
            text: `🚨 RDP Alert: ${alert.severity.toUpperCase()}`,
            attachments: [{
                color: alert.severity === 'critical' ? 'danger' : 'warning',
                fields: [
                    { title: 'Alert Type', value: alert.type, short: true },
                    { title: 'Severity', value: alert.severity, short: true },
                    { title: 'Message', value: alert.message, short: false },
                    { title: 'Time', value: alert.timestamp, short: true }
                ]
            }]
        };

        try {
            const response = await fetch(this.config.notifications.slack.webhook_url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                throw new Error(`Slack API error: ${response.status}`);
            }

            console.log('✅ Slack alert sent successfully');
        } catch (error) {
            console.error('❌ Failed to send Slack alert:', error.message);
        }
    }

    async sendWebhookAlert(alert) {
        if (!this.config.notifications.webhook.url) return;

        const payload = {
            alert,
            timestamp: new Date().toISOString(),
            source: 'rdp-monitoring-dashboard'
        };

        try {
            const response = await fetch(this.config.notifications.webhook.url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                throw new Error(`Webhook error: ${response.status}`);
            }

            console.log('✅ Webhook alert sent successfully');
        } catch (error) {
            console.error('❌ Failed to send webhook alert:', error.message);
        }
    }

    getActiveAlerts() {
        return this.alerts.filter(alert => !alert.acknowledged);
    }

    getAlertHistory(limit = 100) {
        return this.alertHistory.slice(-limit);
    }

    acknowledgeAlert(alertId) {
        const alert = this.alerts.find(a => a.id === alertId);
        if (alert) {
            alert.acknowledged = true;
            return true;
        }
        return false;
    }

    clearAlerts() {
        this.alerts = [];
        this.lastAlerts.clear();
    }

    saveConfig() {
        const configPath = path.join(__dirname, 'config.json');
        fs.writeFileSync(configPath, JSON.stringify(this.config, null, 2));
    }

    updateConfig(newConfig) {
        this.config = this.mergeConfig(this.config, newConfig);
        this.saveConfig();
    }
}

module.exports = AlertSystem;
