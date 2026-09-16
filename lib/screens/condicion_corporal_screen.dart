import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animales_service.dart';

/// Pantalla para editar la condicion corporal de un animal — se llega acá
/// tocando el botón "Condicion Corporal" en la ficha del animal (Pantalla 4).
/// Las 3 categorias (Buena/Regular/Mala) se guardan igual que antes; los
/// rangos que se muestran al lado de cada una son de referencia (escala de
/// Condicion Corporal 1 a 5 que usa el INTA), no se guardan como numero.
class CondicionCorporalScreen extends StatefulWidget {
  final Animal animal;

  const CondicionCorporalScreen({super.key, required this.animal});

  @override
  State<CondicionCorporalScreen> createState() =>
      _CondicionCorporalScreenState();
}

class _CondicionCorporalScreenState extends State<CondicionCorporalScreen> {
  final _animalesService = AnimalesService();
  String? _condicionSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _condicionSeleccionada = widget.animal.condicionCorporal;
  }

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

/// Una fila del desplegable de Condicion Corporal — la categoria a la
/// izquierda y el rango numerico de referencia a la derecha. `Expanded` en
/// vez de confiar solo en `spaceBetween`: asi siempre queda un espacio entre
/// las dos, aunque el propio campo no se estire (era el motivo del bug
/// visual "3.5Regular" pegados, cuando faltaba `isExpanded` en el dropdown).
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
