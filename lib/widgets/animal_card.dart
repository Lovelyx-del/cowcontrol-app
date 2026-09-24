import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../theme/app_theme.dart';
import 'categoria_badge.dart';

/// Tarjeta de un animal — se reusa en la Planilla general (Pantalla 2) y en el
/// Conteo en vivo (Pantalla 3). Muestra el ID con el icono de categoria al
/// lado; el resto de los datos (condicion corporal, vacunas, observaciones) vive en
/// la Pantalla 4.
///
/// En el Conteo (`estiloPlanilla: false`, default) es una Card con elevacion.
/// En la Planilla (`estiloPlanilla: true`) es un recuadro con borde marron muy
/// redondeado y fondo igual al de la pantalla — mismo estilo "pildora" que
/// usan las filas de Cuenta de Google / Obtene un plan Google AI en el menu
/// de la Play Store, que fue la referencia visual pedida.
class AnimalCard extends StatelessWidget {
  final Animal animal;
  final bool detectado;
  final bool estiloPlanilla;
  final VoidCallback? onVerMas;

  const AnimalCard({
    super.key,
    required this.animal,
    this.detectado = false,
    this.estiloPlanilla = false,
    this.onVerMas,
  });

  Widget _tick() {
    return Icon(
      detectado ? Icons.check_circle : Icons.circle_outlined,
      color: detectado ? AppColors.verdeVivo : AppColors.marronPrincipal,
      size: 32,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!estiloPlanilla) {
      return Card(
        child: ListTile(
          leading: _tick(),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  animal.nombreMostrado,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              CategoriaBadge(categoria: animal.categoria),
            ],
          ),
          onTap: onVerMas,
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: AppColors.fondo,
        border: Border.all(color: AppColors.marronPrincipal),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onVerMas,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _tick(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  animal.nombreMostrado,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              CategoriaBadge(categoria: animal.categoria),
            ],
          ),
        ),
      ),
    );
  }
}
