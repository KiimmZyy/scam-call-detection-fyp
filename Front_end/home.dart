import 'package:flutter/material.dart';
import 'dart:developer'; // For logging
import 'history.dart';   // Import History Page
import 'statistics.dart'; // Import Statistics Page
import 'account.dart';    // Import Account Page

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
              onPressed: () {
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
          onTap: (index) {
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
class ScanView extends StatelessWidget {
  const ScanView({super.key});

  @override
  Widget build(BuildContext context) {
    // SizedBox with width: double.infinity ensures content is CENTERED
    return SizedBox(
      width: double.infinity, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // "TAP TO SCAN" Text
          const Text(
            "TAP TO SCAN",
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 40),

          // Main Center Content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🎤 BIG MICROPHONE BUTTON
                GestureDetector(
                  onTap: () {
                    log("Mic tapped"); // Logs to console
                  },
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9D9D9), // Light Grey Circle
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic,
                      size: 100,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // 🎵 AUDIO WAVE ICON (Small)
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD9D9D9), 
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.graphic_eq,
                    size: 60,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

