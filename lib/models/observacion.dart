/// Representa una fila de datos_observacion — una observacion suelta que el
/// productor carga sobre un animal. A diferencia de datos_vacuna, no tiene
/// una fecha que el productor elija: `creadoEn` la pone Supabase sola al
/// insertar, y es lo que define el orden (la mas nueva primero).
class Observacion {
  final String idAnimal;
  final String texto;
  final DateTime creadoEn;

 //constructor que guarda los valores en los datos de la clase  
  const Observacion({
    required this.idAnimal,
    required this.texto,
    required this.creadoEn,
  });

//llama los valores de map y les asigna un nombre de la clase a cada uno
  factory Observacion.fromMap(Map<String, dynamic> map) {
    return Observacion(
      idAnimal: map['id_animal'] as String,
      texto: map['texto'] as String,
      creadoEn: DateTime.parse(map['creado_en'] as String),
    );
  }
}
