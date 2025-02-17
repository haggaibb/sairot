// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdminEventAdapter extends TypeAdapter<AdminEvent> {
  @override
  final int typeId = 50;

  @override
  AdminEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdminEvent(
      name: fields[0] as String,
    )..eventDays = (fields[1] as List).cast<Event>();
  }

  @override
  void write(BinaryWriter writer, AdminEvent obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.eventDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
