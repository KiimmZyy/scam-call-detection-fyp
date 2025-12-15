import os
import numpy as np
import pickle
from flask import Flask, request, jsonify
from flask_cors import CORS
import whisper
from keras.models import load_model
from keras.preprocessing.sequence import pad_sequences
import io
import wave

app = Flask(__name__)
CORS(app)  # Enable cross-origin requests from mobile apps

#CONFIGURATION
MAX_LENGTH = 100 
SCAM_THRESHOLD = 0.6 
CHUNK_DURATION = 5  # Process every 5 seconds of audio

#1. LOAD MODELS
print("Loading Whisper Model (this might take a minute)...")
stt_model = whisper.load_model("base") 

print("Loading Scam Detection Model (CNN-LSTM)...")
try:
    scam_model = load_model('scam_detector_model.h5')
    with open('tokenizer.pickle', 'rb') as handle:
        tokenizer = pickle.load(handle)
    print("All Models Loaded Successfully!")
except Exception as e:
    print(f"Error loading CNN-LSTM model: {e}")
    print("Run 'python train_model.py' first to create the AI brain.")
    exit()

# Helper function for scam detection
def detect_scam(text_transcript):
    """Analyzes text and returns scam prediction"""
    if not text_transcript or len(text_transcript.strip()) == 0:
        return None, None
    
    sequences = tokenizer.texts_to_sequences([text_transcript])
    padded = pad_sequences(sequences, maxlen=MAX_LENGTH, padding='post', truncating='post')
    prediction = scam_model.predict(padded, verbose=0)[0][0]
    
    is_scam = bool(prediction > SCAM_THRESHOLD)
    confidence_score = round(float(prediction) * 100, 2)
    
    if not is_scam:
        confidence_score = round((1 - float(prediction)) * 100, 2)
    
    return is_scam, confidence_score

# ============ ENDPOINT 1: FULL AUDIO FILE (Original) ============
@app.route('/predict', methods=['POST'])
def predict():
    """Process complete audio file for scam detection"""
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400
    
    file = request.files['file']
    filename = "temp_audio.wav"
    file.save(filename)

    try:
        result = stt_model.transcribe(filename)
        text_transcript = result["text"].strip()
        
        if not text_transcript:
            return jsonify({'error': "Could not hear any voice."}), 400
        
        is_scam, confidence_score = detect_scam(text_transcript)
        
        print(f"[FULL] Transcript: {text_transcript}")
        print(f"[FULL] Scam: {is_scam}, Confidence: {confidence_score}%")

        return jsonify({
            "transcription": text_transcript,
            "is_scam": is_scam,
            "confidence": confidence_score
        })
        
    except Exception as e:
        return jsonify({'error': f"Processing failed: {str(e)}"}), 500


# ============ ENDPOINT 2: REAL-TIME AUDIO STREAMING ============
@app.route('/stream', methods=['POST'])
def stream_predict():
    """Process audio chunks in real-time (for mobile apps)"""
    if 'chunk' not in request.files:
        return jsonify({'error': 'No audio chunk provided'}), 400
    
    chunk_file = request.files['chunk']
    chunk_index = request.form.get('chunk_index', 0)
    is_final = request.form.get('is_final', 'false').lower() == 'true'
    
    try:
        # Save chunk temporarily
        chunk_filename = f"temp_chunk_{chunk_index}.wav"
        chunk_file.save(chunk_filename)
        
        # Transcribe this chunk
        result = stt_model.transcribe(chunk_filename)
        text_transcript = result["text"].strip()
        
        # Detect scam on current chunk
        is_scam = None
        confidence_score = None
        
        if text_transcript:
            is_scam, confidence_score = detect_scam(text_transcript)
            print(f"[STREAM] Chunk {chunk_index}: '{text_transcript}' -> Scam: {is_scam}")
        
        # Clean up
        os.remove(chunk_filename)
        
        return jsonify({
            "chunk_index": chunk_index,
            "transcription": text_transcript,
            "is_scam": is_scam,
            "confidence": confidence_score,
            "is_final": is_final
        })
        
    except Exception as e:
        return jsonify({'error': f"Stream processing failed: {str(e)}"}), 500


# ============ ENDPOINT 3: TEXT-ONLY DETECTION ============
@app.route('/detect', methods=['POST'])
def text_detect():
    """Detect scam from text only (no audio needed)"""
    data = request.get_json()
    
    if not data or 'text' not in data:
        return jsonify({'error': 'No text provided'}), 400
    
    text_transcript = data['text'].strip()
    
    if not text_transcript:
        return jsonify({'error': "Text cannot be empty"}), 400
    
    try:
        is_scam, confidence_score = detect_scam(text_transcript)
        
        print(f"[TEXT] Input: '{text_transcript}' -> Scam: {is_scam}")
        
        return jsonify({
            "text": text_transcript,
            "is_scam": is_scam,
            "confidence": confidence_score
        })
        
    except Exception as e:
        return jsonify({'error': f"Detection failed: {str(e)}"}), 500


# ============ ENDPOINT 4: HEALTH CHECK ============
@app.route('/health', methods=['GET'])
def health():
    """Check if API is running and models are loaded"""
    return jsonify({
        "status": "healthy",
        "models_loaded": True,
        "message": "Scam Detection API is running"
    })

if __name__ == '__main__':
    print("\n" + "="*60)
    print("SCAM DETECTION API STARTED")
    print("="*60)
    print("Available Endpoints:")
    print("  1. POST /predict     - Full audio file analysis")
    print("  2. POST /stream      - Real-time audio streaming")
    print("  3. POST /detect      - Text-only detection")
    print("  4. GET  /health      - API health check")
    print("="*60)
    print("Running on: http://0.0.0.0:5000")
    print("="*60 + "\n")
    
    # Host='0.0.0.0' allows mobile phone to connect
    app.run(host='0.0.0.0', port=5000, debug=True)