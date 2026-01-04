# Real-Time Scam Call Detection System

A complete mobile application system for detecting scam calls in real-time using AI/Machine Learning.

## Project Overview

This Final Year Project (FYP) consists of:
- **Backend API** - Flask-based REST API with CNN-LSTM neural network for scam detection
- **Mobile App** - Flutter cross-platform mobile application (iOS & Android)
- **ML Model** - Trained on call transcripts to identify scam patterns

## Project Structure

```
.
├── backend_api/              # Python Flask API
│   ├── app.py               # Main API server
│   ├── train_model.py       # Model training script
│   ├── requirements.txt     # Python dependencies
│   ├── call_transcript_cleaned.csv  # Training dataset
│   └── README.md            # Backend documentation
│
└── mobile_app/              # Flutter mobile application
    ├── lib/                 # Dart source code
    │   ├── main.dart
    │   ├── screens/
    │   ├── providers/
    │   └── widgets/
    ├── pubspec.yaml         # Flutter dependencies
    └── README.md            # Mobile app documentation
```

## Technologies Used

### Backend
- **Python 3.11+**
- **Flask** - Web framework
- **TensorFlow/Keras** - Deep learning
- **OpenAI Whisper** - Speech-to-text
- **CNN-LSTM** - Neural network architecture

### Mobile App
- **Flutter 3.0+**
- **Dart**
- **Provider** - State management
- **HTTP** - API communication

## Prerequisites

### Backend Setup
1. Python 3.11 or higher
2. pip package manager
3. Virtual environment (recommended)

### Mobile App Setup
1. Flutter SDK 3.0+
2. Android Studio (for Android)
3. Xcode (for iOS, Mac only)

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
```

### 2. Backend Setup
```bash
cd backend_api

# Create virtual environment
python -m venv .venv

# Activate virtual environment
# Windows:
.venv\Scripts\activate
# Mac/Linux:
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Train the model (first time only)
python train_model.py

# Run the API server
python app.py
```

The API will start on `http://localhost:5000`

### 3. Mobile App Setup
```bash
cd mobile_app

# Get Flutter dependencies
flutter pub get

# Update API endpoint in lib/providers/api_provider.dart
# Change to your computer's IP if using physical device

# Run the app
flutter run
```

## Documentation

- [Backend API Documentation](backend_api/README.md) - API endpoints, configuration, deployment
- [Mobile App Documentation](mobile_app/README.md) - App features, setup, troubleshooting

## 🔑 Key Features

### Backend API
✅ Multiple detection modes (audio file, text, streaming)  
✅ Real-time audio chunk processing  
✅ Speech-to-text using Whisper  
✅ CNN-LSTM scam detection model  
✅ RESTful API with CORS support  

### Mobile App
✅ Text and Audio-based scam detection  
✅ Call history with statistics  
✅ Confidence score display  
✅ Scam indicator breakdown  
✅ Customizable sensitivity settings  

## Testing

### Test Backend API
```bash
# Health check
curl http://localhost:5000/health

# Test text detection
curl -X POST http://localhost:5000/detect \
  -H "Content-Type: application/json" \
  -d '{"text": "Your account has been compromised. Click here immediately."}'
```

### Test Mobile App
1. Start backend API
2. Run `flutter run`
3. Paste sample scam text in the app
4. Verify detection works

## Model Details

- **Architecture**: CNN-LSTM Neural Network
- **Training Data**: 358 call transcripts (scam + legitimate)
- **Input**: Text transcription (max 100 words)
- **Output**: Scam probability (0-100%)
- **Current Accuracy**: ~79% on training data

## Contributing

This is an academic project. To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Security Notes

- Never commit API keys or secrets
- Model files (`.h5`) are excluded from Git (too large)
- Use environment variables for sensitive config
- Enable HTTPS in production

## License

This project is part of the Final Year Project at IIUM (International Islamic University Malaysia).

## 👥 Team Members

- MUHAMMAD AFIF BIN HUSNAN (2212583)
- MUHAMMAD AMIR ZARIEFF BIN JEFNEE (2216919)

## Contact

For questions or issues, please open a GitHub issue or contact the project maintainers.

## Acknowledgments

- IIUM for project support
- OpenAI for Whisper model
- Flutter & TensorFlow communities

---

**Note**: Remember to train the model (`python train_model.py`) before running the API for the first time!
