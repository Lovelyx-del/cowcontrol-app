// Imports — los mismos que login_screen.dart (ver explicación de cada librería ahí).
// Solo agrego las librerías específicas de esta pantalla, si las hay.
// - dart:ui: de acá saco ImageFilter, el filtro que desenfoca los datos.
// - ../services/campos_service.dart: trae los campos del productor.
// - ../services/auth_service.dart: verifica la contraseña, me da el mail del
//   usuario y manda el mail de recuperación.
// - cambiar_password_screen.dart y verificar_codigo_screen.dart: las dos
//   pantallas a las que se puede ir desde acá.
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/campo.dart';
import '../services/auth_service.dart';
import '../services/campos_service.dart';
import '../theme/app_theme.dart';
import 'cambiar_password_screen.dart';
import 'verificar_codigo_screen.dart';

// ============================================================
// informacion_personal_screen — Sub-pantalla de Configuración (a la que se llega desde el engranaje de la Pantalla 2)
//
// Qué hace este archivo:
// Muestro el mail y los campos del usuario, pero tapados con un desenfoque
// marrón hasta que escribe su contraseña y Supabase confirma que es la
// correcta. Abajo están "Cambiar contraseña" y "¿Olvidaste tu contraseña?".
//
// Información Personal es sub-pantalla de Configuración, no de la Planilla.
// La Planilla (Pantalla 2) nunca la abre directo: desde la Planilla toco el
// engranaje y voy a Configuración, y recién ahí, al tocar "Información
// Personal" en la lista, se abre esta pantalla. Es el único lugar de toda la
// app desde donde se llega acá, así que el camino es siempre Planilla →
// Configuración → Información Personal (dos saltos).
// ============================================================
class InformacionPersonalScreen extends StatefulWidget {
  const InformacionPersonalScreen({super.key});

  @override
  State<InformacionPersonalScreen> createState() =>
      _InformacionPersonalScreenState();
}

// ---------------------------------------------------------------------------
// _InformacionPersonalScreenState — los datos y el desbloqueo
//
// _futureCampos trae los campos en initState. _desbloqueado dice si ya pusieron
// bien la contraseña, _verificando deshabilita el botón mientras pregunto a
// Supabase, y _error es el mensaje en rojo si algo salió mal.
// ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _verDatos — chequea la contraseña y destapa los datos
  //
  // Si el campo está vacío muestro un aviso. Si no, le pido a AuthService que
  // verifique la contraseña contra Supabase. Si es correcta pongo _desbloqueado
  // en true y los datos se ven; si no, muestro "Contraseña incorrecta.".
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // build — mail, campos, desbloqueo y opciones de contraseña
  //
  // Mail y campos pasan por _datoOculto. Mientras no esté desbloqueado se ven
  // el campo de contraseña y "Ver datos". Abajo, "Cambiar contraseña" y
  // "¿Olvidaste tu contraseña?", que manda el mail y abre VerificarCodigoScreen.
  // TODO: revisar en la presentación — antes figuraba que el mail de
  // recuperación tenía problemas de spam/entrega (cosas_pendientes.md item 21).
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // _datoOculto — muestra un dato tapado o destapado
  //
  // Si ya está desbloqueado, el texto normal. Si no, apilo el texto
  // desenfocado (ImageFilter.blur) y encima una capa marrón semitransparente,
  // así no se puede leer pero se nota que ahí hay algo.
  // ---------------------------------------------------------------------------
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
