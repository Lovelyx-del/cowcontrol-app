import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Login, registro y cierre de sesion via Supabase Auth (Pantalla 0).
class AuthService {
  final _client = SupabaseService.client;

  User? get usuarioActual => _client.auth.currentUser;

  /// Se dispara cada vez que cambia el estado de sesion (login, logout, token
  /// renovado). El widget raiz (main.dart) escucha esto para decidir que pantalla mostrar.
  Stream<AuthState> get cambiosDeSesion => _client.auth.onAuthStateChange;

  Future<AuthResponse> iniciarSesion({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> registrarse({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> cerrarSesion() {
    return _client.auth.signOut();
  }

  /// Manda el mail de "restablecer contraseña" — trae un codigo (ver
  /// [verificarCodigoRecuperacion]) y, de respaldo, un link a la pagina de
  /// GitHub Pages (docs/restablecer.html).
  Future<void> restablecerPassword({required String email}) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'https://lovelyx-del.github.io/cowcontrol/restablecer.html',
    );
  }

  /// Confirma el codigo del mail de recuperacion — se completa adentro de la
  /// app (mismo lugar donde se pidio el mail), asi que no depende del link
  /// ni de PKCE. Si es correcto, deja una sesion de "recuperacion" activa,
  /// suficiente para despues llamar a [cambiarPassword] una sola vez.
  Future<void> verificarCodigoRecuperacion({
    required String email,
    required String codigo,
  }) {
    return _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: codigo,
    );
  }

  /// Confirma que `password` es la contraseña actual de la cuenta logueada,
  /// re-intentando el login con el mismo email. Se usa antes de destapar
  /// datos sensibles (Informacion Personal) y antes de dejar cambiar la
  /// contraseña — no hace falta un endpoint aparte, Supabase no tiene uno
  /// para "verificar sin loguear", asi que el login mismo hace de verificacion.
  Future<bool> verificarPasswordActual(String password) async {
    final email = usuarioActual?.email;
    if (email == null) return false;
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return true;
    } on AuthException {
      return false;
    }
  }

  /// Cambia la contraseña de la cuenta ya logueada — a diferencia de
  /// [restablecerPassword], no manda ningun mail, actua directo sobre la
  /// sesion activa.
  Future<void> cambiarPassword(String nuevaPassword) {
    return _client.auth.updateUser(UserAttributes(password: nuevaPassword));
  }
}
