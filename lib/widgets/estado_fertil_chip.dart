import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Indicador visual del estado fertil declarado por el productor
/// ('preñada' / 'amamantando' / 'no-fecundada').
/// Solo aplica a vacas (hembras); si el animal no es hembra, no muestra nada.
class EstadoFertilChip extends StatelessWidget {
  final String? valor;
  final bool esHembra;

  const EstadoFertilChip({
    super.key,
    required this.valor,
    required this.esHembra,
  });

  Color _color() {
    switch (valor) {
      case 'preñada':
        return AppColors.verdeVivo;
      case 'amamantando':
        return Colors.blue;
      case 'no-fecundada':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!esHembra) {
      return const SizedBox.shrink();
    }
    if (valor == null) {
      return const Chip(label: Text('Estado Fertil: sin dato'));
    }
    return Chip(
      avatar: const Icon(Icons.pregnant_woman, size: 18, color: Colors.white),
      label: Text('Estado Fertil: $valor'),
      backgroundColor: _color(),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}