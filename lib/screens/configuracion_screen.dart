import 'package:flutter/material.dart';

import '../models/campo.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'historial_screen.dart';
import 'informacion_personal_screen.dart';
import 'login_screen.dart';

/// Pantalla de configuracion — se entra desde el icono de tuerca en la
/// Planilla. Junta el Historial de lecturas (que antes estaba directo en el
/// AppBar) y Cerrar sesion, con una confirmacion antes de cerrarla de verdad.
class ConfiguracionScreen extends StatelessWidget {
  final Campo campo;

  const ConfiguracionScreen({super.key, required this.campo});

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
    // pushAndRemoveUntil en vez de confiar en AuthGate: cuando hay un solo
    // campo, SelectorCampoScreen entra con pushReplacement (ver seccion 16),
    // asi que AuthGate ya no esta en el arbol de widgets para reaccionar solo
    // al cierre de sesion.
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
