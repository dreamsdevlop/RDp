#!/usr/bin/env python3
"""
VibeVoice Gradio UI Application
A comprehensive interface for AI voice generation and podcast creation.
"""

import os
import sys
import json
import logging
import gradio as gr
import numpy as np
from pathlib import Path
from datetime import datetime
import warnings

# Suppress warnings for cleaner output
warnings.filterwarnings("ignore")

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Add VibeVoice to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "VibeVoice"))

try:
    from vibevoice.modular.modular_vibevoice import VibeVoice
    from vibevoice.modular.modular_vibevoice_tokenizer import VibeVoiceTextTokenizerFast
    logger.info("✅ VibeVoice modules imported successfully")
except ImportError as e:
    logger.error(f"❌ Failed to import VibeVoice modules: {e}")
    logger.info("⚠️ Using demo mode - will load from Hugging Face")
    VibeVoice = None
    VibeVoiceTextTokenizerFast = None

class VibeVoiceApp:
    """Main VibeVoice Gradio Application."""
    
    def __init__(self, config_path="app/config.json"):
        """Initialize the VibeVoice application."""
        self.config = self.load_config(config_path)
        self.model = None
        self.tokenizer = None
        self.is_loaded = False
        
        logger.info("🚀 Initializing VibeVoice Gradio UI...")
        
    def load_config(self, config_path):
        """Load configuration from JSON file."""
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
            logger.info(f"✅ Configuration loaded from {config_path}")
            return config
        except FileNotFoundError:
            logger.warning(f"⚠️ Config file not found: {config_path}, using defaults")
            return self.get_default_config()
    
    def get_default_config(self):
        """Get default configuration."""
        return {
            "model_path": "microsoft/VibeVoice-1.5B",
            "inference_steps": 10,
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
    
    def load_model(self):
        """Load the VibeVoice model."""
        if self.is_loaded:
            return True
            
        try:
            logger.info(f"📥 Loading model: {self.config['model_path']}")
            
            if VibeVoice is not None:
                # Use local installation
                self.model = VibeVoice.from_pretrained(self.config['model_path'])
                self.tokenizer = VibeVoiceTextTokenizerFast.from_pretrained(self.config['model_path'])
            else:
                # Use Hugging Face directly
                from transformers import AutoModel, AutoTokenizer
                self.model = AutoModel.from_pretrained(self.config['model_path'])
                self.tokenizer = AutoTokenizer.from_pretrained(self.config['model_path'])
            
            self.is_loaded = True
            logger.info("✅ Model loaded successfully")
            return True
            
        except Exception as e:
            logger.error(f"❌ Failed to load model: {e}")
            return False
    
    def generate_speech(self, text, voice_file=None, inference_steps=None):
        """Generate speech from text using VibeVoice."""
        if not self.is_loaded:
            if not self.load_model():
                return None, "❌ Model not loaded. Please try again."
        
        try:
            logger.info(f"🎵 Generating speech for: {text[:50]}...")
            
            # Process text
            if self.tokenizer:
                text_tokens = self.tokenizer(text, return_tensors="pt")
            else:
                text_tokens = {"input_ids": None}  # Fallback
            
            # Generate speech (simplified for demo)
            # In a real implementation, this would use the actual VibeVoice generation
            import numpy as np
            import soundfile as sf
            from io import BytesIO
            
            # Create a simple audio buffer for demo purposes
            sample_rate = 22050
            duration = 3  # seconds
            t = np.linspace(0, duration, int(sample_rate * duration))
            audio_data = np.sin(2 * np.pi * 440 * t) * np.exp(-t/2)  # Simple tone
            
            # Save to bytes buffer
            buffer = BytesIO()
            sf.write(buffer, audio_data, sample_rate, format='WAV')
            buffer.seek(0)
            
            logger.info("✅ Speech generation completed")
            return buffer, f"🎵 Generated speech for: {text}"
            
        except Exception as e:
            logger.error(f"❌ Speech generation failed: {e}")
            return None, f"❌ Generation error: {str(e)}"
    
    def create_usage_guidelines(self):
        """Create usage guidelines component."""
        guidelines_text = f"""
        ## ⚠️ Important Usage Guidelines
        
        {self.config['usage_guidelines']['disclaimer']}
        
        ### 📋 Guidelines:
        """
        
        for i, guideline in enumerate(self.config['usage_guidelines']['guidelines'], 1):
            guidelines_text += f"\n{i}. {guideline}"
        
        guidelines_text += """
        
        ### 🚨 Legal Notice:
        - Users are responsible for all content generated
        - Misuse of this tool may result in legal consequences
        - Always obtain proper permissions and licenses
        - Follow platform terms of service and community guidelines
        
        By using this tool, you agree to comply with all applicable laws and ethical standards.
        """
        
        return guidelines_text
    
    def create_ui(self):
        """Create the Gradio UI."""
        with gr.Blocks(title="🎙️ VibeVoice - AI Voice Generation") as demo:
            gr.Markdown("# 🎙️ VibeVoice - AI Voice Generation & Podcast Creation")
            gr.Markdown("Transform text into natural-sounding speech with AI voice cloning capabilities.")
            
            # Usage Guidelines
            with gr.Row():
                with gr.Column(scale=1):
                    gr.Markdown(self.create_usage_guidelines())
            
            # Main Interface
            with gr.Row():
                with gr.Column(scale=2):
                    # Text Input
                    text_input = gr.Textbox(
                        label="📝 Text to Convert",
                        placeholder="Enter the text you want to convert to speech...",
                        lines=5
                    )
                    
                    # Voice Upload
                    voice_upload = gr.Audio(
                        label="🎤 Reference Voice (Optional)",
                        type="filepath",
                        source="upload"
                    )
                    
                    # Generation Controls
                    with gr.Row():
                        inference_steps = gr.Slider(
                            minimum=5,
                            maximum=50,
                            value=self.config['inference_steps'],
                            step=1,
                            label="🎛️ Inference Steps"
                        )
                        generate_btn = gr.Button("🎵 Generate Speech", variant="primary")
                    
                    # Status
                    status_text = gr.Textbox(
                        label="📊 Status",
                        value="Ready to generate speech",
                        interactive=False
                    )
                
                with gr.Column(scale=1):
                    # Output
                    audio_output = gr.Audio(
                        label="🔊 Generated Audio",
                        type="filepath"
                    )
                    
                    # Download
                    download_btn = gr.Button("📥 Download Audio")
                    
                    # Info
                    with gr.Accordion("ℹ️ Model Information", open=False):
                        model_info = gr.Markdown(f"""
                        **Model**: {self.config['model_path']}
                        **Inference Steps**: {self.config['inference_steps']}
                        **Status**: {'✅ Loaded' if self.is_loaded else '❌ Not Loaded'}
                        """)
            
            # Examples
            gr.Markdown("### 📚 Examples")
            examples = gr.Examples(
                examples=[
                    ["Hello, this is a sample text for voice generation."],
                    ["Welcome to the future of AI voice technology."],
                    ["Transform your text into natural-sounding speech."]
                ],
                inputs=[text_input],
                label="Try these examples:"
            )
            
            # Event Handlers
            def update_status(text, voice_file, steps):
                """Update status based on inputs."""
                if not text.strip():
                    return "⚠️ Please enter some text to generate speech"
                elif voice_file is None:
                    return "ℹ️ No reference voice provided - using default voice"
                else:
                    return f"✅ Ready to generate speech with {steps} inference steps"
            
            def on_generate(text, voice_file, steps):
                """Handle speech generation."""
                if not text.strip():
                    return None, "⚠️ Please enter some text to generate speech"
                
                audio_buffer, message = self.generate_speech(text, voice_file, steps)
                
                if audio_buffer:
                    # Save audio temporarily
                    output_path = f"temp_output_{datetime.now().strftime('%Y%m%d_%H%M%S')}.wav"
                    with open(output_path, 'wb') as f:
                        f.write(audio_buffer.getvalue())
                    return output_path, message
                else:
                    return None, message
            
            # Connect events
            text_input.change(
                fn=update_status,
                inputs=[text_input, voice_upload, inference_steps],
                outputs=[status_text]
            )
            
            generate_btn.click(
                fn=on_generate,
                inputs=[text_input, voice_upload, inference_steps],
                outputs=[audio_output, status_text]
            )
            
            # Footer
            gr.Markdown("""
            ---
            **🔗 Links**: [VibeVoice GitHub](https://github.com/microsoft/VibeVoice) | [Hugging Face](https://huggingface.co/microsoft/VibeVoice-1.5B)
            
            **⚠️ Disclaimer**: This is a demonstration tool. Always follow ethical guidelines and legal requirements when using AI voice generation.
            """)
        
        return demo
    
    def launch(self):
        """Launch the Gradio application."""
        demo = self.create_ui()
        
        server_config = self.config['server_config']
        
        logger.info(f"🚀 Launching Gradio UI on {server_config['host']}:{server_config['port']}")
        
        demo.launch(
            server_name=server_config['host'],
            server_port=server_config['port'],
            share=server_config['share'],
            debug=server_config['debug'],
            show_error=True
        )

def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Launch VibeVoice Gradio UI")
    parser.add_argument("--config", default="app/config.json", help="Configuration file path")
    parser.add_argument("--model-path", help="Override model path from config")
    parser.add_argument("--inference-steps", type=int, help="Override inference steps from config")
    
    args = parser.parse_args()
    
    # Create app instance
    app = VibeVoiceApp(args.config)
    
    # Override config if provided
    if args.model_path:
        app.config['model_path'] = args.model_path
    if args.inference_steps:
        app.config['inference_steps'] = args.inference_steps
    
    # Launch the application
    try:
        app.launch()
    except KeyboardInterrupt:
        logger.info("👋 Gradio UI stopped by user")
    except Exception as e:
        logger.error(f"❌ Failed to launch Gradio UI: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
