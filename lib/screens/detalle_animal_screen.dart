import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/campo.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_badge.dart';
import '../widgets/condicion_corporal_chip.dart';
import '../widgets/estado_fertil_chip.dart';
import '../widgets/etapa_vida_chip.dart';
import 'condicion_corporal_screen.dart';
import 'estado_fertil_screen.dart';
import 'etapa_vida_screen.dart';
import 'observaciones_screen.dart';
import 'vacunas_screen.dart';
import 'video_screen.dart';

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
    final esHembra = _animal.categoria == 'hembra';

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
            trailing: CondicionCorporalChip(valor: _animal.condicionCorporal),
            onTap: () => _abrir(CondicionCorporalScreen(animal: _animal)),
          ),
          if (esHembra)
            _FilaMenu(
              icono: Icons.pregnant_woman,
              etiqueta: 'Estado Fertil',
              trailing: EstadoFertilChip(
                valor: _animal.estadoFertil,
                esHembra: esHembra,
              ),
              onTap: () => _abrir(EstadoFertilScreen(animal: _animal)),
            ),
          _FilaMenu(
            icono: Icons.pets,
            etiqueta: 'Etapa de Vida',
            trailing: EtapaVidaChip(valor: _animal.etapaVida),
            onTap: () => _abrir(EtapaVidaScreen(animal: _animal)),
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

class _FilaMenu extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;
  final Widget? trailing;

  const _FilaMenu({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: AppColors.marronPrincipal),
      title: Text(etiqueta),
      trailing: trailing,
      onTap: onTap,
    );
  }
}