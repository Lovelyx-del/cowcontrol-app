import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animales_service.dart';

/// Pantalla para editar el estado fertil de un animal — se llega acá
/// tocando el botón "Estado Fertil" en la ficha del animal (Pantalla 4).
/// Solo aparece para hembras (`categoria == 'hembra'`).
class EstadoFertilScreen extends StatefulWidget {
  final Animal animal;

  const EstadoFertilScreen({super.key, required this.animal});

  @override
  State<EstadoFertilScreen> createState() => _EstadoFertilScreenState();
}

class _EstadoFertilScreenState extends State<EstadoFertilScreen> {
  final _animalesService = AnimalesService();
  String? _estadoSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.animal.estadoFertil;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _animalesService.actualizarAnimal(
        animalId: widget.animal.id,
        estadoFertil: _estadoSeleccionado,
      );
      if (mounted) {
        Navigator.of(context).pop(
          widget.animal.copyWith(estadoFertil: _estadoSeleccionado),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estado Fertil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _estadoSeleccionado,
              isExpanded: true,
              hint: const Text('Sin dato'),
              items: const [
                DropdownMenuItem(
                  value: 'preñada',
                  child: Text('Preñada'),
                ),
                DropdownMenuItem(
                  value: 'amamantando',
                  child: Text('Amamantando'),
                ),
                DropdownMenuItem(
                  value: 'no-fecundada',
                  child: Text('No fecundada'),
                ),
              ],
              onChanged: (valor) =>
                  setState(() => _estadoSeleccionado = valor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}