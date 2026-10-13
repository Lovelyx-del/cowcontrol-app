// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../models/lectura.dart: la clase Lectura, de donde saco la fecha y hora.
// - ../services/lecturas_service.dart: trae el historial de lecturas del campo.
import 'package:flutter/material.dart';

import '../models/campo.dart';
import '../models/lectura.dart';
import '../services/lecturas_service.dart';

// ============================================================
// historial_screen — Pantalla 5 del flujo
//
// Qué hace este archivo:
// Muestro las últimas lecturas del lector en el campo actual, la más reciente
// primero, con su fecha y hora. Se entra desde Configuración.
// ============================================================
class HistorialScreen extends StatefulWidget {
  final Campo campo;

  const HistorialScreen({super.key, required this.campo});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

// ---------------------------------------------------------------------------
// _HistorialScreenState — pide el historial una sola vez
//
// En initState arranco el pedido a LecturasService y guardo el Future. Así el
// FutureBuilder no vuelve a pedir los datos cada vez que se redibuja.
// ---------------------------------------------------------------------------
class _HistorialScreenState extends State<HistorialScreen> {
  final _lecturasService = LecturasService();
  late Future<List<Lectura>> _futureLecturas;

  @override
  void initState() {
    super.initState();
    _futureLecturas = _lecturasService.traerHistorial(widget.campo.id);
  }

  // ---------------------------------------------------------------------------
  // _formatearFecha — pasa la fecha a "dd/mm/aaaa hh:mm"
  //
  // Primero la paso a la hora local del celular (en Supabase se guarda en UTC).
  // Con padLeft le agrego un 0 adelante a los números de un dígito, así queda
  // "05/03" y no "5/3".
  // ---------------------------------------------------------------------------
  String _formatearFecha(DateTime fecha) {
    final f = fecha.toLocal();
    final dia = f.day.toString().padLeft(2, '0');
    final mes = f.month.toString().padLeft(2, '0');
    final hora = f.hour.toString().padLeft(2, '0');
    final minuto = f.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${f.year} $hora:$minuto';
  }

  // ---------------------------------------------------------------------------
  // build — la lista de lecturas según el estado del pedido
  //
  // El FutureBuilder cubre los cuatro casos: cargando (ruedita), error
  // (muestro el mensaje), lista vacía ("Todavía no hay lecturas") y lista con
  // datos, donde cada fila muestra la fecha y hora de una lectura.
  // ---------------------------------------------------------------------------
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
                leading: const Icon(Icons.history),
                title: Text(
                  _formatearFecha(lectura.fechaHora), 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 18,
                    ),
                  ),
              );
            },
          );
        },
      ),
    );
  }
}
