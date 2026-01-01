import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'edit_profile.dart';
import 'change_password.dart';
import 'login.dart';
import '../providers/auth_provider.dart';
import '../providers/api_provider.dart';
import '../providers/call_history_provider.dart';
import '../services/test_audio_service.dart';
import '../widgets/result_bottom_sheet.dart';
import '../models/call_history.dart';
import 'package:overlay_support/overlay_support.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _textController = TextEditingController();
  bool _apiTesting = false;
  bool? _apiOnline;
  bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
      background: ok ? const Color(0xFF15C87A) : const Color(0xFFFF5C5C),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _testAudioFromAsset() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final testAudioPath = await TestAudioService.getOrCreateTestAudio();
      final file = File(testAudioPath);
      final exists = await file.exists();
      final size = exists ? await file.length() : 0;

      if (!exists || size == 0) {
        _showError('Failed to create test audio file');
        return;
      }

      final apiProvider = Provider.of<ApiProvider>(context, listen: false);
      final result = await apiProvider.detectFromAudio(testAudioPath);

      if (result != null) {
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

        _showResultDialog(result);
      } else {
        _showError(apiProvider.error ?? 'Failed to analyze test audio');
      }
    } catch (e) {
      _showError('Test failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _detectFromText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter some text to analyze');
      return;
    }

    setState(() {
      _isProcessing = true;
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
      _showError('Failed to analyze text: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
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
        backgroundColor: const Color(0xFFFF5C5C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E121A), Color(0xFF0B1726)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Account",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0EA5E9), Color(0xFF7CE7FF)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7CE7FF).withOpacity(0.3),
                                blurRadius: 25,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          authProvider.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    "Account Settings",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuButton(context, "Edit Profile", Icons.edit, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfilePage()),
                    );
                  }),
                  _buildMenuButton(context, "Change Password", Icons.lock_outline, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                    );
                  }),

                  const SizedBox(height: 24),
                  const Text(
                    "Testing Tools",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // API Test
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "API Connection",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _apiTesting ? null : _testApi,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.08),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                ),
                              ),
                              icon: Icon(_apiTesting ? Icons.hourglass_bottom : Icons.wifi, size: 18),
                              label: Text(_apiTesting ? 'Testing…' : 'Test API'),
                            ),
                            const SizedBox(width: 12),
                            if (_apiOnline != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _apiOnline! ? const Color(0xFF15C87A) : const Color(0xFFFF5C5C),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _apiOnline! ? 'Online' : 'Offline',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Test Audio
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Audio Testing (Emulator)",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Test the audio pipeline without a real microphone",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _testAudioFromAsset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.audiotrack, size: 18),
                            label: Text(_isProcessing ? 'Testing...' : 'Run Test Audio'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Text Detection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Text Detection",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Test scam detection with text input",
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Type a message to analyze...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF7CE7FF), width: 1.5),
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
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isProcessing ? 'Analyzing...' : 'Analyze Text',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    "Actions",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuButton(context, "Log Out", Icons.logout, () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1F2937),
                        title: const Text('Logout', style: TextStyle(color: Colors.white)),
                        content: const Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout', style: TextStyle(color: Color(0xFFFF5C5C))),
                          ),
                        ],
                      ),
                    );

                    if (shouldLogout == true && context.mounted) {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    }
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}