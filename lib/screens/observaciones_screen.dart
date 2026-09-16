import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/observacion.dart';
import '../services/observaciones_service.dart';

/// Pantalla para agregar una observación nueva y ver el historial completo
/// (la más nueva primero) — se llega acá tocando el botón "Observaciones" en
/// la ficha del animal (Pantalla 4). Guarda en datos_observacion, una fila
/// por observación (no en datos_animales.observaciones, la columna vieja de
/// un solo texto que se pisaba cada vez).
class ObservacionesScreen extends StatefulWidget {
  final Animal animal;

  const ObservacionesScreen({super.key, required this.animal});

  @override
  State<ObservacionesScreen> createState() => _ObservacionesScreenState();
}

class _ObservacionesScreenState extends State<ObservacionesScreen> {
  final _observacionesService = ObservacionesService();
  final _nuevaObservacionController = TextEditingController();
  late Future<List<Observacion>> _futureObservaciones;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _futureObservaciones = _observacionesService.traerObservaciones(
      widget.animal.id,
    );
  }

  @override
  void dispose() {
    _nuevaObservacionController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _agregarObservacion() async {
    final texto = _nuevaObservacionController.text.trim();
    if (texto.isEmpty) return;
    setState(() => _guardando = true);
    try {
      await _observacionesService.agregarObservacion(
        idAnimal: widget.animal.id,
        texto: texto,
      );
      _nuevaObservacionController.clear();
      setState(() {
        _futureObservaciones = _observacionesService.traerObservaciones(
          widget.animal.id,
        );
      });
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Observaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nuevaObservacionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observación nueva'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _guardando ? null : _agregarObservacion,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Agregar observación'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Observacion>>(
                future: _futureObservaciones,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final observaciones = snapshot.data ?? [];
                  if (observaciones.isEmpty) {
                    return const Text('Sin observaciones.');
                  }
                  return ListView.separated(
                    itemCount: observaciones.length,
                    separatorBuilder: (context, indice) =>
                        const Divider(height: 1),
                    itemBuilder: (context, indice) {
                      final observacion = observaciones[indice];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(observacion.texto),
                        subtitle: Text(_formatearFecha(observacion.creadoEn)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
