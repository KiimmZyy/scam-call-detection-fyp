import 'package:hive_flutter/hive_flutter.dart';
import '../models/call_history.dart';

class DatabaseService {
  static const String _callHistoryBox = 'callHistory';
  
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(CallHistoryAdapter());
    await Hive.openBox<CallHistory>(_callHistoryBox);
  }

  static Box<CallHistory> get _box => Hive.box<CallHistory>(_callHistoryBox);

  // Save a new call history record
  static Future<void> saveCallHistory(CallHistory history) async {
    await _box.put(history.id, history);
  }

  // Get all call history records, sorted by date (newest first)
  static List<CallHistory> getAllCallHistory() {
    final histories = _box.values.toList();
    histories.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return histories;
  }

  // Get call history by ID
  static CallHistory? getCallHistoryById(String id) {
    return _box.get(id);
  }

  // Get scam calls only
  static List<CallHistory> getScamCalls() {
    return getAllCallHistory().where((call) => call.isScam).toList();
  }

  // Get legitimate calls only
  static List<CallHistory> getLegitCalls() {
    return getAllCallHistory().where((call) => !call.isScam).toList();
  }

  // Delete a call history record
  static Future<void> deleteCallHistory(String id) async {
    await _box.delete(id);
  }

  // Clear all history
  static Future<void> clearAllHistory() async {
    await _box.clear();
  }

  // Get statistics
  static Map<String, dynamic> getStatistics() {
    final allCalls = getAllCallHistory();
    final scamCalls = allCalls.where((call) => call.isScam).length;
    final legitCalls = allCalls.length - scamCalls;
    
    return {
      'totalCalls': allCalls.length,
      'scamCalls': scamCalls,
      'legitCalls': legitCalls,
      'scamPercentage': allCalls.isEmpty ? 0.0 : (scamCalls / allCalls.length) * 100,
      'legitPercentage': allCalls.isEmpty ? 0.0 : (legitCalls / allCalls.length) * 100,
    };
  }

  // Get calls from last 7 days
  static List<CallHistory> getRecentCalls({int days = 7}) {
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: days));
    return getAllCallHistory()
        .where((call) => call.dateTime.isAfter(cutoffDate))
        .toList();
  }

  // Get calls by date range
  static List<CallHistory> getCallsByDateRange(DateTime start, DateTime end) {
    return getAllCallHistory()
        .where((call) => 
            call.dateTime.isAfter(start) && call.dateTime.isBefore(end))
        .toList();
  }
}
