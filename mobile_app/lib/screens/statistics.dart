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

  Map<String, int> _getCallsPerDayDynamic(List<DateTime> dates) {
    final Map<String, int> result = {};
    for (var i = 0; i < 7; i++) {
      final d = DateTime.now().subtract(Duration(days: 6 - i));
      final key = DateFormat('EEE').format(d).toUpperCase();
      result[key] = 0;
    }
    for (final dt in dates) {
      final key = DateFormat('EEE').format(dt).toUpperCase();
      if (result.containsKey(key)) {
        result[key] = (result[key] ?? 0) + 1;
      }
    }
    return result;
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
        body: Consumer<CallHistoryProvider>(
          builder: (context, historyProvider, child) {
            final stats = historyProvider.statistics;
            final calls = historyProvider.callHistory;
            final totalCalls = stats['totalCalls'] ?? 0;
            final scamPercentage = stats['scamPercentage'] ?? 0.0;
            final legitPercentage = stats['legitPercentage'] ?? 0.0;
            final scamCount = stats['scamCalls'] ?? 0;
            final legitCount = stats['legitCalls'] ?? 0;
            final avgConfidence = totalCalls == 0
                ? 0
                : calls.map((c) => c.confidence).reduce((a, b) => a + b) / totalCalls;
            final recentCalls = historyProvider.getRecentCalls(days: 7);
            final callsPerDay = _getCallsPerDayDynamic(recentCalls.map((c) => c.dateTime).toList());
            final keywords = _extractKeywords(historyProvider);
            final topKeywords = keywords.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            if (totalCalls == 0) {
              return SafeArea(
                child: EmptyState(
                  icon: Icons.bar_chart_outlined,
                  title: 'No Statistics Yet',
                  subtitle: 'Analyze some calls to see real insights here.',
                ),
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      "Insights",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Live stats from your scanned calls",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Summary chips
                    Row(
                      children: [
                        _pill("Total", totalCalls.toString(), const Color(0xFF0EA5E9)),
                        const SizedBox(width: 10),
                        _pill("Scam", scamCount.toString(), const Color(0xFFFF5C5C)),
                        const SizedBox(width: 10),
                        _pill("Legit", legitCount.toString(), const Color(0xFF15C87A)),
                      ],
                    ),

                    const SizedBox(height: 14),

                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Scam vs Legit",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          _progressRow(
                            label: "Scam",
                            value: scamPercentage / 100,
                            color: const Color(0xFFFF5C5C),
                            trailing: "${scamPercentage.toStringAsFixed(1)}%",
                          ),
                          const SizedBox(height: 10),
                          _progressRow(
                            label: "Legit",
                            value: legitPercentage / 100,
                            color: const Color(0xFF15C87A),
                            trailing: "${legitPercentage.toStringAsFixed(1)}%",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Last 7 Days",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: callsPerDay.entries.map((e) {
                              final maxCount = (callsPerDay.values.isEmpty)
                                  ? 1
                                  : (callsPerDay.values.reduce((a, b) => a > b ? a : b)).clamp(1, 50);
                              return _bar(e.key, e.value.toDouble(), maxCount.toDouble());
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Average Detection Confidence",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${avgConfidence.toStringAsFixed(1)}%",
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text("Higher = more certain", style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    Text("Shows model confidence", style: TextStyle(color: Colors.white54, fontSize: 11)),
                                  ],
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Top Scam Keywords",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          topKeywords.isEmpty
                              ? const Text(
                                  "No scam calls detected yet",
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                )
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: topKeywords.take(8).map((entry) {
                                    final size = 12.0 + (entry.value * 3.0).clamp(0.0, 10.0);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      child: Text(
                                        entry.key.toUpperCase(),
                                        style: TextStyle(
                                          color: const Color(0xFFFF5C5C),
                                          fontSize: size,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Recent Activity",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _activityChip("Last 7 days", recentCalls.length.toString()),
                              _activityChip("Scam in 7 days", recentCalls.where((c) => c.isScam).length.toString(), color: const Color(0xFFFF5C5C)),
                              _activityChip("Legit in 7 days", recentCalls.where((c) => !c.isScam).length.toString(), color: const Color(0xFF15C87A)),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 25,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _bar(String day, double count, double maxCount) {
    final ratio = maxCount == 0 ? 0.0 : (count / maxCount);
    final height = 14.0 + (ratio * 80.0);
    return Column(
      children: [
        Container(
          width: 14,
          height: height,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF0EA5E9), Color(0xFF7CE7FF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        Text(count.toInt().toString(), style: const TextStyle(fontSize: 11, color: Colors.white54)),
      ],
    );
  }

  Widget _progressRow({required String label, required double value, required Color color, required String trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            Text(trailing, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _activityChip(String label, String value, {Color color = const Color(0xFF7CE7FF)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
