// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bur.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BurAdapter extends TypeAdapter<Bur> {
  @override
  final int typeId = 7;

  @override
  Bur read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bur(
      id: fields[0] as int,
    )
      ..burGrade = fields[1] as double
      ..instructorComments = (fields[2] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, Bur obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.burGrade)
      ..writeByte(2)
      ..write(obj.instructorComments);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BurAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
