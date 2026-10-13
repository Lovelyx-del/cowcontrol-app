// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - ../main.dart: de ahí saco AuthGate, a donde vuelvo al cerrar sesión.
// - ../services/auth_service.dart: el que cierra la sesión en Supabase.
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/campo.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'historial_screen.dart';
import 'informacion_personal_screen.dart';

// ============================================================
// configuracion_screen — Sub-pantalla de la Pantalla 2 (engranaje de la planilla)
//
// Qué hace este archivo:
// Es el menú de configuración. Desde acá voy al Historial de lecturas, a la
// Información Personal del usuario, y puedo cerrar sesión (con una
// confirmación antes, para que no se cierre por un toque sin querer).
// ============================================================
class ConfiguracionScreen extends StatelessWidget {
  final Campo campo;

  const ConfiguracionScreen({super.key, required this.campo});

  // ---------------------------------------------------------------------------
  // _confirmarCerrarSesion — pregunta, cierra sesión y vuelve al inicio
  //
  // Muestro un diálogo de Sí/No. Solo si tocan "Si" cierro la sesión con
  // AuthService y borro toda la pila de pantallas, dejando solo AuthGate. Así
  // no se puede volver atrás a la planilla sin estar logueado.
  // ---------------------------------------------------------------------------
  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesion'),
        content: const Text('¿Estas seguro de que queres cerrar sesion?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Si'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await AuthService().cerrarSesion();
    // Volver a AuthGate, no a un LoginScreen suelto: con un solo campo,
    // SelectorCampoScreen entra con pushReplacement (ver seccion 16) y saca a
    // AuthGate de la pila. Hay que reconstruirlo para que el proximo login
    // dispare onAuthStateChange y avance solo.
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(
              Icons.history,
              color: AppColors.marronPrincipal,
            ),
            title: const Text('Historial de lecturas'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HistorialScreen(campo: campo)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.marronPrincipal),
            title: const Text('Informacion Personal'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const InformacionPersonalScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.marronPrincipal),
            title: const Text('Cerrar sesion'),
            onTap: () => _confirmarCerrarSesion(context),
          ),
        ],
      ),
    );
  }
}
