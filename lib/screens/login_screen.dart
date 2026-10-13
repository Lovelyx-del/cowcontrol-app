// ---------------------------------------------------------------------------
// Imports — las librerías que uso acá (y en casi todas las otras pantallas)
//
// - flutter/material.dart: la base de todo. Me da los widgets de Material
//   (Scaffold, TextFormField, botones, colores, temas). Sin esto no hay UI.
// - supabase_flutter: el paquete de Supabase. Acá lo uso por AuthException,
//   que es el tipo de error que tira Supabase Auth cuando algo sale mal.
// - ../services/auth_service.dart: la clase que envuelve login, registro y
//   recuperar contraseña. La pantalla no le habla directo a Supabase para eso.
// - ../widgets/password_checklist.dart: la lista de requisitos de contraseña
//   que se va tildando mientras escribís.
// - verificar_codigo_screen.dart: la pantalla a la que mando al usuario
//   después de tocar "¿Olvidaste tu contraseña?".
// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/password_checklist.dart';
import 'verificar_codigo_screen.dart';

// ============================================================
// login_screen — Pantalla 0 del flujo
//
// Qué hace este archivo:
// Es la pantalla de login y registro, las dos en una. Armé un formulario de
// email y contraseña, y con un botón abajo cambio entre "entrar" y "crear
// cuenta". Si el login sale bien no navego yo: AuthGate (main.dart) detecta
// la sesión nueva y muestra la Pantalla 1 solo.
// ============================================================

// ---------------------------------------------------------------------------
// _LoginColors — la paleta celeste que uso solo en el login
//
// El resto de la app usa AppTheme, pero para el login quise algo celeste.
// Junto los colores acá como constantes para no repetir códigos hex por todos
// lados: si cambio uno acá, cambia en toda la pantalla.
// ---------------------------------------------------------------------------
class _LoginColors {
  static const fondo = Color(0xFFEAF4FC);
  static const celesteClaro = Color(0xFFBFE0F5); // bordes de los campos
  static const principal = Color(0xFF1F78BD); // botón, foco y links
  static const texto = Color(0xFF12344D);
}

// ---------------------------------------------------------------------------
// _mensajeError — traduce los errores de Supabase a mensajes en español
//
// Supabase devuelve códigos en inglés como 'invalid_credentials'. Acá los paso
// a frases que un productor entienda, sin mostrarle el detalle técnico. Si el
// código no está en la lista, devuelvo el mensaje genérico que me pasan. Lo
// uso en _enviar y en _recuperarPassword.
// ---------------------------------------------------------------------------
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// ---------------------------------------------------------------------------
// _LoginScreenState — el estado de la pantalla
//
// Acá guardo los controllers de los dos campos y unas banderas. La clave es
// _esRegistro: con eso la misma pantalla sirve para entrar o para crear una
// cuenta, y cambian los textos, el checklist y lo que hace el botón.
// ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _enviar — lo que pasa cuando toco el botón principal
  //
  // Primero valido el formulario. En modo registro llamo a registrarse y miro
  // si "identities" vino vacía: así sé que el mail ya tenía cuenta (Supabase no
  // tira error en ese caso). En modo login llamo a iniciarSesion y nada más,
  // AuthGate se encarga del resto. Si algo falla, muestro _mensajeError.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _recuperarPassword — el botón "¿Olvidaste tu contraseña?"
  //
  // Uso el email que ya está escrito arriba (si no hay, aviso). Le pido a
  // Supabase que mande el mail de restablecer y abro VerificarCodigoScreen
  // para que el usuario escriba ahí el código de 6 dígitos, sin abrir el link.
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _temaLogin — el tema celeste que vale solo dentro de esta pantalla
  //
  // Parto del tema general de la app y le piso los colores con _LoginColors:
  // fondo, botones, bordes de los campos y el label cuando el campo tiene foco.
  // En build envuelvo todo en un Theme con esto, así no toco el resto de la app.
  // ---------------------------------------------------------------------------
  ThemeData _temaLogin(BuildContext context) {
    final base = Theme.of(context);
    OutlineInputBorder borde(Color color, {double ancho = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: ancho),
        );

    return base.copyWith(
      scaffoldBackgroundColor: _LoginColors.fondo,
      colorScheme: base.colorScheme.copyWith(
        primary: _LoginColors.principal,
        secondary: _LoginColors.principal,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _LoginColors.principal),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _LoginColors.principal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: borde(_LoginColors.celesteClaro),
        enabledBorder: borde(_LoginColors.celesteClaro),
        focusedBorder: borde(_LoginColors.principal, ancho: 2),
        floatingLabelStyle: const TextStyle(
          color: _LoginColors.principal,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // build — arma la pantalla: logo, campos, mensajes y botones
  //
  // Es un Form con los dos campos y sus validadores. Según _esRegistro muestro
  // el checklist de contraseña o el link de "olvidé mi contraseña". El botón
  // principal se deshabilita y muestra una ruedita mientras _cargando es true,
  // así nadie lo toca dos veces.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _temaLogin(context),
      child: Scaffold(
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
                    Image.asset(
                      'assets/images/vaca_sensor.png',
                      height: 120,
                      semanticLabel: 'Logo de CowControl',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'CowControl',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _LoginColors.texto,
                      ),
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
      ),
    );
  }
}
