/// Representa una fila de datos_lectura — un pasaje de un tag por el lector RFID/NFC.
class Lectura {
  final String id;
  final String rfidUid;
  final String? campoId;
  final DateTime fechaHora;
  final String? observaciones;

  const Lectura({
    required this.id,
    required this.rfidUid,
    this.campoId,
    required this.fechaHora,
    this.observaciones,
  });

  factory Lectura.fromMap(Map<String, dynamic> map) {
    return Lectura(
      id: map['id'] as String,
      rfidUid: map['rfid_uid'] as String,
      campoId: map['campo_id'] as String?,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
      observaciones: map['observaciones'] as String?,
    );
  }
}
