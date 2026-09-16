import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Indicador visual de la condicion corporal declarada por el productor
/// ('buena' / 'regular' / 'mala').
class CondicionCorporalChip extends StatelessWidget {
  final String? valor;

  const CondicionCorporalChip({super.key, required this.valor});

  Color _color() {
    switch (valor) {
      case 'buena':
        return AppColors.verdeVivo;
      case 'regular':
        return Colors.amber;
      case 'mala':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (valor == null) {
      return const Chip(label: Text('Condicion Corporal: sin dato'));
    }
    return Chip(
      avatar: const Icon(Icons.favorite_outline, size: 18, color: Colors.white),
      label: Text('Condicion Corporal: $valor'),
      backgroundColor: _color(),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
