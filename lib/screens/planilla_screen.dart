import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/campo.dart';
import '../services/animales_service.dart';
import '../services/lecturas_service.dart';
import '../widgets/dialogo_alta_animal.dart';
import '../theme/app_theme.dart';
import '../widgets/animal_card.dart';
import '../widgets/categoria_badge.dart';
import 'configuracion_screen.dart';
import 'conteo_screen.dart';
import 'detalle_animal_screen.dart';

/// Pantalla 2 — planilla general: lista los animales vivos del campo
/// seleccionado, con busqueda por rfid_uid y filtro por categoria.
class PlanillaScreen extends StatefulWidget {
  final Campo campo;

  const PlanillaScreen({super.key, required this.campo});

  @override
  State<PlanillaScreen> createState() => _PlanillaScreenState();
}

class _PlanillaScreenState extends State<PlanillaScreen> {
  final _animalesService = AnimalesService();
  final _lecturasService = LecturasService();
  final _busquedaController = TextEditingController();
  late Future<List<Animal>> _futureAnimales;
  late Future<List<String>> _futureNoRegistrados;

  String? _categoriaFiltro;

  static const _categorias = [
    'vaca',
    'toro',
    'ternero',
    'ternera',
    'vaquillona',
  ];

  @override
  void initState() {
    super.initState();
    _futureAnimales = _animalesService.traerAnimalesDeCampo(widget.campo.id);
    _futureNoRegistrados = _lecturasService.traerNoRegistrados(widget.campo.id);
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _recargar() async {
    setState(() {
      _futureAnimales = _animalesService.traerAnimalesDeCampo(widget.campo.id);
      _futureNoRegistrados = _lecturasService.traerNoRegistrados(widget.campo.id);
    });
  }

  Future<void> _eliminarNoRegistrado(String rfidUid) async {
    await _lecturasService.descartarTag(rfidUid, widget.campo.id);
    _recargar();
  }

  Future<void> _agregarNoRegistrado(String rfidUid) async {
    final datos = await showDialog<DatosAltaAnimal>(
      context: context,
      builder: (_) => const DialogoAltaAnimal(),
    );
    if (datos == null) return;
    await _animalesService.crearAnimal(
      rfidUid: rfidUid,
      campoId: widget.campo.id,
      categoria: datos.categoria,
      animalId: datos.animalId,
      apodo: datos.apodo,
      raza: datos.raza,
    );
    _recargar();
  }

  List<Animal> _filtrar(List<Animal> animales, String busqueda) {
    return animales.where((animal) {
      final coincideBusqueda =
          busqueda.isEmpty ||
          animal.animalId.toLowerCase().contains(busqueda.toLowerCase());
      final coincideCategoria =
          _categoriaFiltro == null || animal.categoria == _categoriaFiltro;
      return coincideBusqueda && coincideCategoria;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campo.nombreCampo),
        centerTitle: false,
        titleSpacing: 12,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuracion',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConfiguracionScreen(campo: widget.campo),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.fondo,
                      border: Border.all(color: AppColors.marronPrincipal),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _busquedaController,
                              expands: true,
                              maxLines: null,
                              minLines: null,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                filled: false,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.fondo,
                      border: Border.all(color: AppColors.marronPrincipal),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _categoriaFiltro,
                      hint: const Text('Categoria'),
                      underline: const SizedBox(),
                      icon: const SizedBox(),
                      dropdownColor: AppColors.fondo,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ..._categorias.map(
                          (categoria) => DropdownMenuItem<String?>(
                            value: categoria,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(categoria),
                                CategoriaBadge(categoria: categoria),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (valor) =>
                          setState(() => _categoriaFiltro = valor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _recargar,
              child: FutureBuilder<List<Animal>>(
                future: _futureAnimales,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar animales: ${snapshot.error}',
                      ),
                    );
                  }
                  final todos = snapshot.data ?? [];
                  // ValueListenableBuilder en vez de leer _busquedaController.text
                  // directo del build de arriba: asi solo esta lista se
                  // reconstruye en cada tecla, el TextField del buscador queda
                  // intacto (mismo motivo que el fix del checklist de
                  // contraseña — reconstruir el campo de texto en cada tecla
                  // puede desincronizar lo tipeado de lo que queda guardado).
                  return ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _busquedaController,
                    builder: (context, valorBusqueda, _) {
                      final animales = _filtrar(todos, valorBusqueda.text);
                      if (animales.isEmpty) {
                        return ListView(
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text('No hay animales para mostrar.'),
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        itemCount: animales.length,
                        itemBuilder: (context, indice) {
                          final animal = animales[indice];
                          return AnimalCard(
                            animal: animal,
                            estiloPlanilla: true,
                            onVerMas: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DetalleAnimalScreen(
                                  animal: animal,
                                  campo: widget.campo,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
          FutureBuilder<List<String>>(
            future: _futureNoRegistrados,
            builder: (context, snapshot) {
              final pendientes = snapshot.data ?? [];
              if (pendientes.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'No registrados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.naranjaTostado,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...pendientes.map(
                      (uid) => Card(
                        child: ListTile(
                          title: Text(
                            uid,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () => _eliminarNoRegistrado(uid),
                                child: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _agregarNoRegistrado(uid),
                                child: const Text(
                                  'Añadir',
                                  style: TextStyle(color: AppColors.verdeVivo),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () async {
                  final animales = await _futureAnimales;
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ConteoScreen(campo: widget.campo, animales: animales),
                    ),
                  );
                },
                child: const Text('Iniciar Conteo'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
