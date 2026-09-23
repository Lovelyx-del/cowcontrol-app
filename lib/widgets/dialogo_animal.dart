import 'package:flutter/material.dart';

class DatosAltaAnimal {
  final String animalId;
  final String? apodo;
  final String categoria;

  DatosAltaAnimal({required this.animalId, this.apodo, required this.categoria});
}

class DialogoAltaAnimal extends StatefulWidget {
  final String? animalIdInicial;
  final String? apodoInicial;
  final String? categoriaInicial;

  const DialogoAltaAnimal({
    super.key,
    this.animalIdInicial,
    this.apodoInicial,
    this.categoriaInicial,
  });

  static const _categorias = [
    'vaca',
    'toro',
    'ternero',
    'ternera',
    'vaquillona',
  ];

  @override
  State<DialogoAltaAnimal> createState() => _DialogoAltaAnimalState();
}

class _DialogoAltaAnimalState extends State<DialogoAltaAnimal> {
  late final _animalIdController = TextEditingController(text: widget.animalIdInicial ?? '');
  late final _apodoController = TextEditingController(text: widget.apodoInicial ?? '');
  late String? _categoria = widget.categoriaInicial;

  @override
  void dispose() {
    _animalIdController.dispose();
    _apodoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Datos del animal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _animalIdController,
            decoration: const InputDecoration(labelText: 'ID del animal'),
          ),
          TextField(
            controller: _apodoController,
            decoration: const InputDecoration(labelText: 'Apodo (opcional)'),
          ),
          DropdownButtonFormField<String>(
            value: _categoria,
            hint: const Text('Categoría'),
            items: DialogoAltaAnimal._categorias
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _categoria = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _animalIdController.text.trim().isEmpty || _categoria == null
              ? null
              : () => Navigator.of(context).pop(
                    DatosAltaAnimal(
                      animalId: _animalIdController.text.trim(),
                      apodo: _apodoController.text.trim().isEmpty
                          ? null
                          : _apodoController.text.trim(),
                      categoria: _categoria!,
                    ),
                  ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
