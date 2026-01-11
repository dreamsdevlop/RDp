# 🚀 VibeVoice Gradio UI - Deployment Guide

This guide provides detailed instructions for deploying and managing the VibeVoice Gradio UI workflow.

## 📋 Prerequisites

### GitHub Repository Setup
1. **Fork or Clone**: Start with this repository or create your own
2. **Enable Actions**: Ensure GitHub Actions are enabled in repository settings
3. **Permissions**: Verify you have admin access to the repository

### Optional: Self-Hosted Runners
For production use or longer uptime:

1. **Setup Runner**: Follow [GitHub's self-hosted runner guide](https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners)
2. **Hardware Requirements**:
   - CPU: 4+ cores recommended
   - RAM: 16GB+ recommended
   - Storage: 50GB+ SSD
   - GPU: Optional but recommended for better performance
3. **Network**: Ensure stable internet connection

## 🚀 Deployment Methods

### Method 1: GitHub Actions (Recommended for Testing)

#### Manual Trigger
1. Navigate to your repository on GitHub
2. Go to the **Actions** tab
3. Find **"VibeVoice Gradio UI"** workflow
4. Click **"Run workflow"**
5. Configure parameters:
   - **Model Path**: `microsoft/VibeVoice-1.5B`
   - **Inference Steps**: `10`
   - **Enable GPU**: `true`
   - **Share URL**: `true`
6. Click **"Run workflow"**

#### Scheduled Deployment
The workflow includes a daily health check at 2 AM UTC. To modify:

```yaml
schedule:
  - cron: '0 2 * * *'  # Change this cron expression
```

#### API Trigger
Use the GitHub API to trigger deployment:

```bash
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"vibevoice-deploy"}'
```

### Method 2: Self-Hosted Deployment

#### 1. Setup Self-Hosted Runner
```bash
# On your server
mkdir actions-runner && cd actions-runner
curl -o actions-runner-osx-x64-2.302.5.tar.gz -L https://github.com/actions/runner/releases/download/v2.302.5/actions-runner-osx-x64-2.302.5.tar.gz
tar xzf ./actions-runner-osx-x64-2.302.5.tar.gz

# Configure
./config.sh --url https://github.com/OWNER/REPO --token TOKEN

# Run as service
sudo ./svc.sh install
sudo ./svc.sh start
```

#### 2. Modify Workflow for Self-Hosted
Update `.github/workflows/vibevoice-gradio.yml`:

```yaml
jobs:
  setup-and-deploy:
    runs-on: self-hosted  # Change from ubuntu-latest
    # ... rest of configuration
```

#### 3. Deploy
Trigger the workflow as usual, but it will run on your self-hosted runner.

### Method 3: Docker Deployment

#### 1. Build Docker Image
```dockerfile
# Dockerfile
FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Expose port
EXPOSE 7860

# Run application
CMD ["python", "app/app.py"]
```

#### 2. Build and Run
```bash
# Build image
docker build -t vibevoice-gradio .

# Run container
docker run -p 7860:7860 vibevoice-gradio
```

## ⚙️ Configuration Options

### Workflow Configuration

#### Environment Variables
```yaml
env:
  MODEL_PATH: "microsoft/VibeVoice-1.5B"
  INFERENCE_STEPS: "10"
  ENABLE_GPU: "true"
  SHARE_URL: "true"
```

#### Resource Limits
```yaml
jobs:
  setup-and-deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 120  # Adjust as needed
```

### Application Configuration

#### Model Configuration
Edit `app/config.json`:

```json
{
  "model_path": "microsoft/VibeVoice-1.5B",
  "inference_steps": 10,
  "server_config": {
    "host": "0.0.0.0",
    "port": 7860,
    "debug": false,
    "share": true
  }
}
```

#### Custom Models
To use a custom model:

1. **Upload Model**: Upload your model to Hugging Face Hub
2. **Update Config**: Change `model_path` in config
3. **Test**: Verify model compatibility

## 📊 Monitoring & Maintenance

### Health Monitoring

#### Built-in Health Checks
The workflow includes automatic health monitoring:

```bash
# Check if Gradio server is running
curl http://localhost:7860/

# Check application logs
tail -f /var/log/vibevoice_setup.log
```

#### Custom Monitoring
Add your own monitoring:

```python
# scripts/monitor.py
import requests
import time

def monitor_service():
    while True:
        try:
            response = requests.get("http://localhost:7860/", timeout=10)
            if response.status_code == 200:
                print("✅ Service healthy")
            else:
                print(f"❌ Service unhealthy: {response.status_code}")
        except Exception as e:
            print(f"❌ Service down: {e}")
        time.sleep(60)

if __name__ == "__main__":
    monitor_service()
```

### Performance Optimization

#### Model Caching
```yaml
- name: Cache Model Weights
  uses: actions/cache@v3
  with:
    path: ~/.cache/huggingface
    key: vibevoice-model-${{ hashFiles('**/requirements.txt') }}
```

#### Resource Management
```yaml
# Limit memory usage
- name: Set memory limits
  run: |
    echo "export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512" >> $GITHUB_ENV
```

### Backup & Recovery

#### Configuration Backup
```bash
# Backup configuration
tar -czf backup-$(date +%Y%m%d).tar.gz app/config.json requirements.txt
```

#### Model Backup
```bash
# Backup model cache
cp -r ~/.cache/huggingface ./model-backup/
```

## 🔧 Troubleshooting

### Common Deployment Issues

#### 1. Workflow Permission Errors
**Problem**: Workflow fails with permission errors
**Solution**:
- Check repository permissions
- Verify GitHub Actions are enabled
- Ensure proper access tokens

#### 2. Model Download Failures
**Problem**: Model fails to download from Hugging Face
**Solution**:
- Check network connectivity
- Verify model path is correct
- Clear cache and retry

#### 3. Port Conflicts
**Problem**: Port 7860 is already in use
**Solution**:
- Change port in config: `"port": 7861`
- Check for other running services
- Use different host configuration

#### 4. Memory Issues
**Problem**: Out of memory errors during model loading
**Solution**:
- Use smaller model
- Increase system memory
- Enable swap space
- Use CPU-only mode

### Debugging Steps

#### 1. Check Workflow Logs
```bash
# View workflow logs in GitHub UI
# Look for error messages and stack traces
```

#### 2. Local Testing
```bash
# Test locally before deploying
python scripts/setup_vibevoice.py
python app/app.py
```

#### 3. Container Debugging
```bash
# If using Docker
docker logs container_name
docker exec -it container_name bash
```

## 🚀 Production Deployment

### Security Considerations

#### Authentication
Add authentication to your Gradio app:

```python
# In app/app.py
demo.launch(
    auth=("username", "password"),  # Add authentication
    # ... other parameters
)
```

#### HTTPS
For production, use HTTPS:

```yaml
# Use a reverse proxy like nginx
# Configure SSL certificates
# Set up proper domain mapping
```

#### Rate Limiting
Implement rate limiting:

```python
# Add rate limiting middleware
from flask_limiter import Limiter
limiter = Limiter(app, default_limits=["100 per hour"])
```

### Scaling Strategies

#### Horizontal Scaling
- Deploy multiple instances
- Use load balancer
- Implement session management

#### Vertical Scaling
- Upgrade server resources
- Use GPU instances
- Optimize model size

### CI/CD Integration

#### Automated Testing
```yaml
# Add to workflow
- name: Test Application
  run: |
    python -m pytest tests/
    python scripts/health_check.py
```

#### Automated Deployment
```yaml
# Trigger on push to main
on:
  push:
    branches: [main]
```

## 📈 Performance Monitoring

### Metrics to Track

#### Application Metrics
- Response time
- Error rate
- Concurrent users
- Audio generation time

#### System Metrics
- CPU usage
- Memory usage
- Disk I/O
- Network bandwidth

### Monitoring Tools

#### GitHub Actions
- Built-in workflow monitoring
- Log analysis
- Performance metrics

#### External Tools
- Prometheus + Grafana
- Datadog
- New Relic
- Custom monitoring scripts

## 🔄 Updates & Maintenance

### Regular Updates

#### Model Updates
```bash
# Update model path in config
# Test compatibility
# Deploy with new model
```

#### Dependency Updates
```bash
# Update requirements.txt
# Test compatibility
# Deploy with new dependencies
```

#### Security Updates
- Regularly update base images
- Monitor security advisories
- Apply security patches promptly

### Maintenance Tasks

#### Log Rotation
```bash
# Setup log rotation
sudo logrotate -f /etc/logrotate.conf
```

#### Cache Cleanup
```bash
# Clean model cache periodically
rm -rf ~/.cache/huggingface
```

#### Performance Review
- Monitor resource usage
- Optimize slow operations
- Review user feedback

---

This deployment guide provides comprehensive instructions for deploying and maintaining your VibeVoice Gradio UI. For additional support, refer to the [main README](README.md) or create an issue in the repository.
