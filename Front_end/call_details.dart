import 'package:flutter/material.dart';

class CallDetailsPage extends StatelessWidget {
  final String name;
  final String date;
  final String duration;
  final bool isScam; // Controls if it's the RED or GREEN screen

  const CallDetailsPage({
    super.key,
    required this.name,
    required this.date,
    required this.duration,
    required this.isScam,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Theme Logic: Set colors based on scam status
    final themeColor = isScam ? Colors.redAccent : Colors.green;
    final statusTitle = isScam ? "SCAM DETECTED" : "LEGIT CALL";
    final statusIcon = isScam ? Icons.warning_amber_rounded : Icons.thumb_up_alt_outlined;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("CALL DETAILS", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ---------------------------------------------
            // 1. STATUS CARD (White Box)
            // ---------------------------------------------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5), // White-ish grey
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: Colors.black, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        statusTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black54),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      text: "Hi, is this Miss Aimi? ",
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      children: [
                        if (isScam) ...[
                          const TextSpan(text: "Your account has been "),
                          const TextSpan(
                            text: "compromised",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ". Please provide your "),
                          const TextSpan(
                            text: "login details",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: "."),
                        ] else ...[
                           const TextSpan(text: "Please pay now your university fees before due date."),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------------------------------------------
            // 2. SCAM LIKELIHOOD BAR
            // ---------------------------------------------
            _buildSectionLabel("SCAM LIKELIHOOD"),
            const SizedBox(height: 5),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: isScam ? 85 : 10, // 85% width if scam, 10% if legit
                    child: Container(
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: isScam ? 15 : 90,
                    child: const SizedBox(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      isScam ? "85%" : "10%",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---------------------------------------------
            // 3. SENTIMENT & KEYWORDS
            // ---------------------------------------------
            _buildInfoRow("SENTIMENT ANALYSIS", isScam ? "NEGATIVE" : "POSITIVE"),
            const SizedBox(height: 20),
            _buildSectionLabel("SCAM KEYWORDS"),
            const SizedBox(height: 5),
             Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isScam ? "compromised       login details" : "-                   -",
                style: TextStyle(
                  color: isScam ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---------------------------------------------
            // 4. CALL INFORMATION
            // ---------------------------------------------
            _buildInfoRow("DURATION", duration),
            const SizedBox(height: 10),
            _buildInfoRow("DATE", date),
            const SizedBox(height: 30),

            // ---------------------------------------------
            // 5. EXPORT BUTTON
            // ---------------------------------------------
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0), // Purple color
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {},
                child: const Text("EXPORT", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
