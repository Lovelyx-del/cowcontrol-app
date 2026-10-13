// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - supabase_flutter: acá lo uso por AuthException, el error que tira Supabase
//   cuando algo de la sesión o la contraseña sale mal.
// - ../widgets/password_checklist.dart: la lista de requisitos de la
//   contraseña, la misma que en el registro.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/password_checklist.dart';

// ============================================================
// cambiar_password_screen — Sub-pantalla de Información Personal
//
// Qué hace este archivo:
// Cambio la contraseña estando ya logueado. Pido la actual (que Supabase
// verifica) y la nueva, con el mismo checklist de requisitos del registro.
// No depende de ningún mail, así que anda aunque falle la recuperación.
// ============================================================
class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

// ---------------------------------------------------------------------------
// _CambiarPasswordScreenState — el formulario y su estado
//
// Tengo un controller por campo, _formKey para validar los dos juntos,
// _mostrarActual/_mostrarNueva para el ojito de cada campo, _cargando para
// el botón y _error para el mensaje en rojo. _passwordEsValida le pregunta
// al PasswordChecklist si la nueva cumple todo.
// ---------------------------------------------------------------------------
class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();

  bool _mostrarActual = false;
  bool _mostrarNueva = false;
  bool _cargando = false;
  String? _error;

  bool get _passwordEsValida =>
      PasswordChecklist.esValida(_passwordNuevaController.text);

  @override
  void dispose() {
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // _cambiar — verifica la actual y guarda la nueva
  //
  // Primero valido el formulario. Después verifico la contraseña actual contra
  // Supabase; si está mal, muestro el error y corto. Si está bien, cambio la
  // contraseña, vuelvo atrás y aviso con un SnackBar. Si Supabase tira un
  // AuthException, muestro su mensaje.
  // ---------------------------------------------------------------------------
  Future<void> _cambiar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final actualCorrecta = await _authService.verificarPasswordActual(
        _passwordActualController.text,
      );
      if (!actualCorrecta) {
        setState(() => _error = 'La contraseña actual es incorrecta.');
        return;
      }
      await _authService.cambiarPassword(_passwordNuevaController.text);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña cambiada con exito.')),
        );
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // build — los dos campos, el checklist y el botón
  //
  // Es un Form con dos TextFormField: cada uno tiene su validator y un ojito
  // para mostrar u ocultar lo que se escribe. Debajo de la nueva va el
  // checklist de requisitos, después el error (si hay) y el botón.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _passwordActualController,
                obscureText: !_mostrarActual,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarActual ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _mostrarActual = !_mostrarActual),
                  ),
                ),
                validator: (valor) => (valor == null || valor.isEmpty)
                    ? 'Ingresa tu contraseña actual'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordNuevaController,
                obscureText: !_mostrarNueva,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Contraseña nueva',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarNueva ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _mostrarNueva = !_mostrarNueva),
                  ),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'Ingresa una contraseña nueva';
                  }
                  if (!_passwordEsValida) {
                    return 'La contraseña no cumple los requisitos de abajo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // ValueListenableBuilder en vez de onChanged+setState en el
              // TextFormField de arriba: reconstruir el campo entero en cada
              // tecla puede desincronizar lo que el teclado de Android
              // compone de lo que queda en el controller (bug conocido de
              // Flutter) — reconstruyendo solo el checklist se evita del todo.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _passwordNuevaController,
                builder: (context, valor, _) =>
                    PasswordChecklist(password: valor.text),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cargando ? null : _cambiar,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Cambiar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
