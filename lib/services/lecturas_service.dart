import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lectura.dart';
import 'supabase_service.dart';

/// Historial de lecturas (Pantalla 5) + suscripcion Realtime para el conteo
/// en vivo (Pantalla 3). Ver seccion 7 de explicacion_cada_funcion.pdf.
class LecturasService {
  final _client = SupabaseService.client;

  Future<List<Lectura>> traerHistorial(
    String campoId, {
    int limite = 50,
  }) async {
    final data = await _client
        .from('datos_lectura')
        .select()
        .eq('campo_id', campoId)
        .order('fecha_hora', ascending: false)
        .limit(limite);
    return (data as List)
        .map((fila) => Lectura.fromMap(fila as Map<String, dynamic>))
        .toList();
  }

  /// Se suscribe a los inserts nuevos de datos_lectura para el campo dado.
  /// Supabase Realtime avisa por websocket apenas Postgres registra la fila
  /// (sin que la app tenga que preguntar "¿hay algo nuevo?" cada tanto).
  RealtimeChannel escucharNuevasLecturas({
    required String campoId,
    required void Function(Lectura) alRecibirLectura,
  }) {
    final canal = _client.channel('lecturas_campo_$campoId');
    canal
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'datos_lectura',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'campo_id',
            value: campoId,
          ),
          callback: (payload) {
            alRecibirLectura(Lectura.fromMap(payload.newRecord));
          },
        )
        .subscribe();
    return canal;
  }

  Future<void> dejarDeEscuchar(RealtimeChannel canal) {
    return _client.removeChannel(canal);
  }
}
