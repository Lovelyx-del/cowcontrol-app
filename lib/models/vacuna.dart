/// Representa una fila de datos_vacuna. La app solo pide la mas reciente por
/// animal (fecha_vacuna descendente) para el resumen de la Pantalla 4.
class Vacuna {
  final String idAnimal;
  final String nombreVacuna;
  final DateTime? fechaVacuna;

  const Vacuna({
    required this.idAnimal,
    required this.nombreVacuna,
    this.fechaVacuna,
  });

  factory Vacuna.fromMap(Map<String, dynamic> map) {
    return Vacuna(
      idAnimal: map['id_animal'] as String,
      nombreVacuna: map['nombre_vacuna'] as String,
      fechaVacuna: map['fecha_vacuna'] != null
          ? DateTime.parse(map['fecha_vacuna'] as String)
          : null,
    );
  }
}
