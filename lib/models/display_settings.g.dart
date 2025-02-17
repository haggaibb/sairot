// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'display_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DisplaySettingsAdapter extends TypeAdapter<DisplaySettings> {
  @override
  final int typeId = 6;

  @override
  DisplaySettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DisplaySettings()
      ..sprintsFullScreen = fields[0] as bool
      ..numberOfCols = fields[1] as int
      ..alonkaFullScreen = fields[2] as bool;
  }

  @override
  void write(BinaryWriter writer, DisplaySettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sprintsFullScreen)
      ..writeByte(1)
      ..write(obj.numberOfCols)
      ..writeByte(2)
      ..write(obj.alonkaFullScreen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplaySettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
