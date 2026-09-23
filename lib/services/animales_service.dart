import '../models/animal.dart';
import 'supabase_service.dart';

/// Trae los animales vivos de un campo (Pantallas 2 y 3) y el detalle de uno
/// en particular (Pantalla 4).
class AnimalesService {
  final _client = SupabaseService.client;

  Future<List<Animal>> traerAnimalesDeCampo(String campoId) async {
    final data = await _client
        .from('datos_animales')
        .select()
        .eq('campo_id', campoId)
        .eq('estado_vital', 'vivo')
        .order('rfid_uid');
    return (data as List)
        .map((fila) => Animal.fromMap(fila as Map<String, dynamic>))
        .toList();
  }

  Future<Animal> traerDetalle(String animalId) async {
    final fila = await _client
        .from('datos_animales')
        .select()
        .eq('id', animalId)
        .single();
    return Animal.fromMap(fila);
  }

  /// Solo actualiza condicion corporal — las observaciones se manejan aparte
  /// (ver ObservacionesService), no pisan datos_animales.observaciones.
  Future<void> actualizarAnimal({
    required String animalId,
    String? condicionCorporal,
  }) async {
    await _client
        .from('datos_animales')
        .update({'condicion_corporal': condicionCorporal})
        .eq('id', animalId);
  }

  /// Crea un animal nuevo a partir de un tag que se leyo por primera vez y
  /// no coincidia con ninguno ya cargado — el productor carga el ID propio
  /// del animal, un apodo opcional y la categoria viendolo pasar en el
  /// conteo en vivo (Pantalla 3).
  Future<Animal> crearAnimal({
    required String rfidUid,
    required String campoId,
    required String categoria,
    required String animalId,
    String? apodo,
  }) async {
    final fila = await _client
        .from('datos_animales')
        .insert({
          'rfid_uid': rfidUid,
          'campo_id': campoId,
          'sexo': categoria,
          'estado_vital': 'vivo',
          'animal_id': animalId,
          'apodo': apodo,
        })
        .select()
        .single();
    return Animal.fromMap(fila);
  }

  /// Actualiza el ID, apodo y categoria de un animal ya existente — se puede
  /// llamar en cualquier momento desde la ficha del animal (Pantalla 4).
  Future<Animal> actualizarDatosAnimal({
    required String id, // fila en datos_animales (animal.id), no animal_id
    required String animalId,
    String? apodo,
    required String categoria,
  }) async {
    final fila = await _client
        .from('datos_animales')
        .update({
          'animal_id': animalId,
          'apodo': apodo,
          'sexo': categoria,
        })
        .eq('id', id)
        .select()
        .single();
    return Animal.fromMap(fila);
  }
}
