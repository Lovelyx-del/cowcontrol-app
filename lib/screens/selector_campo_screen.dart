// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../models/campo.dart: la clase Campo (id, nombre y ubicación de un campo).
// - ../services/campos_service.dart: el que trae y crea campos en Supabase.
import 'package:flutter/material.dart';

import '../models/campo.dart';
import '../services/auth_service.dart';
import '../services/campos_service.dart';
import 'planilla_screen.dart';

// ============================================================
// selector_campo_screen — Pantalla 1 del flujo
//
// Qué hace este archivo:
// Muestro la lista de campos del productor que inició sesión (Supabase ya me
// filtra solo los suyos con RLS). Si tiene uno solo, lo mando directo a la
// planilla; si no tiene ninguno, le ofrezco crear el primero.
// ============================================================
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

  // ---------------------------------------------------------------------------
  // _cargarCampos — trae los campos y, si hay uno solo, entra directo
  //
  // Le pido los campos a CamposService. Si vuelve exactamente uno, espero a que
  // termine de dibujarse el frame (addPostFrameCallback) y reemplazo esta
  // pantalla por la planilla de ese campo. _recargar lo vuelve a llamar.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _crearCampo — abre el diálogo de campo nuevo y lo guarda
  //
  // Muestro _FormularioNuevoCampo como diálogo y espero lo que devuelve. Si el
  // usuario canceló, viene null y no hago nada. Si no, lo creo en Supabase y
  // recargo la lista para que aparezca el campo nuevo.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // build — la lista de campos con sus cuatro estados posibles
  //
  // Uso un FutureBuilder sobre _futureCampos: mientras carga muestro una
  // ruedita, si falla muestro el error, si no hay campos muestro el botón de
  // "Crear mi primer campo", y si hay muestro la lista. Arriba está el botón de
  // cerrar sesión (AuthGate me devuelve al login solo).
  // ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// _DatosNuevoCampo — el "paquete" que devuelve el diálogo
//
// Es una clase mínima con el nombre y la ubicación (opcional). La uso para que
// el diálogo me devuelva los dos datos juntos en un solo objeto al cerrarse.
// ---------------------------------------------------------------------------
class _DatosNuevoCampo {
  final String nombre;
  final String? ubicacion;

  _DatosNuevoCampo(this.nombre, this.ubicacion);
}

// ---------------------------------------------------------------------------
// _FormularioNuevoCampo — el diálogo para crear un campo
//
// Es un AlertDialog con dos campos: nombre (obligatorio) y ubicación
// (opcional). Al tocar "Crear" valido, y si está bien cierro el diálogo con
// pop pasándole un _DatosNuevoCampo. Si la ubicación quedó vacía, mando null.
// ---------------------------------------------------------------------------
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
