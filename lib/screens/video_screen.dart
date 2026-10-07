import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/animal.dart';
import '../services/video_service.dart';

/// Pantalla de video del animal: muestra el video COMPLETO del conteo y un
/// botón que salta al momento exacto donde se leyó al animal.
class VideoScreen extends StatefulWidget {
  final Animal animal;

  const VideoScreen({super.key, required this.animal});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  // El botón salta 1 segundo antes de que aparezca la vaca.
  static const _antesDelAnimal = Duration(seconds: 1);

  VideoPlayerController? _c;
  VideoSegmento? _seg;
  bool _cargando = true;
  String? _error;

  /// Momento del video donde aparece el animal.
  Duration get _momentoAnimal {
    final ms = (((_seg?.inicio ?? 0) * 1000).round()) -
        _antesDelAnimal.inMilliseconds;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  String _formatear(Duration d) {
    final min = d.inMinutes;
    final seg = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$min:$seg';
  }

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
      debugPrint(
          '[VideoScreen] segmento: ${seg == null ? "null" : seg.storagePath}');

      if (seg == null) {
        if (mounted) setState(() => _cargando = false);
        return;
      }
      final url = await service.urlFirmada(seg.storagePath);
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      _seg = seg;
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

  Future<void> _alternarPlayPause() async {
    final c = _c;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
  }

  Future<void> _irAlAnimal() async {
    final c = _c;
    if (c == null) return;
    await c.seekTo(_momentoAnimal);
    await c.play();
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
    return SingleChildScrollView(
      child: Column(
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
              ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _c!,
                builder: (context, value, _) => IconButton(
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: _alternarPlayPause,
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: Text('Ir a donde aparece (${_formatear(_momentoAnimal)})'),
                onPressed: _irAlAnimal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}