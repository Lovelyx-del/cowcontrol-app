// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../models/observacion.dart: la clase Observacion (texto y fecha).
// - ../services/observaciones_service.dart: trae y agrega observaciones en la
//   tabla datos_observacion de Supabase.
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/observacion.dart';
import '../services/observaciones_service.dart';

// ============================================================
// observaciones_screen — Sub-pantalla de la Pantalla 4 (ficha del animal)
//
// Qué hace este archivo:
// Arriba escribo una observación nueva y abajo muestro todas las del animal,
// la más nueva primero. Cada una es una fila en datos_observacion; antes era
// una sola columna de texto en datos_animales que se pisaba cada vez.
// TODO: revisar en la presentación — la ficha abre esta pantalla con _abrir,
// que espera un Animal de vuelta, pero acá nunca hago pop con uno. No rompe
// nada: llega null y la ficha no cambia.
// ============================================================
class ObservacionesScreen extends StatefulWidget {
  final Animal animal;

  const ObservacionesScreen({super.key, required this.animal});

  @override
  State<ObservacionesScreen> createState() => _ObservacionesScreenState();
}

// ---------------------------------------------------------------------------
// _ObservacionesScreenState — el campo de texto y la lista
//
// _nuevaObservacionController guarda lo que se escribe, _futureObservaciones
// el pedido de la lista (arranca en initState) y _guardando deshabilita el
// botón mientras espero a Supabase.
// ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _formatearFecha — pasa la fecha a "dd/mm/aaaa"
  //
  // Es la misma función que en vacunas: día y mes con un 0 adelante si tienen
  // un solo dígito, y el año.
  // ---------------------------------------------------------------------------
  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  // ---------------------------------------------------------------------------
  // _agregarObservacion — guarda la observación y recarga la lista
  //
  // Si el texto está vacío no hago nada. Si no, la guardo con
  // ObservacionesService, limpio el campo y vuelvo a pedir la lista para que
  // aparezca arriba. El finally apaga _guardando aunque falle.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // build — campo de texto arriba, lista de observaciones abajo
  //
  // El campo tiene 3 líneas para escribir cómodo. Abajo, un FutureBuilder con
  // la lista: cada fila muestra el texto y, debajo, la fecha en que se cargó.
  // ---------------------------------------------------------------------------
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
