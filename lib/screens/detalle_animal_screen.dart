// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../widgets/condicion_corporal_chip.dart, estado_fertil_chip.dart y
//   etapa_vida_chip.dart: los chips de color que muestran el valor actual a la
//   derecha de cada fila.
// - Las sub-pantallas de edición (condición corporal, estado fértil, etapa de
//   vida, vacunas, observaciones y video), que abro desde cada fila.
// - ../services/animales_service.dart y ../widgets/dialogo_alta_animal.dart:
//   para editar los datos básicos con el lápiz.
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

// ============================================================
// detalle_animal_screen — Pantalla 4 del flujo
//
// Qué hace este archivo:
// Es la ficha de un animal. Arriba muestro su categoría y su nombre con un
// lápiz para editarlo, y abajo un menú con cada dato (raza, condición
// corporal, estado fértil, etapa de vida, vacunas, observaciones y video).
// Cada fila abre su sub-pantalla.
// ============================================================
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

// ---------------------------------------------------------------------------
// _DetalleAnimalScreenState — el estado de la ficha
//
// Guardo una copia del animal en _animal. Arranca con el que me pasaron, y la
// reemplazo cada vez que una sub-pantalla o el lápiz me devuelven el animal
// actualizado, así la ficha muestra siempre lo último sin volver a Supabase.
// ---------------------------------------------------------------------------
class _DetalleAnimalScreenState extends State<DetalleAnimalScreen> {
  late Animal _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  // ---------------------------------------------------------------------------
  // _abrir — abre una sub-pantalla y recibe el animal actualizado
  //
  // Hago push de la pantalla que me pasen y espero a que vuelva. Si me devuelve
  // un Animal (porque se guardó algo), lo pongo en _animal con setState y los
  // chips se actualizan. Si vuelven sin guardar, llega null y no cambio nada.
  // ---------------------------------------------------------------------------
  Future<void> _abrir(Widget pantalla) async {
    final resultado = await Navigator.of(
      context,
    ).push<Animal>(MaterialPageRoute(builder: (_) => pantalla));
    if (resultado != null && mounted) {
      setState(() => _animal = resultado);
    }
  }

  // ---------------------------------------------------------------------------
  // _editar — editar los datos básicos (lápiz y fila de Raza)
  //
  // Reuso DialogoAltaAnimal, pero precargado con los datos actuales del animal.
  // Si no cancelan, guardo los cambios con AnimalesService y me quedo con el
  // animal que me devuelve Supabase.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _categoriasHembra — qué categorías son hembras
  //
  // La uso en build para decidir si muestro la fila de Estado Fértil: solo
  // tiene sentido para vaca, ternera y vaquillona.
  // ---------------------------------------------------------------------------
  static const _categoriasHembra = {'vaca', 'ternera', 'vaquillona'};

  // ---------------------------------------------------------------------------
  // build — encabezado con nombre y lápiz, y el menú de datos del animal
  //
  // Arriba, el CategoriaBadge y el nombre centrados (el SizedBox de 48 a la
  // izquierda compensa el ancho del lápiz). Abajo, una _FilaMenu por dato.
  // Condición, estado fértil, etapa y observaciones se abren con _abrir;
  // Vacunas y Video con un push común, sin esperar nada de vuelta.
  // ---------------------------------------------------------------------------
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
            imagen: 'assets/images/vaca2.png',
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
            imagen: 'assets/images/vaca2.png',
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

// ---------------------------------------------------------------------------
// _FilaMenu — una fila del menú de la ficha
//
// Es un ListTile con ícono (o una imagen de assets), el nombre del dato y, a
// la derecha, el chip con el valor actual. El assert obliga a pasar ícono o
// imagen. Al trailing le pongo un ancho máximo para que no tape el texto.
// ---------------------------------------------------------------------------
class _FilaMenu extends StatelessWidget {
  final IconData? icono;
  final String? imagen; // ruta de un asset, en lugar del ícono
  final String etiqueta;
  final VoidCallback onTap;
  final Widget? trailing;

  const _FilaMenu({
    this.icono,
    this.imagen,
    required this.etiqueta,
    required this.onTap,
    this.trailing,
  }) : assert(icono != null || imagen != null);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: imagen != null
          ? Image.asset(imagen!, width: 28, height: 28, fit: BoxFit.contain)
          : Icon(icono, color: AppColors.marronPrincipal),
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