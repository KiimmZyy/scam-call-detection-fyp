import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'providers/api_provider.dart';
import 'providers/call_history_provider.dart';
import 'providers/auth_provider.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  // Request critical permissions upfront
  await _requestPermissions();
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  final permissions = [
    Permission.microphone,
    Permission.phone,
    Permission.notification,
  ];
  await Future.wait(permissions.map((p) => p.request()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiProvider()),
        ChangeNotifierProvider(create: (_) => CallHistoryProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: OverlaySupport.global(
        child: MaterialApp(
          title: 'Scam Detector',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0E121A),
            primaryColor: const Color(0xFF0EA5E9),
            useMaterial3: true,
            textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF0EA5E9),
              secondary: const Color(0xFF7CE7FF),
              surface: const Color(0xFF111827),
              error: const Color(0xFFFF5C5C),
              onPrimary: Colors.white,
              onSurface: Colors.white,
            ),
          ),
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return authProvider.isAuthenticated
            ? const HomePage()
            : const LoginPage();
      },
    );
  }
}

