import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animales_service.dart';

/// Pantalla para editar la etapa de vida de un animal — se llega acá
/// tocando el botón "Etapa de Vida" en la ficha del animal (Pantalla 4).
class EtapaVidaScreen extends StatefulWidget {
  final Animal animal;

  const EtapaVidaScreen({super.key, required this.animal});

  @override
  State<EtapaVidaScreen> createState() => _EtapaVidaScreenState();
}

class _EtapaVidaScreenState extends State<EtapaVidaScreen> {
  final _animalesService = AnimalesService();
  String? _etapaSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _etapaSeleccionada = widget.animal.etapaVida;
  }

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