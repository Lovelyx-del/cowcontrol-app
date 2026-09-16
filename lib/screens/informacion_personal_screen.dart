import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/campo.dart';
import '../services/auth_service.dart';
import '../services/campos_service.dart';
import '../theme/app_theme.dart';
import 'cambiar_password_screen.dart';
import 'verificar_codigo_screen.dart';

/// Pantalla de datos de la cuenta — se llega acá desde Configuracion. El
/// mail y los campos del productor arrancan tapados (blureados en marron);
/// hay que escribir la contraseña actual y que se verifique de verdad contra
/// Supabase para destaparlos. "Cambiar contraseña" funciona ya (no depende
/// de mail); "Olvide mi contraseña" manda el mismo mail de siempre — sigue
/// sin funcionar del todo hasta que se resuelva el problema de spam/entrega
/// documentado en cosas_pendientes.md item 21.
class InformacionPersonalScreen extends StatefulWidget {
  const InformacionPersonalScreen({super.key});

  @override
  State<InformacionPersonalScreen> createState() =>
      _InformacionPersonalScreenState();
}

class _InformacionPersonalScreenState extends State<InformacionPersonalScreen> {
  final _authService = AuthService();
  late Future<List<Campo>> _futureCampos;

  final _passwordController = TextEditingController();
  bool _desbloqueado = false;
  bool _verificando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _futureCampos = CamposService().traerCampos();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verDatos() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Escribi tu contraseña para ver los datos.');
      return;
    }
    setState(() {
      _verificando = true;
      _error = null;
    });
    final correcta = await _authService.verificarPasswordActual(
      _passwordController.text,
    );
    setState(() {
      _verificando = false;
      if (correcta) {
        _desbloqueado = true;
      } else {
        _error = 'Contraseña incorrecta.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.usuarioActual?.email ?? 'sin dato';
    return Scaffold(
      appBar: AppBar(title: const Text('Informacion Personal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _datoOculto(email),
          const SizedBox(height: 20),
          const Text('Campos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          FutureBuilder<List<Campo>>(
            future: _futureCampos,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final campos = snapshot.data ?? [];
              if (campos.isEmpty) {
                return _datoOculto('Sin campos cargados');
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: campos
                    .map((campo) => _datoOculto(campo.nombreCampo))
                    .toList(),
              );
            },
          ),
          if (!_desbloqueado) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                hintText: 'Ingresala para ver los datos de arriba',
              ),
              onSubmitted: (_) => _verDatos(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _verificando ? null : _verDatos,
              child: _verificando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Ver datos'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
          const SizedBox(height: 28),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock, color: AppColors.marronPrincipal),
            title: const Text('Cambiar contraseña'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CambiarPasswordScreen()),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                await _authService.restablecerPassword(email: email);
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VerificarCodigoScreen(email: email),
                  ),
                );
              },
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra el texto normal si ya se desbloqueo con la contraseña, o
  /// blureado en marron si todavia no.
  Widget _datoOculto(String valor) {
    if (_desbloqueado) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(valor),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Text(valor, style: const TextStyle(color: Colors.black)),
          ),
          Positioned.fill(
            child: Container(
              color: AppColors.marronPrincipal.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
