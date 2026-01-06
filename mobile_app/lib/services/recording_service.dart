import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  // Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Check if we have permission
  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  // Start recording with retry logic
  Future<bool> startRecording({int maxRetries = 3}) async {
    try {
      print('[RecordingService] Starting recording...');
      
      // Check and request permission
      final hasPermission = await Permission.microphone.isGranted;
      if (!hasPermission) {
        print('[RecordingService] Requesting microphone permission...');
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          print('[RecordingService] Microphone permission DENIED');
          throw Exception('Microphone permission denied');
        }
      }

      // Create file path for recording (use temp directory - no permission needed)
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.wav';
      
      print('[RecordingService] Recording path: $_currentRecordingPath');
      print('[RecordingService] Temp directory: ${directory.path}');

      // Retry logic for starting recording
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('[RecordingService] Attempt $attempt/$maxRetries to start recording');
          
          // Stop any existing recording before starting new one
          if (_isRecording) {
            await _recorder.stop();
          }
          
          // Use wav encoder with audio enhancements
          await _recorder.start(
            RecordConfig(
              encoder: AudioEncoder.wav,  // WAV is universal and supported
              bitRate: 128000,
              sampleRate: 16000,  // 16kHz for speech
              numChannels: 1,  // Mono is sufficient for speech
              echoCancel: false,  // Disable to preserve voice
              noiseSuppress: false,  // Disable to preserve voice  
              autoGain: true,  // Keep auto-gain for consistent levels
            ),
            path: _currentRecordingPath!,
          );

          _isRecording = true;
          print('[RecordingService] Recording STARTED successfully on attempt $attempt');
          return true;
        } catch (retryError) {
          print('[RecordingService] Attempt $attempt failed: $retryError');
          if (attempt < maxRetries) {
            // Wait before retry
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            rethrow;
          }
        }
      }
      return false;
    } catch (e) {
      print('[RecordingService] ERROR starting recording after retries: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      return false;
    }
  }

  // Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      print('[RecordingService] Stopping recording...');
      final path = await _recorder.stop();
      _isRecording = false;
      
      final finalPath = path ?? _currentRecordingPath;
      print('[RecordingService] Recording stopped. Path: $finalPath');
      
      if (finalPath != null) {
        final file = File(finalPath);
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;
        print('[RecordingService] File exists: $exists, Size: $size bytes');
      }
      
      return finalPath;
    } catch (e) {
      print('[RecordingService] Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  // Cancel recording and delete the file
  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _isRecording = false;
      _currentRecordingPath = null;
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  // Pause recording
  Future<void> pauseRecording() async {
    if (_isRecording) {
      await _recorder.pause();
    }
  }

  // Resume recording
  Future<void> resumeRecording() async {
    if (_isRecording) {
      await _recorder.resume();
    }
  }

  // Get current amplitude (for visualizing audio)
  Future<double> getAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      return amplitude.current;
    } catch (e) {
      return 0.0;
    }
  }

  // Dispose
  void dispose() {
    _recorder.dispose();
  }
}
