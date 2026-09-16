import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/selector_campo_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Credenciales de Supabase: vienen del .env (nunca hardcodeadas ni subidas a git).
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const CowControlApp());
}

class CowControlApp extends StatelessWidget {
  const CowControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CowControl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.tema,
      home: const AuthGate(),
    );
  }
}

/// Decide que pantalla mostrar segun haya o no una sesion activa de Supabase
/// Auth. Escucha onAuthStateChange, asi que un login/logout desde cualquier
/// pantalla se refleja aca sin tener que navegar a mano.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final sesion =
            snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;
        if (sesion == null) {
          return const LoginScreen();
        }
        return const SelectorCampoScreen();
      },
    );
  }
}
