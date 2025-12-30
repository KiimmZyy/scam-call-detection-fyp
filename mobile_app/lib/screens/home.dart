import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
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
    return Scaffold(
      backgroundColor: Colors.black,
      
      // 🎩 APP BAR: Only show the "Profile Icon" AppBar when on the Scan Screen (Index 1)
      appBar: _selectedIndex == 1 ? AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false, // Hides default back button
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0, top: 10.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: Colors.black, size: 30),
              ),
              onPressed: () async {
                // Haptic feedback on profile button tap
                await HapticFeedback.lightImpact();
                // 🚀 NAVIGATE TO ACCOUNT PAGE
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountPage()),
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
        decoration: const BoxDecoration(
          color: Color(0xFF5C6BC0), // The purple background color
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // Transparent so container color shows
          elevation: 0,
          selectedItemColor: Colors.black,    // Active Icon Color
          unselectedItemColor: Colors.black54, // Inactive Icon Color
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          iconSize: 35,
          type: BottomNavigationBarType.fixed,
          onTap: (index) async {
            // Haptic feedback on navigation
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
    );
  }
}

// 📱 THE SCAN VIEW WIDGET (The content of the middle home screen)
class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  final RecordingService _recordingService = RecordingService();
  final CallMonitorService _callMonitorService = CallMonitorService();
  final TextEditingController _textController = TextEditingController();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isCallMonitoringActive = false;
  bool _apiTesting = false;
  bool? _apiOnline;
  String _statusText = "TAP TO SCAN";
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  double _amplitude = 0.0;

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

  Future<void> _testApi() async {
    setState(() {
      _apiTesting = true;
    });
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    final ok = await apiProvider.testConnection();
    setState(() {
      _apiOnline = ok;
      _apiTesting = false;
    });
    showSimpleNotification(
      Text(ok ? 'API online' : 'API offline', style: const TextStyle(color: Colors.white)),
      background: ok ? Colors.green : Colors.red,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recordingService.dispose();
    _textController.dispose();
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
      builder: (context) => ResultBottomSheet(
        isScam: isScam,
        confidence: confidence.toDouble(),
        transcript: transcript,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _detectFromText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter some text to analyze');
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusText = "ANALYZING...";
    });

    try {
      final apiProvider = Provider.of<ApiProvider>(context, listen: false);
      final result = await apiProvider.detectFromText(text);

      if (result == null) {
        throw Exception('No response from server');
      }

      _showResultDialog(result);
      _textController.clear();
    } catch (e) {
      debugPrint('[HOME] Error detecting from text: $e');
      _showError('Failed to analyze text: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _statusText = "TAP TO SCAN";
      });
    }
  }

  Future<void> _testAudioFromAsset() async {
    debugPrint('[HOME] Testing with asset audio...');
    setState(() {
      _isProcessing = true;
      _statusText = "TESTING AUDIO...";
    });

    try {
      // Get or create test audio
      final testAudioPath = await TestAudioService.getOrCreateTestAudio();
      debugPrint('[HOME] Test audio path: $testAudioPath');

      // Verify file exists and has content
      final file = File(testAudioPath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;
      debugPrint('[HOME] Test file exists: $exists, Size: $size bytes');

      if (!exists || size == 0) {
        _showError('Failed to create test audio file');
        return;
      }

      // Send to API for analysis
      final apiProvider = Provider.of<ApiProvider>(context, listen: false);
      debugPrint('[HOME] Sending test audio to API: $testAudioPath');
      final result = await apiProvider.detectFromAudio(testAudioPath);

      debugPrint('[HOME] Test audio API Result: $result');

      if (result != null) {
        // Save to database
        final callHistory = CallHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          phoneNumber: 'Test Call',
          dateTime: DateTime.now(),
          transcript: result['transcript'] ?? '',
          isScam: result['is_scam'] ?? false,
          confidence: (result['confidence'] ?? 0).toDouble(),
          audioFilePath: testAudioPath,
        );

        final historyProvider = Provider.of<CallHistoryProvider>(context, listen: false);
        await historyProvider.addCallHistory(callHistory);

        await HapticFeedback.mediumImpact();
        _showResultDialog(result);
      } else {
        _showError(apiProvider.error ?? 'Failed to analyze test audio');
      }
    } catch (e) {
      debugPrint('[HOME] Error testing audio: $e');
      _showError('Test failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _statusText = "TAP TO SCAN";
      });
    }
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
      backgroundColor: Colors.black,
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Call monitoring toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isCallMonitoringActive ? Icons.shield : Icons.shield_outlined,
                              color: _isCallMonitoringActive ? Colors.green : Colors.white54,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Real-time Protection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _isCallMonitoringActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: _isCallMonitoringActive ? Colors.green : Colors.white54,
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
                                background: Colors.green,
                                duration: const Duration(seconds: 2),
                              );
                            } else {
                              _callMonitorService.stopMonitoring();

                              showSimpleNotification(
                                const Text('Real-time call protection disabled',
                                    style: TextStyle(color: Colors.white)),
                                background: Colors.orange,
                                duration: const Duration(seconds: 2),
                              );
                            }
                            setState(() {
                              _isCallMonitoringActive = value;
                              _statusText = value ? "PROTECTION ACTIVE" : "TAP TO SCAN";
                            });
                          },
                          activeColor: Colors.green,
                          activeTrackColor: Colors.green.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // API test button and status
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _apiTesting ? null : _testApi,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5C6BC0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: Icon(_apiTesting ? Icons.hourglass_bottom : Icons.wifi),
                              label: Text(_apiTesting ? 'Testing…' : 'Test API'),
                            ),
                            const SizedBox(width: 12),
                            if (_apiOnline != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _apiOnline! ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _apiOnline! ? 'Online' : 'Offline',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Test audio button (for emulator testing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _testAudioFromAsset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.audiotrack),
                            label: const Text('Test Audio (Emulator)'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Status Text
                  Text(
                    _statusText,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // TEXT INPUT SECTION - MOVED UP FOR VISIBILITY
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Or enter text to test:',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _textController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Type a text message to analyze...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.08),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF5C6BC0), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _detectFromText,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5C6BC0),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _isProcessing ? 'Analyzing...' : 'Analyze Text',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Recording duration
                  if (_isRecording)
                    Text(
                      _formatDuration(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.red,
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
                        onTap: (_isProcessing || _isCallMonitoringActive) ? null : _toggleRecording,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: _isCallMonitoringActive
                                ? Colors.grey
                                : (_isRecording
                                    ? Colors.red.withOpacity(0.8)
                                    : (_isProcessing ? Colors.grey : const Color(0xFFD9D9D9))),
                            shape: BoxShape.circle,
                            boxShadow: _isRecording
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isCallMonitoringActive
                                ? Icons.shield
                                : (_isProcessing ? Icons.hourglass_empty : Icons.mic),
                            size: 90,
                            color: _isCallMonitoringActive
                                ? Colors.white
                                : (_isRecording ? Colors.white : Colors.black),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // 🎵 AUDIO WAVE ICON (Visual feedback)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? const Color(0xFF5C6BC0).withOpacity(0.6)
                              : const Color(0xFFD9D9D9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.graphic_eq,
                          size: 50,
                          color: _isRecording ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


