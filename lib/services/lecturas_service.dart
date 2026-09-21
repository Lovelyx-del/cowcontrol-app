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
  
  /// UIDs leídos en el campo que no coinciden con ningún animal cargado y
  /// que el productor todavía no descartó — para la sección "no registrados"
  /// de Pantalla 2, después de cerrar el conteo.
  Future<List<String>> traerNoRegistrados(String campoId) async {
    final lecturas = await _client
        .from('datos_lectura')
        .select('rfid_uid')
        .eq('campo_id', campoId);
    final uidsLeidos = (lecturas as List)
        .map((fila) => fila['rfid_uid'] as String)
        .toSet();

    final animales = await _client
        .from('datos_animales')
        .select('rfid_uid')
        .eq('campo_id', campoId);
    final uidsAnimales = (animales as List)
        .map((fila) => fila['rfid_uid'] as String)
        .toSet();

    final descartados = await _client
        .from('tags_descartados')
        .select('rfid_uid')
        .eq('campo_id', campoId);
    final uidsDescartados = (descartados as List)
        .map((fila) => fila['rfid_uid'] as String)
        .toSet();

    return uidsLeidos
        .difference(uidsAnimales)
        .difference(uidsDescartados)
        .toList();
  }

  /// El productor decidió que ese tag no corresponde a un animal (lectura
  /// falsa, tag ajeno, etc.). No borra el historial, solo lo saca de la
  /// lista de pendientes.
  Future<void> descartarTag(String rfidUid, String campoId) async {
    await _client.from('tags_descartados').upsert({
      'rfid_uid': rfidUid,
      'campo_id': campoId,
    });
  }
