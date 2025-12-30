import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/call_history_provider.dart';
import '../widgets/empty_state.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  Map<String, int> _getCallsPerDay(CallHistoryProvider provider) {
    final calls = provider.getRecentCalls(days: 7);
    final Map<String, int> callsPerDay = {
      'MON': 0,
      'TUE': 0,
      'WED': 0,
      'THU': 0,
      'FRI': 0,
      'SAT': 0,
      'SUN': 0,
    };

    for (var call in calls) {
      final day = DateFormat('EEE').format(call.dateTime).toUpperCase();
      final key = day.substring(0, 3);
      callsPerDay[key] = (callsPerDay[key] ?? 0) + 1;
    }

    return callsPerDay;
  }

  Map<String, int> _extractKeywords(CallHistoryProvider provider) {
    final scamCalls = provider.getScamCalls();
    final Map<String, int> keywords = {};
    
    final commonScamWords = [
      'urgent', 'money', 'verify', 'account', 'bank', 'confirm', 
      'security', 'password', 'credit', 'card', 'suspended', 'blocked',
      'win', 'prize', 'congratulations', 'click', 'link', 'immediately'
    ];

    for (var call in scamCalls) {
      final words = call.transcript.toLowerCase().split(' ');
      for (var word in words) {
        word = word.replaceAll(RegExp(r'[^\w]'), '');
        if (commonScamWords.contains(word) && word.isNotEmpty) {
          keywords[word] = (keywords[word] ?? 0) + 1;
        }
      }
    }

    return keywords;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CallHistoryProvider>(
        builder: (context, historyProvider, child) {
          final stats = historyProvider.statistics;
          final totalCalls = stats['totalCalls'] ?? 0;
          final scamPercentage = stats['scamPercentage'] ?? 0.0;
          final legitPercentage = stats['legitPercentage'] ?? 0.0;
          final callsPerDay = _getCallsPerDay(historyProvider);
          final keywords = _extractKeywords(historyProvider);
          final topKeywords = keywords.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Show full empty state if no data at all
          if (totalCalls == 0) {
            return SafeArea(
              child: EmptyState(
                icon: Icons.bar_chart_outlined,
                title: 'No Statistics Available',
                subtitle: 'Tap the Home button below to start scanning calls and build your statistics',
              ),
            );
          }

          return SingleChildScrollView(
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
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      totalCalls == 0
                          ? const Text(
                              "No data yet",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            )
                          : SizedBox(
                              height: 120,
                              width: 120,
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: 120,
                                    width: 120,
                                    child: CircularProgressIndicator(
                                      value: scamPercentage / 100,
                                      strokeWidth: 25,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                                      backgroundColor: const Color(0xFF5C6BC0),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      "Total\n$totalCalls",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10, color: Colors.black),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.circle, color: Colors.redAccent, size: 10),
                          const SizedBox(width: 5),
                          Text(
                            "Scam ${scamPercentage.toStringAsFixed(0)}%",
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(width: 20),
                          const Icon(Icons.circle, color: Color(0xFF5C6BC0), size: 10),
                          const SizedBox(width: 5),
                          Text(
                            "Legit ${legitPercentage.toStringAsFixed(0)}%",
                            style: const TextStyle(color: Colors.black),
                          ),
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
                        "Number Of Calls Per Day (Last 7 Days)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar("MON", callsPerDay['MON']!.toDouble(), const Color(0xFF5C6BC0)),
                          _buildBar("TUE", callsPerDay['TUE']!.toDouble(), const Color(0xFF5C6BC0)),
                          _buildBar("WED", callsPerDay['WED']!.toDouble(), const Color(0xFF5C6BC0)),
                          _buildBar("THU", callsPerDay['THU']!.toDouble(), const Color(0xFF5C6BC0)),
                          _buildBar("FRI", callsPerDay['FRI']!.toDouble(), const Color(0xFF5C6BC0)),
                          _buildBar("SAT", callsPerDay['SAT']!.toDouble(), const Color(0xFF5C6BC0)),
                          _buildBar("SUN", callsPerDay['SUN']!.toDouble(), const Color(0xFF5C6BC0)),
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
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 15),
                      topKeywords.isEmpty
                          ? const Text(
                              "No scam calls detected yet",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            )
                          : Wrap(
                              spacing: 15,
                              runSpacing: 10,
                              alignment: WrapAlignment.center,
                              children: topKeywords.take(5).map((entry) {
                                final size = 14.0 + (entry.value * 4.0).clamp(0.0, 12.0);
                                return Text(
                                  entry.key.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: size,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // 4. ACCURACY (Average Confidence)
                _buildCard(
                  child: Column(
                    children: [
                      const Text(
                        "Average Detection Confidence",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        totalCalls == 0
                            ? "No data"
                            : "${(historyProvider.callHistory.map((c) => c.confidence).reduce((a, b) => a + b) / totalCalls).toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
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
          );
        },
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  Widget _buildBar(String day, double count, Color color) {
    final height = count == 0 ? 5.0 : (count * 15.0).clamp(5.0, 80.0);
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
        Text(day, style: const TextStyle(fontSize: 10, color: Colors.black)),
      ],
    );
  }
}
