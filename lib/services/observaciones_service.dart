import '../models/observacion.dart';
import 'supabase_service.dart';

/// Trae y agrega observaciones de un animal — datos_observacion, no la
/// columna vieja datos_animales.observaciones (esa queda sin usar, ver
/// base_datos.md).
class ObservacionesService {
  final _client = SupabaseService.client;

  Future<List<Observacion>> traerObservaciones(String animalId) async {
    final data = await _client
        .from('datos_observacion')
        .select()
        .eq('id_animal', animalId)
        .order('creado_en', ascending: false);
    return (data as List)
        .map((fila) => Observacion.fromMap(fila as Map<String, dynamic>))
        .toList();
  }

  Future<void> agregarObservacion({
    required String idAnimal,
    required String texto,
  }) async {
    await _client.from('datos_observacion').insert({
      'id_animal': idAnimal,
      'texto': texto,
    });
  }
}
