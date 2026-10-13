// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../services/animales_service.dart: guarda el estado fértil en Supabase.
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animales_service.dart';

// ============================================================
// estado_fertil_screen — Sub-pantalla de la Pantalla 4 (ficha del animal)
//
// Qué hace este archivo:
// Acá edito el estado fértil: Preñada, Amamantando o No fecundada. La fila que
// abre esta pantalla solo aparece en la ficha si el animal es hembra (vaca,
// ternera o vaquillona; eso lo decide detalle_animal_screen).
// ============================================================
class EstadoFertilScreen extends StatefulWidget {
  final Animal animal;

  const EstadoFertilScreen({super.key, required this.animal});

  @override
  State<EstadoFertilScreen> createState() => _EstadoFertilScreenState();
}

// ---------------------------------------------------------------------------
// _EstadoFertilScreenState — la opción elegida y si estoy guardando
//
// Es igual que en condición corporal: _estadoSeleccionado arranca con el valor
// que ya tenía el animal, y _guardando deshabilita el botón mientras espero a
// Supabase.
// ---------------------------------------------------------------------------
class _EstadoFertilScreenState extends State<EstadoFertilScreen> {
  final _animalesService = AnimalesService();
  String? _estadoSeleccionado;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estadoSeleccionado = widget.animal.estadoFertil;
  }

  // ---------------------------------------------------------------------------
  // _guardar — guarda en Supabase y vuelve a la ficha
  //
  // Actualizo el estado fértil con AnimalesService y hago pop devolviendo una
  // copia del animal con el valor nuevo, para que la ficha actualice el chip.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // build — el desplegable con los 3 estados y el botón Guardar
  //
  // En Supabase se guarda el value de cada opción ("preñada", "amamantando" o
  // "no-fecundada"); lo que se ve es el texto con mayúscula.
  // ---------------------------------------------------------------------------
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