import 'package:flutter/material.dart';

/// Dialogo simple para elegir la categoria de un animal recien detectado
/// (tag que no coincidia con ningun animal ya cargado).
class DialogoCategoria extends StatelessWidget {
  const DialogoCategoria({super.key});

  static const categorias = [
    'vaca',
    'toro',
    'ternero',
    'ternera',
    'vaquillona',
  ];

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('¿Qué categoría es?'),
      children: categorias
          .map(
            (categoria) => SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(categoria),
              child: Text(categoria[0].toUpperCase() + categoria.substring(1)),
            ),
          )
          .toList(),
    );
  }
}
