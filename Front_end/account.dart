import 'package:flutter/material.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'login.dart'; // To handle logout

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("ACCOUNT", style: TextStyle(color: Colors.white, fontFamily: 'serif')),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Big Profile Icon
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 80, color: Colors.black),
              ),
              const SizedBox(height: 20),
              const Text("AIMI", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif')),
              const SizedBox(height: 50),

              // Menu Buttons
              _buildMenuButton(context, "EDIT PROFILE", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage()));
              }),
              _buildMenuButton(context, "CHANGE PASSWORD", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordPage()));
              }),
              _buildMenuButton(context, "LOG OUT", () {
                // Return to Login Page
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE0E0E0), // Light grey
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Icon(Icons.arrow_forward, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
