import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/password_checklist.dart';
import 'verificar_codigo_screen.dart';

/// Traduce los codigos de error de Supabase Auth a mensajes en español que un
/// productor pueda entender, sin exponer el detalle tecnico de la excepcion.
String _mensajeError(Object error, {required String mensajeGenerico}) {
  if (error is AuthException) {
    switch (error.code) {
      case 'email_not_confirmed':
        return 'Todavia no confirmaste tu email. Revisa tu correo y toca el '
            'link de confirmacion antes de iniciar sesion.';
      case 'invalid_credentials':
        return 'Email o contraseña incorrectos.';
      case 'user_already_exists':
        return 'Ya existe una cuenta registrada con ese email.';
      case 'weak_password':
        return 'La contraseña no cumple los requisitos minimos (8 caracteres, '
            'con letras y numeros).';
      case 'over_email_send_rate_limit':
        return 'Se enviaron demasiados emails. Espera unos minutos e intenta de nuevo.';
    }
  }
  return mensajeGenerico;
}

/// Pantalla 0 — login/registro con Supabase Auth. Al loguearse con exito no
/// navega a mano: AuthGate (main.dart) escucha el cambio de sesion y muestra
/// la Pantalla 1 automaticamente.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _esRegistro = false;
  bool _cargando = false;
  bool _mostrarPassword = false;
  String? _error;
  String? _mensajeExito;

  // Requisitos de contraseña — solo se exigen al registrarse, no al iniciar
  // sesion (una cuenta vieja puede tener una contraseña mas corta que la
  // regla actual, y no tiene que quedar bloqueada por eso).
  bool get _passwordEsValida =>
      PasswordChecklist.esValida(_passwordController.text);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
      _mensajeExito = null;
    });
    try {
      if (_esRegistro) {
        final respuesta = await _authService.registrarse(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        // Supabase no tira error si el mail ya existe y ya esta confirmado
        // (para no revelar que mails tienen cuenta) — pero devuelve la lista
        // de "identities" vacia en ese caso, a diferencia de un registro
        // realmente nuevo. Es la unica forma de distinguir ambos casos.
        final yaExistia = respuesta.user?.identities?.isEmpty ?? false;
        setState(() {
          if (yaExistia) {
            _error = 'Ya existe una cuenta registrada con ese email.';
          } else {
            _mensajeExito =
                'Te registraste con exito. Revisa tu correo '
                '(y la carpeta de spam) y toca el link de confirmacion antes '
                'de iniciar sesion.';
          }
        });
      } else {
        await _authService.iniciarSesion(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      debugPrint('Error de auth (${_esRegistro ? "registro" : "login"}): $e');
      setState(() {
        _error = _mensajeError(
          e,
          mensajeGenerico: _esRegistro
              ? 'No se pudo completar el registro. Intenta de nuevo.'
              : 'No se pudo iniciar sesion. Intenta de nuevo.',
        );
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Manda el mail de "restablecer contraseña" (Supabase.resetPasswordForEmail)
  /// y lleva a la pantalla para escribir el código de 6 dígitos que trae ese
  /// mail — se confirma adentro de la app, no hace falta abrir el link.
  Future<void> _recuperarPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(
        () => _error = 'Escribi tu email arriba antes de tocar este boton.',
      );
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
      _mensajeExito = null;
    });
    try {
      await _authService.restablecerPassword(email: email);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VerificarCodigoScreen(email: email),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al pedir recuperacion de password: $e');
      setState(() {
        _error = _mensajeError(
          e,
          mensajeGenerico:
              'No se pudo enviar el mail de recuperacion. Intenta de nuevo.',
        );
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.pets,
                    size: 72,
                    color: AppColors.marronPrincipal,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'CowControl',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (valor) =>
                        (valor == null || !valor.contains('@'))
                        ? 'Ingresa un email valido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_mostrarPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _mostrarPassword = !_mostrarPassword,
                        ),
                      ),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) {
                        return 'Ingresa una contraseña';
                      }
                      if (_esRegistro && !_passwordEsValida) {
                        return 'La contraseña no cumple los requisitos de arriba';
                      }
                      return null;
                    },
                  ),
                  if (_esRegistro) ...[
                    const SizedBox(height: 8),
                    // Reconstruir solo el checklist (no el TextFormField
                    // entero) en cada tecla — un campo que se reconstruye
                    // completo mientras el teclado de Android todavia esta
                    // componiendo el texto puede terminar guardando algo
                    // distinto de lo que se escribio, sin ningun error.
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _passwordController,
                      builder: (context, valor, _) =>
                          PasswordChecklist(password: valor.text),
                    ),
                  ],
                  if (!_esRegistro)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _cargando ? null : _recuperarPassword,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                  if (_mensajeExito != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _mensajeExito!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _cargando ? null : _enviar,
                    child: _cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_esRegistro ? 'Registrarme' : 'Iniciar sesion'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () => setState(() {
                            _esRegistro = !_esRegistro;
                            _error = null;
                            _mensajeExito = null;
                          }),
                    child: Text(
                      _esRegistro
                          ? 'Ya tengo cuenta — Iniciar sesion'
                          : 'Soy nuevo — Registrarme',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
