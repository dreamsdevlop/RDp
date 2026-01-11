#!/usr/bin/env python3
"""
VibeVoice Setup Script
Automates the installation and configuration of VibeVoice for Gradio UI deployment.
"""

import os
import sys
import subprocess
import argparse
import logging
from pathlib import Path
import json

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('vibevoice_setup.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

def run_command(command, description=""):
    """Run a shell command and handle errors."""
    logger.info(f"Running: {description or command}")
    try:
        result = subprocess.run(
            command,
            shell=True,
            check=True,
            capture_output=True,
            text=True
        )
        if result.stdout:
            logger.debug(f"Output: {result.stdout.strip()}")
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {command}")
        logger.error(f"Error: {e.stderr}")
        raise

def check_python_version():
    """Check if Python version is compatible."""
    version = sys.version_info
    if version.major != 3 or version.minor < 8:
        logger.error(f"Python 3.8+ required, found {version.major}.{version.minor}")
        sys.exit(1)
    logger.info(f"Python version: {version.major}.{version.minor}.{version.micro}")

def install_dependencies():
    """Install required Python packages."""
    logger.info("Installing Python dependencies...")
    
    packages = [
        "torch==2.0.1",
        "torchvision==0.15.2", 
        "torchaudio==2.0.2",
        "gradio==4.25.0",
        "transformers==4.35.0",
        "accelerate==0.24.1",
        "safetensors==0.4.0",
        "pydub==0.25.1",
        "numpy==1.24.3",
        "scipy==1.11.3",
        "huggingface_hub==0.17.3",
        "requests==2.31.0",
        "tqdm==4.66.1"
    ]
    
    for package in packages:
        try:
            run_command(f"pip install {package}", f"Installing {package}")
        except Exception as e:
            logger.warning(f"Failed to install {package}: {e}")
    
    logger.info("Dependencies installation completed")

def clone_vibevoice_repo():
    """Clone the VibeVoice repository."""
    logger.info("Cloning VibeVoice repository...")
    
    if os.path.exists("VibeVoice"):
        logger.info("VibeVoice repository already exists, skipping clone")
        return
    
    try:
        run_command(
            "git clone https://github.com/microsoft/VibeVoice.git",
            "Cloning VibeVoice repository"
        )
        logger.info("VibeVoice repository cloned successfully")
    except Exception as e:
        logger.error(f"Failed to clone VibeVoice repository: {e}")
        sys.exit(1)

def install_vibevoice():
    """Install VibeVoice package."""
    logger.info("Installing VibeVoice package...")
    
    try:
        run_command(
            "pip install -e VibeVoice",
            "Installing VibeVoice package"
        )
        logger.info("VibeVoice package installed successfully")
    except Exception as e:
        logger.error(f"Failed to install VibeVoice package: {e}")
        sys.exit(1)

def create_app_structure():
    """Create the application directory structure."""
    logger.info("Creating application directory structure...")
    
    directories = [
        "app",
        "app/utils",
        "docs",
        "scripts"
    ]
    
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        logger.debug(f"Created directory: {directory}")
    
    logger.info("Application structure created")

def create_config_file(model_path="microsoft/VibeVoice-1.5B", inference_steps=10):
    """Create configuration file for VibeVoice."""
    logger.info("Creating configuration file...")
    
    config = {
        "model_path": model_path,
        "inference_steps": inference_steps,
        "server_config": {
            "host": "0.0.0.0",
            "port": 7860,
            "debug": True,
            "share": True
        },
        "usage_guidelines": {
            "disclaimer": "This tool enables AI-generated podcast creation using cloned voices. Users must comply with all applicable laws and ethical guidelines.",
            "guidelines": [
                "Do not use cloned voices to impersonate real people",
                "Clearly disclose when content is AI-generated",
                "Do not produce harmful or misleading content",
                "Respect copyright and data protection laws",
                "Obtain explicit permission before using anyone's voice"
            ]
        }
    }
    
    with open("app/config.json", "w") as f:
        json.dump(config, f, indent=2)
    
    logger.info("Configuration file created at app/config.json")

def create_health_check_script():
    """Create health check script for monitoring."""
    logger.info("Creating health check script...")
    
    health_check_content = '''#!/usr/bin/env python3
"""
Health check script for VibeVoice Gradio UI.
"""

import requests
import sys
import time
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def check_gradio_health(url="http://localhost:7860"):
    """Check if Gradio server is healthy."""
    try:
        response = requests.get(f"{url}/", timeout=10)
        if response.status_code == 200:
            logger.info("✅ Gradio server is healthy")
            return True
        else:
            logger.error(f"❌ Gradio server returned status code: {response.status_code}")
            return False
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Gradio server health check failed: {e}")
        return False

if __name__ == "__main__":
    if check_gradio_health():
        sys.exit(0)
    else:
        sys.exit(1)
'''
    
    with open("scripts/health_check.py", "w") as f:
        f.write(health_check_content)
    
    # Make script executable
    os.chmod("scripts/health_check.py", 0o755)
    logger.info("Health check script created at scripts/health_check.py")

def create_requirements_file():
    """Create requirements.txt file."""
    logger.info("Creating requirements.txt...")
    
    requirements = """torch==2.0.1
torchvision==0.15.2
torchaudio==2.0.2
gradio==4.25.0
transformers==4.35.0
accelerate==0.24.1
safetensors==0.4.0
pydub==0.25.1
numpy==1.24.3
scipy==1.11.3
huggingface_hub==0.17.3
requests==2.31.0
tqdm==4.66.1
"""
    
    with open("requirements.txt", "w") as f:
        f.write(requirements)
    
    logger.info("requirements.txt created")

def validate_installation():
    """Validate the installation by importing key modules."""
    logger.info("Validating installation...")
    
    try:
        import torch
        logger.info(f"✅ PyTorch version: {torch.__version__}")
        
        import gradio as gr
        logger.info(f"✅ Gradio version: {gr.__version__}")
        
        import transformers
        logger.info(f"✅ Transformers version: {transformers.__version__}")
        
        # Try to import VibeVoice
        try:
            from vibevoice import VibeVoiceTokenizer, VibeVoiceModel
            logger.info("✅ VibeVoice modules imported successfully")
        except ImportError:
            logger.warning("⚠️ VibeVoice modules not found, but installation may still work")
        
        logger.info("✅ Installation validation completed")
        return True
        
    except ImportError as e:
        logger.error(f"❌ Installation validation failed: {e}")
        return False

def main():
    """Main setup function."""
    parser = argparse.ArgumentParser(description="Setup VibeVoice for Gradio UI")
    parser.add_argument("--model-path", default="microsoft/VibeVoice-1.5B", 
                       help="Hugging Face model path")
    parser.add_argument("--inference-steps", type=int, default=10,
                       help="Number of inference steps")
    parser.add_argument("--skip-deps", action="store_true",
                       help="Skip dependency installation")
    
    args = parser.parse_args()
    
    logger.info("🚀 Starting VibeVoice setup...")
    
    # Check Python version
    check_python_version()
    
    # Install dependencies (unless skipped)
    if not args.skip_deps:
        install_dependencies()
    
    # Clone repository
    clone_vibevoice_repo()
    
    # Install VibeVoice package
    install_vibevoice()
    
    # Create app structure
    create_app_structure()
    
    # Create configuration
    create_config_file(args.model_path, args.inference_steps)
    
    # Create health check script
    create_health_check_script()
    
    # Create requirements file
    create_requirements_file()
    
    # Validate installation
    if validate_installation():
        logger.info("🎉 VibeVoice setup completed successfully!")
        logger.info("📋 Next steps:")
        logger.info("   1. Run the GitHub workflow to deploy the Gradio UI")
        logger.info("   2. Access the UI via the public URL in workflow logs")
        logger.info("   3. Follow the usage guidelines and legal requirements")
    else:
        logger.error("❌ Setup completed with validation errors")
        sys.exit(1)

if __name__ == "__main__":
    main()
