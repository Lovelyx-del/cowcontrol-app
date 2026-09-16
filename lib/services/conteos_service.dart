import 'supabase_service.dart';

/// Maneja la fila de `conteos` de este conteo en vivo — la Raspberry Pi
/// consulta esa tabla para saber a que conteo con estado "en_curso" mandarle
/// las lecturas que va leyendo (ver Guia_Raspberry_Pi-CowControl.pdf).
class ConteosService {
  final _client = SupabaseService.client;

  /// Si ya hay un conteo en pausa para este campo, lo reanuda. Si no hay
  /// ninguno, crea uno nuevo en estado "en_curso". Devuelve el id del conteo.
  Future<String> iniciarOReanudar(String campoId) async {
    final pausado = await _client
        .from('conteos')
        .select('id')
        .eq('campo_id', campoId)
        .eq('estado', 'pausado')
        .maybeSingle();

    if (pausado != null) {
      final id = pausado['id'] as String;
      await reanudar(id);
      return id;
    }

    final nuevo = await _client
        .from('conteos')
        .insert({
          'campo_id': campoId,
          'fecha': DateTime.now().toUtc().toIso8601String(),
          'estado': 'en_curso',
        })
        .select('id')
        .single();
    return nuevo['id'] as String;
  }

  Future<void> pausar(String conteoId) {
    return _client
        .from('conteos')
        .update({'estado': 'pausado'})
        .eq('id', conteoId);
  }

  Future<void> reanudar(String conteoId) {
    return _client
        .from('conteos')
        .update({'estado': 'en_curso'})
        .eq('id', conteoId);
  }

  Future<void> finalizar(String conteoId) {
    return _client
        .from('conteos')
        .update({'estado': 'finalizado'})
        .eq('id', conteoId);
  }
}
