import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import '../models/call_history.dart';
import '../providers/api_provider.dart';
import '../providers/call_history_provider.dart';
import '../services/recording_service.dart';

class CallMonitorService {
  static final CallMonitorService _instance = CallMonitorService._internal();
  factory CallMonitorService() => _instance;
  CallMonitorService._internal();

  final RecordingService _recordingService = RecordingService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  PhoneState? _lastPhoneState;
  String? _currentCallNumber;
  bool _isMonitoring = false;
  Timer? _analysisTimer;
  String? _currentRecordingPath;
  int _chunkIndex = 0;
  bool _callActive = false;
  bool _isAnalyzing = false;

  Future<void> initialize() async {
    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);

    // Request permissions
    await _requestPermissions();
  }

  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.microphone,
      Permission.storage,
      Permission.notification,
      Permission.systemAlertWindow,
    ];

    for (var permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        debugPrint('Permission denied: $permission');
        return false;
      }
    }
    return true;
  }

  Future<void> startMonitoring(BuildContext context, ApiProvider apiProvider, 
      CallHistoryProvider historyProvider) async {
    if (_isMonitoring) return;

    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      _showNotification('Permissions Required', 
          'Please grant all permissions to monitor calls');
      return;
    }

    _isMonitoring = true;
    
    // Set up phone state listener
    PhoneState.stream.listen((phoneState) async {
      await _handlePhoneStateChange(phoneState, context, apiProvider, historyProvider);
    });

    _showNotification('Scam Detector Active', 
        'Monitoring calls for scam detection');
  }

  Future<void> _handlePhoneStateChange(PhoneState phoneState, BuildContext context,
      ApiProvider apiProvider, CallHistoryProvider historyProvider) async {
    
    debugPrint('Phone state changed: ${phoneState.status}');
    
    switch (phoneState.status) {
      case PhoneStateStatus.CALL_STARTED:
      case PhoneStateStatus.CALL_INCOMING:
        _currentCallNumber = phoneState.number ?? 'Unknown';
        await _startCallRecording(context, apiProvider, historyProvider);
        break;
        
      case PhoneStateStatus.CALL_ENDED:
        await _stopCallRecording(apiProvider, historyProvider);
        break;
        
      default:
        break;
    }
    
    _lastPhoneState = phoneState;
  }

  Future<void> _startCallRecording(BuildContext context, ApiProvider apiProvider,
      CallHistoryProvider historyProvider) async {
    debugPrint('Starting call recording for: $_currentCallNumber');
    _chunkIndex = 0;
    _callActive = true;
    
    final success = await _recordingService.startRecording();
    if (!success) {
      _showNotification('Recording Failed', 
          'Unable to record call. Check permissions.');
      return;
    }

    // Show overlay notification
    showSimpleNotification(
      const Text('Recording call...', style: TextStyle(color: Colors.white)),
      background: const Color(0xFF5C6BC0),
      duration: const Duration(seconds: 3),
    );

    // Start periodic analysis (every 5 seconds)
    _analysisTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _analyzeCallInProgress(context, apiProvider);
    });
  }

  Future<void> _analyzeCallInProgress(BuildContext context, 
      ApiProvider apiProvider) async {
    if (!_callActive || _isAnalyzing) return;
    _isAnalyzing = true;

    // Stop current recording temporarily to get a chunk
    final tempPath = await _recordingService.stopRecording();
    if (tempPath == null) {
      _isAnalyzing = false;
      return;
    }

    // Stream the chunk for near real-time detection
    final result = await apiProvider.streamAudioChunk(
      tempPath,
      _chunkIndex,
      false,
    );

    if (result != null && result['is_scam'] == true) {
      final confidence = (result['confidence'] ?? 0).toDouble();

      // Show urgent scam warning
      _showScamAlert(confidence);

      // Overlay warning
      showSimpleNotification(
        Text(
          '⚠️ POSSIBLE SCAM DETECTED! Confidence: ${confidence.toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        background: Colors.red,
        duration: const Duration(seconds: 10),
      );
    }

    // Clean up chunk file
    try {
      final file = File(tempPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    _chunkIndex++;

    // Resume recording a fresh chunk
    await _recordingService.startRecording();
    _isAnalyzing = false;
  }

  Future<void> _stopCallRecording(ApiProvider apiProvider, 
      CallHistoryProvider historyProvider) async {
    debugPrint('Stopping call recording');
    _callActive = false;
    
    _analysisTimer?.cancel();
    _analysisTimer = null;

    final filePath = await _recordingService.stopRecording();
    if (filePath == null) return;

    _currentRecordingPath = filePath;

    // Final stream chunk to close the loop
    await apiProvider.streamAudioChunk(filePath, _chunkIndex, true);
    _chunkIndex = 0;

    // Final analysis
    final result = await apiProvider.detectFromAudio(filePath);
    
    if (result != null) {
      // Save to database
      final callHistory = CallHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        phoneNumber: _currentCallNumber ?? 'Unknown',
        dateTime: DateTime.now(),
        transcript: result['transcript'] ?? '',
        isScam: result['is_scam'] ?? false,
        confidence: (result['confidence'] ?? 0).toDouble(),
        audioFilePath: filePath,
      );
      
      await historyProvider.addCallHistory(callHistory);

      // Show final result notification
      final isScam = result['is_scam'] ?? false;
      _showNotification(
        isScam ? '⚠️ Scam Call Detected' : '✓ Call Verified Safe',
        isScam 
            ? 'This call was flagged as a potential scam'
            : 'No scam indicators detected in this call',
      );
    }

    _currentCallNumber = null;
    _currentRecordingPath = null;
  }

  Future<void> _showScamAlert(double confidence) async {
    const androidDetails = AndroidNotificationDetails(
      'scam_alert',
      'Scam Alerts',
      channelDescription: 'Real-time scam detection alerts',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('scam_alert'),
      color: Colors.red,
      ledColor: Colors.red,
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      999,
      '⚠️ SCAM WARNING!',
      'This call may be a scam! Confidence: ${confidence.toStringAsFixed(1)}%',
      notificationDetails,
    );
  }

  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'call_monitor',
      'Call Monitoring',
      channelDescription: 'Call monitoring status notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 1000,
      title,
      body,
      notificationDetails,
    );
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _analysisTimer?.cancel();
    _showNotification('Scam Detector Stopped', 
        'Call monitoring has been disabled');
  }

  bool get isMonitoring => _isMonitoring;
}
