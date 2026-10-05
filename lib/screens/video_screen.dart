import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/animal.dart';
import '../services/video_service.dart';

/// Pantalla de video del animal: muestra el video completo del conteo y un
/// botón que salta al momento exacto donde se leyó al animal.
class VideoScreen extends StatefulWidget {
  final Animal animal;

  const VideoScreen({super.key, required this.animal});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _c;
  VideoSegmento? _seg;
  bool _cargando = true;
  String? _error;

  /// Punto de salto: 2 segundos antes de que aparezca el animal.
  Duration get _momentoAnimal {
    final s = ((_seg?.inicio ?? 0) - 2).clamp(0, double.infinity);
    return Duration(milliseconds: (s * 1000).round());
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
      await c.seekTo(_momentoAnimal);
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

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// Genera un link nuevo (el bucket es privado, el link vence en 1 hora) y
  /// abre el video completo fuera de la app.
  Future<void> _abrirVideoCompleto() async {
    final seg = _seg;
    if (seg == null) return;
    try {
      final url = await VideoService().urlFirmada(seg.storagePath);
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _avisar('No se pudo abrir el video completo');
    } catch (e) {
      debugPrint('[VideoScreen] error al abrir video completo: $e');
      _avisar('No se pudo abrir el video completo');
    }
  }

  Future<void> _copiarLinkVideoCompleto() async {
    final seg = _seg;
    if (seg == null) return;
    try {
      final url = await VideoService().urlFirmada(seg.storagePath);
      await Clipboard.setData(ClipboardData(text: url));
      _avisar('Link copiado (vale por 1 hora)');
    } catch (e) {
      debugPrint('[VideoScreen] error al copiar link: $e');
      _avisar('No se pudo copiar el link');
    }
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text(
                  'Abrir video completo',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
                onPressed: _abrirVideoCompleto,
              ),
              IconButton(
                tooltip: 'Copiar link',
                icon: const Icon(Icons.link),
                onPressed: _copiarLinkVideoCompleto,
              ),
            ],
          ),
        ],
      ),
    );
  }
}