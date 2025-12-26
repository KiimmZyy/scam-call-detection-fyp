import 'package:flutter/material.dart';
import 'call_details.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            "HISTORY",
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildHistoryCard(context, "AIMAN", "JUST NOW", "00:05", true),       // Legit
                _buildHistoryCard(context, "012-3456789", "TODAY", "02:15", false),   // Scam (Red)
                _buildHistoryCard(context, "AINA", "YESTERDAY", "05:00", true),       // Legit
                _buildHistoryCard(context, "019-8765432", "2 DAYS AGO", "01:20", false), // Scam (Red)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, String name, String time, String duration, bool isLegit) {
    return GestureDetector(
      onTap: () {
        // Navigate to Details Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallDetailsPage(
              name: name,
              date: "20 APRIL 2024", // Hardcoded for demo
              duration: duration,
              isScam: !isLegit, // Pass true if it IS a scam
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), // White-ish card
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // Avatar Icon
            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.black87,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 15),
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isLegit ? Colors.black : Colors.red, // Red name if scam
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 16),
          ],
        ),
      ),
    );
  }
}
