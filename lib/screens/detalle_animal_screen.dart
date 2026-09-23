import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/campo.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_badge.dart';
import 'condicion_corporal_screen.dart';
import 'observaciones_screen.dart';
import 'vacunas_screen.dart';
import 'video_screen.dart';

/// Pantalla 4 — ficha de un animal: nombre del campo en el appbar (igual que
/// el resto de las pantallas), ID + categoria juntos arriba, y una lista de
/// accesos (Condicion Corporal, Vacunas, Observaciones, Video) estilo menu de
/// configuracion (fila con icono + texto, sin flecha).
///
/// Stateful porque Condicion Corporal devuelve el animal actualizado al
/// volver (`Navigator.pop(animalActualizado)`) — sin esto, si el productor
/// guardaba un cambio y volvia a entrar a la misma pantalla para revisar,
/// veia el valor viejo (el animal que llega por parametro nunca se volvia a
/// pedir a Supabase) y parecia que no habia guardado nada. Observaciones ya
/// no devuelve nada (maneja su propia lista aparte, ver ObservacionesScreen),
/// pero sigue pasando por `_abrir` sin problema: si el pop no trae valor,
/// simplemente no actualiza `_animal`.
class DetalleAnimalScreen extends StatefulWidget {
  final Animal animal;
  final Campo campo;

  const DetalleAnimalScreen({
    super.key,
    required this.animal,
    required this.campo,
  });

  @override
  State<DetalleAnimalScreen> createState() => _DetalleAnimalScreenState();
}

class _DetalleAnimalScreenState extends State<DetalleAnimalScreen> {
  late Animal _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  Future<void> _abrir(Widget pantalla) async {
    final resultado = await Navigator.of(
      context,
    ).push<Animal>(MaterialPageRoute(builder: (_) => pantalla));
    if (resultado != null && mounted) {
      setState(() => _animal = resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campo.nombreCampo),
        centerTitle: false,
        titleSpacing: 12,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CategoriaBadge(categoria: _animal.categoria),
                const SizedBox(width: 8),
                Text(
                  _animal.nombreMostrado,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          _FilaMenu(
            icono: Icons.favorite,
            etiqueta: 'Condicion Corporal',
            onTap: () => _abrir(CondicionCorporalScreen(animal: _animal)),
          ),
          _FilaMenu(
            icono: Icons.vaccines,
            etiqueta: 'Vacunas',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VacunasScreen(animal: _animal)),
            ),
          ),
          _FilaMenu(
            icono: Icons.visibility,
            etiqueta: 'Observaciones',
            onTap: () => _abrir(ObservacionesScreen(animal: _animal)),
          ),
          _FilaMenu(
            icono: Icons.videocam,
            etiqueta: 'Video',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VideoScreen(animal: _animal)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila del menu de la Pantalla 4 — icono a la izquierda y texto, estilo
/// el menu de "Configuracion y actividad" de Instagram.
class _FilaMenu extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  const _FilaMenu({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: AppColors.marronPrincipal),
      title: Text(etiqueta),
      onTap: onTap,
    );
  }
}
