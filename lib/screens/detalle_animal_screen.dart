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
import '../services/animales_service.dart';
import '../widgets/dialogo_alta_animal.dart';

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

  Future<void> _editar() async {
    final datos = await showDialog<DatosAltaAnimal>(
      context: context,
      builder: (_) => DialogoAltaAnimal(
        animalIdInicial: _animal.animalId,
        apodoInicial: _animal.apodo,
        categoriaInicial: _animal.categoria,
        razaInicial: _animal.raza,
      ),
    );
    if (datos == null) return;
    final actualizado = await AnimalesService().actualizarDatosAnimal(
      id: _animal.id,
      animalId: datos.animalId,
      apodo: datos.apodo,
      categoria: datos.categoria,
      raza: datos.raza,
    );
    if (mounted) setState(() => _animal = actualizado);
  }

  static const _categoriasHembra = {'vaca', 'ternera', 'vaquillona'};

  @override
  Widget build(BuildContext context) {
    final esHembra = _categoriasHembra.contains(_animal.categoria);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campo.nombreCampo),
        centerTitle: false,
        titleSpacing: 12,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 48),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategoriaBadge(categoria: _animal.categoria),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _animal.nombreMostrado,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _editar,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          _FilaMenu(
            icono: Icons.pets_outlined,
            etiqueta: 'Raza',
            trailing: Text(_animal.raza ?? 'Sin especificar'),
            onTap: _editar,
          ),
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
      title: Text(
        etiqueta,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing == null
          ? null
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: trailing,
            ),
      onTap: onTap,
    );
  }
}
