/// Representa una fila de datos_lectura — un pasaje de un tag por el lector RFID/NFC.
class Lectura {
  final String id;
  final String rfidUid;
  final String? campoId;
  final DateTime fechaHora;
  final String? observaciones;

//el constructor guarda los valores en los campos del objeto
  const Lectura({
    required this.id,
    required this.rfidUid,
    this.campoId,
    required this.fechaHora,
    this.observaciones,
  });

 //trae de map cada valor y lo guarda con un nombre 
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
