import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Indicador visual de la etapa de vida del animal
/// ('muy_joven' / 'para_destetar' / 'para_vender_carnear' /
///  'adulto_fertil' / 'adulto_mayor').
/// Resalta con ⚠️ y color rojo cuando el animal necesita atención
/// (para destetar o para vender/carnear).
class EtapaVidaChip extends StatelessWidget {
  final String? valor;

  const EtapaVidaChip({super.key, required this.valor});

  static const _labels = {
    'muy_joven': 'Muy joven',
    'para_destetar': 'Para destetar',
    'para_vender_carnear': 'Para vender/carnear',
    'adulto_fertil': 'Adulto fértil',
    'adulto_mayor': 'Adulto mayor',
  };

  bool get _necesitaAlerta =>
      valor == 'para_destetar' || valor == 'para_vender_carnear';

  Color _color() {
    if (_necesitaAlerta) return Colors.redAccent;
    switch (valor) {
      case 'muy_joven':
        return Colors.lightBlue;
      case 'adulto_fertil':
        return AppColors.verdeVivo;
      case 'adulto_mayor':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (valor == null) {
      return const Chip(label: Text('Etapa de vida: sin dato'));
    }
    final label = _labels[valor] ?? valor!;
    return Chip(
      avatar: Icon(
        _necesitaAlerta ? Icons.warning_amber_rounded : Icons.pets,
        size: 18,
        color: Colors.white,
      ),
      label: Text(
        _necesitaAlerta ? '⚠️ $label' : label,
      ),
      backgroundColor: _color(),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}