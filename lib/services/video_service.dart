import 'package:supabase_flutter/supabase_flutter.dart';

class VideoSegmento {
  final String rfidUid;
  final String? raza;
  final String storagePath;
  final double inicio;
  final double fin;

  VideoSegmento({
    required this.rfidUid,
    required this.raza,
    required this.storagePath,
    required this.inicio,
    required this.fin,
  });

  factory VideoSegmento.fromMap(Map<String, dynamic> m) => VideoSegmento(
        rfidUid: m['rfid_uid'] as String,
        raza: m['raza'] as String?,
        storagePath: m['storage_path'] as String,
        inicio: (m['segundo_inicio'] as num).toDouble(),
        fin: (m['segundo_fin'] as num).toDouble(),
      );
}

class VideoService {
  final _sb = Supabase.instance.client;
  static const bucket = 'videos-conteos'; // cambiar por el nombre de tu bucket

  Future<List<VideoSegmento>> segmentosDelConteo(String conteoId) async {
    final rows = await _sb
        .from('animal_video_segmentos')
        .select()
        .eq('conteo_id', conteoId)
        .order('segundo_inicio');
    return (rows as List)
        .map((r) => VideoSegmento.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<VideoSegmento?> ultimoSegmentoDelAnimal(String rfidUid) async {
    final rows = await _sb
        .from('animal_video_segmentos')
        .select()
        .eq('rfid_uid', rfidUid)
        .order('marca_creada', ascending: false)
        .limit(1);
    final lista = rows as List;
    if (lista.isEmpty) return null;
    return VideoSegmento.fromMap(lista.first as Map<String, dynamic>);
  }

  Future<String> urlFirmada(String path) =>
      _sb.storage.from(bucket).createSignedUrl(path, 3600);
}