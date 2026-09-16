import 'package:flutter/material.dart';

import '../models/campo.dart';
import '../models/lectura.dart';
import '../services/lecturas_service.dart';

/// Pantalla 5 — ultimas lecturas del campo actual, mas reciente primero.
class HistorialScreen extends StatefulWidget {
  final Campo campo;

  const HistorialScreen({super.key, required this.campo});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _lecturasService = LecturasService();
  late Future<List<Lectura>> _futureLecturas;

  @override
  void initState() {
    super.initState();
    _futureLecturas = _lecturasService.traerHistorial(widget.campo.id);
  }

  String _formatearFecha(DateTime fecha) {
    final f = fecha.toLocal();
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final minuto = f.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year} $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de lecturas')),
      body: FutureBuilder<List<Lectura>>(
        future: _futureLecturas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar historial: ${snapshot.error}'),
            );
          }
          final lecturas = snapshot.data ?? [];
          if (lecturas.isEmpty) {
            return const Center(
              child: Text('Todavia no hay lecturas registradas.'),
            );
          }
          return ListView.builder(
            itemCount: lecturas.length,
            itemBuilder: (context, indice) {
              final lectura = lecturas[indice];
              return ListTile(
                leading: const Icon(Icons.nfc),
                title: Text(lectura.rfidUid),
                subtitle: Text(_formatearFecha(lectura.fechaHora)),
              );
            },
          );
        },
      ),
    );
  }
}
