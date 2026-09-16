import 'package:flutter/material.dart';

/// Checklist visual de los requisitos de contraseña (8 caracteres, letra,
/// numero) — se repite en el registro, en "Cambiar contraseña" y al
/// confirmar el codigo de recuperacion, asi que vive en un solo lugar.
class PasswordChecklist extends StatelessWidget {
  final String password;

  const PasswordChecklist({super.key, required this.password});

  static bool esValida(String password) =>
      password.length >= 8 &&
      RegExp(r'[A-Za-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password);

  @override
  Widget build(BuildContext context) {
    final tieneOchoCaracteres = password.length >= 8;
    final tieneLetra = RegExp(r'[A-Za-z]').hasMatch(password);
    final tieneNumero = RegExp(r'[0-9]').hasMatch(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _regla('Minimo 8 caracteres', tieneOchoCaracteres),
        _regla('Al menos una letra', tieneLetra),
        _regla('Al menos un numero', tieneNumero),
      ],
    );
  }

  Widget _regla(String texto, bool cumplida) {
    final color = cumplida ? Colors.green : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          cumplida ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
