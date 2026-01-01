import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'history.dart';   // Import History Page
import 'statistics.dart'; // Import Statistics Page
import 'account.dart';    // Import Account Page
import '../services/recording_service.dart';
import '../services/call_monitor_service.dart';
import '../services/test_audio_service.dart';
import '../providers/api_provider.dart';
import 'package:provider/provider.dart';
import '../models/call_history.dart';
import '../providers/call_history_provider.dart';
import '../widgets/result_bottom_sheet.dart';
import 'package:overlay_support/overlay_support.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Start at index 1 (The Middle "Home" Scan Screen)

  // 📄 The 3 Main Pages for the Bottom Navigation
  final List<Widget> _pages = [
    const HistoryPage(),     // Index 0: History Screen
    const ScanView(),        // Index 1: The Scan UI (Defined below)
    const StatisticsPage(),  // Index 2: Statistics Dashboard
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E121A), Color(0xFF0B1726)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
        // 🎩 APP BAR: Only show the "Profile Icon" AppBar when on the Scan Screen (Index 1)
        appBar: _selectedIndex == 1 ? AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false, // Hides default back button
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0, top: 10.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 30),
                ),
                onPressed: () async {
                  await HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const AccountPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        var offsetAnimation = animation.drive(tween);
                        return SlideTransition(position: offsetAnimation, child: FadeTransition(opacity: animation, child: child));
                      },
                      transitionDuration: const Duration(milliseconds: 300),
                    ),
                  );
                },
              ),
            ),
          ],
        ) : null, // If not on Home screen, no AppBar (History/Stats have their own titles)

        // 🔄 BODY: Switches based on the selected bottom icon
        body: _pages[_selectedIndex],

        // 🦶 BOTTOM NAVIGATION BAR
        bottomNavigationBar: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent, // Transparent so container color shows
            elevation: 0,
            selectedItemColor: const Color(0xFF7CE7FF),
            unselectedItemColor: Colors.white70,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            currentIndex: _selectedIndex,
            iconSize: 30,
            type: BottomNavigationBarType.fixed,
            onTap: (index) async {
              await HapticFeedback.lightImpact();
              setState(() {
                _selectedIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.history), 
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), 
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), 
                label: 'Stats',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 📱 THE SCAN VIEW WIDGET (The content of the middle home screen)
class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> with SingleTickerProviderStateMixin {
  final RecordingService _recordingService = RecordingService();
  final CallMonitorService _callMonitorService = CallMonitorService();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isCallMonitoringActive = false;
  String _statusText = "TAP TO SCAN";
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  double _amplitude = 0.0;
  double _micButtonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCallMonitoring();
  }

  Future<void> _initializeCallMonitoring() async {
    await _callMonitorService.initialize();
    setState(() {
      _isCallMonitoringActive = _callMonitorService.isMonitoring;
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recordingService.dispose();
    super.dispose();
  }

  void _startAmplitudeUpdates() {
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_isRecording) {
        final amp = await _recordingService.getAmplitude();
        setState(() {
          _amplitude = amp;
          _recordingDuration++;
        });
      }
    });
  }

  Future<void> _toggleRecording() async {
    // Prevent manual recording when real-time protection is active
    if (_isCallMonitoringActive) {
      _showError('Disable Real-time Protection to use manual recording.');
      return;
    }
    
    debugPrint('[HOME] Toggle recording called. Current state: $_isRecording');
    
    if (_isRecording) {
      // Stop recording
      debugPrint('[HOME] Stopping recording...');
      setState(() {
        _isProcessing = true;
        _statusText = "PROCESSING...";
      });

      _recordingTimer?.cancel();
      final filePath = await _recordingService.stopRecording();
      
      debugPrint('[HOME] Recording stopped. File path: $filePath');

      if (filePath != null) {
        // Verify file exists and has content
        final file = File(filePath);
        final exists = await file.exists();
        final size = exists ? await file.length() : 0;
        debugPrint('[HOME] File exists: $exists, Size: $size bytes');
        
        // Send to API for analysis
        final apiProvider = Provider.of<ApiProvider>(context, listen: false);
        debugPrint('[HOME] Sending audio to API: $filePath');
        final result = await apiProvider.detectFromAudio(filePath);
        
        debugPrint('[HOME] API Result: $result');

        if (result != null) {
          // Save to database
          final callHistory = CallHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            phoneNumber: 'Unknown', // Will be updated when we get real call data
            dateTime: DateTime.now(),
            transcript: result['transcript'] ?? '',
            isScam: result['is_scam'] ?? false,
            confidence: (result['confidence'] ?? 0).toDouble(),
            audioFilePath: filePath,
          );
          
          final historyProvider = Provider.of<CallHistoryProvider>(context, listen: false);
          await historyProvider.addCallHistory(callHistory);
          
          // Haptic feedback on successful detection
          await HapticFeedback.mediumImpact();
          _showResultDialog(result);
        } else {
          _showError(apiProvider.error ?? 'Failed to analyze audio');
        }
      } else {
        debugPrint('[HOME] ERROR: File path is null!');
        _showError('Failed to save recording. Check microphone and permissions.');
      }

      setState(() {
        _isRecording = false;
        _isProcessing = false;
        _statusText = "TAP TO SCAN";
        _recordingDuration = 0;
        _amplitude = 0.0;
      });
    } else {
      // Start recording
      debugPrint('[HOME] Starting recording...');
      final success = await _recordingService.startRecording();
      debugPrint('[HOME] Start recording result: $success');
      
      if (success) {
        setState(() {
          _isRecording = true;
          _statusText = "RECORDING...";
          _recordingDuration = 0;
        });
        _startAmplitudeUpdates();
      } else {
        _showError('Failed to start recording. Please check microphone permission.');
      }
    }
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final isScam = result['is_scam'] ?? false;
    final confidence = result['confidence'] ?? 0;
    final transcript = result['transcript'] ?? 'No transcript available';

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: ResultBottomSheet(
          isScam: isScam,
          confidence: confidence.toDouble(),
          transcript: transcript,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF5C5C),
      ),
    );
  }

  String _formatDuration() {
    final seconds = (_recordingDuration / 10).floor();
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
                  // Call monitoring toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isCallMonitoringActive ? Icons.shield : Icons.shield_outlined,
                              color: _isCallMonitoringActive ? const Color(0xFF7CE7FF) : Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Real-time Protection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _isCallMonitoringActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: _isCallMonitoringActive ? const Color(0xFF7CE7FF) : Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _isCallMonitoringActive,
                          onChanged: (value) async {
                            await HapticFeedback.lightImpact();
                            if (value) {
                              final apiProvider = Provider.of<ApiProvider>(context, listen: false);
                              final historyProvider = Provider.of<CallHistoryProvider>(context, listen: false);
                              await _callMonitorService.startMonitoring(context, apiProvider, historyProvider);

                              showSimpleNotification(
                                const Text('Real-time call protection enabled',
                                    style: TextStyle(color: Colors.white)),
                                background: const Color(0xFF15C87A),
                                duration: const Duration(seconds: 2),
                              );
                            } else {
                              _callMonitorService.stopMonitoring();

                              showSimpleNotification(
                                const Text('Real-time call protection disabled',
                                    style: TextStyle(color: Colors.white)),
                                background: const Color(0xFFFFB74D),
                                duration: const Duration(seconds: 2),
                              );
                            }
                            setState(() {
                              _isCallMonitoringActive = value;
                              _statusText = value ? "PROTECTION ACTIVE" : "TAP TO SCAN";
                            });
                          },
                          activeColor: const Color(0xFF0F172A),
                          activeTrackColor: const Color(0xFF7CE7FF),
                          inactiveThumbColor: const Color(0xFF101621),
                          inactiveTrackColor: Colors.white24,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // API test button and status
                  const SizedBox(height: 12),

                  // Status Text
                  Text(
                    _statusText,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Recording duration
                  if (_isRecording)
                    Text(
                      _formatDuration(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFFFF5C5C),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 15),

                  // Main Center Content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 🎤 BIG MICROPHONE BUTTON
                      GestureDetector(
                        onTapDown: (_) {
                          if (!_isProcessing && !_isCallMonitoringActive) {
                            setState(() => _micButtonScale = 0.92);
                          }
                        },
                        onTapUp: (_) {
                          if (!_isProcessing && !_isCallMonitoringActive) {
                            setState(() => _micButtonScale = 1.0);
                          }
                        },
                        onTapCancel: () {
                          setState(() => _micButtonScale = 1.0);
                        },
                        onTap: (_isProcessing || _isCallMonitoringActive) ? null : _toggleRecording,
                        child: AnimatedScale(
                          scale: _micButtonScale,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: _isCallMonitoringActive
                                  ? const Color(0xFF1F2937)
                                  : (_isRecording
                                      ? const Color(0xFFFF5C5C)
                                      : (_isProcessing ? const Color(0xFF1F2937) : const Color(0xFF111827))),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording ? const Color(0xFFFF5C5C) : const Color(0xFF7CE7FF)).withOpacity(0.35),
                                  blurRadius: 35,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isCallMonitoringActive
                                  ? Icons.shield
                                  : (_isProcessing ? Icons.hourglass_empty : Icons.mic),
                              size: 84,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 🎵 AUDIO WAVEFORM (iOS-style breathing bars)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording ? const Color(0xFFFF5C5C) : const Color(0xFF7CE7FF)).withOpacity(0.22),
                              blurRadius: 28,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(12, (i) {
                            final base = 0.3 + 0.7 * math.sin((i / 2) + DateTime.now().millisecond / 320);
                            final level = (_amplitude.clamp(0.0, 1.0) + 0.15);
                            final height = 14 + 40 * base * level;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              width: 6,
                              height: height,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: _isRecording
                                      ? [const Color(0xFFFF5C5C), const Color(0xFFFF9A8B)]
                                      : [const Color(0xFF0EA5E9), const Color(0xFF7CE7FF)],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }
}


