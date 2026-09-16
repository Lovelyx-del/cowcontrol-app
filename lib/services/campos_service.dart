import '../models/campo.dart';
import 'supabase_service.dart';

/// Trae y crea campos (establecimientos) del productor logueado (Pantalla 1).
/// RLS ya filtra por productor_id = auth.uid() en el SELECT, no hace falta
/// pasarlo a mano; en el INSERT si hay que setearlo para cumplir la politica.
class CamposService {
  final _client = SupabaseService.client;

  Future<List<Campo>> traerCampos() async {
    final data = await _client
        .from('datos_campo')
        .select()
        .order('nombre_campo');
    return (data as List)
        .map((fila) => Campo.fromMap(fila as Map<String, dynamic>))
        .toList();
  }

  Future<Campo> crearCampo({
    required String nombreCampo,
    String? ubicacion,
  }) async {
    final productorId = _client.auth.currentUser!.id;
    final fila = await _client
        .from('datos_campo')
        .insert({
          'nombre_campo': nombreCampo,
          'ubicacion': ubicacion,
          'productor_id': productorId,
        })
        .select()
        .single();
    return Campo.fromMap(fila);
  }
}
