import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ilustracion que representa la categoria del animal (columna "sexo") — sin
/// texto, se muestra al lado del ID en la tarjeta (Pantallas 2 y 3) y arriba
/// de todo en la Pantalla 4. Es solo referencia visual, no es un boton.
class CategoriaBadge extends StatelessWidget {
  final String? categoria;

  const CategoriaBadge({super.key, required this.categoria});

  String? get _asset {
    switch (categoria) {
      case 'vaca':
        return 'assets/images/vaca.png';
      case 'toro':
        return 'assets/images/toro.png';
      case 'ternero':
        return 'assets/images/ternero.png';
      case 'ternera':
        return 'assets/images/ternera.png';
      case 'vaquillona':
        return 'assets/images/vaquillona.png';
      default:
        return null;
    }
  }

  // Celeste para las categorias macho, rosa para las hembra — a este tamaño
  // (28px) la orientacion del dibujo sola no alcanza para distinguirlas de un
  // vistazo, hace falta tambien un color.
  Color get _color {
    switch (categoria) {
      case 'toro':
      case 'ternero':
        return AppColors.celesteMacho;
      default:
        return AppColors.rosaHembra;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    if (asset == null) {
      return const Icon(Icons.pets, color: AppColors.marronPrincipal, size: 26);
    }
    return Image.asset(
      asset,
      width: 28,
      height: 28,
      fit: BoxFit.contain,
      color: _color,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}
