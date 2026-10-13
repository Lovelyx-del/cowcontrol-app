// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../models/vacuna.dart: la clase Vacuna (nombre y fecha de una vacuna).
// - ../services/vacunas_service.dart: trae y agrega vacunas en la tabla
//   datos_vacuna de Supabase.
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/vacuna.dart';
import '../services/vacunas_service.dart';

// ============================================================
// vacunas_screen — Sub-pantalla de la Pantalla 4 (ficha del animal)
//
// Qué hace este archivo:
// Arriba cargo una vacuna nueva (nombre y fecha) y abajo muestro todas las
// vacunas que tiene el animal, la más nueva primero. A diferencia de las
// otras sub-pantallas, acá no edito el animal: las vacunas van a otra tabla.
// ============================================================
class VacunasScreen extends StatefulWidget {
  final Animal animal;

  const VacunasScreen({super.key, required this.animal});

  @override
  State<VacunasScreen> createState() => _VacunasScreenState();
}

// ---------------------------------------------------------------------------
// _VacunasScreenState — el formulario y la lista de vacunas
//
// _nombreVacunaController guarda lo que se escribe en el campo de texto y
// _fechaVacunaSeleccionada la fecha elegida (null si no eligieron). En
// _futureVacunas está el pedido de la lista, que arranco en initState.
// ---------------------------------------------------------------------------
class _VacunasScreenState extends State<VacunasScreen> {
  final _vacunasService = VacunasService();
  final _nombreVacunaController = TextEditingController();
  late Future<List<Vacuna>> _futureVacunas;
  DateTime? _fechaVacunaSeleccionada;

  @override
  void initState() {
    super.initState();
    _futureVacunas = _vacunasService.traerVacunas(widget.animal.id);
  }

  @override
  void dispose() {
    _nombreVacunaController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // _formatearFecha — pasa la fecha a "dd/mm/aaaa"
  //
  // Igual que en el historial pero sin la hora, porque de una vacuna solo
  // importa el día. padLeft le pone un 0 adelante a los números de un dígito.
  // ---------------------------------------------------------------------------
  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  // ---------------------------------------------------------------------------
  // _elegirFecha — abre el calendario
  //
  // Uso el showDatePicker de Flutter. Se puede elegir desde 2020 hasta hoy, no
  // fechas futuras. Si cierran sin elegir, llega null y no cambio nada.
  // ---------------------------------------------------------------------------
  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fechaVacunaSeleccionada = fecha);
  }

  // ---------------------------------------------------------------------------
  // _agregarVacuna — guarda la vacuna y recarga la lista
  //
  // Si el nombre está vacío no hago nada. Si no, la guardo con VacunasService,
  // limpio el formulario, vuelvo a pedir la lista y aviso con un SnackBar.
  // TODO: revisar en la presentación — si no eligen fecha, el servicio no manda
  // fecha_vacuna y queda lo que tenga por defecto esa columna en datos_vacuna.
  // ---------------------------------------------------------------------------
  Future<void> _agregarVacuna() async {
    if (_nombreVacunaController.text.trim().isEmpty) return;
    await _vacunasService.agregarVacuna(
      idAnimal: widget.animal.id,
      nombreVacuna: _nombreVacunaController.text.trim(),
      fechaVacuna: _fechaVacunaSeleccionada,
    );
    _nombreVacunaController.clear();
    setState(() {
      _fechaVacunaSeleccionada = null;
      _futureVacunas = _vacunasService.traerVacunas(widget.animal.id);
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vacuna agregada.')));
    }
  }

  // ---------------------------------------------------------------------------
  // build — formulario arriba, lista de vacunas abajo
  //
  // Arriba, el campo del nombre con el botón de fecha al lado y "Agregar
  // vacuna". Abajo, un FutureBuilder con la lista: cada fila es el nombre y,
  // si tiene, la fecha. Si no hay ninguna, muestro "Sin vacunas registradas".
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacunas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nombreVacunaController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la vacuna',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _elegirFecha,
                  child: Text(
                    _fechaVacunaSeleccionada == null
                        ? 'Elegir fecha'
                        : _formatearFecha(_fechaVacunaSeleccionada!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _agregarVacuna,
              child: const Text('Agregar vacuna'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Vacuna>>(
                future: _futureVacunas,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final vacunas = snapshot.data ?? [];
                  if (vacunas.isEmpty) {
                    return const Text('Sin vacunas registradas.');
                  }
                  return ListView.separated(
                    itemCount: vacunas.length,
                    separatorBuilder: (context, indice) =>
                        const Divider(height: 1),
                    itemBuilder: (context, indice) {
                      final vacuna = vacunas[indice];
                      final fecha = vacuna.fechaVacuna;
                      final fechaTexto = fecha == null
                          ? ''
                          : ' — ${_formatearFecha(fecha)}';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${vacuna.nombreVacuna}$fechaTexto'),
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
