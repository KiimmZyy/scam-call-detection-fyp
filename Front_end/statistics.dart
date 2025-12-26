import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "STATISTICS",
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // 1. SCAM VS LEGIT RATIO (Pie Chart Card)
            _buildCard(
              child: Column(
                children: [
                  const Text(
                    "Scam VS Legit Call Ratio",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), // ⚫ Set to Black
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      children: [
                        // The Chart
                        const SizedBox(
                          height: 120,
                          width: 120,
                          child: CircularProgressIndicator(
                            value: 0.25, // 25% Scam
                            strokeWidth: 25,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                            backgroundColor: Color(0xFF5C6BC0),
                          ),
                        ),
                        // Center Text
                        const Center(
                          child: Text(
                            "Total\n100%",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: Colors.black), // ⚫ Set to Black
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.circle, color: Colors.redAccent, size: 10),
                      SizedBox(width: 5),
                      Text("Scam 25%", style: TextStyle(color: Colors.black)), // ⚫ Set to Black
                      SizedBox(width: 20),
                      Icon(Icons.circle, color: Color(0xFF5C6BC0), size: 10),
                      SizedBox(width: 5),
                      Text("Legit 75%", style: TextStyle(color: Colors.black)), // ⚫ Set to Black
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 2. CALLS PER DAY (Bar Chart Card)
            _buildCard(
              child: Column(
                children: [
                  const Text(
                    "Number Of Calls Per Day",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), // ⚫ Set to Black
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar("MON", 30, Colors.blue),
                      _buildBar("TUE", 60, Colors.red),
                      _buildBar("WED", 40, Colors.blue),
                      _buildBar("THU", 50, Colors.red),
                      _buildBar("FRI", 80, Colors.red),
                      _buildBar("SAT", 70, Colors.blue),
                      _buildBar("SUN", 65, Colors.blue),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 3. TOP KEYWORDS (Word Cloud)
            _buildCard(
              child: Column(
                children: [
                  const Text(
                    "Top Scam Keywords",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), // ⚫ Set to Black
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 15,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: const [
                      Text("Urgent", style: TextStyle(color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold)),
                      Text("Money", style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Verify", style: TextStyle(color: Colors.black, fontSize: 14)), // ⚫ Set to Black
                      Text("Account", style: TextStyle(color: Colors.red, fontSize: 16)),
                      Text("Bank", style: TextStyle(color: Colors.black, fontSize: 14)), // ⚫ Set to Black
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 4. ACCURACY
            _buildCard(
              child: Column(
                children: [
                  const Text(
                    "Detection Accuracy",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black), // ⚫ Set to Black
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "90 %",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black), // ⚫ Set to Black
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // EXPORT BUTTON
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {},
                child: const Text("EXPORT", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper widget for the white cards
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // White-ish grey
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  // Helper widget for a single bar in the bar chart
  Widget _buildBar(String day, double height, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 5),
        // ⚫ Set Bar Labels (MON, TUE) to Black
        Text(day, style: const TextStyle(fontSize: 10, color: Colors.black)),
      ],
    );
  }
}
