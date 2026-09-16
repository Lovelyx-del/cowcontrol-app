/// Representa una fila de datos_campo — un establecimiento ganadero del productor logueado.
class Campo {
  final String id;
  final String nombreCampo;
  final String? ubicacion;

  const Campo({required this.id, required this.nombreCampo, this.ubicacion});

  factory Campo.fromMap(Map<String, dynamic> map) {
    return Campo(
      id: map['id'] as String,
      nombreCampo: map['nombre_campo'] as String,
      ubicacion: map['ubicacion'] as String?,
    );
  }
}
