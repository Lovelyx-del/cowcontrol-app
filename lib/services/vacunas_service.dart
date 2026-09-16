import '../models/vacuna.dart';
import 'supabase_service.dart';

/// Trae todas las vacunas de un animal, la mas nueva primero.
class VacunasService {
  final _client = SupabaseService.client;
  Future<List<Vacuna>> traerVacunas(String animalId) async {
    final data = await _client
        .from('datos_vacuna')
        .select()
        .eq('id_animal', animalId)
        .order('fecha_vacuna', ascending: false);
    return (data as List)
        .map((fila) => Vacuna.fromMap(fila as Map<String, dynamic>))
        .toList();
  }

  Future<void> agregarVacuna({
    required String idAnimal,
    required String nombreVacuna,
    DateTime? fechaVacuna,
  }) async {
    await _client.from('datos_vacuna').insert({
      'id_animal': idAnimal,
      'nombre_vacuna': nombreVacuna,
      if (fechaVacuna != null) 'fecha_vacuna': fechaVacuna.toIso8601String(),
    });
  }
}
