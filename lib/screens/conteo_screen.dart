// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - supabase_flutter: acá lo necesito por el tipo RealtimeChannel, que es el
//   canal que queda escuchando las lecturas nuevas.
// - ../models/lectura.dart: la clase Lectura (una fila de datos_lectura, con
//   el rfidUid que leyó el lector).
// - ../services/conteos_service.dart: crea, pausa, reanuda y finaliza la fila
//   del conteo en la tabla conteos.
// - ../services/lecturas_service.dart: abre y cierra la escucha en tiempo real.
// - ../services/animales_service.dart y ../widgets/dialogo_alta_animal.dart:
//   para dar de alta ahí mismo un tag sin identificar.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/animal.dart';
import '../models/campo.dart';
import '../models/lectura.dart';
import '../services/animales_service.dart';
import '../services/conteos_service.dart';
import '../services/lecturas_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animal_card.dart';
import '../widgets/dialogo_alta_animal.dart';
import 'detalle_animal_screen.dart';

// ============================================================
// conteo_screen — Pantalla 3 del flujo
//
// Qué hace este archivo:
// Es el conteo en vivo. Escucho las lecturas del lector RFID por Supabase
// Realtime y marco cada animal apenas pasa. Además manejo la fila del conteo
// en la tabla conteos, que es la que consulta la Raspberry Pi para saber a
// qué conteo mandarle lo que lee. Los tags que no son de nadie van a una
// lista de "Sin identificar" para darlos de alta ahí mismo.
// ============================================================
class ConteoScreen extends StatefulWidget {
  final Campo campo;
  final List<Animal> animales;

  const ConteoScreen({super.key, required this.campo, required this.animales});

  @override
  State<ConteoScreen> createState() => _ConteoScreenState();
}

// ---------------------------------------------------------------------------
// _ConteoScreenState — el estado del conteo
//
// _idsDetectados es un Set (no repite) con los animales que ya pasaron, y
// _sinIdentificar los tags que no son de nadie. _animales es una copia de la
// lista de la planilla, así le puedo sumar los que doy de alta acá. _canal es
// la escucha de Realtime y _conteoId la fila del conteo en Supabase.
// ---------------------------------------------------------------------------
class _ConteoScreenState extends State<ConteoScreen> {
  final _lecturasService = LecturasService();
  final _conteosService = ConteosService();
  final _animalesService = AnimalesService();
  final Set<String> _idsDetectados = {};
  final List<String> _sinIdentificar = [];

  late List<Animal> _animales;
  RealtimeChannel? _canal;
  String? _conteoId;
  bool _enPausa = false;

  @override
  void initState() {
    super.initState();
    _animales = List.of(widget.animales);
    _inicializarConteo();
  }

  // ---------------------------------------------------------------------------
  // _inicializarConteo — crea o retoma el conteo y empieza a escuchar
  //
  // Le pido a ConteosService un conteo para este campo: si había uno pausado
  // lo reanuda, y si no, crea uno nuevo. Me guardo su id y recién ahí abro la
  // escucha de lecturas. Lo llamo desde initState.
  // ---------------------------------------------------------------------------
  Future<void> _inicializarConteo() async {
    _conteoId = await _conteosService.iniciarOReanudar(widget.campo.id);
    _empezarAEscuchar();
  }

  // ---------------------------------------------------------------------------
  // _empezarAEscuchar — abre el canal de Realtime
  //
  // LecturasService se suscribe a las lecturas nuevas de este campo y, cada vez
  // que llega una, llama a _marcarLectura. Guardo el canal en _canal para
  // poder cerrarlo después (al detener, al finalizar o al salir de la pantalla).
  // ---------------------------------------------------------------------------
  void _empezarAEscuchar() {
    _canal = _lecturasService.escucharNuevasLecturas(
      campoId: widget.campo.id,
      alRecibirLectura: _marcarLectura,
    );
  }

  // ---------------------------------------------------------------------------
  // _marcarLectura — qué hago con cada lectura que llega
  //
  // Busco el animal que tenga el mismo rfidUid que la lectura. Si lo encuentro,
  // lo agrego a _idsDetectados y su tarjeta se marca como detectada. Si no es
  // de ningún animal, el tag va a "Sin identificar", una sola vez aunque el
  // lector lo vuelva a leer.
  // ---------------------------------------------------------------------------
  void _marcarLectura(Lectura lectura) {
    Animal? animalCoincidente;
    for (final animal in _animales) {
      if (animal.rfidUid == lectura.rfidUid) {
        animalCoincidente = animal;
        break;
      }
    }
    if (animalCoincidente == null) {
      if (!_sinIdentificar.contains(lectura.rfidUid)) {
        setState(() => _sinIdentificar.add(lectura.rfidUid));
      }
      return;
    }
    setState(() => _idsDetectados.add(animalCoincidente!.id));
  }

  // ---------------------------------------------------------------------------
  // _asignarCategoria — dar de alta un tag sin identificar en el momento
  //
  // Abro el mismo DialogoAltaAnimal de la planilla. Si no cancelan, creo el
  // animal en Supabase con el rfidUid del tag, lo saco de "Sin identificar",
  // lo sumo a la lista y lo marco como detectado, porque ya pasó por el lector.
  // ---------------------------------------------------------------------------
  Future<void> _asignarCategoria(String rfidUid) async {
    final datos = await showDialog<DatosAltaAnimal>(
      context: context,
      builder: (_) => const DialogoAltaAnimal(),
    );
    if (datos == null) return;
    final nuevoAnimal = await _animalesService.crearAnimal(
      rfidUid: rfidUid,
      campoId: widget.campo.id,
      categoria: datos.categoria,
      animalId: datos.animalId,
      apodo: datos.apodo,
      raza: datos.raza,
    );
    setState(() {
      _sinIdentificar.remove(rfidUid);
      _animales.add(nuevoAnimal);
      _idsDetectados.add(nuevoAnimal.id);
    });
  }

  // ---------------------------------------------------------------------------
  // _detener — pausa el conteo
  //
  // Cierro la escucha de Realtime y marco el conteo como pausado en la tabla
  // conteos (la que consulta la Pi). El botón pasa a decir "Reanudar". Chequeo
  // `mounted` antes del setState por si ya se fueron de la pantalla.
  // ---------------------------------------------------------------------------
  Future<void> _detener() async {
    if (_canal != null) {
      await _lecturasService.dejarDeEscuchar(_canal!);
      _canal = null;
    }
    if (_conteoId != null) {
      await _conteosService.pausar(_conteoId!);
    }
    if (mounted) setState(() => _enPausa = true);
  }

  // ---------------------------------------------------------------------------
  // _reanudar — vuelve a activar el conteo pausado
  //
  // Es lo contrario de _detener: reanudo el conteo en Supabase y vuelvo a abrir
  // la escucha. Lo que ya estaba detectado no se pierde, porque _idsDetectados
  // sigue en memoria.
  // ---------------------------------------------------------------------------
  Future<void> _reanudar() async {
    if (_conteoId != null) {
      await _conteosService.reanudar(_conteoId!);
    }
    _empezarAEscuchar();
    if (mounted) setState(() => _enPausa = false);
  }

  // ---------------------------------------------------------------------------
  // _finalizar — cierra el conteo y vuelve a la planilla
  //
  // Cierro la escucha, marco el conteo como finalizado en Supabase y hago pop.
  // Al volver, la planilla recarga todo (eso está en planilla_screen).
  // ---------------------------------------------------------------------------
  Future<void> _finalizar() async {
    if (_canal != null) {
      await _lecturasService.dejarDeEscuchar(_canal!);
      _canal = null;
    }
    if (_conteoId != null) {
      await _conteosService.finalizar(_conteoId!);
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // dispose — cierro la escucha al salir de la pantalla
  //
  // Si no cierro el canal, Realtime sigue mandando lecturas a una pantalla que
  // ya no existe. Ojo: acá solo dejo de escuchar, el conteo no se pausa ni se
  // finaliza en Supabase.
  // TODO: revisar en la presentación — si salen con la flecha de atrás, el
  // conteo no queda pausado en la tabla conteos, y iniciarOReanudar solo
  // retoma los pausados.
  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    if (_canal != null) {
      _lecturasService.dejarDeEscuchar(_canal!);
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // build — contador, aviso, lista de animales, sin identificar y botones
  //
  // Arriba, el "X / Y detectados". Si hay tags sin identificar, un aviso bordó
  // que pide pausar para completar sus datos. En el medio, las AnimalCard y
  // después los "Sin identificar" (tocar uno abre _asignarCategoria). Abajo,
  // Detener/Reanudar (según _enPausa) y Finalizar.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conteo — ${widget.campo.nombreCampo}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${_idsDetectados.length} / ${_animales.length} detectados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (_sinIdentificar.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bordoAlertaFondo,
                border: Border.all(color: AppColors.bordoAlerta),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.bordoAlerta),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cada 5 animales, pausá para completar género y tipo — así quedan '
                      'guardados para los próximos conteos.',
                      style: const TextStyle(
                        color: AppColors.bordoAlerta,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              children: [
                ..._animales.map(
                  (animal) => AnimalCard(
                    animal: animal,
                    detectado: _idsDetectados.contains(animal.id),
                    onVerMas: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetalleAnimalScreen(
                          animal: animal,
                          campo: widget.campo,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_sinIdentificar.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Sin identificar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.naranjaTostado,
                      ),
                    ),
                  ),
                  ..._sinIdentificar.map(
                    (rfidUid) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.help_outline,
                          color: AppColors.naranjaTostado,
                        ),
                        title: Text(
                          rfidUid,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        subtitle: const Text(
                          'Tocá para asignarle una categoría',
                        ),
                        onTap: () => _asignarCategoria(rfidUid),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(_enPausa ? Icons.play_arrow : Icons.pause),
                      label: Text(_enPausa ? 'Reanudar' : 'Detener'),
                      onPressed: _enPausa ? _reanudar : _detener,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Finalizar'),
                      onPressed: _finalizar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}