// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SystemAdapter extends TypeAdapter<System> {
  @override
  final int typeId = 102;

  @override
  System read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return System()
      ..loggedIn = fields[0] as String
      ..isDarkMode = fields[1] as bool
      ..accessibility = fields[2] as Accessibility;
  }

  @override
  void write(BinaryWriter writer, System obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.loggedIn)
      ..writeByte(1)
      ..write(obj.isDarkMode)
      ..writeByte(2)
      ..write(obj.accessibility);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SystemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccessibilityAdapter extends TypeAdapter<Accessibility> {
  @override
  final int typeId = 200;

  @override
  Accessibility read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Accessibility.normal;
      case 1:
        return Accessibility.big;
      case 2:
        return Accessibility.biggest;
      default:
        return Accessibility.normal;
    }
  }

  @override
  void write(BinaryWriter writer, Accessibility obj) {
    switch (obj) {
      case Accessibility.normal:
        writer.writeByte(0);
        break;
      case Accessibility.big:
        writer.writeByte(1);
        break;
      case Accessibility.biggest:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
