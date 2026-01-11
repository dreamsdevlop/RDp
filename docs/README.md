# 🎙️ VibeVoice Gradio UI - GitHub Actions Workflow

A complete GitHub Actions workflow for deploying VibeVoice with Gradio UI, enabling AI voice generation and podcast creation through a web interface.

## 🌟 Features

- 🎵 **AI Voice Generation**: Transform text into natural-sounding speech
- 🎤 **Voice Cloning**: Use reference audio for personalized voice generation
- 🎙️ **Podcast Creation**: Create AI-generated podcast content
- 🌐 **Web Interface**: Gradio-based UI accessible via public URL
- 🤖 **Hugging Face Integration**: Direct model loading from Hugging Face
- 📊 **Health Monitoring**: Real-time service health checks
- ⚠️ **Usage Guidelines**: Built-in ethical guidelines and legal compliance

## 🚀 Quick Start

### 1. Manual Deployment

1. **Go to Actions Tab**: Navigate to your repository's Actions tab
2. **Select VibeVoice Workflow**: Find "VibeVoice Gradio UI" workflow
3. **Run Workflow**: Click "Run workflow" and configure options:
   - **Model Path**: `microsoft/VibeVoice-1.5B` (default)
   - **Inference Steps**: `10` (default)
   - **Enable GPU**: `true` (default)
   - **Share URL**: `true` (default)
4. **Wait for Deployment**: The workflow will take 10-15 minutes to complete
5. **Access UI**: Check workflow logs for the public URL

### 2. API Trigger

You can also trigger the workflow via API:

```bash
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/dispatches \
  -d '{"event_type":"vibevoice-deploy"}'
```

## ⚙️ Configuration

### Workflow Inputs

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model_path` | string | `microsoft/VibeVoice-1.5B` | Hugging Face model repository |
| `inference_steps` | string | `10` | Number of inference steps (5-50) |
| `enable_gpu` | boolean | `true` | Enable GPU acceleration |
| `share_url` | boolean | `true` | Generate public share URL |

### Environment Variables

The workflow automatically sets these environment variables:

- `MODEL_PATH`: Model repository path
- `INFERENCE_STEPS`: Number of inference steps
- `ENABLE_GPU`: GPU acceleration flag
- `SHARE_URL`: Public URL generation flag

## 📋 System Requirements

### GitHub Actions Runner
- **OS**: Ubuntu 20.04+ (GitHub-hosted)
- **Memory**: 7GB RAM minimum
- **Storage**: 14GB disk space
- **Runtime**: 2 hours maximum (GitHub limit)

### Dependencies
- **Python**: 3.10+
- **PyTorch**: CPU/GPU versions
- **Gradio**: Web interface framework
- **Transformers**: Hugging Face library
- **FFmpeg**: Audio processing

## 🎛️ User Interface

### Main Interface
- **Text Input**: Enter text to convert to speech
- **Voice Upload**: Optional reference audio for voice cloning
- **Generation Controls**: Adjust inference steps and other parameters
- **Status Display**: Real-time generation status

### Features
- **Examples**: Pre-loaded example texts
- **Audio Output**: Generated speech playback
- **Download**: Save generated audio files
- **Model Info**: Current model and configuration details

### Usage Guidelines
The interface includes comprehensive usage guidelines:
- Legal compliance requirements
- Ethical usage guidelines
- Copyright and permission requirements
- Platform terms of service

## 🔧 Advanced Configuration

### Custom Model Deployment

To use a different model:

1. **Modify Workflow Input**: Set `model_path` to your desired model
2. **Check Compatibility**: Ensure model is compatible with VibeVoice
3. **Monitor Resources**: Larger models may require more memory

### Self-Hosted Deployment

For longer uptime and better performance:

1. **Setup Self-Hosted Runner**: Follow [GitHub documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
2. **Configure Resources**: Ensure adequate CPU, GPU, and memory
3. **Update Workflow**: Modify workflow to use self-hosted runners

### Custom Configuration

Create a custom `app/config.json`:

```json
{
  "model_path": "your/model/path",
  "inference_steps": 15,
  "server_config": {
    "host": "0.0.0.0",
    "port": 7860,
    "debug": false,
    "share": true
  }
}
```

## 📊 Monitoring & Maintenance

### Health Checks
The workflow includes automatic health monitoring:
- **Service Status**: Checks if Gradio server is running
- **Response Time**: Monitors API response times
- **Error Detection**: Identifies and reports errors

### Logs & Debugging
- **Workflow Logs**: Check GitHub Actions logs for deployment issues
- **Application Logs**: View real-time application logs
- **Error Reports**: Automatic error reporting and diagnostics

### Performance Optimization
- **Model Caching**: Automatic model caching for faster startup
- **Resource Management**: Efficient memory and CPU usage
- **Cleanup**: Automatic cleanup of temporary files

## ⚠️ Important Considerations

### GitHub Actions Limitations
- **Runtime Limit**: 2 hours maximum per workflow
- **Resource Limits**: Limited CPU and memory on GitHub runners
- **Network Restrictions**: Some network operations may be restricted

### Legal & Ethical Usage
- **Compliance**: Always follow applicable laws and regulations
- **Permissions**: Obtain necessary permissions for voice usage
- **Disclosure**: Clearly disclose AI-generated content
- **Copyright**: Respect intellectual property rights

### Security
- **Access Control**: Consider implementing authentication
- **Rate Limiting**: Prevent abuse and excessive usage
- **Data Privacy**: Handle user data according to privacy laws

## 🐛 Troubleshooting

### Common Issues

#### Workflow Fails to Start
- **Check Repository**: Ensure repository is accessible
- **Permissions**: Verify GitHub Actions permissions
- **Resources**: Check if GitHub runner has sufficient resources

#### Model Loading Fails
- **Model Path**: Verify model path is correct
- **Network**: Check network connectivity to Hugging Face
- **Cache**: Clear model cache if corrupted

#### Gradio UI Not Accessible
- **URL**: Check workflow logs for correct URL
- **Firewall**: Ensure no firewall blocking access
- **Timeout**: Check if workflow timed out

#### Audio Generation Issues
- **Dependencies**: Verify all audio processing dependencies
- **Permissions**: Check file system permissions
- **Memory**: Monitor memory usage during generation

### Getting Help

1. **Check Logs**: Review workflow and application logs
2. **Documentation**: Refer to this README and related docs
3. **Issues**: Create GitHub issue with detailed information
4. **Community**: Check VibeVoice and Gradio communities

## 📈 Performance Tips

### Optimization Strategies
- **Model Selection**: Choose appropriate model size for your needs
- **Inference Steps**: Balance quality vs. speed with inference steps
- **Caching**: Leverage model and audio caching
- **Resource Allocation**: Use self-hosted runners for better performance

### Monitoring Performance
- **Response Times**: Monitor API response times
- **Memory Usage**: Track memory consumption
- **Error Rates**: Monitor and reduce error rates
- **User Experience**: Gather user feedback

## 🔗 Related Resources

### Official Documentation
- [VibeVoice GitHub Repository](https://github.com/microsoft/VibeVoice)
- [VibeVoice Hugging Face](https://huggingface.co/microsoft/VibeVoice-1.5B)
- [Gradio Documentation](https://gradio.app/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Community & Support
- [VibeVoice Issues](https://github.com/microsoft/VibeVoice/issues)
- [Gradio Community](https://huggingface.co/join/discord)
- [GitHub Community](https://github.community/)

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📞 Support

For support and questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review [GitHub Issues](https://github.com/your-repo/vibevoice-gradio/issues)
3. Join our [Discord Community](https://discord.gg/your-community)

---

**⚠️ Disclaimer**: This tool enables AI-generated podcast creation using cloned voices. Users must comply with all applicable laws and ethical guidelines. The developers are not responsible for misuse of this tool.
