import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/password_checklist.dart';

/// Pantalla para terminar de restablecer la contraseña con el código que
/// manda el mail de recuperación — se llega acá justo después de pedir el
/// mail (desde login_screen.dart o informacion_personal_screen.dart).
///
/// Dos pasos, uno primero que el otro: se pide y confirma el código solo
/// (nada de contraseña todavía); recién cuando el código es correcto
/// aparece el campo de contraseña nueva. A diferencia del link de
/// docs/restablecer.html, el código se confirma adentro de la app, en el
/// mismo lugar donde se pidió el mail, así que no choca con PKCE.
class VerificarCodigoScreen extends StatefulWidget {
  final String email;

  const VerificarCodigoScreen({super.key, required this.email});

  @override
  State<VerificarCodigoScreen> createState() => _VerificarCodigoScreenState();
}

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
