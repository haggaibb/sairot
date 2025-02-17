// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SystemSettingsAdapter extends TypeAdapter<SystemSettings> {
  @override
  final int typeId = 104;

  @override
  SystemSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SystemSettings()
      ..minutesInterval = fields[0] as int
      ..checkIntervalSeconds = fields[1] as int
      ..totalChecks = fields[2] as int;
  }

  @override
  void write(BinaryWriter writer, SystemSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.minutesInterval)
      ..writeByte(1)
      ..write(obj.checkIntervalSeconds)
      ..writeByte(2)
      ..write(obj.totalChecks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
