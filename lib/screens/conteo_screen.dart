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
import 'detalle_animal_screen.dart';

/// Pantalla 3 — conteo en vivo. Escucha datos_lectura por Supabase Realtime y
/// marca cada animal apenas llega su lectura. Ademas maneja la fila en
/// `conteos`, que la Raspberry Pi consulta para saber a que conteo activo
/// mandarle las lecturas que va leyendo. Las lecturas que no coinciden con
/// ningun animal cargado quedan en una lista aparte de "sin identificar",
/// para que el productor les asigne categoria ahi mismo, viendo el animal
/// pasar en persona.
class ConteoScreen extends StatefulWidget {
  final Campo campo;
  final List<Animal> animales;

  const ConteoScreen({super.key, required this.campo, required this.animales});

  @override
  State<ConteoScreen> createState() => _ConteoScreenState();
}

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

  Future<void> _inicializarConteo() async {
    _conteoId = await _conteosService.iniciarOReanudar(widget.campo.id);
    _empezarAEscuchar();
  }

  void _empezarAEscuchar() {
    _canal = _lecturasService.escucharNuevasLecturas(
      campoId: widget.campo.id,
      alRecibirLectura: _marcarLectura,
    );
  }

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

  Future<void> _asignarCategoria(String rfidUid) async {
    final categoria = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoCategoria(),
    );
    if (categoria == null) return;
    final nuevoAnimal = await _animalesService.crearAnimal(
      rfidUid: rfidUid,
      campoId: widget.campo.id,
      categoria: categoria,
    );
    setState(() {
      _sinIdentificar.remove(rfidUid);
      _animales.add(nuevoAnimal);
      _idsDetectados.add(nuevoAnimal.id);
    });
  }

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

  Future<void> _reanudar() async {
    if (_conteoId != null) {
      await _conteosService.reanudar(_conteoId!);
    }
    _empezarAEscuchar();
    if (mounted) setState(() => _enPausa = false);
  }

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

  @override
  void dispose() {
    if (_canal != null) {
      _lecturasService.dejarDeEscuchar(_canal!);
    }
    super.dispose();
  }

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

/// Dialogo simple para elegir la categoria de un animal recien detectado
/// (tag que no coincidia con ningun animal ya cargado).
class _DialogoCategoria extends StatelessWidget {
  const _DialogoCategoria();

  static const _categorias = [
    'vaca',
    'toro',
    'ternero',
    'ternera',
    'vaquillona',
  ];

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('¿Qué categoría es?'),
      children: _categorias
          .map(
            (categoria) => SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(categoria),
              child: Text(categoria[0].toUpperCase() + categoria.substring(1)),
            ),
          )
          .toList(),
    );
  }
}
