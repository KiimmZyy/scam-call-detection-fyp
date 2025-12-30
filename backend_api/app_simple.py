import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Try to import speech recognition libraries
try:
    import speech_recognition as sr
    HAS_SPEECH_RECOGNITION = True
except ImportError:
    HAS_SPEECH_RECOGNITION = False

# Simplified configuration
MAX_LENGTH = 100
SCAM_THRESHOLD = 0.6
CHUNK_DURATION = 5

# Mock Scam Detector
def detect_scam(text_transcript):
    """Analyzes text and returns mock scam prediction for testing"""
    if not text_transcript or len(text_transcript.strip()) == 0:
        return None, None
    
    # Simple heuristic: check for common scam keywords
    scam_keywords = ['money', 'pay', 'bank', 'account', 'password', 'verify', 'confirm', 
                     'urgent', 'claim', 'prize', 'winner', 'refund', 'transfer', 'crypto']
    
    text_lower = text_transcript.lower()
    keyword_count = sum(1 for keyword in scam_keywords if keyword in text_lower)
    
    # Score based on keywords (0-1)
    prediction = min(keyword_count / 5, 1.0)  # Max score 1.0
    is_scam = bool(prediction > SCAM_THRESHOLD)
    confidence_score = round(float(prediction) * 100, 2)
    
    if not is_scam:
        confidence_score = round((1 - float(prediction)) * 100, 2)
    
    return is_scam, confidence_score

# ENDPOINTS

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'online', 'message': 'Scam Detector API Running (Simplified Mode)'}), 200

@app.route('/predict', methods=['POST'])
def predict():
    """Full analysis endpoint for complete audio file"""
    try:
        # Check if audio file is provided
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        audio_file = request.files['file']
        if audio_file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Mock: Process audio (in real implementation, use Whisper)
        mock_transcript = "Hey, I'm calling about your bank account verification. Please provide your password."
        
        # Perform scam detection
        is_scam, confidence = detect_scam(mock_transcript)
        
        return jsonify({
            'is_scam': is_scam,
            'confidence': confidence,
            'transcript': mock_transcript,
            'message': 'Analysis complete'
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/stream', methods=['POST'])
def stream():
    """Stream-based analysis for real-time detection"""
    try:
        # Check if multipart file is provided
        if 'chunk' in request.files:
            # Handle multipart file upload
            chunk_file = request.files['chunk']
            chunk_index = int(request.form.get('chunk_index', 0))
            is_final = request.form.get('is_final', 'false').lower() == 'true'
            
            # Save temporary file and transcribe
            temp_path = f'/tmp/audio_chunk_{chunk_index}.wav'
            chunk_file.save(temp_path)
            
            # Try to transcribe audio
            transcript = ""
            if HAS_SPEECH_RECOGNITION:
                try:
                    recognizer = sr.Recognizer()
                    with sr.AudioFile(temp_path) as source:
                        audio = recognizer.record(source)
                    transcript = recognizer.recognize_google(audio)
                except Exception as e:
                    transcript = f"[Audio - unable to transcribe: {str(e)[:50]}]"
            else:
                transcript = "[Audio chunk received - speech recognition not available]"
            
            # Clean up temp file
            try:
                os.remove(temp_path)
            except:
                pass
            
            # Perform scam detection on transcript
            is_scam, confidence = detect_scam(transcript)
            
            return jsonify({
                'chunk_index': chunk_index,
                'is_scam': is_scam,
                'confidence': confidence,
                'is_final': is_final,
                'transcript': transcript
            }), 200
        else:
            # Handle JSON request
            data = request.get_json()
            
            if not data or 'transcript_chunk' not in data:
                return jsonify({'error': 'No transcript or audio provided'}), 400
            
            transcript_chunk = data.get('transcript_chunk', '')
            chunk_index = data.get('chunk_index', 0)
            is_final = data.get('is_final', False)
            
            # Perform scam detection on chunk
            is_scam, confidence = detect_scam(transcript_chunk)
            
            return jsonify({
                'chunk_index': chunk_index,
                'is_scam': is_scam,
                'confidence': confidence,
                'is_final': is_final,
                'transcript': transcript_chunk
            }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/detect', methods=['POST'])
def detect():
    """Text-based detection endpoint"""
    try:
        data = request.get_json()
        
        if not data or 'text' not in data:
            return jsonify({'error': 'No text provided'}), 400
        
        text = data.get('text', '')
        
        # Perform scam detection
        is_scam, confidence = detect_scam(text)
        
        return jsonify({
            'is_scam': is_scam,
            'confidence': confidence,
            'text': text
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("=" * 50)
    print("Scam Detector API (Simplified Mock Mode)")
    print("=" * 50)
    print("Available Endpoints:")
    print("  GET  /health         - Health check")
    print("  POST /predict        - Full audio analysis")
    print("  POST /stream         - Real-time chunk analysis")
    print("  POST /detect         - Text analysis")
    print("=" * 50)
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
