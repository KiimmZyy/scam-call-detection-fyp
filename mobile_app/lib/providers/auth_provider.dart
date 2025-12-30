import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _username = '';
  String _error = '';

  bool get isAuthenticated => _isAuthenticated;
  String get username => _username;
  String get error => _error;

  // Initialize and check if user is already logged in
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _username = prefs.getString('username') ?? '';
    notifyListeners();
  }

  // Login with username and password
  Future<bool> login(String username, String password) async {
    _error = '';
    
    // Validate input
    if (username.isEmpty || password.isEmpty) {
      _error = 'Please enter both username and password';
      notifyListeners();
      return false;
    }

    // Simple validation - in production, this would call a backend API
    // For demo purposes, accept any username with password length >= 6
    if (password.length < 6) {
      _error = 'Password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    // Simulate authentication
    try {
      // In a real app, you would call an API here
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAuthenticated', true);
      await prefs.setString('username', username);
      
      _isAuthenticated = true;
      _username = username;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isAuthenticated');
    await prefs.remove('username');
    
    _isAuthenticated = false;
    _username = '';
    notifyListeners();
  }

  // Change password (for demonstration)
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _error = '';
    
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      _error = 'Please enter both old and new password';
      notifyListeners();
      return false;
    }

    if (newPassword.length < 6) {
      _error = 'New password must be at least 6 characters';
      notifyListeners();
      return false;
    }

    // In a real app, you would verify old password and update via API
    try {
      await Future.delayed(const Duration(seconds: 1));
      _error = '';
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to change password. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
