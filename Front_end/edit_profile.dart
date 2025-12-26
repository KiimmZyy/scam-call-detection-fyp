import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("EDIT PROFILE", style: TextStyle(color: Colors.white, fontFamily: 'serif')),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: Colors.black),
            ),
            const SizedBox(height: 40),
            
            _buildLabel("NAME"),
            _buildInput("Siti Nur Aimi binti Amir"),
            const SizedBox(height: 20),
            
            _buildLabel("EMAIL"),
            _buildInput("sitiaimi@gmail.com"),
            const SizedBox(height: 20),
            
            _buildLabel("PHONE NUMBER"),
            _buildInput("013-5792468"),
            const SizedBox(height: 40),

            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("SAVE", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5, left: 5),
        child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }

  Widget _buildInput(String initialValue) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFD9D9D9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
