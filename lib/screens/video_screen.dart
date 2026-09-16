import 'package:flutter/material.dart';

import '../models/animal.dart';

/// Pantalla de video del animal — se llega acá tocando el botón "Video" en
/// la ficha del animal (Pantalla 4). Todavía sin implementar — la función
/// real se va a definir con el equipo (ver cosas_pendientes.md, ítem 26).
class VideoScreen extends StatelessWidget {
  final Animal animal;

  const VideoScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no está lista esta función.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
