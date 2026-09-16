import 'package:flutter/material.dart';

import '../models/campo.dart';
import '../services/auth_service.dart';
import '../services/campos_service.dart';
import 'planilla_screen.dart';

/// Pantalla 1 — lista los campos del productor logueado (filtrados por RLS).
/// Si tiene uno solo, entra directo a la planilla; si no tiene ninguno,
/// ofrece crear el primero.
class SelectorCampoScreen extends StatefulWidget {
  const SelectorCampoScreen({super.key});

  @override
  State<SelectorCampoScreen> createState() => _SelectorCampoScreenState();
}

class _SelectorCampoScreenState extends State<SelectorCampoScreen> {
  final _camposService = CamposService();
  final _authService = AuthService();

  late Future<List<Campo>> _futureCampos;

  @override
  void initState() {
    super.initState();
    _futureCampos = _cargarCampos();
  }

  Future<List<Campo>> _cargarCampos() async {
    final campos = await _camposService.traerCampos();
    if (campos.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PlanillaScreen(campo: campos.first),
          ),
        );
      });
    }
    return campos;
  }

  void _recargar() {
    setState(() => _futureCampos = _cargarCampos());
  }

  Future<void> _crearCampo() async {
    final resultado = await showDialog<_DatosNuevoCampo>(
      context: context,
      builder: (_) => const _FormularioNuevoCampo(),
    );
    if (resultado == null) return;
    await _camposService.crearCampo(
      nombreCampo: resultado.nombre,
      ubicacion: resultado.ubicacion,
    );
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tus campos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
            onPressed: () => _authService.cerrarSesion(),
          ),
        ],
      ),
      body: FutureBuilder<List<Campo>>(
        future: _futureCampos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar campos: ${snapshot.error}'),
            );
          }
          final campos = snapshot.data ?? [];
          if (campos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Todavia no tenes ningun campo cargado.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _crearCampo,
                      child: const Text('Crear mi primer campo'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: campos.length,
            itemBuilder: (context, indice) {
              final campo = campos[indice];
              return ListTile(
                leading: const Icon(Icons.landscape),
                title: Text(campo.nombreCampo),
                subtitle: campo.ubicacion == null
                    ? null
                    : Text(campo.ubicacion!),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlanillaScreen(campo: campo),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearCampo,
        tooltip: 'Crear campo nuevo',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DatosNuevoCampo {
  final String nombre;
  final String? ubicacion;

  _DatosNuevoCampo(this.nombre, this.ubicacion);
}

class _FormularioNuevoCampo extends StatefulWidget {
  const _FormularioNuevoCampo();

  @override
  State<_FormularioNuevoCampo> createState() => _FormularioNuevoCampoState();
}

class _FormularioNuevoCampoState extends State<_FormularioNuevoCampo> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ubicacionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo campo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre del campo'),
              validator: (valor) =>
                  (valor == null || valor.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ubicacionController,
              decoration: const InputDecoration(
                labelText: 'Ubicacion (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              _DatosNuevoCampo(
                _nombreController.text.trim(),
                _ubicacionController.text.trim().isEmpty
                    ? null
                    : _ubicacionController.text.trim(),
              ),
            );
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
