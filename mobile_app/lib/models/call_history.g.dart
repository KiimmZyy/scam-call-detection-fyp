// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CallHistoryAdapter extends TypeAdapter<CallHistory> {
  @override
  final int typeId = 0;

  @override
  CallHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallHistory(
      id: fields[0] as String,
      phoneNumber: fields[1] as String,
      dateTime: fields[2] as DateTime,
      transcript: fields[3] as String,
      isScam: fields[4] as bool,
      confidence: fields[5] as double,
      audioFilePath: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CallHistory obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.dateTime)
      ..writeByte(3)
      ..write(obj.transcript)
      ..writeByte(4)
      ..write(obj.isScam)
      ..writeByte(5)
      ..write(obj.confidence)
      ..writeByte(6)
      ..write(obj.audioFilePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
