import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class TestAudioService {
  // Generate a simple WAV file with some audio data for testing
  // This is a minimal valid WAV file with ~1 second of silence
  static Future<String> getOrCreateTestAudio() async {
    final directory = await getTemporaryDirectory();
    final testAudioPath = '${directory.path}/test_audio.wav';
    final file = File(testAudioPath);

    // If test audio already exists, use it
    if (await file.exists()) {
      print('[TestAudioService] Using existing test audio: $testAudioPath');
      return testAudioPath;
    }

    try {
      // Try to load from assets first
      print('[TestAudioService] Attempting to load test audio from assets...');
      final data = await rootBundle.load('assets/audio/test_audio.wav');
      await file.writeAsBytes(data.buffer.asUint8List());
      print('[TestAudioService] Test audio loaded from assets: $testAudioPath');
      return testAudioPath;
    } catch (e) {
      print('[TestAudioService] Asset not found, creating minimal test WAV: $e');
      // Create a minimal valid WAV file if asset not available
      final wavData = _createMinimalWav();
      await file.writeAsBytes(wavData);
      print('[TestAudioService] Created minimal test WAV: $testAudioPath');
      return testAudioPath;
    }
  }

  // Create a minimal valid WAV header + some audio data
  // WAV format: 44-byte header + audio data
  static List<int> _createMinimalWav() {
    // This creates a very simple WAV file with audio that might register
    // Format: PCM, 16-bit, mono, 16000 Hz, ~2 seconds of audio
    const sampleRate = 16000;
    const channels = 1;
    const bitsPerSample = 16;
    const durationSeconds = 2;
    
    final numSamples = sampleRate * durationSeconds;
    final bytesPerSample = bitsPerSample ~/ 8;
    final audioDataSize = numSamples * channels * bytesPerSample;
    final fileSize = 36 + audioDataSize;

    final header = <int>[];

    // RIFF chunk descriptor
    header.addAll('RIFF'.codeUnits);
    header.addAll(_intToBytes(fileSize, 4)); // file size - 8
    header.addAll('WAVE'.codeUnits);

    // fmt sub-chunk
    header.addAll('fmt '.codeUnits);
    header.addAll(_intToBytes(16, 4)); // subchunk1 size
    header.addAll(_intToBytes(1, 2)); // audio format (1 = PCM)
    header.addAll(_intToBytes(channels, 2)); // num channels
    header.addAll(_intToBytes(sampleRate, 4)); // sample rate
    header.addAll(_intToBytes(sampleRate * channels * bytesPerSample, 4)); // byte rate
    header.addAll(_intToBytes(channels * bytesPerSample, 2)); // block align
    header.addAll(_intToBytes(bitsPerSample, 2)); // bits per sample

    // data sub-chunk
    header.addAll('data'.codeUnits);
    header.addAll(_intToBytes(audioDataSize, 4)); // subchunk2 size

    // Add some audio data (sine wave-like pattern to have non-zero amplitude)
    final audioData = <int>[];
    for (int i = 0; i < numSamples; i++) {
      // Generate a simple sine wave pattern
      final sample = (32767 * 0.3 * ((i % 100) / 100)).toInt();
      audioData.addAll(_intToBytes(sample, 2, signed: true));
    }

    return header + audioData;
  }

  static List<int> _intToBytes(int value, int bytes, {bool signed = false}) {
    final result = <int>[];
    for (int i = 0; i < bytes; i++) {
      result.add((value >> (i * 8)) & 0xFF);
    }
    return result;
  }
}
