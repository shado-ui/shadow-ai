# Shadow Hub — AI Hub

[![Flutter Version](https://img.shields.io/badge/Flutter-3.19+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)]()

A powerful, cross-platform AI chat application that works **online and offline** with support for text generation, image analysis, image generation, and video generation. Built with Flutter.

![Shadow Hub](screenshots/app_preview.png)

## ✨ Features

### 🤖 AI Chat Modes
- **Auto Mode** — Automatically switches between online/offline based on connectivity
- **Online Mode** — Use free AI models from OpenRouter, Pollinations, and more
- **Offline Mode** — Run LLMs locally on your device (100% private, no internet needed)

### 🆓 Free AI Models (Online)
Access 20+ free models without API keys:

| Model | Size | Best For |
|-------|------|----------|
| Llama 4 Maverick | Large | General purpose, vision |
| Llama 4 Scout | Large | Reasoning, analysis |
| Llama 3.3 70B | Large | Complex tasks |
| GPT-OSS 120B | Large | High quality responses |
| DeepSeek R1 | Large | Coding, reasoning |
| Qwen3 Coder 480B | Large | Programming |
| Mistral Small 3.1 | Medium | Balanced performance |
| Venice 24B (Dolphin) | Medium | Creative, open |
| Gemma 3 27B/12B/4B | Various | Google models, vision |
| And 15+ more... | | |

### 📦 Offline Models (Downloadable)
Download and run GGUF models locally:

| Model | Size | RAM Needed | Best For |
|-------|------|------------|----------|
| TinyLlama 1.1B | 670 MB | 2 GB | Ultra-fast responses |
| Phi-3 Mini 3.8B | 2.3 GB | 4 GB | Smart reasoning |
| Gemma 2 2B | 1.5 GB | 3 GB | Google efficiency |
| Llama 3.2 3B | 2.0 GB | 4 GB | Recommended starter |
| Llama 3.3 8B | 4.9 GB | 8 GB | Gold standard |
| Mistral 7B | 4.4 GB | 8 GB | Speed & creativity |
| DeepSeek Coder 6.7B | 3.8 GB | 8 GB | Programming |
| Dolphin 2.6 7B | 4.4 GB | 8 GB | Creative, unrestricted |

### 🖼️ Image Capabilities
- **Image Generation** — Create images using Freepik, DALL-E, or HuggingFace (FLUX.1)
- **Image Analysis (Vision)** — Upload images and ask the AI to describe, analyze, or extract text
- Supports JPG, PNG, GIF, WEBP, BMP

### 🎥 Video Generation
Generate AI videos from text prompts using the dedicated Video tab.

### 📄 File Upload & Analysis
Upload files and the AI reads their actual content:

| Format | Support |
|--------|---------|
| PDF | Full text extraction with page structure |
| DOCX | Word document text extraction |
| XLSX | Spreadsheet data extraction |
| PPTX | PowerPoint slide text extraction |
| TXT, MD, CSV | Direct content reading |
| Code files | Python, Dart, JS, HTML, CSS, and 40+ more |
| RTF | Rich text to plain text |

### 🎙️ Voice Features
- **Text-to-Speech** — Have AI responses read aloud
- **Speech-to-Text** — Voice input for messages (mobile)

### 💾 Project Management
- Multiple chat projects/chats
- Persistent history with SQLite
- Auto-generated chat titles
- Star/favorite messages

### 🎨 UI/UX
- Beautiful dark theme with glassmorphism
- Responsive design (mobile & desktop)
- Smooth animations
- Model-specific icons and colors
- Typing indicators
- Copy messages with long-press

## 📱 Platforms

- ✅ Android
- ✅ iOS
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Web (experimental)

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.19 or higher
- Dart 3.0 or higher
- Android Studio / Xcode (for mobile)
- Visual Studio 2022 (for Windows)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ai_hub.git
   cd ai_hub
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   
   Android:
   ```bash
   flutter run
   ```
   
   Windows:
   ```bash
   flutter run -d windows
   ```
   
   iOS (Mac only):
   ```bash
   flutter run -d ios
   ```

### Building Release Versions

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Windows
flutter build windows --release

# iOS (Mac only)
flutter build ios --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── theme/
│   └── app_theme.dart           # Colors, themes, styling
├── models/
│   ├── chat_message.dart        # Message model
│   └── app_state.dart           # Global app state
├── services/
│   ├── providers/               # AI provider implementations
│   │   ├── openrouter_provider.dart    # OpenRouter API
│   │   ├── free_provider.dart          # Pollinations, other free APIs
│   │   ├── huggingface_provider.dart   # HuggingFace (image gen)
│   │   ├── local_provider.dart         # Offline llama.cpp
│   │   └── ...
│   ├── connectivity_service.dart # Network detection
│   ├── database_service.dart     # SQLite persistence
│   ├── file_reader_service.dart  # PDF/DOCX extraction
│   ├── model_router.dart         # Provider routing
│   ├── tts_service.dart          # Text-to-speech
│   └── stt_service.dart          # Speech-to-text
├── screens/
│   ├── chat_screen.dart          # Main chat interface
│   ├── home_screen.dart          # Navigation container
│   ├── image_screen.dart         # Image generation
│   ├── video_screen.dart         # Video generation
│   ├── models_screen.dart        # Offline model downloader
│   ├── agents_screen.dart        # AI agents
│   └── settings_screen.dart      # App settings
└── widgets/
    ├── message_bubble.dart       # Chat message UI
    ├── chat_input.dart           # Message input
    ├── status_bar.dart           # Connection status
    └── ...

## 🔧 Configuration

### Using Your Own API Keys (Optional)

The app works out-of-the-box with free models, but you can add your own keys for better performance:

1. Create a `.env` file in the project root:
   ```
   OPENROUTER_API_KEY=your_key_here
   HUGGINGFACE_API_KEY=your_key_here
   OPENAI_API_KEY=your_key_here
   ```

2. Or add keys in-app via the Settings screen

### Getting API Keys

- **OpenRouter**: https://openrouter.ai/keys (free tier available)
- **HuggingFace**: https://huggingface.co/settings/tokens (free)
- **OpenAI**: https://platform.openai.com/api-keys (paid)
- **Freepik**: https://www.freepik.com/api (for image generation)

## 🛠️ Tech Stack

- **Framework**: Flutter 3.19+
- **State Management**: ValueNotifier + InheritedWidget
- **Database**: SQLite (sqflite)
- **HTTP**: Dio + http package
- **File Handling**: file_picker, image_picker
- **PDF Processing**: syncfusion_flutter_pdf
- **Office Documents**: archive (ZIP parsing for DOCX/XLSX/PPTX)
- **Offline AI**: llama.cpp (via platform channels)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [OpenRouter](https://openrouter.ai/) for free model access
- [Pollinations.AI](https://pollinations.ai/) for free image/text generation
- [HuggingFace](https://huggingface.co/) for model hosting
- [TheBloke](https://huggingface.co/TheBloke) for quantized GGUF models
- [Google](https://ai.google.dev/) for Gemini API
- [Meta](https://ai.meta.com/) for Llama models
- [Microsoft](https://www.microsoft.com/en-us/research/research-area/artificial-intelligence/) for Phi models

## 📧 Contact

wasshadow.lordshadow@gmail.com

---

**Note**: This is an unofficial project. All AI models are property of their respective owners. The app uses free tiers and APIs where available.
