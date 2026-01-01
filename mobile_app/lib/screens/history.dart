import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'call_details.dart';
import '../providers/call_history_provider.dart';
import '../widgets/empty_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController(initialRefresh: false);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Provider.of<CallHistoryProvider>(context, listen: false).loadCallHistory();
      _refreshController.refreshCompleted();
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'JUST NOW';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}M AGO';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}H AGO';
    } else if (difference.inDays == 1) {
      return 'YESTERDAY';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} DAYS AGO';
    } else {
      return DateFormat('MMM dd').format(dateTime).toUpperCase();
    }
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
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Call History",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Consumer<CallHistoryProvider>(
                      builder: (context, historyProvider, child) {
                        final total = historyProvider.callHistory.length;
                        final scam = historyProvider.getScamCalls().length;
                        return Text(
                          "$total total • $scam scam detected",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<CallHistoryProvider>(
                  builder: (context, historyProvider, child) {
                    final history = historyProvider.callHistory;

                    if (history.isEmpty) {
                      return EmptyState(
                        icon: Icons.history_outlined,
                        title: 'No Call History Yet',
                        subtitle: 'Tap the Home button below and start scanning calls to see your history',
                      );
                    }

                    return SmartRefresher(
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      header: WaterDropHeader(
                        waterDropColor: const Color(0xFF7CE7FF),
                        refresh: const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Color(0xFF7CE7FF)),
                          ),
                        ),
                        complete: const Icon(Icons.check, color: Color(0xFF7CE7FF)),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final call = history[index];
                          return _buildHistoryCard(
                            context,
                            call.phoneNumber,
                            _formatTime(call.dateTime),
                            call.isScam,
                            call.transcript,
                            call.confidence,
                            DateFormat('dd MMMM yyyy').format(call.dateTime).toUpperCase(),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    String name,
    String time,
    bool isScam,
    String transcript,
    double confidence,
    String formattedDate,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallDetailsPage(
              name: name,
              date: formattedDate,
              duration: "00:00", // Duration not tracked yet
              isScam: isScam,
              transcript: transcript,
              confidence: confidence,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isScam
                      ? [const Color(0xFFFF5C5C), const Color(0xFFFF9A8B)]
                      : [const Color(0xFF0EA5E9), const Color(0xFF7CE7FF)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isScam ? Icons.warning_rounded : Icons.phone,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isScam)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5C5C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFF5C5C).withOpacity(0.5)),
                          ),
                          child: const Text(
                            "SCAM",
                            style: TextStyle(
                              color: Color(0xFFFF5C5C),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.speed, size: 12, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        "${confidence.toStringAsFixed(1)}% confidence",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }
}
