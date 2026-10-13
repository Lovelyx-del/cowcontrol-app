// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../services/animales_service.dart: guarda la condición corporal en Supabase.
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animales_service.dart';

// ============================================================
// condicion_corporal_screen — Sub-pantalla de la Pantalla 4 (ficha del animal)
//
// Qué hace este archivo:
// Acá edito la condición corporal del animal: Buena, Regular o Mala. Al lado
// de cada opción muestro el rango de la escala 1 a 5 del INTA, pero es solo de
// referencia: en Supabase se guarda la palabra, no el número.
// ============================================================
class CondicionCorporalScreen extends StatefulWidget {
  final Animal animal;

  const CondicionCorporalScreen({super.key, required this.animal});

  @override
  State<CondicionCorporalScreen> createState() =>
      _CondicionCorporalScreenState();
}

// ---------------------------------------------------------------------------
// _CondicionCorporalScreenState — la opción elegida y si estoy guardando
//
// _condicionSeleccionada arranca con el valor que ya tenía el animal (o null
// si no tenía). _guardando lo uso para deshabilitar el botón mientras espero
// a Supabase, así no se guarda dos veces.
// ---------------------------------------------------------------------------
class _CondicionCorporalScreenState extends State<CondicionCorporalScreen> {
  final _animalesService = AnimalesService();
  String? _condicionSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _condicionSeleccionada = widget.animal.condicionCorporal;
  }

  // ---------------------------------------------------------------------------
  // _guardar — guarda en Supabase y vuelve a la ficha
  //
  // Actualizo el animal con AnimalesService y hago pop devolviendo una copia
  // del animal con el valor nuevo (copyWith). Así la ficha se actualiza sin
  // volver a pedirlo. El finally apaga _guardando aunque falle.
  // ---------------------------------------------------------------------------
  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _animalesService.actualizarAnimal(
        animalId: widget.animal.id,
        condicionCorporal: _condicionSeleccionada,
      );
      if (mounted) {
        Navigator.of(context).pop(
          widget.animal.copyWith(condicionCorporal: _condicionSeleccionada),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // build — el desplegable con las 3 opciones y el botón Guardar
  //
  // Cada opción del desplegable es una _FilaCondicion. Si el animal no tenía
  // dato, se ve "Sin dato". Mientras guardo, el botón muestra una ruedita en
  // lugar del texto y queda deshabilitado.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Condicion Corporal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _condicionSeleccionada,
              isExpanded: true,
              hint: const Text('Sin dato'),
              items: const [
                DropdownMenuItem(
                  value: 'buena',
                  child: _FilaCondicion(rango: 'de 4 a 5', etiqueta: 'Buena'),
                ),
                DropdownMenuItem(
                  value: 'regular',
                  child: _FilaCondicion(
                    rango: 'de 2.5 a 3.5',
                    etiqueta: 'Regular',
                  ),
                ),
                DropdownMenuItem(
                  value: 'mala',
                  child: _FilaCondicion(rango: 'de 1 a 2', etiqueta: 'Mala'),
                ),
              ],
              onChanged: (valor) =>
                  setState(() => _condicionSeleccionada = valor),
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

// ---------------------------------------------------------------------------
// _FilaCondicion — una opción del desplegable
//
// La categoría a la izquierda y el rango de referencia en gris a la derecha.
// Uso Expanded en la etiqueta para que siempre quede espacio entre las dos;
// antes se veía "3.5Regular" todo pegado.
// ---------------------------------------------------------------------------
class _FilaCondicion extends StatelessWidget {
  final String rango;
  final String etiqueta;

  const _FilaCondicion({required this.rango, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(etiqueta)),
        Text(rango, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
