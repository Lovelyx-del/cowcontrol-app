/// Representa una fila de datos_vacuna. La app solo pide la mas reciente por
/// animal (fecha_vacuna descendente) para el resumen de la Pantalla 4.
class Vacuna {
  final String idAnimal;
  final String nombreVacuna;
  final DateTime? fechaVacuna;

//guarda los valores en los datos de la clase
  const Vacuna({
    required this.idAnimal,
    required this.nombreVacuna,
    this.fechaVacuna,
  });

//trae de map los valores y le asigna un nombre
  factory Vacuna.fromMap(Map<String, dynamic> map) {
    return Vacuna(
      idAnimal: map['datos_animales_id'] as String,   // antes: 'id_animal', se cambio el nombre del campo por confusiones al trabajar
      nombreVacuna: map['nombre_vacuna'] as String,
      fechaVacuna: map['fecha_vacuna'] != null //contempla que puede traer o no una fecha; si hay la hay la guarda como string y si no la guarda como null
          ? DateTime.parse(map['fecha_vacuna'] as String)
          : null,
    );
  }
}
