import os
import json
from flask import Flask, request, jsonify
from flask_cors import CORS
import whisper
import tempfile
import librosa
import numpy as np

app = Flask(__name__)
CORS(app)

# Simplified configuration
MAX_LENGTH = 100
SCAM_THRESHOLD = 0.6
CHUNK_DURATION = 5

# Load Whisper model
print("Loading OpenAI Whisper Model...")
try:
    stt_model = whisper.load_model("base")
    print("Whisper Model Loaded Successfully!")
except Exception as e:
    print(f"Error loading Whisper: {e}")
    stt_model = None

# Mock Scam Detector (using keyword heuristics)
def detect_scam(text_transcript):
    """Analyzes text and returns scam prediction"""
    if not text_transcript or len(text_transcript.strip()) == 0:
        return None, None
    
    # Simple heuristic: check for common scam keywords
    scam_keywords = ['money', 'pay', 'bank', 'account', 'password', 'verify', 'confirm', 
                     'urgent', 'claim', 'prize', 'winner', 'refund', 'transfer', 'crypto',
                     'update', 'click', 'link', 'confirm identity', 'social security']
    
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
    return jsonify({'status': 'online', 'message': 'Scam Detector API Running (Whisper Mode)'}), 200

@app.route('/predict', methods=['POST'])
def predict():
    """Full analysis endpoint for complete audio file"""
    try:
        print("[Predict] Request received")
        print(f"[Predict] Request files: {request.files.keys()}")
        
        # Check if audio file is provided
        if 'file' not in request.files:
            print("[Predict] ERROR: No 'file' in request")
            return jsonify({'error': 'No file provided'}), 400
        
        audio_file = request.files['file']
        print(f"[Predict] File received: {audio_file.filename}")
        
        if audio_file.filename == '':
            print("[Predict] ERROR: Empty filename")
            return jsonify({'error': 'No file selected'}), 400
        
        # Save temporary audio file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp:
            audio_file.save(tmp.name)
            temp_audio_path = tmp.name
        
        file_size = os.path.getsize(temp_audio_path)
        print(f"[Predict] Saved to: {temp_audio_path}, Size: {file_size} bytes")
        
        try:
            # Transcribe using Whisper
            if stt_model:
                print("[Predict] Processing with Whisper...")
                try:
                    # Load audio with librosa 
                    audio, sr = librosa.load(temp_audio_path, sr=16000)
                    print(f"[Predict] Audio loaded: {len(audio)} samples at {sr}Hz")
                    
                    # Pass audio array directly to Whisper transcribe
                    result = stt_model.transcribe(audio)
                    transcript = result['text'].strip()
                    print(f"[Predict] Whisper result: '{transcript}'")
                except Exception as e:
                    print(f"[Predict] Whisper error: {e}")
                    # If still fails, try with file path one more time
                    try:
                        result = stt_model.transcribe(temp_audio_path)
                        transcript = result['text'].strip()
                        print(f"[Predict] Whisper result (fallback): '{transcript}'")
                    except Exception as e2:
                        print(f"[Predict] Both methods failed: {e2}")
                        transcript = f"[Transcription failed: Could not process audio]"
            else:
                transcript = "[Whisper not available]"
                print("[Predict] Whisper model not loaded")
            
            # Perform scam detection
            is_scam, confidence = detect_scam(transcript)
            print(f"[Predict] Detection: is_scam={is_scam}, confidence={confidence}")
            
            return jsonify({
                'is_scam': is_scam,
                'confidence': confidence,
                'transcript': transcript,
                'message': 'Analysis complete'
            }), 200
        finally:
            # Clean up temp file
            try:
                os.remove(temp_audio_path)
                print("[Predict] Temp file cleaned up")
            except:
                pass
    
    except Exception as e:
        print(f"[Predict] EXCEPTION: {e}")
        import traceback
        traceback.print_exc()
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
            
            print(f"[Stream] Chunk {chunk_index}: Received file '{chunk_file.filename}', size: {len(chunk_file.read())} bytes")
            chunk_file.seek(0)  # Reset file pointer
            
            # Save temporary file
            with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as tmp:
                chunk_file.save(tmp.name)
                temp_audio_path = tmp.name
            
            # Check file size
            file_size = os.path.getsize(temp_audio_path)
            print(f"[Stream] Saved to: {temp_audio_path}, File size: {file_size} bytes")
            
            try:
                # Transcribe audio chunk using Whisper
                transcript = ""
                if stt_model and file_size > 100:  # Only process if file has content
                    try:
                        print(f"[Stream] Processing with Whisper...")
                        result = stt_model.transcribe(temp_audio_path, language='en')
                        transcript = result['text'].strip()
                        print(f"[Stream] Whisper result: '{transcript}'")
                    except Exception as e:
                        print(f"[Stream] Whisper error: {e}")
                        transcript = f"[Error: {str(e)[:50]}]"
                else:
                    transcript = "[No audio data or Whisper unavailable]"
                
                # Perform scam detection on transcript
                is_scam, confidence = detect_scam(transcript)
                
                print(f"[Stream] Scam detection - is_scam: {is_scam}, confidence: {confidence}")
                
                return jsonify({
                    'chunk_index': chunk_index,
                    'is_scam': is_scam,
                    'confidence': confidence,
                    'is_final': is_final,
                    'transcript': transcript
                }), 200
            finally:
                # Clean up temp file
                try:
                    os.remove(temp_audio_path)
                except:
                    pass
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
        print(f"[Stream] Exception: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/detect', methods=['POST'])
def detect():
    """Text-based detection endpoint"""
    try:
        data = request.get_json()
        
        if not data or 'text' not in data:
            return jsonify({'error': 'No text provided'}), 400
        
        text = data.get('text', '').strip()
        
        # Perform scam detection
        is_scam, confidence = detect_scam(text)
        
        print(f"[Detect] Text: '{text}' -> is_scam: {is_scam}, confidence: {confidence}")
        
        return jsonify({
            'is_scam': is_scam,
            'confidence': confidence,
            'text': text,
            'transcript': text  # Return as transcript for compatibility
        }), 200
    
    except Exception as e:
        print(f"[Detect] Exception: {e}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("=" * 50)
    print("Scam Detector API (Whisper Mode)")
    print("=" * 50)
    print("Available Endpoints:")
    print("  GET  /health         - Health check")
    print("  POST /predict        - Full audio analysis with Whisper")
    print("  POST /stream         - Real-time chunk analysis")
    print("  POST /detect         - Text analysis")
    print("=" * 50)
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
