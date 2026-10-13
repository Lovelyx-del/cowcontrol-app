// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - video_player: el paquete oficial de Flutter para reproducir videos. De
//   acá salen VideoPlayerController, VideoPlayer y VideoProgressIndicator.
// - ../services/video_service.dart: busca el segmento de video del animal y
//   me da la URL firmada para poder bajarlo.
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/animal.dart';
import '../services/video_service.dart';

// ============================================================
// video_screen — Sub-pantalla de la Pantalla 4 (ficha del animal)
//
// Qué hace este archivo:
// Muestro el video completo del último conteo en el que pasó el animal, con
// play/pausa y una barra para adelantar. Abajo hay un botón que salta justo
// al momento en que el lector leyó al animal.
// ============================================================
class VideoScreen extends StatefulWidget {
  final Animal animal;

  const VideoScreen({super.key, required this.animal});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

// ---------------------------------------------------------------------------
// _VideoScreenState — el reproductor y el estado de la carga
//
// _c es el controlador del video (null hasta que carga), _seg el segmento que
// encontré para este animal, y _cargando / _error me dicen qué mostrar
// mientras tanto.
// ---------------------------------------------------------------------------
class _VideoScreenState extends State<VideoScreen> {
  // El botón salta 1 segundo antes de que aparezca la vaca.
  static const _antesDelAnimal = Duration(seconds: 1);

  VideoPlayerController? _c;
  VideoSegmento? _seg;
  bool _cargando = true;
  String? _error;

  // ---------------------------------------------------------------------------
  // _momentoAnimal — a qué segundo del video tiene que saltar el botón
  //
  // _seg.inicio está en segundos; lo paso a milisegundos y le resto 1 segundo
  // (_antesDelAnimal) para que se vea al animal llegar. Si da negativo, uso 0.
  // ---------------------------------------------------------------------------
  Duration get _momentoAnimal {
    final ms = (((_seg?.inicio ?? 0) * 1000).round()) -
        _antesDelAnimal.inMilliseconds;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }

  // ---------------------------------------------------------------------------
  // _formatear — pasa una duración a "m:ss"
  //
  // La uso para mostrar en el botón el momento al que va a saltar, por ejemplo
  // "2:05". padLeft le pone el 0 a los segundos de un dígito.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _cargar — busca el video del animal y lo prepara para reproducir
  //
  // Le pido a VideoService el último segmento donde aparece el rfidUid del
  // animal. Si no hay, termino y build muestra "todavía no tiene video". Si
  // hay, pido la URL firmada, creo el controlador y lo inicializo. Cualquier
  // error lo guardo en _error. Los debugPrint muestran en consola qué pasó.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _alternarPlayPause — el botón de play/pausa
  //
  // Si el video se está reproduciendo lo pauso, y si no, lo reproduzco.
  // ---------------------------------------------------------------------------
  Future<void> _alternarPlayPause() async {
    final c = _c;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
  }

  // ---------------------------------------------------------------------------
  // _irAlAnimal — salta al momento del animal y reproduce
  //
  // Muevo el video a _momentoAnimal con seekTo y le doy play. Es lo que hace el
  // botón grande de abajo.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _cuerpo — qué muestro según cómo terminó la carga
  //
  // Cargando: ruedita. Error: el mensaje. Sin video: aviso con el RFID que
  // busqué. Con video: el reproductor, la barra de progreso (se puede
  // arrastrar), el play/pausa y el botón "Ir a donde aparece este animal".
  // ---------------------------------------------------------------------------
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
          const SizedBox(height: 8),
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _c!,
            builder: (context, value, _) => IconButton(
              iconSize: 40,
              icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _alternarPlayPause,
            ),
          ),
          const SizedBox(height: 8),
          // Fuera de un Row, para que el botón ocupe todo el ancho (el tema
          // de la app le pide ancho infinito y dentro de un Row no se dibuja).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.my_location),
                label: Text(
                    'Ir a donde aparece este animal (${_formatear(_momentoAnimal)})'),
                onPressed: _irAlAnimal,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}