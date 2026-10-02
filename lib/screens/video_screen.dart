import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/animal.dart';
import '../services/video_service.dart';

/// Pantalla de video del animal: reproduce el segmento donde fue leído y
/// permite alternar con el video completo del conteo.
class VideoScreen extends StatefulWidget {
  final Animal animal;

  const VideoScreen({super.key, required this.animal});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _c;
  VideoSegmento? _seg;
  bool _soloSegmento = true;
  bool _cargando = true;
  String? _error;

  Duration get _desde {
    final s = ((_seg?.inicio ?? 0) - 2).clamp(0, double.infinity);
    return Duration(milliseconds: (s * 1000).round());
  }

  Duration get _hasta =>
      Duration(milliseconds: (((_seg?.fin ?? 0) + 2) * 1000).round());

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final service = VideoService();
      final rfid = widget.animal.rfidUid;
      debugPrint('[VideoScreen] rfid buscado: "$rfid"');

      final seg = await service.ultimoSegmentoDelAnimal(rfid);
      debugPrint('[VideoScreen] segmento: ${seg == null ? "null" : seg.storagePath}');

      if (seg == null) {
        if (mounted) setState(() => _cargando = false);
        return;
      }
      final url = await service.urlFirmada(seg.storagePath);
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      c.addListener(() {
        if (_soloSegmento && c.value.isPlaying && c.value.position >= _hasta) {
          c.pause();
        }
      });
      _seg = seg;
      await c.seekTo(_desde);
      await c.play();
      if (mounted) {
        setState(() {
          _c = c;
          _cargando = false;
        });
      }
    } catch (e, st) {
      debugPrint('[VideoScreen] ERROR: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _alternar() async {
    if (_c == null) return;
    setState(() => _soloSegmento = !_soloSegmento);
    await _c!.seekTo(_soloSegmento ? _desde : Duration.zero);
    await _c!.play();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video')),
      body: _cuerpo(),
    );
  }

  Widget _cuerpo() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se pudo cargar el video.\n$_error',
              textAlign: TextAlign.center),
        ),
      );
    }
    if (_c == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Este animal todavía no tiene video de ningún conteo.\n\n'
            'RFID buscado: "${widget.animal.rfidUid}"',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _c!.value.aspectRatio,
          child: VideoPlayer(_c!),
        ),
        VideoProgressIndicator(_c!, allowScrubbing: true),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_c!.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => setState(
                  () => _c!.value.isPlaying ? _c!.pause() : _c!.play()),
            ),
            ElevatedButton.icon(
              icon: Icon(_soloSegmento ? Icons.movie : Icons.content_cut),
              label: Text(
                  _soloSegmento ? 'Ver video completo' : 'Volver al segmento'),
              onPressed: _alternar,
            ),
          ],
        ),
      ],
    );
  }
}