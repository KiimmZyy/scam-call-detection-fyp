import 'package:hive/hive.dart';

part 'call_history.g.dart';

@HiveType(typeId: 0)
class CallHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String phoneNumber;

  @HiveField(2)
  final DateTime dateTime;

  @HiveField(3)
  final String transcript;

  @HiveField(4)
  final bool isScam;

  @HiveField(5)
  final double confidence;

  @HiveField(6)
  final String audioFilePath;

  CallHistory({
    required this.id,
    required this.phoneNumber,
    required this.dateTime,
    required this.transcript,
    required this.isScam,
    required this.confidence,
    required this.audioFilePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'dateTime': dateTime.toIso8601String(),
      'transcript': transcript,
      'isScam': isScam,
      'confidence': confidence,
      'audioFilePath': audioFilePath,
    };
  }

  factory CallHistory.fromJson(Map<String, dynamic> json) {
    return CallHistory(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      dateTime: DateTime.parse(json['dateTime']),
      transcript: json['transcript'],
      isScam: json['isScam'],
      confidence: json['confidence'],
      audioFilePath: json['audioFilePath'],
    );
  }
}
