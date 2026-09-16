/// Representa una fila de datos_animales. Solo incluye los campos que muestra la v1
/// de la app (la columna "sexo" se usa como categoria) — el resto de lo que trae el
/// mockup original (nombre, edad, maternidad, etc.) vive libre en observaciones.
class Animal {
  final String id;
  final String rfidUid;
  final String? categoria; // vaca / toro / ternero / ternera / vaquillona
  final String estadoVital; // vivo / muerto
  final String? condicionCorporal; // 'buena' / 'regular' / 'mala'
  final String? observaciones;
  final String campoId;

  const Animal({
    required this.id,
    required this.rfidUid,
    this.categoria,
    required this.estadoVital,
    this.condicionCorporal,
    this.observaciones,
    required this.campoId,
  });

  factory Animal.fromMap(Map<String, dynamic> map) {
    return Animal(
      id: map['id'] as String,
      rfidUid: map['rfid_uid'] as String,
      categoria: map['sexo'] as String?,
      estadoVital: map['estado_vital'] as String? ?? 'vivo',
      condicionCorporal: map['condicion_corporal'] as String?,
      observaciones: map['observaciones'] as String?,
      campoId: map['campo_id'] as String,
    );
  }

  /// Copia el animal reemplazando solo los campos que edita el productor a
  /// mano (condicion corporal, observaciones) — para actualizar la Pantalla 4
  /// apenas se guarda, sin tener que volver a pedirle el animal a Supabase.
  /// Usa un objeto "no tocado" en vez de `??` para poder distinguir "dejar
  /// como estaba" de "borrar a proposito" (ej: vaciar las observaciones).
  Animal copyWith({
    Object? condicionCorporal = _noTocado,
    Object? observaciones = _noTocado,
  }) {
    return Animal(
      id: id,
      rfidUid: rfidUid,
      categoria: categoria,
      estadoVital: estadoVital,
      condicionCorporal: identical(condicionCorporal, _noTocado)
          ? this.condicionCorporal
          : condicionCorporal as String?,
      observaciones: identical(observaciones, _noTocado)
          ? this.observaciones
          : observaciones as String?,
      campoId: campoId,
    );
  }
}

const _noTocado = Object();
