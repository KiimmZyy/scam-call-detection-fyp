import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiProvider extends ChangeNotifier {
  // Using host Wi-Fi IPv4 so physical devices/emulators can reach the backend
  static const String apiUrl = 'http://172.20.10.2:5000';

  bool isLoading = false;
  String? error;
  Map<String, dynamic>? lastResult;

  // Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      error = 'Cannot connect to API: $e';
      notifyListeners();
      return false;
    }
  }

  // Detect scam from text only
  Future<Map<String, dynamic>?> detectFromText(String text) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        lastResult = jsonDecode(response.body);
        isLoading = false;
        notifyListeners();
        return lastResult;
      } else {
        error = 'API Error: ${response.statusCode}';
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      error = 'Error: $e';
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Detect scam from audio file
  Future<Map<String, dynamic>?> detectFromAudio(String filePath) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$apiUrl/predict'))
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        lastResult = jsonDecode(responseBody);
        isLoading = false;
        notifyListeners();
        return lastResult;
      } else {
        error = 'API Error: ${response.statusCode}';
        isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      error = 'Error: $e';
      isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Stream audio chunks for real-time detection
  Future<Map<String, dynamic>?> streamAudioChunk(
    String filePath,
    int chunkIndex,
    bool isFinal,
  ) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$apiUrl/stream'))
        ..files.add(await http.MultipartFile.fromPath('chunk', filePath))
        ..fields['chunk_index'] = chunkIndex.toString()
        ..fields['is_final'] = isFinal.toString();

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        error = 'Stream API Error: ${response.statusCode}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      error = 'Stream Error: $e';
      notifyListeners();
      return null;
    }
  }
}
