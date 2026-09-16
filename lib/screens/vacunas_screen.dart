import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/vacuna.dart';
import '../services/vacunas_service.dart';

/// Pantalla para agregar una vacuna nueva y ver el historial completo (la mas
/// nueva primero) — se llega acá tocando el botón "Vacunas" en la ficha del
/// animal (Pantalla 4).
class VacunasScreen extends StatefulWidget {
  final Animal animal;

  const VacunasScreen({super.key, required this.animal});

  @override
  State<VacunasScreen> createState() => _VacunasScreenState();
}

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

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fechaVacunaSeleccionada = fecha);
  }

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
