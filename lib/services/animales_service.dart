import '../models/animal.dart';
import 'supabase_service.dart';

/// Objeto centinela para distinguir "no se pasó este parámetro" de
/// "se pasó explícitamente null" (igual que en Animal.copyWith).
const _sinCambio = Object();

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

  /// Actualiza condicion corporal, estado fertil y/o etapa de vida — cada
  /// pantalla editora solo pasa el campo que le corresponde, así que solo
  /// ese campo se manda al `.update()`. Las observaciones se manejan aparte
  /// (ver ObservacionesService), no pisan datos_animales.observaciones.
  Future<void> actualizarAnimal({
    required String animalId,
    Object? condicionCorporal = _sinCambio,
    Object? estadoFertil = _sinCambio,
    Object? etapaVida = _sinCambio,
  }) async {
    final cambios = <String, dynamic>{};
    if (!identical(condicionCorporal, _sinCambio)) {
      cambios['condicion_corporal'] = condicionCorporal as String?;
    }
    if (!identical(estadoFertil, _sinCambio)) {
      cambios['estado_fertil'] = estadoFertil as String?;
    }
    if (!identical(etapaVida, _sinCambio)) {
      cambios['etapa_vida'] = etapaVida as String?;
    }
    if (cambios.isEmpty) return;

    await _client.from('datos_animales').update(cambios).eq('id', animalId);
  }

  /// Crea un animal nuevo a partir de un tag que se leyo por primera vez y
  /// no coincidia con ninguno ya cargado — el productor le eligio la
  /// categoria viendo el animal pasar en el conteo en vivo (Pantalla 3).
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
}
