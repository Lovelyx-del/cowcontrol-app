// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../services/animales_service.dart: guarda la etapa de vida en Supabase.
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animales_service.dart';

// ============================================================
// etapa_vida_screen — Sub-pantalla de la Pantalla 4 (ficha del animal)
//
// Qué hace este archivo:
// Acá edito la etapa de vida del animal: desde "Muy joven" hasta "Adulto
// mayor". Está armada igual que condición corporal y estado fértil.
// ============================================================
class EtapaVidaScreen extends StatefulWidget {
  final Animal animal;

  const EtapaVidaScreen({super.key, required this.animal});

  @override
  State<EtapaVidaScreen> createState() => _EtapaVidaScreenState();
}

// ---------------------------------------------------------------------------
// _EtapaVidaScreenState — la opción elegida y si estoy guardando
//
// _etapaSeleccionada arranca con la etapa que ya tenía el animal, y
// _guardando deshabilita el botón mientras espero a Supabase.
// ---------------------------------------------------------------------------
class _EtapaVidaScreenState extends State<EtapaVidaScreen> {
  final _animalesService = AnimalesService();
  String? _etapaSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _etapaSeleccionada = widget.animal.etapaVida;
  }

  // ---------------------------------------------------------------------------
  // _guardar — guarda en Supabase y vuelve a la ficha
  //
  // Actualizo la etapa con AnimalesService y hago pop devolviendo una copia del
  // animal con el valor nuevo, para que la ficha actualice el chip.
  // ---------------------------------------------------------------------------
  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _animalesService.actualizarAnimal(
        animalId: widget.animal.id,
        etapaVida: _etapaSeleccionada,
      );
      if (mounted) {
        Navigator.of(context).pop(
          widget.animal.copyWith(etapaVida: _etapaSeleccionada),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // build — el desplegable con las 5 etapas y el botón Guardar
  //
  // En Supabase se guarda el value de cada opción (por ejemplo "para_destetar"),
  // escrito sin espacios ni mayúsculas; lo que se ve es el texto lindo.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Etapa de Vida')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _etapaSeleccionada,
              isExpanded: true,
              hint: const Text('Sin dato'),
              items: const [
                DropdownMenuItem(value: 'muy_joven', child: Text('Muy joven')),
                DropdownMenuItem(
                  value: 'para_destetar',
                  child: Text('Para destetar'),
                ),
                DropdownMenuItem(
                  value: 'para_vender_carnear',
                  child: Text('Para vender/carnear'),
                ),
                DropdownMenuItem(
                  value: 'adulto_fertil',
                  child: Text('Adulto fertil'),
                ),
                DropdownMenuItem(
                  value: 'adulto_mayor',
                  child: Text('Adulto mayor'),
                ),
              ],
              onChanged: (valor) =>
                  setState(() => _etapaSeleccionada = valor),
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