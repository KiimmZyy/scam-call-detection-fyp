import 'package:flutter/foundation.dart';
import '../models/call_history.dart';
import '../services/database_service.dart';

class CallHistoryProvider extends ChangeNotifier {
  List<CallHistory> _callHistory = [];
  Map<String, dynamic> _statistics = {};

  List<CallHistory> get callHistory => _callHistory;
  Map<String, dynamic> get statistics => _statistics;

  CallHistoryProvider() {
    loadCallHistory();
  }

  void loadCallHistory() {
    _callHistory = DatabaseService.getAllCallHistory();
    _statistics = DatabaseService.getStatistics();
    notifyListeners();
  }

  Future<void> addCallHistory(CallHistory history) async {
    await DatabaseService.saveCallHistory(history);
    loadCallHistory(); // Reload to update UI
  }

  Future<void> deleteCallHistory(String id) async {
    await DatabaseService.deleteCallHistory(id);
    loadCallHistory(); // Reload to update UI
  }

  Future<void> clearAllHistory() async {
    await DatabaseService.clearAllHistory();
    loadCallHistory(); // Reload to update UI
  }

  List<CallHistory> getScamCalls() {
    return _callHistory.where((call) => call.isScam).toList();
  }

  List<CallHistory> getLegitCalls() {
    return _callHistory.where((call) => !call.isScam).toList();
  }

  List<CallHistory> getRecentCalls({int days = 7}) {
    return DatabaseService.getRecentCalls(days: days);
  }
}
