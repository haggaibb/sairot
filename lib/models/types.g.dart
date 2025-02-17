// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParticipantStatusAdapter extends TypeAdapter<ParticipantStatus> {
  @override
  final int typeId = 100;

  @override
  ParticipantStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ParticipantStatus.Active;
      case 1:
        return ParticipantStatus.Droped;
      default:
        return ParticipantStatus.Active;
    }
  }

  @override
  void write(BinaryWriter writer, ParticipantStatus obj) {
    switch (obj) {
      case ParticipantStatus.Active:
        writer.writeByte(0);
        break;
      case ParticipantStatus.Droped:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlonkaCreditTypesAdapter extends TypeAdapter<AlonkaCreditTypes> {
  @override
  final int typeId = 101;

  @override
  AlonkaCreditTypes read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AlonkaCreditTypes.Alonka;
      case 1:
        return AlonkaCreditTypes.Gerikan;
      case 3:
        return AlonkaCreditTypes.Runner;
      case 4:
        return AlonkaCreditTypes.Participated;
      default:
        return AlonkaCreditTypes.Alonka;
    }
  }

  @override
  void write(BinaryWriter writer, AlonkaCreditTypes obj) {
    switch (obj) {
      case AlonkaCreditTypes.Alonka:
        writer.writeByte(0);
        break;
      case AlonkaCreditTypes.Gerikan:
        writer.writeByte(1);
        break;
      case AlonkaCreditTypes.Runner:
        writer.writeByte(3);
        break;
      case AlonkaCreditTypes.Participated:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlonkaCreditTypesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
