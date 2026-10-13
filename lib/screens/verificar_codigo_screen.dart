// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - supabase_flutter: por AuthException, para leer el código de error (por
//   ejemplo 'otp_expired' cuando el código venció).
// - ../widgets/password_checklist.dart: los requisitos de la contraseña nueva.
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/password_checklist.dart';

// ============================================================
// verificar_codigo_screen — Sub-pantalla de recuperación de contraseña
// (se llega desde la Pantalla 0 o desde Información Personal)
//
// Qué hace este archivo:
// Termino de restablecer la contraseña con el código que llega por mail, en
// dos pasos: primero confirmo el código y recién ahí aparece el campo de la
// contraseña nueva. Antes se usaba un link a docs/restablecer.html; con el
// código todo pasa adentro de la app, así que no choca con PKCE.
// ============================================================
class VerificarCodigoScreen extends StatefulWidget {
  final String email;

  const VerificarCodigoScreen({super.key, required this.email});

  @override
  State<VerificarCodigoScreen> createState() => _VerificarCodigoScreenState();
}

// ---------------------------------------------------------------------------
// _VerificarCodigoScreenState — en qué paso estoy
//
// _codigoVerificado decide qué paso se ve: false = pedir el código, true =
// pedir la contraseña nueva. Tengo un controller para cada campo, el ojito de
// la contraseña, _cargando para los botones y _error para el mensaje en rojo.
// ---------------------------------------------------------------------------
class _VerificarCodigoScreenState extends State<VerificarCodigoScreen> {
  final _authService = AuthService();
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _codigoVerificado = false;
  bool _mostrarPassword = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // _verificarCodigo — paso 1: confirmar el código del mail
  //
  // Si está vacío aviso. Si no, se lo mando a Supabase con el mail. Si es
  // correcto, cierro el teclado y paso al paso 2. Si venció ('otp_expired')
  // muestro un mensaje claro para pedir otro; si es otro error, su mensaje.
  // ---------------------------------------------------------------------------
  Future<void> _verificarCodigo() async {
    if (_codigoController.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el código que te mandamos.');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await _authService.verificarCodigoRecuperacion(
        email: widget.email,
        codigo: _codigoController.text.trim(),
      );
      if (mounted) {
        // Cerrar el teclado numerico del codigo antes de mostrar el campo de
        // contraseña — si el foco pasa directo de un campo a otro en la
        // misma pantalla, Android a veces no actualiza el tipo de teclado y
        // se queda mostrando el numerico.
        FocusScope.of(context).unfocus();
        setState(() => _codigoVerificado = true);
      }
    } on AuthException catch (e) {
      setState(
        () => _error = e.code == 'otp_expired'
            ? 'El código está vencido o es incorrecto. Pedí uno nuevo.'
            : e.message,
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // _guardarPassword — paso 2: guardar la contraseña nueva
  //
  // Si no cumple el checklist, aviso y corto. Si cumple, la guardo con
  // AuthService y vuelvo a la primera pantalla de la pila (popUntil isFirst).
  // TODO: revisar en la presentación — confirmar a qué pantalla cae en cada
  // camino (desde el login o desde Información Personal).
  // ---------------------------------------------------------------------------
  Future<void> _guardarPassword() async {
    if (!PasswordChecklist.esValida(_passwordController.text)) {
      setState(
        () => _error = 'La contraseña no cumple los requisitos de abajo',
      );
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await _authService.cambiarPassword(_passwordController.text);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // build — muestra el paso 1 o el paso 2
  //
  // Arriba, un texto que cambia según el paso. Paso 1: campo de código con
  // teclado numérico y "Confirmar código". Paso 2: contraseña nueva con ojito,
  // el checklist y "Guardar contraseña". Abajo de todo, el error si hay.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _codigoVerificado
                  ? 'Código confirmado. Elegí tu contraseña nueva.'
                  : 'Te mandamos un código a ${widget.email}. Escribilo acá abajo.',
            ),
            const SizedBox(height: 16),
            if (!_codigoVerificado) ...[
              TextField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Código'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargando ? null : _verificarCodigo,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmar código'),
              ),
            ] else ...[
              TextField(
                controller: _passwordController,
                obscureText: !_mostrarPassword,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'Contraseña nueva',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _mostrarPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _mostrarPassword = !_mostrarPassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Reconstruir solo el checklist (no el TextField entero) en
              // cada tecla — ver el comentario igual en cambiar_password_screen.dart.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _passwordController,
                builder: (context, valor, _) =>
                    PasswordChecklist(password: valor.text),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargando ? null : _guardarPassword,
                child: _cargando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar contraseña'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
