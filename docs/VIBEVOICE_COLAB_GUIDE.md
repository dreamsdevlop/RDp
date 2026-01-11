# VibeVoice Colab Workflow Guide

This guide provides comprehensive instructions for setting up and running VibeVoice using the Colab workflow commands.

## 🎯 Overview

The VibeVoice Colab workflow automates the setup and deployment of the VibeVoice AI voice generation system using the exact commands from the original Colab notebook.

## 📋 Prerequisites

- Python 3.8+
- Git
- Internet connection for downloading models and dependencies

## 🚀 Quick Start

### 1. Environment Setup

```bash
# Setup Python Environment
python -m pip install --upgrade pip

# Install System Dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y ffmpeg libsndfile1
```

### 2. Install Python Dependencies (Colab Style)

```bash
# Install PyTorch with CPU support (Colab style)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install Gradio and other dependencies
pip install gradio==4.25.0
pip install transformers==4.35.0
pip install accelerate==0.24.1
pip install safetensors==0.4.0
pip install pydub>=0.25.1
pip install numpy==1.24.3
pip install scipy==1.11.3
pip install huggingface_hub==0.17.3
pip install requests==2.31.0
pip install tqdm==4.66.1
```

### 3. Clone and Setup VibeVoice (Colab Style)

```bash
# Clone the official repository
git clone https://github.com/microsoft/VibeVoice.git

# Install VibeVoice package
cd VibeVoice
pip install -e .
```

### 4. Run VibeVoice Podcast (Colab Commands)

```bash
# Launch the application using colab.py
cd VibeVoice
python demo/colab.py \
  --model_path microsoft/VibeVoice-1.5B \
  --inference_steps 10 \
  --debug \
  --share
```

## 🔧 Configuration Options

### Model Parameters

- `--model_path`: Hugging Face model path (default: `microsoft/VibeVoice-1.5B`)
- `--inference_steps`: Number of inference steps (default: 10)
- `--debug`: Enable debug mode
- `--share`: Generate public share URL

### Example Configurations

```bash
# Basic setup
python demo/colab.py --model_path microsoft/VibeVoice-1.5B --inference_steps 10

# With debug mode
python demo/colab.py --model_path microsoft/VibeVoice-1.5B --inference_steps 10 --debug

# With share URL
python demo/colab.py --model_path microsoft/VibeVoice-1.5B --inference_steps 10 --share

# Full configuration
python demo/colab.py --model_path microsoft/VibeVoice-1.5B --inference_steps 10 --debug --share
```

## 🏗️ GitHub Actions Workflow

The workflow automates the entire setup process:

### Workflow Inputs

- `model_path`: Model path (default: `microsoft/VibeVoice-1.5B`)
- `inference_steps`: Inference steps (default: `10`)
- `enable_gpu`: Enable GPU acceleration (default: `true`)
- `share_url`: Generate public share URL (default: `true`)
- `enable_drive_save`: Enable Google Drive save functionality (default: `false`)

### Workflow Steps

1. **Checkout Repository**: Clone the project repository
2. **Setup Environment**: Configure system and Python environment
3. **Install Dependencies**: Install all required Python packages
4. **Clone VibeVoice**: Clone and install VibeVoice from GitHub
5. **Create Structure**: Set up application directory structure
6. **Cache Models**: Cache Hugging Face model weights
7. **Launch Application**: Start the Gradio UI with specified parameters
8. **Monitor Health**: Monitor the application health
9. **Generate Report**: Create deployment report
10. **Cleanup**: Clean up processes

## 📁 Project Structure

```
VibeVoice/
├── demo/
│   ├── colab.py          # Colab demo script
│   ├── gradio_demo.py    # Gradio UI demo
│   └── ...
├── app/
│   ├── app.py           # Main application
│   └── config.json      # Configuration file
├── docs/
│   └── VIBEVOICE_COLAB_GUIDE.md  # This guide
├── scripts/
│   └── setup_vibevoice.py       # Setup script
└── .github/
    └── workflows/
        └── vibevoice-gradio.yml # GitHub Actions workflow
```

## ⚠️ Usage Guidelines

### Legal and Ethical Requirements

1. **No Misrepresentation**: Do not use cloned voices to impersonate real people
2. **Transparency**: Clearly disclose when content is AI-generated
3. **No Harmful Content**: Do not produce or distribute harmful/deceptive material
4. **Legal Compliance**: Ensure compliance with copyright laws and data protection regulations
5. **Respect for Consent**: Do not replicate anyone's voice without explicit permission

### Important Notes

- Users bear full responsibility for all content generated
- Misuse may result in legal consequences
- Always follow platform terms of service and community guidelines
- By using this tool, you agree to comply with all applicable laws and ethical standards

## 🔍 Troubleshooting

### Common Issues

1. **Dependency Installation Failures**
   - Ensure pip is updated: `python -m pip install --upgrade pip`
   - Check internet connection for downloading packages

2. **Model Download Issues**
   - Ensure sufficient disk space (models can be large)
   - Check Hugging Face access and authentication

3. **Port Binding Issues**
   - Ensure port 7860 is available
   - Check for conflicting services

4. **Memory Issues**
   - VibeVoice requires significant RAM for model loading
   - Consider using smaller models if memory is limited

### Debug Mode

Enable debug mode for detailed logging:

```bash
python demo/colab.py --model_path microsoft/VibeVoice-1.5B --inference_steps 10 --debug
```

## 🌐 Accessing the Application

Once the workflow completes successfully:

1. Check the workflow logs for the public URL
2. Look for the line: `Running on public URL: https://...`
3. Access the Gradio UI through the provided URL
4. Use the interface to generate AI voices

## 🔄 Maintenance

### Regular Updates

- Update dependencies regularly
- Monitor for new VibeVoice releases
- Update workflow actions to latest versions

### Monitoring

- Check workflow logs for errors
- Monitor application health
- Review usage patterns and performance

## 📞 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review the workflow logs for detailed error messages
3. Consult the [VibeVoice GitHub repository](https://github.com/microsoft/VibeVoice)
4. Check the [Hugging Face documentation](https://huggingface.co/microsoft/VibeVoice-1.5B)

## 📄 License

This project is provided under the [MIT License](https://github.com/microsoft/VibeVoice/blob/main/LICENSE).

## 🔗 Related Resources

- [VibeVoice GitHub Repository](https://github.com/microsoft/VibeVoice)
- [VibeVoice on Hugging Face](https://huggingface.co/microsoft/VibeVoice-1.5B)
- [Gradio Documentation](https://gradio.app/docs/)
- [Hugging Face Transformers](https://huggingface.co/docs/transformers/)

---

**⚠️ Disclaimer**: This tool enables AI-generated podcast creation using cloned voices. Users must comply with all applicable laws and ethical guidelines. The developers disclaim all liability for misuse.
