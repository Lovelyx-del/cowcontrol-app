# Cosas pendientes — App CowControl

Funcionalidades que aparecen en la carpeta técnica / mockups pero que **no se van a implementar en la primera versión de la app**. Quedan anotadas acá para retomarlas más adelante, decidido el 2026-07-13.

---

## Requisito no negociable: Android + iOS, adaptado a móvil

A diferencia de los puntos de abajo (que son funciones que se dejan afuera), esto **no es algo que se difiere** — es un requisito fijo de la v1: la app tiene que compilar y andar bien tanto en **Android** como en **iOS**, con la interfaz adaptada a pantalla de celular (no un diseño pensado para escritorio que "también anda" en el celular). Flutter compila a ambas plataformas desde el mismo código, pero eso no garantiza una UI bien adaptada — hay que probar tamaños de pantalla, áreas seguras (notch, gestos del sistema), y que los botones/tarjetas sean cómodos para tocar con el dedo (no para mouse). Recordatorio para cuando se arranque a escribir las pantallas: diseñar mobile-first desde el principio, no ajustar al final.

---

## 1. Sesiones de conteo (guardar / borrar un conteo completo) — ✅ YA NO ES DIFERIDO, pasa a la v1 (decidido 2026-07-26)

La carpeta técnica describe un flujo donde "iniciar conteo" → "detener" → "reanudar" → "finalizar" termina en elegir **guardar** o **borrar** todo el conteo, y la app permite ver "planillas anteriores" de conteos ya hechos.

Se evaluó una alternativa (que la Raspberry Pi retenga las lecturas localmente en su propio servidor durante el conteo, y recién las mande a la app/Supabase al finalizar) y se **descartó**: rompía el ✓ en tiempo real de la Pantalla 3, que es la función principal del proyecto. Se decidió en cambio agregar una tabla `sesiones_conteo` (id, campo_id, fecha_inicio, fecha_fin, estado) + FK `sesion_id` en `datos_lectura`, manteniendo Supabase Realtime para el ✓ en vivo. Detalle y SQL de la migración en `base_datos.md`; plan de pantallas actualizado en `memory.md`.

**Queda para exportar a PDF de un conteo puntual** — eso sí sigue diferido, no forma parte de la v1.

---

## 2. Cámara vinculada al conteo (resumen)

Idea original: cámara que graba el conteo y cada lectura RFID queda asociada al minuto
exacto del video en que ese animal pasó, para revisión visual. **No implementada** — falta
armar el hardware (cámara + Raspberry Pi juntos), no hay tabla ni storage en Supabase para
video todavía. A futuro: guardar el video (Supabase Storage o local con referencia en
Supabase), un campo en `datos_lectura` con el timestamp exacto dentro de la grabación, y una
pantalla para reproducirlo desde el detalle de una lectura. Sin fecha definida, depende de
tener el hardware completo armado primero.

---

## 3. Campos del mockup descartados (validado con productores del INTA)

La carpeta técnica muestra en el mockup campos como: preñez, fertilidad, crías del último año, crías del año actual, "para carnear", alertas puntuales tipo "pata lastimada". Al consultar con productores del INTA, indicaron que **no son necesarios** por ahora — la única categoría que sí vale la pena incorporar es **condición corporal** (reemplaza al "Estado: Saludable/gorda" del mockup).

El resto de categorías se van a ir evaluando **de a una**, consultando antes de agregar cada una al schema — no se vuelca todo el mockup de una.

**Actualización 2026-08-03/2026-08-06:** esta decisión se revisó — `condicion_corporal` se sacó de la app (no aporta al prototipo de demo) y `fertilidad` se agregó de vuelta (sí está en el mockup y Santiago la quiere mostrar; la exclusión del INTA aplicaba a otro contexto). Detalle completo en `prompts.md` secciones 9 y 10. El resto de la lista de arriba (preñez, crías, "para carnear", alertas puntuales) sigue pendiente de revisar uno por uno, sin decisión tomada todavía.

---

## 4. Preparar respuestas para posibles preguntas de la presentación (librerías, imports, herramientas)

Anotado 2026-08-07, a pedido de Santiago — no es una funcionalidad, es preparación para la
expo. Como Santiago no tipea el código él mismo, necesita poder explicar con seguridad cosas
que seguramente le van a preguntar en la presentación, del estilo:
- "¿Cómo importaste tal librería? ¿Hay una interfaz de Flutter para ir agregando paquetes?"
- "¿De dónde salen los paquetes que usa la app (`supabase_flutter`, `flutter_dotenv`,
  etc.)? ¿Hay un repositorio de GitHub detrás de cada uno?"
- En general: cómo se instalan/actualizan dependencias en un proyecto Flutter, qué es
  `pubspec.yaml`/`pubspec.lock`, qué es pub.dev.

**Pendiente:** armar, más adelante (después de la documentación línea por línea en PDF que
también está pendiente — ver `info.md`), una explicación corta y simple de esto, pensada
para que Santiago la pueda repetir con confianza sin necesitar entender Dart a fondo.

---

## 5. Limitaciones conocidas a tener preparadas para la presentación (no implementar todavía)

Anotado 2026-08-07. Dos cosas que **no están resueltas hoy**, que conviene tener
fundamentadas de antemano por si las preguntan en la expo — mejor tener lista una
explicación breve de "por qué no está hecho y qué se haría" que quedarse sin respuesta.
**No tocar nada de esto todavía** — no está urgente, y ni siquiera anda de punta a punta la
app en un celular físico todavía (ver bug de login en `prompts.md`).

**a) iOS.** Ya documentado en la sección "Requisito no negociable" al principio de este
archivo, y en `prompts.md` sección 11. Resumen para la respuesta breve: hace falta una Mac
con Xcode (requisito de Apple, no se puede evitar desde Windows), y para instalarlo en el
celular de alguien más sin pasar por la App Store hace falta además una cuenta Apple
Developer paga (o una versión que expira a los 7 días con cuenta gratis). Está identificado,
tiene plan, falta el acceso al hardware (la Mac).

**b) Seguridad de qué Raspberry Pi puede escribirle a qué campo.** Hoy, cualquier
Raspberry Pi configurada con la `service_role key` del proyecto puede escribir en el
`campo_id` que sea — no hay nada de software que impida que una Raspberry mal configurada
(por error o a propósito) le escriba a los datos de un campo que no es el suyo, porque esa
key bypassea las políticas de seguridad (RLS) a propósito, para que la Raspberry pueda
insertar sin necesitar loguearse. Es un límite real, aceptable para un prototipo de
secundaria (no hay un actor externo tratando de "hackear" el proyecto), pero corresponde
mencionarlo con la solución pensada: si esto fuera un producto real, cada Raspberry física
tendría su **propia credencial**, atada del lado del servidor a un único `campo_id`
permitido — así ni por error ni a propósito una Raspberry podría escribir en el campo de
otro productor. Ver el detalle completo de la pregunta original en `base_datos.md` sección
12.

**c) "¿Por qué 4 tablas y no 3?"** Duda planteada por un compañero de equipo (2026-08-08),
pensando en que un profesor podría preguntar si se puede simplificar. Respuesta breve para
tener lista: las 4 tablas (`datos_campo`, `datos_animales`, `datos_lectura`, `datos_vacuna`)
representan 4 cosas distintas que no tiene sentido mezclar — un campo/establecimiento, un
animal, una lectura puntual del lector RFID, y el historial de vacunas de un animal (que
puede tener varias en el tiempo, no una sola). Separarlas así es la forma estándar de
organizar una base de datos relacional (evita repetir datos y permite que cada animal tenga
cualquier cantidad de vacunas sin duplicar sus datos generales) — no es un capricho, es
justamente lo que hace que se pueda, por ejemplo, guardar el historial completo de vacunas
de un animal sin repetir su ID/categoría en cada fila. **Nota:** si en algún momento se
concreta el pedido del compañero de fusionar `datos_vacuna` dentro de `datos_animales`
(ver ítem 6 de este archivo, todavía sin decidir), esta respuesta pasaría a ser sobre 3
tablas en vez de 4 — no se actualizó porque esa fusión no está confirmada todavía.

---

## 6. ACTIVO — hacer editables fertilidad, vacunas y observaciones (Pantalla 4)

Confirmado en el celular (2026-08-07): la ficha de detalle de un animal hoy **solo muestra**
fertilidad/vacunas/observaciones, no deja escribir nada — revisado el código,
`AnimalesService` y `VacunasService` ni siquiera tienen un método para guardar. Tiene
sentido arreglarlo: son justo los tres datos que el lector RFID no puede leer solo, tienen
que entrar a mano por el productor.

**Buena noticia — no hace falta tocar SQL ni RLS para esto.** Ya quedaron habilitados de la
sesión del bug de permisos (`base_datos.md` sección 10.3): `datos_animales` ya tiene GRANT
de `UPDATE` y la política RLS es `FOR ALL` (cubre UPDATE); `datos_vacuna` ya tiene GRANT de
`INSERT` y también es `FOR ALL`. Es un cambio **100% del lado de la app** (Dart), en 3
archivos. Santiago lo va a hacer él mismo, guiado — el código ya está armado abajo, listo
para copiar tal cual.

### Paso 1 — `lib/services/animales_service.dart`

El archivo hoy tiene 25 líneas. El método `traerDetalle` ocupa las líneas 21 a 24 (la línea
24 es el `}` que lo cierra); la línea 25 es el `}` que cierra toda la clase `AnimalesService`.
**Pegar el código nuevo entre esas dos líneas** — es decir, justo debajo de la línea 24
(el `}` de `traerDetalle`), antes de la línea 25 (el `}` de la clase):
```dart
  Future<void> actualizarAnimal({
    required String animalId,
    String? observaciones,
    String? fertilidad,
  }) async {
    await _client.from('datos_animales').update({
      'observaciones': observaciones,
      'fertilidad': fertilidad,
    }).eq('id', animalId);
  }
```

### Paso 2 — `lib/services/vacunas_service.dart`

El archivo hoy tiene 20 líneas. El método `traerUltimaVacuna` ocupa las líneas 9 a 19 (la
línea 19 es el `}` que lo cierra); la línea 20 es el `}` que cierra toda la clase
`VacunasService`. **Pegar el código nuevo entre esas dos líneas** — justo debajo de la línea
19, antes de la línea 20:
```dart
  Future<void> agregarVacuna({
    required String idAnimal,
    required String nombreVacuna,
    DateTime? fechaVacuna,
  }) async {
    await _client.from('datos_vacuna').insert({
      'id_animal': idAnimal,
      'nombre_vacuna': nombreVacuna,
      if (fechaVacuna != null) 'fecha_vacuna': fechaVacuna.toIso8601String(),
    });
  }
```

### Paso 3 — `lib/screens/detalle_animal_screen.dart`

Este paso no tiene ambigüedad de línea: es un reemplazo total. Seleccionar todo el contenido
del archivo (`Ctrl+A` con el archivo abierto y enfocado) y pegar esto encima, reemplazando
todo (deja de usar `FertilidadChip` acá — ese
widget sigue existiendo y se sigue usando en `animal_card.dart`, no se toca ni se borra):
```dart
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/vacuna.dart';
import '../services/animales_service.dart';
import '../services/vacunas_service.dart';
import '../widgets/categoria_badge.dart';

/// Pantalla 4 — ficha de un animal: ID, y tres datos editables por el
/// productor (fertilidad, vacunas, observaciones) — el lector RFID no puede
/// leer ninguno de estos solo.
class DetalleAnimalScreen extends StatefulWidget {
  final Animal animal;

  const DetalleAnimalScreen({super.key, required this.animal});

  @override
  State<DetalleAnimalScreen> createState() => _DetalleAnimalScreenState();
}

class _DetalleAnimalScreenState extends State<DetalleAnimalScreen> {
  final _animalesService = AnimalesService();
  final _vacunasService = VacunasService();
  final _observacionesController = TextEditingController();
  final _nombreVacunaController = TextEditingController();

  late Future<Vacuna?> _futureVacuna;
  String? _fertilidadSeleccionada;
  DateTime? _fechaVacunaSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _observacionesController.text = widget.animal.observaciones ?? '';
    _fertilidadSeleccionada = widget.animal.fertilidad;
    _futureVacuna = _vacunasService.traerUltimaVacuna(widget.animal.id);
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _nombreVacunaController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _elegirFechaVacuna() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fechaVacunaSeleccionada = fecha);
  }

  Future<void> _agregarVacuna() async {
    if (_nombreVacunaController.text.trim().isEmpty) return;
    await _vacunasService.agregarVacuna(
      idAnimal: widget.animal.id,
      nombreVacuna: _nombreVacunaController.text.trim(),
      fechaVacuna: _fechaVacunaSeleccionada,
    );
    _nombreVacunaController.clear();
    setState(() {
      _fechaVacunaSeleccionada = null;
      _futureVacuna = _vacunasService.traerUltimaVacuna(widget.animal.id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vacuna agregada.')));
    }
  }

  Future<void> _guardarCambios() async {
    setState(() => _guardando = true);
    try {
      final observaciones = _observacionesController.text.trim();
      await _animalesService.actualizarAnimal(
        animalId: widget.animal.id,
        observaciones: observaciones.isEmpty ? null : observaciones,
        fertilidad: _fertilidadSeleccionada,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    return Scaffold(
      appBar: AppBar(title: Text(animal.rfidUid)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CategoriaBadge(categoria: animal.categoria),
          const SizedBox(height: 24),
          Text('Fertilidad', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _fertilidadSeleccionada,
            hint: const Text('Sin dato'),
            items: const [
              DropdownMenuItem(value: 'buena', child: Text('Buena')),
              DropdownMenuItem(value: 'regular', child: Text('Regular')),
              DropdownMenuItem(value: 'mala', child: Text('Mala')),
            ],
            onChanged: (valor) => setState(() => _fertilidadSeleccionada = valor),
          ),
          const SizedBox(height: 24),
          Text('Vacunas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          FutureBuilder<Vacuna?>(
            future: _futureVacuna,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final vacuna = snapshot.data;
              if (vacuna == null) {
                return const Text('Sin vacunas registradas.');
              }
              final fecha = vacuna.fechaVacuna;
              final fechaTexto = fecha == null ? '' : ' — ${_formatearFecha(fecha)}';
              return Text('Ultima vacuna: ${vacuna.nombreVacuna}$fechaTexto');
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nombreVacunaController,
            decoration: const InputDecoration(labelText: 'Nombre de la vacuna nueva'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _fechaVacunaSeleccionada == null
                      ? 'Sin fecha elegida'
                      : _formatearFecha(_fechaVacunaSeleccionada!),
                ),
              ),
              TextButton(onPressed: _elegirFechaVacuna, child: const Text('Elegir fecha')),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _agregarVacuna, child: const Text('Agregar vacuna')),
          const SizedBox(height: 24),
          Text('Observaciones', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _observacionesController,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Sin observaciones.'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _guardando ? null : _guardarCambios,
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
```
**Después de pegar los 3 archivos:** correr `flutter analyze` (tiene que dar "No issues
found!"), después `R` en la terminal para hot restart, y probar: cambiar fertilidad, agregar
una vacuna, escribir una observación, tocar "Guardar cambios", y volver a entrar a la ficha
para confirmar que quedó guardado de verdad en Supabase (no solo en la pantalla).

**Confirmado funcionando (2026-08-10):** fertilidad y observaciones ya guardan bien.
Vacunas también guarda, pero Santiago pidió compactar el layout — ver ítem 7 más abajo.

---

## 7. ACTIVO — Pantalla 4 rediseñada en 3 botones + sacar fertilidad de la Planilla

**2026-08-10 — confirmado con referencia visual** (captura de Santiago de la Pantalla 4
actual). La ficha del animal deja de mostrar fertilidad/vacunas/observaciones todo junto y
suelto — pasa a tener **tres botones** ("Fertilidad", "Vacunas", "Observaciones", mismo
estilo redondeado que ya tenía "Agregar vacuna"), y cada uno lleva a **su propia pantalla**
con el formulario de esa categoría puntual. **Esto es un primer armado** — el contenido de
adentro de cada pantalla reutiliza tal cual la lógica que ya estaba funcionando (guardar
fertilidad, agregar vacuna, guardar observaciones), pero el diseño visual de esas 3 pantallas
nuevas todavía se puede ajustar más adelante si Santiago trae otra referencia — lo importante
ahora es que la Pantalla 4 pase a ser botones, como pidió.

También se saca el chip de "Fertilidad: sin dato" de la Planilla general (Pantalla 2) y del
Conteo en vivo (Pantalla 3) — ahí solo se ve ID + categoría.

Son **6 pasos**: 3 archivos nuevos, 2 reemplazos completos, 1 borrado de una línea.

### Paso 1 — crear `lib/screens/fertilidad_screen.dart` (archivo nuevo)

```dart
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animales_service.dart';

/// Pantalla para editar la fertilidad de un animal — se llega acá tocando el
/// botón "Fertilidad" en la ficha del animal (Pantalla 4).
class FertilidadScreen extends StatefulWidget {
  final Animal animal;

  const FertilidadScreen({super.key, required this.animal});

  @override
  State<FertilidadScreen> createState() => _FertilidadScreenState();
}

class _FertilidadScreenState extends State<FertilidadScreen> {
  final _animalesService = AnimalesService();
  String? _fertilidadSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _fertilidadSeleccionada = widget.animal.fertilidad;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await _animalesService.actualizarAnimal(
        animalId: widget.animal.id,
        observaciones: widget.animal.observaciones,
        fertilidad: _fertilidadSeleccionada,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fertilidad')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _fertilidadSeleccionada,
              hint: const Text('Sin dato'),
              items: const [
                DropdownMenuItem(value: 'buena', child: Text('Buena')),
                DropdownMenuItem(value: 'regular', child: Text('Regular')),
                DropdownMenuItem(value: 'mala', child: Text('Mala')),
              ],
              onChanged: (valor) => setState(() => _fertilidadSeleccionada = valor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Paso 2 — crear `lib/screens/observaciones_screen.dart` (archivo nuevo)

```dart
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/animales_service.dart';

/// Pantalla para editar las observaciones de un animal — se llega acá
/// tocando el botón "Observaciones" en la ficha del animal (Pantalla 4).
class ObservacionesScreen extends StatefulWidget {
  final Animal animal;

  const ObservacionesScreen({super.key, required this.animal});

  @override
  State<ObservacionesScreen> createState() => _ObservacionesScreenState();
}

class _ObservacionesScreenState extends State<ObservacionesScreen> {
  final _animalesService = AnimalesService();
  final _observacionesController = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _observacionesController.text = widget.animal.observaciones ?? '';
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final observaciones = _observacionesController.text.trim();
      await _animalesService.actualizarAnimal(
        animalId: widget.animal.id,
        observaciones: observaciones.isEmpty ? null : observaciones,
        fertilidad: widget.animal.fertilidad,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Observaciones')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _observacionesController,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Sin observaciones.'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Paso 3 — crear `lib/screens/vacunas_screen.dart` (archivo nuevo)

De paso, incluye el ajuste de nombre+fecha en una misma línea que ya habías pedido antes.

```dart
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/vacuna.dart';
import '../services/vacunas_service.dart';

/// Pantalla para ver la ultima vacuna y agregar una nueva — se llega acá
/// tocando el botón "Vacunas" en la ficha del animal (Pantalla 4).
class VacunasScreen extends StatefulWidget {
  final Animal animal;

  const VacunasScreen({super.key, required this.animal});

  @override
  State<VacunasScreen> createState() => _VacunasScreenState();
}

class _VacunasScreenState extends State<VacunasScreen> {
  final _vacunasService = VacunasService();
  final _nombreVacunaController = TextEditingController();
  late Future<Vacuna?> _futureVacuna;
  DateTime? _fechaVacunaSeleccionada;

  @override
  void initState() {
    super.initState();
    _futureVacuna = _vacunasService.traerUltimaVacuna(widget.animal.id);
  }

  @override
  void dispose() {
    _nombreVacunaController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (fecha != null) setState(() => _fechaVacunaSeleccionada = fecha);
  }

  Future<void> _agregarVacuna() async {
    if (_nombreVacunaController.text.trim().isEmpty) return;
    await _vacunasService.agregarVacuna(
      idAnimal: widget.animal.id,
      nombreVacuna: _nombreVacunaController.text.trim(),
      fechaVacuna: _fechaVacunaSeleccionada,
    );
    _nombreVacunaController.clear();
    setState(() {
      _fechaVacunaSeleccionada = null;
      _futureVacuna = _vacunasService.traerUltimaVacuna(widget.animal.id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vacuna agregada.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vacunas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<Vacuna?>(
              future: _futureVacuna,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                final vacuna = snapshot.data;
                if (vacuna == null) {
                  return const Text('Sin vacunas registradas.');
                }
                final fecha = vacuna.fechaVacuna;
                final fechaTexto = fecha == null ? '' : ' — ${_formatearFecha(fecha)}';
                return Text('Ultima vacuna: ${vacuna.nombreVacuna}$fechaTexto');
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nombreVacunaController,
                    decoration: const InputDecoration(labelText: 'Nombre de la vacuna'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _elegirFecha,
                  child: Text(
                    _fechaVacunaSeleccionada == null
                        ? 'Elegir fecha'
                        : _formatearFecha(_fechaVacunaSeleccionada!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _agregarVacuna, child: const Text('Agregar vacuna')),
          ],
        ),
      ),
    );
  }
}
```

### Paso 4 — reemplazar `lib/screens/detalle_animal_screen.dart` completo

Esta pantalla pasa a ser solo el menú de 3 botones — todo el trabajo real vive en las 3
pantallas nuevas de arriba. Seleccionar todo (`Ctrl+A`) y pegar esto encima:

```dart
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../widgets/categoria_badge.dart';
import 'fertilidad_screen.dart';
import 'observaciones_screen.dart';
import 'vacunas_screen.dart';

/// Pantalla 4 — ficha de un animal: ID, categoria, y tres botones que llevan
/// a la pantalla de edicion de cada dato (fertilidad, vacunas, observaciones)
/// — son datos que el lector RFID no puede leer solo, los carga el productor.
class DetalleAnimalScreen extends StatelessWidget {
  final Animal animal;

  const DetalleAnimalScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(animal.rfidUid)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: CategoriaBadge(categoria: animal.categoria)),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FertilidadScreen(animal: animal)),
              ),
              child: const Text('Fertilidad'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VacunasScreen(animal: animal)),
              ),
              child: const Text('Vacunas'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ObservacionesScreen(animal: animal)),
              ),
              child: const Text('Observaciones'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Paso 5 — reemplazar `lib/widgets/animal_card.dart` completo

(Este paso es igual al que ya se había escrito antes de pausar — sigue vigente tal cual.)
Seleccionar todo (`Ctrl+A`) y pegar esto encima:

```dart
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../theme/app_theme.dart';
import 'categoria_badge.dart';

/// Tarjeta de un animal — se reusa en la Planilla general (Pantalla 2) y en el
/// Conteo en vivo (Pantalla 3). Muestra solo ID + categoria; el resto de los
/// datos (fertilidad, vacunas, observaciones) vive en la Pantalla 4.
class AnimalCard extends StatelessWidget {
  final Animal animal;
  final bool detectado;
  final VoidCallback? onVerMas;

  const AnimalCard({
    super.key,
    required this.animal,
    this.detectado = false,
    this.onVerMas,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: detectado
            ? const Icon(Icons.check_circle, color: AppColors.verdeVivo, size: 32)
            : const Icon(Icons.circle_outlined, color: AppColors.marronPrincipal, size: 32),
        title: Text(
          animal.rfidUid,
          style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        subtitle: CategoriaBadge(categoria: animal.categoria),
        trailing: onVerMas == null ? null : const Icon(Icons.chevron_right),
        onTap: onVerMas,
      ),
    );
  }
}
```

**Nota:** `fertilidad_chip.dart` no se borra — queda sin usarse por ahora, no molesta.

### Paso 6 — `lib/screens/conteo_screen.dart`, borrar una línea

El parámetro `mostrarFertilidad` ya no existe en `AnimalCard`. Buscar la línea (hoy es la
**110**) que dice:
```dart
                  mostrarFertilidad: false,
```
Borrar esa línea completa, nada más.

### Verificación

`flutter analyze` (tiene que dar "No issues found!"), `R` para hot restart, y probar en el
celular: la Planilla ya no muestra fertilidad; al entrar a un animal se ven los 3 botones;
cada botón abre su pantalla, deja cargar/guardar el dato, y vuelve para atrás solo al
guardar.

---

## 8. ACTIVO — íconos en vez de texto (categoría en la tarjeta, y los 3 botones de la Pantalla 4)

Pedido de Santiago (2026-08-10), después de ver el ítem 7 andando en el celular — dos ajustes
visuales, sobre lo que ya quedó funcionando (no cambia ninguna lógica de guardado, solo cómo
se ve):

**a) Categoría en las tarjetas (Planilla y Conteo):** hoy se ve como una píldora de color con
ícono + texto ("♀ vaca") debajo del ID. Pasa a ser **solo el ícono**, sin texto ni fondo de
color, ubicado al lado del ID (mismo renglón, a la derecha) — a modo de referencia visual,
no es un botón.

**b) Los 3 botones de la Pantalla 4** dejan de ser botones de texto apilados (quedaban muy
"planos", sin nada más en la pantalla) y pasan a ser **3 íconos cuadrados en una fila**,
del mismo tamaño, uno al lado del otro — cada uno sigue siendo el botón real que lleva a su
pantalla (Fertilidad, Vacunas, Observaciones), no son solo decorativos como el ícono de
categoría del punto (a). Íconos elegidos: **corazón** para Fertilidad, **jeringa** para
Vacunas, **ojo** para Observaciones — confirmado con Santiago.

Son 3 pasos, los 3 de reemplazo completo del archivo (para no repetir el lío de líneas
sueltas de la vez pasada).

### Paso 1 — reemplazar `lib/widgets/categoria_badge.dart` completo

```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Icono que representa la categoria del animal (columna "sexo") — sin
/// texto, se muestra al lado del ID en la tarjeta (Pantallas 2 y 3) y arriba
/// de todo en la Pantalla 4. Es solo referencia visual, no es un botón.
class CategoriaBadge extends StatelessWidget {
  final String? categoria;

  const CategoriaBadge({super.key, required this.categoria});

  IconData get _icono {
    switch (categoria) {
      case 'vaca':
      case 'vaquillona':
        return Icons.female;
      case 'toro':
        return Icons.male;
      case 'ternero':
      case 'ternera':
        return Icons.child_care;
      default:
        return Icons.pets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(_icono, color: AppColors.marronPrincipal, size: 26);
  }
}
```

### Paso 2 — reemplazar `lib/widgets/animal_card.dart` completo

Cambia el `title` (ID + ícono en la misma fila, en vez de ID arriba y badge como subtítulo
abajo):

```dart

import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../theme/app_theme.dart';
import 'categoria_badge.dart';

/// Tarjeta de un animal — se reusa en la Planilla general (Pantalla 2) y en el
/// Conteo en vivo (Pantalla 3). Muestra el ID con el icono de categoria al
/// lado; el resto de los datos (fertilidad, vacunas, observaciones) vive en
/// la Pantalla 4.
class AnimalCard extends StatelessWidget {
  final Animal animal;
  final bool detectado;
  final VoidCallback? onVerMas;

  const AnimalCard({
    super.key,
    required this.animal,
    this.detectado = false,
    this.onVerMas,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: detectado
            ? const Icon(Icons.check_circle, color: AppColors.verdeVivo, size: 32)
            : const Icon(Icons.circle_outlined, color: AppColors.marronPrincipal, size: 32),
        title: Row(
          children: [
            Expanded(
              child: Text(
                animal.rfidUid,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
            ),
            CategoriaBadge(categoria: animal.categoria),
          ],
        ),
        trailing: onVerMas == null ? null : const Icon(Icons.chevron_right),
        onTap: onVerMas,
      ),
    );
  }
}
```

### Paso 3 — reemplazar `lib/screens/detalle_animal_screen.dart` completo

Los 3 botones de texto apilados pasan a ser 3 cuadrados con ícono, en una fila:

```dart
import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../theme/app_theme.dart';
import '../widgets/categoria_badge.dart';
import 'fertilidad_screen.dart';
import 'observaciones_screen.dart';
import 'vacunas_screen.dart';

/// Pantalla 4 — ficha de un animal: ID, categoria, y tres botones (con
/// icono) que llevan a la pantalla de edicion de cada dato (fertilidad,
/// vacunas, observaciones) — son datos que el lector RFID no puede leer
/// solo, los carga el productor.
class DetalleAnimalScreen extends StatelessWidget {
  final Animal animal;

  const DetalleAnimalScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(animal.rfidUid)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: CategoriaBadge(categoria: animal.categoria)),
            const SizedBox(height: 24),
            Row(
              children: [
                _BotonIcono(
                  icono: Icons.favorite,
                  etiqueta: 'Fertilidad',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FertilidadScreen(animal: animal)),
                  ),
                ),
                const SizedBox(width: 12),
                _BotonIcono(
                  icono: Icons.vaccines,
                  etiqueta: 'Vacunas',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VacunasScreen(animal: animal)),
                  ),
                ),
                const SizedBox(width: 12),
                _BotonIcono(
                  icono: Icons.visibility,
                  etiqueta: 'Observaciones',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ObservacionesScreen(animal: animal)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Boton cuadrado con icono arriba y etiqueta abajo, usado para los 3
/// accesos de la Pantalla 4. Queda privado a este archivo (el guion bajo).
class _BotonIcono extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final VoidCallback onTap;

  const _BotonIcono({
    required this.icono,
    required this.etiqueta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.marronPrincipal),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: AppColors.marronPrincipal, size: 32),
              const SizedBox(height: 8),
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.marronPrincipal, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Verificación

`flutter analyze` (tiene que dar "No issues found!"), `R` para hot restart, y mirar en el
celular: en la Planilla, el ícono de categoría al lado del ID sin texto ni píldora de color;
al entrar a un animal, los 3 cuadrados con ícono en fila en vez de los botones de texto
apilados, y que cada uno siga llevando a su pantalla correspondiente.

---

## 9. PENDIENTE (no hacer hoy) — armar un mapa/roadmap completo del proyecto

Anotado 2026-08-10, a pedido de Santiago. Falta un documento que no se limite a explicar el
código de cada archivo puntual (eso ya lo empezó `info.md`), sino que mapee **la lógica
completa del proyecto de punta a punta**: cómo se relaciona el código entre archivos (no
solo qué hace cada uno por separado), el uso de Flutter vía terminal (los comandos que se
fueron usando y por qué, en la línea de lo que ya se empezó en `info.md` sección 7), y cómo
se integra todo con la Raspberry Pi (protocolo, `campo_id`, service_role, etc. — hoy
disperso entre `base_datos.md` y `prompts.md`).

**No se hace hoy** — queda anotado para retomarlo más adelante, junto con la documentación
línea por línea en PDF que también está pendiente (ver la nota al principio de `info.md`).

---

## 10. HECHO (2026-08-30, ver ítem 19 para los ajustes finales) — reemplazar los íconos de categoría por las ilustraciones de Gemini (SVG)

2026-08-10. Las 5 imágenes ya están generadas y aprobadas (en
`documentacion.md/fotos_adjuntas.md/anexos_img_app/`) — vaca, toro, ternero, ternera y
vaquillona, cada una diferenciada por orientación (machos a la izquierda, hembras a la
derecha) y por anatomía (ubre, cuernos, tamaño).

**Cambio de decisión (mismo día):** se descartó vectorizarlas (SVG) porque las herramientas
buenas de vectorizado son pagas. Se pasa al camino raster (PNG con fondo transparente) — es
gratis, más simple, y visualmente **no se pierde nada** para el tamaño chico que van a tener
estos íconos (28px): el recoloreado al marrón de la app funciona igual de bien sobre un PNG
transparente que sobre un SVG. Tampoco hace falta agregar ningún paquete nuevo
(`flutter_svg` ya no es necesario).

Son 2 partes: **Parte 1 la hace Santiago afuera de la app** (sacar el fondo), **Parte 2 es
código** (para pegar una vez que estén los 5 PNG listos).

### Parte 1 — sacar el fondo blanco de las 5 imágenes (fuera de VS Code)

**Herramienta:** [remove.bg](https://remove.bg) — gratis para uso estándar, subís el JPG y
descargás el PNG con el fondo ya transparente, en segundos, sin instalar nada.

Por cada una de las 5 imágenes:
1. Subir el JPG a remove.bg.
2. Descargar el resultado (PNG con fondo transparente).
3. Renombrar cada archivo con **estos nombres exactos** (importante, el código de la Parte 2
   los busca por este nombre):
   - `vaca.png`
   - `toro.png`
   - `ternero.png`
   - `ternera.png`
   - `vaquillona.png`
4. Crear la carpeta `assets/images/` en la raíz del proyecto (al lado de `lib/`, no adentro)
   — es decir: `C:\dev\CowControl\app_cowcontrol\assets\images\` — y poner ahí los 5
   archivos.

### Parte 2 — código (para cuando tengas los 5 PNG en esa carpeta)

**Paso 1 — `pubspec.yaml`:** solo hace falta declarar la carpeta de assets, no agregar
ningún paquete nuevo. Hoy la línea 64 es `- .env` (dentro de la sección `assets:`) —
agregar esta línea justo debajo:
```yaml
    - assets/images/
```
(con la barra al final — así declarás toda la carpeta de una, sin tener que listar cada
archivo suelto ni volver a tocar este archivo si agregan más imágenes después).

**Paso 2 — reemplazar `lib/widgets/categoria_badge.dart` completo:**
```dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ilustracion que representa la categoria del animal (columna "sexo") — sin
/// texto, se muestra al lado del ID en la tarjeta (Pantallas 2 y 3) y arriba
/// de todo en la Pantalla 4. Es solo referencia visual, no es un boton.
class CategoriaBadge extends StatelessWidget {
  final String? categoria;

  const CategoriaBadge({super.key, required this.categoria});

  String? get _asset {
    switch (categoria) {
      case 'vaca':
        return 'assets/images/vaca.png';
      case 'toro':
        return 'assets/images/toro.png';
      case 'ternero':
        return 'assets/images/ternero.png';
      case 'ternera':
        return 'assets/images/ternera.png';
      case 'vaquillona':
        return 'assets/images/vaquillona.png';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asset = _asset;
    if (asset == null) {
      return const Icon(Icons.pets, color: AppColors.marronPrincipal, size: 26);
    }
    return Image.asset(
      asset,
      width: 28,
      height: 28,
      color: AppColors.marronPrincipal,
      colorBlendMode: BlendMode.srcIn,
    );
  }
}
```

**Nota importante:** `animal_card.dart` y `detalle_animal_screen.dart` **no se tocan** — los
dos ya usan `CategoriaBadge` tal cual, así que al cambiar solo este archivo el ícono nuevo
aparece automáticamente en todos lados donde ya se mostraba el viejo.

**Qué hace `color` + `colorBlendMode`:** el `BlendMode.srcIn` toma todos los píxeles
visibles de la imagen (las líneas del dibujo) y los pinta del marrón de la app
(`AppColors.marronPrincipal`) — por eso no importa que el dibujo original sea negro, el
color final en la app va a ser el mismo marrón que ya usan los demás íconos. Si al PNG le
quedó algo del fondo sin limpiar del todo, ese `BlendMode` también lo pintaría del mismo
color — por eso conviene mirar cada PNG antes de este paso y confirmar que el fondo quedó
realmente transparente (se puede abrir el archivo y fijarse que no tenga un cuadrado blanco
alrededor del dibujo).

### Verificación

`flutter analyze` (tiene que dar "No issues found!"), `R` para hot restart (o volver a
instalar el APK si la sesión USB se corta de nuevo), y mirar en el celular: en la Planilla,
el ícono al lado de cada ID ahora es la ilustración de vaca/toro/ternero/ternera/vaquillona
en vez del símbolo genérico; mismo cambio en la Pantalla 4.

---

## 11. Integración con la Raspberry Pi — script listo para probar con el hardware real

2026-08-13. Esto es lo que hace falta para que alguien con la Raspberry Pi, el lector RFID
(módulo RC522) y los tags físicos pueda probar el circuito completo (tag → Pi → Supabase →
app en tiempo real) sin necesitar tocar código Dart ni Flutter.

**Hay dos niveles.** El nivel 1 se puede probar **ya mismo**, sin aplicar ninguna migración
nueva. El nivel 2 (el flujo completo de iniciar/pausar/finalizar desde la app) necesita que
antes se aplique la migración de `sesiones_conteo` (sección "Migración pendiente —
sesiones_conteo" en `base_datos.md`), que sigue marcada como pendiente de revisar antes de
correr.

### Nivel 1 — probar que el circuito básico funciona (recomendado para empezar)

Cada vez que el lector detecta un tag, la Raspberry lo manda directo a la tabla
`datos_lectura` — sin sesión, sin "iniciar conteo" desde la app. Alcanza para confirmar que
el tag pasa de la Raspberry a Supabase y aparece solo en la app (sin recargar nada), que es
la función más importante de todo el proyecto.

**Qué se necesita antes de correr el script:**
1. **La URL de Supabase** — ya está en el archivo `.env` de la carpeta del proyecto
   (`SUPABASE_URL=...`). Copiarla de ahí.
2. **La `service_role key`** — **no es la misma que la del `.env`** (esa es la `anon key`,
   para la app; la `service_role` es otra, con permiso total, que nunca va dentro de la app).
   Se consigue en el dashboard de Supabase → **Settings → API → Project API keys →
   `service_role`**. Es secreta — no compartirla fuera del equipo ni subirla a ningún
   repositorio público.
3. **El `campo_id`** — el UUID del campo al que va a estar atada esta Raspberry. Se consigue
   corriendo esto en el SQL Editor de Supabase:
   ```sql
   SELECT id, nombre_campo FROM datos_campo;
   ```
   Copiar el `id` de la fila que corresponda (por ejemplo, "Campo Principal" para probar
   contra los datos ya existentes).

**Instalar dependencias en la Raspberry** (una sola vez):
```bash
pip3 install requests RPi.GPIO mfrc522
```

**Script (`rfid_tick.py`):**
```python
import time
from datetime import datetime, timezone

import requests
import RPi.GPIO as GPIO
from mfrc522 import SimpleMFRC522

# ─── Configuración — completar antes de correr ─────────────
SUPABASE_URL = "PEGAR_ACA_LA_SUPABASE_URL_DEL_.ENV"
SUPABASE_SERVICE_ROLE_KEY = "PEGAR_ACA_LA_SERVICE_ROLE_KEY_DEL_DASHBOARD"
CAMPO_ID = "PEGAR_ACA_EL_UUID_DEL_CAMPO"
TIEMPO_IGNORAR = 5  # segundos para ignorar relecturas del mismo tag
# ────────────────────────────────────────────────────────────

headers = {
    "apikey": SUPABASE_SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
    "Content-Type": "application/json",
}

lector = SimpleMFRC522()
ultimas_lecturas = {}


def ya_fue_leida_recientemente(uid):
    uid_str = str(uid)
    ahora = time.time()
    if uid_str in ultimas_lecturas and ahora - ultimas_lecturas[uid_str] < TIEMPO_IGNORAR:
        return True
    ultimas_lecturas[uid_str] = ahora
    return False


def mandar_lectura(uid):
    url = f"{SUPABASE_URL}/rest/v1/datos_lectura"
    payload = {
        "rfid_uid": str(uid),
        "campo_id": CAMPO_ID,
        "fecha_hora": datetime.now(timezone.utc).isoformat(),
    }
    try:
        respuesta = requests.post(url, json=payload, headers=headers, timeout=5)
        if respuesta.status_code in (200, 201):
            print(f"OK - Lectura guardada: {uid}")
        else:
            print(f"ERROR de Supabase ({respuesta.status_code}): {respuesta.text}")
    except requests.exceptions.RequestException as e:
        print(f"ERROR de red: {e}")


def bucle_principal():
    print("Lista. Acerca un tag al lector...\n")
    try:
        while True:
            try:
                uid, _texto = lector.read()
            except Exception as e:
                print(f"Error leyendo tag: {e}")
                time.sleep(1)
                continue

            if not ya_fue_leida_recientemente(uid):
                print(f"Tag leido: {uid}")
                mandar_lectura(uid)

            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\nDetenido manualmente")
    finally:
        GPIO.cleanup()


if __name__ == "__main__":
    bucle_principal()
```

**Cómo confirmar que funcionó:** con la app abierta y logueada en la cuenta dueña de ese
`campo_id` (parada en la Planilla o en Conteo en vivo), acercar un tag al lector — el
`rfid_uid` debería llegar a Supabase y, si coincide con un animal ya cargado en ese campo
(Milka o Oscar, por ejemplo, cuyos `rfid_uid` son `147-24-83-210` y `123-23-45-312`),
aparecer marcado en tiempo real en la app, sin tocar nada del celular.

### Nivel 2 — el flujo completo (iniciar/pausar/finalizar desde la app)

Esto todavía **no se puede probar** porque depende de una migración que no está aplicada
(`sesiones_conteo` — SQL completo en `base_datos.md`, sección "Migración pendiente"). Una
vez aplicada esa migración (con las 3 funciones `iniciar_o_retomar_conteo`, `pausar_conteo`,
`finalizar_conteo` ajustadas para recibir `campo_id_param` — ver `base_datos.md` secciones
"8" y el ítem 4 de `prompts.md`), el script de arriba se extendería para primero consultar
el estado del conteo cada 5 segundos antes de mandar cada lectura — la lógica ya está descrita
en detalle en `base_datos.md` sección 9, solo falta la migración de base para poder
implementarla de verdad.

**No aplicar esa migración sin que quien esté a cargo del proyecto la revise primero** —
quedó marcada explícitamente como "pendiente de revisar a fondo" en `base_datos.md`.

---

## 12. RESUELTO — un compañero no podía registrarse/iniciar sesión (SMTP propio configurado)

**Contexto (2026-08-25, durante el viaje de Santiago):** un compañero del equipo (grupo de
WhatsApp "proyecto: Lector automático de caravana", con Germaioni y kei) instaló el APK sin
problema, pero al registrarse con su mail nunca le llegó el correo de confirmación de
Supabase — y sin confirmarlo, tampoco pudo iniciar sesión.

**Diagnóstico:** se revisó `Authentication → Users` en el dashboard de Supabase y no apareció
ninguna fila con su mail — ni siquiera sin confirmar. Eso descarta que el problema haya sido
solo la entrega del mail: el pedido de registro **nunca llegó al servidor**. (El
"Total: 10 users (estimated)" que muestra el dashboard es un conteo aproximado que usa
Postgres internamente, no un conteo en vivo — la tabla real solo tenía 1 fila, la cuenta de
Santiago). Causa más probable, según Santiago: el celular del compañero no tenía conexión a
internet en el momento de registrarse.

**Arreglo aplicado de todos modos (causa raíz real, ya sospechada desde agosto):** el mail de
confirmación que trae Supabase por defecto tiene un límite bajo de envíos por hora y mala
entrega — está pensado solo para pruebas chicas, no para uso real. Se configuró SMTP propio
usando Gmail, en `Project → Authentication → Emails → SMTP Settings`:
- Sender email / Username: `santiagoargentote18@gmail.com`
- Sender name: `CowControl`
- Host: `smtp.gmail.com`
- Port: `587`
- Password: una "contraseña de aplicación" generada en la cuenta de Google (no la contraseña
  normal — se genera en `myaccount.google.com/apppasswords`, requiere verificación en dos
  pasos activada).

Esto sube el límite de correos a 30/hora y mejora la entrega — vale para cualquier compañero
que se registre de acá en adelante, sin depender de que Santiago esté presente o conectado.

**Para reactivar el registro de alguien que quedó a medias:** borrar su fila en
`Authentication → Users` (si llegó a crearse) y pedirle que se registre de nuevo, confirmando
antes que su celular tiene internet andando.

**APK:** se regeneró un APK de release nuevo — quedó **idéntico en tamaño** (50,7MB /
53.135.412 bytes) al que ya estaba, porque el cambio de SMTP es 100% del lado de Supabase y no
tocó ningún código de la app. Se reenvía igual al equipo junto con el aviso de este arreglo.

---

## 13. PENDIENTE (evaluar más adelante, sin implementar) — modo sin conexión para el conteo en campo

Duda de alcance planteada por Santiago a partir del ítem 12: si un productor real está en un
campo sin señal, ¿puede usar la app igual?

- **Registrarse y el primer login sí necesitan internet sí o sí** (Supabase es un backend en
  la nube, no hay forma de evitarlo) — pero eso pasa normalmente una sola vez, no cada vez que
  se cuenta.
- **La sesión queda guardada en el celular** una vez logueado — abrir la app de nuevo no
  vuelve a pedir conexión para el login.
- **La pantalla de Conteo en vivo sí depende de tener señal en el momento**, porque funciona
  mostrando en tiempo real lo que llega por Supabase Realtime — sin conexión, no se puede
  actualizar sola.

Si en el uso real el brete no tiene señal, sería una limitación real del diseño actual. La
solución (guardar lecturas localmente y sincronizarlas después, "modo offline") es un cambio
de arquitectura más grande, no algo para decidir ni tocar de improviso. **Sin decisión
tomada — retomar cuando Santiago pueda revisar el proyecto con calma.**

---

## 14. RESUELTO — el link de confirmación de mail lleva a un error de "localhost" (mala UX, no rompe la confirmación)

**Contexto (2026-08-25):** al confirmar un mail de registro, el link del correo (llegó a la
carpeta de spam, sin ningún texto tipo "tu cuenta fue confirmada") lleva a
`localhost:3000/?code=...` — que en el celular (o cualquier navegador fuera de la propia PC)
tira "localhost rechazó la conexión" (`ERR_CONNECTION_REFUSED`). Confirmado con captura de
pantalla.

**Causa:** Supabase valida el link **en su propio servidor primero** — ahí es donde ya marca
la cuenta como confirmada — y **recién después** redirige el navegador a la "Site URL"
configurada en el proyecto, que quedó en el valor por defecto `localhost:3000` (pensado para
cuando hay una web corriendo en la propia compu, algo que este proyecto no tiene al ser una
app mobile).

**Impacto real:** la confirmación funciona igual — probado por Santiago, que después de ver
la pantalla de error pudo iniciar sesión sin problema con esa cuenta. El problema es puramente
de percepción: un productor real, viendo esa pantalla rota justo después de tocar "confirmar
mail", muy probablemente va a pensar que hizo algo mal o que la app está rota, y capaz ni
vuelve a abrir la app para probar si igual funcionó.

**Arreglo pendiente (sin implementar, dos caminos):**
1. **Rápido:** cambiar el "Site URL" (`Project Settings → Authentication → URL Configuration`
   — dentro de la sección Authentication, no en Project Settings general) por una página
   simple y real que no tire error (por ejemplo, un mensaje de "Ya confirmaste tu cuenta, volvé
   a la app"). No requiere tocar código Flutter ni generar un APK nuevo.
2. **Ideal para una app mobile:** configurar un "deep link" para que el link del mail abra
   directamente la app CowControl en vez del navegador — mejor experiencia, pero requiere
   cambios de código (paquete de deep links, intent filter en `AndroidManifest.xml`, configurar
   la redirect URL en Supabase) y un nuevo APK.

**Arreglo aplicado (2026-08-26), camino 1 ("Rápido"):**
- Se inicializó git en el proyecto y se creó el repo público **`github.com/Lovelyx-del/cowcontrol`**
  (ver sección "Meta" de `prompts.md` para el detalle de qué se subió y qué se excluyó).
- Se agregó `docs/confirmacion.html` (página estática con la paleta de colores de la app,
  mensaje "Cuenta confirmada — volvé a la app CowControl") y se activó **GitHub Pages**
  apuntando a esa carpeta (`master` / `/docs`). URL pública:
  `https://lovelyx-del.github.io/cowcontrol/confirmacion.html`.
- En Supabase (`Authentication → URL Configuration`), se cambió el **Site URL** de
  `localhost:3000` a esa URL, y se agregó la misma URL a la lista de **Redirect URLs**.
  Confirmado guardado por Santiago en ambos campos.
- **Verificado:** la página responde `200 OK` y se ve correctamente. No se probó todavía el
  flujo completo de principio a fin con un registro nuevo real (queda para la próxima vez que
  alguien se registre).
- El camino 2 (deep link a la app) sigue sin implementarse — no hace falta mientras el camino 1
  funcione bien; retomar solo si en algún momento se justifica la mejor UX.

---

## 17. PENDIENTE — cuenta de SendGrid trabada, no se pudo terminar de configurar el SMTP

**Contexto (2026-08-26):** para mejorar la entrega del mail de confirmación (con Gmail SMTP
cae seguido en spam — ver ítem 12), se decidió migrar a **SendGrid** (plan gratis, 100
mails/día, no requiere dominio propio, solo verificar un remitente). Al intentar crear la
cuenta con `santiagoargentote18@gmail.com` en signup.sendgrid.com (que redirige a Twilio Login,
el sistema unificado de cuentas desde que Twilio compró SendGrid):

- El formulario de registro dice **"The user already exists. Click the login link below to
  continue"**.
- Pero intentar loguearse con ese mail falla, y "¿olvidaste tu contraseña?" responde que **no
  hay ningún usuario vinculado a ese mail**.
- Causa probable, según la propia documentación de Twilio (`Troubleshooting account login
  issues` → "You haven't confirmed your email address"): en algún momento anterior se empezó
  un registro con ese mail pero nunca se confirmó el mail de verificación, así que la cuenta
  quedó a medio crear — ni loguable ni recuperable, pero suficiente para bloquear un registro
  nuevo con el mismo mail.
- Se revisó la bandeja de entrada y spam de `santiagoargentote18@gmail.com` buscando ese mail
  de verificación vieja de Twilio/SendGrid — no se lo encontró (puede haber expirado o nunca
  haber llegado).

**Sin resolver al cierre — próximo paso sugerido:** probar de nuevo el registro en SendGrid
con **otro mail** (evita el conflicto de la cuenta a medio crear), y si con eso entra, seguir
con lo planeado: verificar ese remitente (Single Sender Verification), crear una API Key
(Settings → API Keys), y cargarla en Supabase (`Authentication → Emails → SMTP Settings`):
host `smtp.sendgrid.net`, puerto `587`, usuario literal `apikey`, contraseña = la API key.
Mientras tanto, el proyecto sigue mandando mails con el SMTP de Gmail configurado en el ítem 12
(funciona, solo que cae en spam seguido — pedirle a cada persona que revise esa carpeta).

---

## 15. HECHO — requisitos de contraseña, mostrar/ocultar, y autocorrector apagado (`login_screen.dart`)

**Contexto:** Santiago pidió reglas de contraseña más estrictas que "mínimo 6 caracteres sin
ninguna regla" (que hasta ahora dejaba poner cualquier cosa), con un checklist visual en vivo
como en la mayoría de apps. Al mismo tiempo, se aprovechó para intentar mitigar un bug
reportado: la misma cuenta (mismo mail y contraseña) dejaba entrar a Santiago desde su celular
pero no a un compañero desde el suyo — sospecha fuerte: el teclado del celular del compañero
puede haber autocorregido/autocompletado la contraseña sin que él lo note, ya que el campo
está oculto por puntitos.

**Qué cambió, todo en `lib/screens/login_screen.dart`:**

1. **Nueva regla de contraseña, solo al registrarse:** mínimo 8 caracteres, al menos una letra
   y al menos un número. Al iniciar sesión NO se exige esto — una cuenta vieja podría tener
   una contraseña más corta (creada antes de esta regla) y no tiene que quedar bloqueada por
   eso.
2. **Checklist visual en vivo** debajo del campo de contraseña, visible solo en el formulario
   de registro: 3 líneas que pasan de ○ gris a ✓ verde a medida que se escribe y se cumple
   cada regla.
3. **Botón de "mostrar/ocultar contraseña"** (ícono de ojo) en el campo — para poder confirmar
   con la vista qué se tipeó realmente antes de enviar el formulario.
4. **`autocorrect: false` y `enableSuggestions: false`** en los campos de email y contraseña —
   apaga el autocorrector y las sugerencias del teclado del celular en esos dos campos
   puntuales.

**Por qué los puntos 3 y 4 apuntan directo al bug del compañero:** si el teclado de su celular
(pueden variar mucho entre marcas — Samsung, Xiaomi, Motorola traen cada uno su propio teclado
con comportamientos distintos) autocorrigió o sugirió una contraseña guardada distinta a la
que él pensaba haber escrito, no había forma de notarlo con el campo oculto. Con el
autocorrector apagado baja mucho la chance de que vuelva a pasar, y si pasa igual, el botón
del ojito permite confirmarlo a simple vista antes de tocar "Registrarme"/"Iniciar sesión".
**Falta confirmar** si esto resuelve el caso puntual del compañero — hay que pedirle que
pruebe de nuevo con esta versión y mire la contraseña con el ojito antes de enviar.

**Código completo del archivo final:**

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Traduce los codigos de error de Supabase Auth a mensajes en español que un
/// productor pueda entender, sin exponer el detalle tecnico de la excepcion.
String _mensajeError(Object error, {required bool esRegistro}) {
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
  return esRegistro
      ? 'No se pudo completar el registro. Intenta de nuevo.'
      : 'No se pudo iniciar sesion. Intenta de nuevo.';
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

  // Requisitos de contraseña — solo se exigen al registrarse, no al iniciar
  // sesion (una cuenta vieja puede tener una contraseña mas corta que la
  // regla actual, y no tiene que quedar bloqueada por eso).
  bool get _tieneOchoCaracteres => _passwordController.text.length >= 8;
  bool get _tieneLetra => _passwordController.text.contains(RegExp(r'[A-Za-z]'));
  bool get _tieneNumero => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _passwordEsValida => _tieneOchoCaracteres && _tieneLetra && _tieneNumero;

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
    });
    try {
      if (_esRegistro) {
        await _authService.registrarse(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.iniciarSesion(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (e) {
      debugPrint('Error de auth (${_esRegistro ? "registro" : "login"}): $e');
      setState(() {
        _error = _mensajeError(e, esRegistro: _esRegistro);
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
                  const Icon(Icons.pets, size: 72, color: AppColors.marronPrincipal),
                  const SizedBox(height: 12),
                  Text(
                    'CowControl',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (valor) =>
                        (valor == null || !valor.contains('@')) ? 'Ingresa un email valido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_mostrarPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(_mostrarPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
                      ),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) return 'Ingresa una contraseña';
                      if (_esRegistro && !_passwordEsValida) {
                        return 'La contraseña no cumple los requisitos de arriba';
                      }
                      return null;
                    },
                  ),
                  if (_esRegistro) ...[
                    const SizedBox(height: 8),
                    _reglaPassword('Minimo 8 caracteres', _tieneOchoCaracteres),
                    _reglaPassword('Al menos una letra', _tieneLetra),
                    _reglaPassword('Al menos un numero', _tieneNumero),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_esRegistro ? 'Registrarme' : 'Iniciar sesion'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed:
                        _cargando ? null : () => setState(() => _esRegistro = !_esRegistro),
                    child: Text(
                      _esRegistro ? 'Ya tengo cuenta — Iniciar sesion' : 'Soy nuevo — Registrarme',
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

  /// Una fila del checklist de requisitos de contraseña: circulo gris vacio
  /// si todavia no se cumple, tilde verde apenas se cumple.
  Widget _reglaPassword(String texto, bool cumplida) {
    final color = cumplida ? Colors.green : Colors.grey;
    return Row(
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
```

**Verificado:** `flutter analyze` sin errores. Falta probar visualmente en un celular (Santiago
lo va a hacer).

**Pendiente relacionado:** aplicar la misma regla (8 caracteres, letra + número) del lado de
Supabase, en `Authentication → Sign In / Providers` — sin eso, la app impide mandar una
contraseña débil desde la pantalla de registro, pero no hay nada que impida crear una cuenta
más floja por fuera de la app (llamando a la API directo). Falta hacerlo, es un paso rápido
del lado del dashboard, sin código.

---

## 16. HECHO — avisar si el registro salió bien o si el mail ya existía (`login_screen.dart` + `auth_service.dart`)

**Bug real encontrado:** Santiago probó "registrarse" con un mail que ya tenía cuenta (de
pruebas viejas) y la app no tiró ningún error — pero tampoco cambió la contraseña de esa
cuenta a la nueva que había tipeado. Al iniciar sesión después con la contraseña nueva, fallaba
(la real seguía siendo la vieja).

**Causa (no es un bug de la app, es comportamiento a propósito de Supabase):** si se llama a
`signUp()` con un mail que **ya existe y ya está confirmado**, Supabase no tira ningún error —
es una medida de seguridad para que nadie pueda "probar" mails ajenos y descubrir cuáles ya
tienen cuenta creada. El pedido se ignora silenciosamente (no cambia la contraseña, no manda
mail), pero desde el cliente se ve exactamente igual que un registro exitoso. La única forma
de distinguirlo: la respuesta trae `user.identities` **vacío** en ese caso, y con al menos un
elemento cuando el registro es realmente nuevo.

**Arreglo:** en `_enviar()` (`login_screen.dart`), al registrarse se revisa
`respuesta.user?.identities?.isEmpty` — si es `true`, se muestra el mismo mensaje que ya existía
para `user_already_exists` ("Ya existe una cuenta registrada con ese email."); si es `false`
(registro realmente nuevo), se muestra un mensaje de éxito en verde:

```dart
final respuesta = await _authService.registrarse(
  email: _emailController.text.trim(),
  password: _passwordController.text,
);
final yaExistia = respuesta.user?.identities?.isEmpty ?? false;
setState(() {
  if (yaExistia) {
    _error = 'Ya existe una cuenta registrada con ese email.';
  } else {
    _mensajeExito = 'Te registraste con exito. Revisa tu correo '
        '(y la carpeta de spam) y toca el link de confirmacion antes '
        'de iniciar sesion.';
  }
});
```

Se agregó el estado `_mensajeExito` (mismo patrón que `_error`, pero en verde) y se limpian
los dos (`_error` y `_mensajeExito`) cada vez que se envía el formulario de nuevo o se cambia
entre "Registrarme"/"Iniciar sesión", para que no quede un mensaje viejo pegado en pantalla.
`AuthService.registrarse()` no necesitó cambios — ya devolvía el `AuthResponse` completo,
solo faltaba leer el campo `identities` del lado de la pantalla.

**Verificado:** `flutter analyze` sin errores. APK regenerado y actualizado en
`C:\dev\CowControl.apk` y `apk_para_probar\`.

**Consecuencia práctica de este hallazgo:** todas las cuentas de prueba creadas antes de la
regla de 8 caracteres/letra/número (ítem 15) quedaron con contraseñas viejas que no se pueden
"actualizar" simplemente registrándose de nuevo con el mismo mail — hay que borrarlas. Como
todavía no hay ningún productor real usando la app, se decidió borrar todas las cuentas de
prueba existentes en `Authentication → Users` y volver a registrarse desde cero con la versión
nueva del APK. Sin implementar todavía un flujo de "cambiar contraseña" dentro de la app — no
hacía falta hasta ahora, quedaría para más adelante si se necesita.

---

## 18. RESUELTO — faltaba el permiso INTERNET en el manifest de release (bug de mes y medio: "no deja registrarse ni iniciar sesión" en cualquier celular que no fuera el de Santiago)

**Contexto (2026-08-30):** un compañero (Federico) instaló el APK y no pudo ni registrarse ni
iniciar sesión — mismo mensaje genérico en los dos casos, con capturas confirmando que los
datos cumplían todas las reglas de contraseña. Este bug ya se había reportado sin resolver el
2026-08-07 (`prompts.md` sección 11) y vuelto a sospechar el 2026-08-25, siempre atribuido a
"el internet del celular" o "el autocorrector", sin poder confirmarlo nunca porque nadie podía
conectar por USB el celular que fallaba.

**Causa real, encontrada revisando el código (no hacía falta un celular conectado):**
`android/app/src/main/AndroidManifest.xml` nunca declaró
`<uses-permission android:name="android.permission.INTERNET"/>`. Ese permiso sí estaba en
`android/app/src/debug/AndroidManifest.xml` (puesto ahí por el propio template de Flutter,
"required for development... hot reload"), pero **ese archivo solo se mezcla en builds debug y
profile, nunca en release**. Entonces:
- `flutter run` (siempre por USB, lo único que se había usado para "confirmar que funciona")
  → build debug → permiso agregado automáticamente → todo bien.
- El `.apk` de release real, el que se manda por WhatsApp → sin el permiso en ningún lado → la
  app no tiene acceso a internet → cualquier llamada a Supabase falla con una excepción de red
  genérica → mismo mensaje de error en login y en registro, porque ninguno de los dos llega
  siquiera a tocar la red.

Esto explica el patrón completo que nunca cerraba: por qué fallaba igual en las dos pantallas,
por qué "en la PC de Santiago andaba" (ahí siempre se probó con `flutter run`, nunca con el
`.apk` instalado a mano), y por qué revisar `minifyEnabled` o sospechar del celular ajeno nunca
encontraba nada — el bug no estaba en la lógica de la app ni en ningún celular en particular.

**Arreglo aplicado:**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application ...>
```
Agregado a nivel raíz del `<manifest>` de `android/app/src/main/AndroidManifest.xml` (fuera de
`<application>`), para que quede incluido en **todos** los build types, no solo debug.
Verificado con `flutter analyze` → "No issues found!".

**Pendiente para dar por cerrado del todo:** regenerar el APK de release e instalarlo en un
celular ajeno (no probar con `flutter run`, que es justamente lo que ocultaba el bug) para
confirmar que ahora sí deja registrarse e iniciar sesión.

---

## 19. RESUELTO — íconos de categoría en el filtro "Todas" de la Planilla, tamaños parejos, y colores por sexo

**Contexto (2026-08-30):** se confirmó visualmente en el celular (con 5 animales de prueba,
`TEST-VACA-001` etc., uno por categoría en el campo "Horacio SRL") y se corrigieron 3 problemas
que aparecieron en el camino:
1. **`ternero.png` y `ternera.png` se veían mucho más chicos** que los otros 3 — no era por el
   largo del texto (`TEST-VAQUILLONA-001` es el más largo de todos y su ícono salía normal),
   sino porque esos dos PNG tenían mucho margen transparente sin usar dentro de su lienzo
   (ocupaban 49-56% del ancho vs. 87-100% de los otros 3). Se recortó el margen transparente de
   las 5 imágenes (`assets/images/*.png`) a su contenido real, y se agregó `fit: BoxFit.contain`
   en `categoria_badge.dart` para que ninguna quede deformada al tener ahora relaciones de
   aspecto distintas entre sí.
2. **Colores por sexo** (pedido para poder distinguir categorías de un vistazo, ya que a este
   tamaño la sola orientación del dibujo no alcanza): toro/ternero en celeste, vaca/vaquillona/
   ternera en rosa. Primer intento con tonos pasteles (`Color(0xFF64B5F6)` / `Color(0xFFF48FB1)`)
   quedó muy apagado contra el fondo crema de la app — se subió la saturación a
   `AppColors.celesteMacho = 0xFF2196F3` y `AppColors.rosaHembra = 0xFFE91E63` (Material Blue
   500 / Pink 500), mucho más distinguibles.
3. **En el dropdown "Todas"**, el ícono quedaba pegado al texto de cada opción en vez de ir al
   extremo derecho del menú — causa: el `Row` interno usaba `mainAxisSize: MainAxisSize.min`
   (se ajusta al contenido). Cambiado a `mainAxisAlignment: MainAxisAlignment.spaceBetween`,
   que empuja el ícono al borde derecho del ancho real del menú desplegable.

Confirmado por Santiago: "quedó perfecto, por lo menos el botón de todas".

---

## 20. PENDIENTE (mejora a futuro, no urgente) — íconos de cara en vez de cuerpo entero

Aun con el color por sexo (ítem 19), Santiago sigue sin distinguir bien un animal de otro por
la silueta del cuerpo sola (todos son "una vaca de perfil" con pequeñas diferencias de tamaño/
cuernos/ubre difíciles de notar a 28px). Idea para más adelante: reemplazar las 5 ilustraciones
de cuerpo entero por ilustraciones de **cara** de cada categoría — capaz se note más la
diferencia entre categorías por rasgos de la cara (cuernos, tamaño, forma) que por el cuerpo
completo. Sin definir todavía cómo se generarían esas 5 caras nuevas (¿Gemini otra vez, como
las de cuerpo?) — retomar cuando Santiago quiera buscarlas.

---

## 21. HECHO — recuperación de contraseña ("¿Olvidaste tu contraseña?"), explicado para la presentación

**Por qué se hizo:** hasta ahora, si un productor se olvidaba la contraseña, no había ninguna
forma de recuperarla desde la app — la única opción era que Santiago (como administrador del
proyecto en Supabase) le pusiera una nueva a mano desde el dashboard, algo que obviamente no
escala a productores reales. Se evaluaron dos caminos (ver conversación del 2026-08-30): un
"camino prolijo" con *deep links* (el mail abre la app directo) y un "camino simple" (el mail
abre una página web aparte). **Se eligió el camino simple**, pensando en la fecha de la
presentación — menos superficie para que algo salga mal a último momento.

**Se descartó explícitamente la idea de una "pregunta secreta"** (tipo "¿nombre de tu
mascota?") como paso previo a mandar el mail de recuperación. No es una decisión de gusto: las
guías de seguridad más aceptadas (NIST, la agencia de EE.UU. que fija estándares de
autenticación) sacaron ese método de la lista de prácticas válidas en 2017, porque las
respuestas casi siempre se pueden adivinar o buscar en redes sociales — no suman seguridad
real, solo suman fricción. El estándar actual (el mismo que usan bancos y todas las apps
grandes) es: mandar un link de un solo uso a un mail ya verificado, con vencimiento corto. Eso
es exactamente lo que hace Supabase Auth de fábrica.

### Cómo funciona de punta a punta (para explicarlo en la presentación)

1. En la Pantalla 0 (`login_screen.dart`), en el modo "Iniciar sesión", hay un botón nuevo
   **"¿Olvidaste tu contraseña?"** debajo del campo de contraseña.
2. Al tocarlo, la app llama a `AuthService.restablecerPassword(email)`
   (`lib/services/auth_service.dart`), que es una sola línea:
   `Supabase.auth.resetPasswordForEmail(email, redirectTo: '...')`. Supabase se encarga de
   generar un token de un solo uso y mandar el mail — no hay que programar nada de eso a mano.
3. El link de ese mail **no abre la app** — abre una página nueva,
   **`docs/restablecer.html`**, publicada en el mismo GitHub Pages que ya usamos para la
   página de "cuenta confirmada" (`https://lovelyx-del.github.io/cowcontrol/restablecer.html`).
   Se eligió esto en vez de que el link abra la app directo porque eso ("deep links") pide
   configuración extra de Android/iOS — más cosas que podrían fallar justo antes de la
   presentación. Queda anotado como mejora posible a futuro si en algún momento molesta salir
   de la app.
4. Esa página carga el **SDK de Supabase para JavaScript** (una librería externa, vía
   `<script src="...">`, no hace falta instalar nada) usando la misma `SUPABASE_URL` y
   `anon key` que ya usa la app. **La "anon key" no es secreta** — está pensada para ir en
   código público (páginas web, apps móviles); lo que de verdad protege los datos es RLS del
   lado del servidor (las políticas de seguridad por fila), no ocultar esta clave. Es la misma
   que ya viaja adentro del `.apk` que se comparte por WhatsApp.
5. Cuando la página carga, el SDK **detecta solo** el token que Supabase pegó en la URL del
   link (evento `PASSWORD_RECOVERY`) y arma una sesión temporal válida únicamente para cambiar
   la contraseña — no le da acceso a nada más de la cuenta.
6. La página muestra un formulario simple (misma regla que la app: 8 caracteres, letra y
   número, con el mismo checklist visual en vivo). Al confirmar, llama a
   `supabase.auth.updateUser({ password })` y muestra un mensaje de éxito.
7. Si el link ya venció o es inválido (pasaron más de unos segundos sin que llegue el evento de
   recuperación), la página avisa que hay que pedir uno nuevo desde la app, en vez de mostrar
   un error críptico.

### Configuración que hubo que hacer en Supabase (aparte del código)

En **Authentication → URL Configuration → Redirect URLs**, agregar
`https://lovelyx-del.github.io/cowcontrol/restablecer.html` a la lista — Supabase exige que
cualquier URL de redirección esté en esa lista blanca antes de dejarla usar, es una medida de
seguridad para que nadie pueda mandar el token de recuperación a un sitio ajeno.

### Archivos involucrados

- `lib/services/auth_service.dart` — método `restablecerPassword()`.
- `lib/screens/login_screen.dart` — botón "¿Olvidaste tu contraseña?" y su manejo de
  éxito/error (reutiliza `_mensajeError()`, que se generalizó para aceptar cualquier mensaje de
  respaldo en vez de solo login/registro).
- `docs/restablecer.html` — la página nueva, con su propio HTML/CSS/JS (sin build, sin
  dependencias que instalar) y comentarios explicando cada parte.

**PENDIENTE — la página se queda trabada en "Verificando el link..." y nunca llega a mostrar
el formulario (probado 2026-08-30, captura de WhatsApp).** Causa más probable: este proyecto
usa el flujo **PKCE** de Supabase (se lo notamos antes con el `?code=...` de la confirmación de
mail) — en PKCE, completar el link requiere un "code verifier" que Supabase guarda **en el
mismo lugar donde se pidió el link**. Como el botón "¿Olvidaste tu contraseña?" se toca **desde
la app Flutter** (que guarda ese verifier en su propio almacenamiento interno del celular) pero
el link se abre **en el navegador** (un lugar de almacenamiento completamente distinto, sin
acceso a lo que guardó la app), el navegador nunca puede completar el intercambio del código —
se queda esperando para siempre. Es un problema de arquitectura (dos contextos distintos), no
un bug de tipeo en el HTML.

**Posible solución (sin aplicar todavía):** cambiar el flujo de autenticación de PKCE a
**implícito** — con ese flujo, el link del mail trae el token de acceso directo en la URL
(`#access_token=...`), autocontenido, sin necesitar nada guardado de antemano en ningún lado.
Se configura al inicializar Supabase en `main.dart`:
```dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
);
```
**Ojo:** esto afecta el flujo de autenticación de toda la app (login, registro, confirmación de
mail), no solo esta pantalla — hay que probar de nuevo todo el ciclo de auth si se cambia, no
solo la recuperación de contraseña. Evaluar con calma antes de aplicarlo. Alternativa sin tocar
el flujo global: revisar si `resetPasswordForEmail` acepta especificar el flujo por-llamada
(no confirmado todavía si la versión actual de `supabase_flutter` lo permite).

**Retomado el 2026-08-30 (misma sesión, más tarde) — diagnóstico confirmado por código, pero
sin aplicar el fix todavía, decisión de Santiago.** Se revisó `main.dart`
(no declara `authFlowType`, así que usa **PKCE** por defecto) y `auth_service.dart` para
confirmar la causa. Se afinó además el mecanismo exacto de por qué queda trabado **para
siempre** en vez de mostrar el error a los 2.5 segundos como debería el `setTimeout` de
respaldo: el intento de intercambio de código PKCE sin "code verifier" no solo falla, deja
colgado un lock interno del SDK de JS de Supabase — y como `getSession()` (el que corre en
ese `setTimeout`) necesita el mismo lock, también se queda esperando para siempre. Por eso no
es un típo del HTML, es la arquitectura de dos contextos de storage distintos chocando.

Se le explicó a Santiago la diferencia entre PKCE e implícito con la analogía de la caja
fuerte de doble llave (el secreto que se queda en el celular vs. la llave completa mandada por
mail), y se evaluó el riesgo real de pasar a implícito: **bajo pero no cero** — el caso real es
que algunos proveedores de mail "pre-visitan" links automáticamente antes de que el usuario los
abra, lo que en implícito podría gastar el link antes de tiempo (en PKCE no, porque el código
solo no alcanza sin la llave del celular). CowControl no usa Google/OAuth ni "magic link" (los
casos donde PKCE importa más), así que el riesgo queda acotado a los dos mails de auth
(confirmación y recuperación) — comparable en aceptabilidad al riesgo ya documentado y aceptado
en el ítem 5b (Raspberry Pi con `service_role` sin restricción de `campo_id`).

**Alternativas evaluadas (ninguna aplicada todavía):**
1. Cambiar a implícito globalmente — simple, bajo esfuerzo, riesgo bajo y aceptable. Recomendado
   por Claude.
2. Deep links (el mail abre la app directo, no el navegador) — la solución técnicamente más
   correcta (mantiene PKCE de punta a punta, sin este problema), pero pide configuración extra
   de Android/iOS — más superficie para que algo falle justo antes de la presentación. Ya se
   había descartado por esto mismo en la sección 21 de arriba.
3. Implícito solo para `resetPasswordForEmail`, PKCE para el resto — **no es posible**, se
   confirmó que el tipo de flujo se configura una sola vez para toda la app en
   `Supabase.initialize()`, no por llamada individual.
4. Dejarlo pendiente, documentado como limitación conocida — **esta es la que eligió Santiago
   por ahora.**

**Decisión (2026-08-30):** Santiago prefirió no tocar nada todavía. Queda igual que antes —
`docs/restablecer.html` sigue trabado — pero ahora con el diagnóstico completo y las 4
alternativas evaluadas, listo para decidir rápido en cuanto se quiera retomar. Si se retoma,
lo más probable es la alternativa 1 (cambio chico en `main.dart`, guiado paso a paso porque es
código Dart) salvo que Santiago prefiera invertir el tiempo extra en deep links (alternativa 2)
antes de la expo.

---

## 22. HECHO (2026-09-13) — sacar el ícono de la pantalla de carga nativa (queda mal recortado)

Anotado 2026-08-30, a pedido de Santiago. Cuando la app arranca (pantalla de carga antes de que
se termine de cargar el campo/registro, etc.) aparece el ícono de la app — y se ve mal
recortado, porque salió de una herramienta gratuita (remove.bg + Pillow, ver sección 15.6 de
`prompts.md`) que no lo centró perfecto para este uso puntual. **Santiago no quiere que
aparezca ningún ícono en esa pantalla** — de mínima, que quede solo un fondo marrón liso, sin
nada más.

**Pista técnica (revisado el código, no aplicado todavía):** el proyecto no usa el paquete
`flutter_native_splash` — `android/app/src/main/res/drawable/launch_background.xml` es todavía
la plantilla por defecto de Flutter (fondo blanco liso, sin imagen), y no hay ningún
`android/app/src/main/res/values-v31/styles.xml`. Eso hace sospechar que el ícono recortado que
ve Santiago **no** sale de ese archivo, sino de la pantalla de splash automática que trae
Android 12 en adelante (API 31+): si no hay un `values-v31/styles.xml` que la configure a mano,
Android usa el ícono adaptable de la app (el mismo del launcher) metido en una máscara circular
propia de esa pantalla — más agresiva que el recorte del ícono del launcher — y ahí es donde se
nota mal centrado.

**Dirección posible para cuando se retome (sin confirmar ni probar todavía):**
- Crear `android/app/src/main/res/values-v31/styles.xml` con un `LaunchTheme` que fije
  `android:windowSplashScreenBackground` al marrón de la app (`AppColors.marronPrincipal` o el
  fondo crema, a confirmar con Santiago cuál) y sin ícono (o uno transparente de 1x1) — o
  directamente sumar el paquete `flutter_native_splash`, que resuelve esto para todas las
  versiones de Android de una sola vez con un color plano configurado en `pubspec.yaml`.
- De paso, actualizar `launch_background.xml` (el splash viejo, pre-Android 12) del blanco
  actual al mismo marrón, para que el arranque se vea consistente en cualquier versión de
  Android, no solo en las nuevas.
- Falta confirmar con Santiago qué tono exacto de marrón/crema quiere antes de tocar nada, y
  probar en un dispositivo Android 12+ real (el emulador `Pixel_CowControl` corre Android 15,
  sirve para probar esto).

**Aplicado (2026-09-13):** se usó el mismo crema de fondo de toda la app
(`AppColors.fondo` = `#FAF3E8`, definido en `lib/theme/app_theme.dart`), no marrón — así no hay
ningún salto de color al pasar del splash a la primera pantalla (Login), que ya usa ese mismo
fondo. Se creó `android/app/src/main/res/values-v31/styles.xml` (la pieza que faltaba — sin
esto Android 12+ usa su pantalla de splash propia, aparte de `windowBackground`, y mete el
ícono del launcher en una máscara circular que lo recorta mal): `windowSplashScreenBackground`
en el crema nuevo, y `windowSplashScreenAnimatedIcon` apuntando a
`@android:color/transparent` — el truco estándar para que no aparezca ningún ícono. Se agregó
también `values-night-v31/styles.xml` (mismo contenido) para que el modo oscuro del sistema no
muestre un splash distinto, ya que la app no tiene tema oscuro propio. De paso se actualizó
`drawable/launch_background.xml` y `drawable-v21/launch_background.xml` (splash pre-Android 12,
antes blanco liso) al mismo crema, para que el arranque se vea igual en cualquier versión de
Android. Se agregó el color `fondo_splash` en `android/app/src/main/res/values/colors.xml`.

**Bug encontrado y corregido en el camino:** los comentarios XML no permiten `--` adentro (error
de Gradle: `La cadena "--" no está permitida en los comentarios`) — se reemplazaron los guiones
dobles por raya (—) en los comentarios nuevos.

**Confirmado:** `flutter build apk --debug` compila bien y `flutter analyze` da "No issues
found!". Falta la prueba visual en un dispositivo/emulador real (abrir la app y confirmar que
el splash se ve crema liso, sin ícono, en vez del ícono recortado de antes).

---

## 23. ACTIVO (2026-09-13) — animal sin categoría en la primera lectura del tag, el productor la elige

Anotado 2026-08-30, a pedido de Santiago — **reafirma y precisa** el diseño conceptual ya
acordado el 2026-08-06 (`prompts.md` sección 10.6, y pendiente ítem 11 de la sección 7 del
mismo archivo), sin implementar todavía.

Cuando llega una lectura de un tag que no coincide con ningún animal ya cargado en el campo
(caso típico: la primera vez que un productor nuevo — o un compañero de equipo probando con el
PDF/guía de Raspberry Pi — pasa un animal por el lector), **el animal no tiene que aparecer con
una categoría puesta de antemano** (no asumir "vaca" ni ninguna otra por defecto). Tiene que
aparecer **sin tipo asignado**, y recién ahí, viendo el animal físicamente pasar, el productor
elige a mano de qué categoría es (vaca/toro/ternero/ternera/vaquillona) — no se le asigna nada
automático ni se adivina.

Sigue dependiendo de lo mismo que ya estaba anotado en el ítem 11 de `prompts.md` sección 7:
tener `sesiones_conteo` con `campo_id` funcionando, y cambiar el `_marcarLectura` de
`conteo_screen.dart` (hoy descarta con `if (animalCoincidente == null) return;` en vez de
mostrar la lectura como "no identificada"). No implementar nada de esto todavía — queda
anotado junto con el resto del rework de sesiones de conteo.

**Implementado (2026-09-13):** ya no hace falta `sesiones_conteo` — se resolvió con la tabla
`conteos` del ítem 25. `_marcarLectura` de `conteo_screen.dart` ahora agrega el `rfid_uid` a
una lista `_sinIdentificar` en vez de descartarlo; cada uno aparece en una sección "Sin
identificar" de la Pantalla 3, y tocarlo abre un diálogo para elegir categoría — al confirmar,
`AnimalesService.crearAnimal()` (método nuevo) inserta la fila en `datos_animales` con ese
`rfid_uid`, el `campo_id` del conteo actual, y la categoría elegida (columna `sexo`). No hizo
falta ningún cambio de SQL — el GRANT y la política RLS de `datos_animales` ya cubrían el
INSERT. Pendiente: probar con una lectura real (o insertada a mano por SQL) para confirmar
que funciona de punta a punta.

**Nota — el llamado a la acción original queda separado, ver ítem 29 más abajo.**

---

## 24. ACTIVO (pasos 2 y 3 hechos, falta el paso 1) — sacar `id_animal` de `datos_lectura`

Anotado 2026-08-30. Surgió de una duda de Germaioni por WhatsApp sobre el diagrama de tablas
de Supabase — ya se le había explicado lo mismo a un compañero en la sesión del 2026-08-06 (fue
el ítem 10.8 de `prompts.md`), así que es la segunda vez que este campo confunde al equipo.

**Confirmado con el código antes de decidir:** `id_animal` en `datos_lectura` nunca lo llena
nadie — el script de referencia de la Raspberry Pi (`rfid_tick.py`) solo manda `rfid_uid`,
`campo_id` y `fecha_hora`; y el emparejamiento real en `conteo_screen.dart` (`_marcarLectura`)
ya funciona con `rfid_uid`, `id_animal` era solo una condición extra que nunca se cumplía en la
práctica. Se evaluaron dos caminos: sacar el campo (simplificar) o agregar un trigger de
Postgres que lo llene solo al insertar (más útil para reportes SQL directos, pero suma
complejidad que hoy nadie necesita). **Se eligió sacarlo** — proyecto de secundaria, sin
reportes SQL pendientes que lo necesiten, y ya generó confusión dos veces.

### Paso 1 — SQL Editor de Supabase
```sql
alter table datos_lectura drop column id_animal;
```

### Paso 2 — reemplazar `lib/models/lectura.dart` completo
```dart
/// Representa una fila de datos_lectura — un pasaje de un tag por el lector RFID/NFC.
class Lectura {
  final String id;
  final String rfidUid;
  final String? campoId;
  final DateTime fechaHora;
  final String? observaciones;

  const Lectura({
    required this.id,
    required this.rfidUid,
    this.campoId,
    required this.fechaHora,
    this.observaciones,
  });

  factory Lectura.fromMap(Map<String, dynamic> map) {
    return Lectura(
      id: map['id'] as String,
      rfidUid: map['rfid_uid'] as String,
      campoId: map['campo_id'] as String?,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
      observaciones: map['observaciones'] as String?,
    );
  }
}
```

### Paso 3 — `lib/screens/conteo_screen.dart`, cambiar una línea
La línea 51 hoy dice:
```dart
      if (animal.id == lectura.idAnimal || animal.rfidUid == lectura.rfidUid) {
```
Borrar esa línea y poner esta en su lugar:
```dart
      if (animal.rfidUid == lectura.rfidUid) {
```

**Ojo, no confundir con `datos_vacuna.id_animal`** — es un campo de otra tabla, distinto, que sí
se usa (`vacunas_screen.dart`) y no se toca.

### Verificación
`flutter analyze` (tiene que dar "No issues found!"), `R` para hot restart, y probar el conteo
en vivo — que el ✓ se siga marcando igual que antes de sacar el campo.

**Estado (2026-08-30):** Santiago aplicó los pasos 2 y 3 en su copia local — confirmado con
`flutter analyze` → "No issues found!" y revisado el contenido de los dos archivos, coincide
exacto. **Falta el paso 1** (el `alter table` en Supabase) — queda a cargo de Germaioni, que
también va a probar el conteo con la Pi y los tags reales del lado del hardware (Santiago no
tiene el hardware para probar esa parte). Como es la misma base de datos compartida para
todos, ese paso solo hace falta correrlo una vez, no importa quién lo corra.

---

## 25. HECHO (2026-08-31) — la app ahora sí escribe en `conteos` al iniciar/detener/finalizar

Surgió de una duda de Germaioni por WhatsApp el 2026-08-31: armó por su cuenta una tabla
`conteos` (`id`, `fecha`, `estado`) esperando que la app escribiera ahí al apretar "Iniciar
conteo", pero nunca aparecía ninguna fila. **No era un bug — esa parte nunca se había
construido del lado de la app.** `conteo_screen.dart` solo escuchaba Realtime, nunca escribía
en ninguna tabla de conteos (la migración `sesiones_conteo` documentada en la sección 6/7 de
`prompts.md` seguía sin aplicarse). Se armó la integración completa contra la tabla `conteos`
que Germaioni ya tenía viva, en vez de retomar el diseño original de `sesiones_conteo`.

**Hallazgos en el camino:**
- La tabla `conteos` de Germaioni no tenía `campo_id` — se agregó (`alter table ... add column
  campo_id uuid references datos_campo(id)`), más el `GRANT` explícito a `authenticated` (la
  capa que siempre se olvida, ítem 12 de `prompts.md` sección 7) y una política RLS
  `"solo conteos de su campo"`, mismo criterio que el resto de las tablas.
- El `CHECK` real de `estado` no es `'activo'/'pausado'/'finalizado'` como decían las notas de
  Germaioni, sino **`'en_curso'/'pausado'/'finalizado'`** — confirmado con
  `pg_get_constraintdef`. Importante para que Germaioni ajuste el polling del lado de la
  Raspberry Pi (su plan original decía que iba a buscar `estado = 'activo'`, que nunca va a
  aparecer).

**Archivos nuevos/tocados:**
- `lib/services/conteos_service.dart` (nuevo) — `iniciarOReanudar(campoId)` (si hay un conteo
  `'pausado'` de ese campo lo reanuda, si no crea uno nuevo `'en_curso'`), `pausar`,
  `reanudar`, `finalizar`.
- `lib/screens/conteo_screen.dart` — `initState` ahora llama a `iniciarOReanudar` antes de
  escuchar Realtime; los botones "Detener"/"Reanudar"/"Finalizar" ahora también actualizan el
  estado en `conteos`, no solo el listener local.

**Confirmado funcionando (2026-08-31):** probado en el emulador de Santiago sin hardware —
apretar "Iniciar conteo" crea la fila en `conteos` con el `campo_id` correcto, "Detener" la
pasa a `'pausado'`, "Finalizar" a `'finalizado'`. Es la misma tabla compartida para todos los
productores (mismo Supabase, mismo patrón multi-tenant que el resto de la app) — cuando
Germaioni pruebe desde su propia cuenta logueada, su conteo va a aparecer como otra fila más
en la misma tabla, distinguida por su `campo_id`.

**Pendiente:** que Germaioni corra su parte (Raspberry Pi consultando `conteos` por
`estado = 'en_curso'` y mandando `conteo_id` en cada lectura a `datos_lectura`) y confirme con
tags reales. También falta actualizar `Guia_Raspberry_Pi-CowControl.pdf`/`rfid_tick.py` con
este flujo cuando se retome esa guía — no se tocó en esta sesión.

---

## 26. PENDIENTE — arquitectura elegida para la cámara/grabación (con Juana Manso), sin implementar

Anotado 2026-09-01. Se retomó el pendiente viejo de "cámara" (ítem 2 de este archivo, y
sección 16 del pendiente de `prompts.md`). Antes de diseñar nada se releyó completa la
`Carpeta técnica-CowControl.pdf` (el documento fundacional del proyecto ante el colegio) para
confirmar qué pide exactamente — **confirmado: pide video, no foto**, textual: *"los tiempos
de grabación sincronizados y especificados cuando el animal en particular se acerca al sensor.
Ejemplo: el ID número 2387 pasó en el minuto 8:33."* El plan original de ese mismo documento
(de antes de que existiera la app Flutter) ya proponía usar la webcam de una notebook **"Juana
Manso"** (netbook que el Estado argentino entrega a estudiantes secundarios) como cámara — no
hay ningún módulo de cámara comprado ni planeado para la Raspberry Pi.

**Metodología:** Santiago pidió explícitamente correr 3 propuestas de arquitectura
independientes (sin verse entre sí) + un 4to agente "chairman" que las evalúe. Se corrió como
`Workflow` (4 agentes, ~330k tokens, ~11 min). Detalle completo de las 3 propuestas completas
(cada una larguísima, con código de ejemplo) quedó en el transcript de esa sesión de Claude
Code — acá se resume lo esencial para poder implementarlo sin tener que re-correr nada.

### Las 3 arquitecturas evaluadas (resumen)

1. **Edge/todo local** — la Juana Manso graba y corta los clips ella misma con ffmpeg (Python
   + `subprocess`), sin subir nunca el video pesado a ningún lado — solo los clips finales
   (livianos) suben a Supabase Storage. Sin n8n.
2. **n8n como orquestador central** — la idea original de Santiago, llevada a diseño concreto:
   n8n self-hosteado en la propia notebook, dos workflows visuales (control de grabación +
   corte de clips), usando el nodo Execute Command para correr ffmpeg.
3. **Serverless, sin servidor propio** — el video sube completo a Supabase Storage, dispara un
   webhook a una Edge Function liviana, que dispara un job de GitHub Actions (VM efímera y
   gratis) que baja el video, corta los clips con ffmpeg, sube los clips y borra el video
   crudo. Nada queda corriendo 24/7.

### Veredicto del chairman: gana la Propuesta 1 (edge/local), con un ajuste de la 3

**Por qué gana:** es la única de las tres donde el video pesado nunca sale de la notebook (ni
sube ni baja de ningún lado), no mete ninguna herramienta nueva para el equipo (es el mismo
tipo de trabajo — Python + HTTP — que Germaioni ya hizo para la Raspberry Pi), y termina siendo
la más barata en cuota real de Supabase.

**n8n queda descartado** en las 3 propuestas, por caminos distintos: no resuelve nada que el
script no resuelva más simple (P1), depende de que alguien se acuerde de prenderlo a mano cada
vez, y su nodo Execute Command viene deshabilitado por defecto desde n8n 2.0 (P2), y n8n Cloud
ya no tiene plan free permanente mientras que self-hosted necesita igual un proceso corriendo
(P3). **Verificación en vivo del chairman:** probó el health check de la instancia de n8n
conectada a esta sesión de Claude Code y no estaba corriendo ("Application not found") —
evidencia concreta, el mismo día, del riesgo que señalaba la Propuesta 2.

**El chairman también encontró un error en la Propuesta 1** (revisando el código real, no
confiando en lo que decía cada propuesta): asumía que `fecha_hora` en `datos_lectura` la pone
el reloj de Supabase, pero `rfid_tick.py` (línea 39) en realidad usa
`datetime.now(timezone.utc)` — **el reloj de la propia Raspberry Pi**. La Propuesta 3 sí lo
había marcado como duda a confirmar en vez de asumirlo — de ahí el ajuste importado.

### Arquitectura final recomendada (Propuesta 1 + el ajuste de la 3)

- Un script Python corre en la Juana Manso, en loop, haciendo polling a la tabla `conteos`
  cada pocos segundos (mismo patrón que ya usa `rfid_tick.py` sobre esa tabla) para saber
  cuándo arrancar/parar de grabar.
- Al detectar `estado = 'en_curso'` por primera vez para un conteo nuevo: arranca a grabar con
  `ffmpeg` (webcam vía DirectShow en Windows, resolución modesta tipo 640x480/15fps), y en ese
  mismo instante **le pide la hora a Supabase** (no usa el reloj de Windows) y la guarda como
  el "cero" (`t0`) contra el que se van a calcular todos los offsets — así se compara todo
  contra un solo reloj de referencia, no dos relojes de máquinas distintas (Pi vs. notebook).
- Sigue grabando de corrido aunque el conteo pase por `'pausado'`/`'en_curso'` de nuevo — no
  corta ni empalma segmentos, es más simple y no se pierde nada.
- Al detectar `estado = 'finalizado'`: cierra ffmpeg prolijamente, y por cada fila de
  `datos_lectura` de ese `conteo_id` calcula `offset = fecha_hora_lectura - t0`, corta un clip
  de ~2-3s con `ffmpeg -ss {offset-1} -i grabacion.mp4 -t 3 ...` (reencodando, no `-c copy`,
  para que el corte caiga justo donde se pidió y no en el keyframe más cercano).
- Cada clip sube a un bucket nuevo de Supabase Storage (`clips-conteo/<conteo_id>/<lectura_id>.mp4`),
  y se guarda su URL en una columna nueva `datos_lectura.clip_url` (`alter table datos_lectura
  add column clip_url text;`) — no hace falta tabla aparte.
- Del lado Flutter: paquete `video_player` (gratis, oficial) para reproducir el clip, en la
  ficha del animal o el historial de lecturas — mismo patrón que los botones de
  Fertilidad/Vacunas/Observaciones que ya existen.
- Costo esperado: gratis con margen amplio (clips de ~0.3-0.8MB cada uno, caben más de 1000 en
  el 1GB gratis de Supabase Storage — muy por encima de lo que un prototipo de secundaria va a
  generar).

**Riesgos/puntos débiles que quedan, aceptados para un prototipo:** no probado todavía en el
hardware real (webcam+ffmpeg en la Juana Manso específica — primer paso a probar aislado, sin
nada de Supabase); la notebook tiene que estar prendida, sin suspenderse y bien apuntada
durante todo el conteo (detalle humano de armado, no de software); segunda `service_role key`
en circulación (mismo modelo de confianza ya aceptado para la Pi, ítem 5b, simplemente
duplicado).

### Bloqueante compartido por las 3 propuestas (hay que resolverlo antes, sea cual sea la arquitectura)

**`rfid_tick.py` todavía no manda `conteo_id` en cada lectura que inserta en `datos_lectura`**
(confirmado leyendo el script real — el `payload` de `mandar_lectura()` solo tiene `rfid_uid`,
`campo_id`, `fecha_hora`). Sin `conteo_id`, ninguna arquitectura de video puede saber qué
lecturas pertenecen a qué conteo/video. Hay que confirmar con Germaioni si ya lo actualizó él
mismo o sigue pendiente, y coordinar el cambio si falta.

### Próximos pasos, en orden (nada de esto se implementó todavía)

1. Confirmar con Germaioni el estado real de `conteo_id` en `datos_lectura` (bloqueante).
2. Prueba aislada de hardware: los 2 comandos de ffmpeg (grabar webcam + cortar un clip),
   corridos a mano en la Juana Manso real, sin nada de Supabase todavía — para confirmar que
   la cámara/ffmpeg cooperan antes de escribir el script completo. La puede hacer Santiago
   mismo con un instructivo corto.
3. Cambios chicos en Supabase: bucket nuevo `clips-conteo` + columna `clip_url` en
   `datos_lectura`. SQL corto, lo puede correr Santiago como ya hizo antes.
4. Script de arranque/parada en la notebook (polling + lanzar/cerrar ffmpeg, con el ajuste del
   reloj de Supabase) — sesión guiada.
5. Lógica de corte + subida de clips — sesión guiada.
6. Botón/pantalla en Flutter para reproducir el clip — sesión guiada.
7. Prueba de punta a punta con hardware real, coordinando con Germaioni — con margen antes de
   la presentación, no la semana previa.

---

## 27. RESUELTO (análisis, no implementación) — evaluado un backend propio con JWT (Fastify/Bun), no se adopta en CowControl

Anotado 2026-09-11. Santiago pidió revisar 25 capturas de WhatsApp (una videollamada donde un
compañero, Nazareno, armaba en vivo un backend con Fastify + Bun + SQLite + `jose` — "José,
JSON" en la transcripción de voz era justamente **JWT**) para evaluar si conviene aplicar algo
similar a CowControl, específicamente para reforzar la seguridad del registro/login (motivo:
"no tenemos mucha seguridad y nuestra clave es bastante básica... que no puedan ingresar al
campo de otro productor"). **Capturas guardadas en:**
`documentacion.md/fotos_adjuntas.md/imags_varias/anexos_img_app/fotos_cod_guia/` (25 imágenes,
quedan ahí como referencia — no se borran).

### Qué mostraban las capturas

Un backend chico, sin terminar (la llamada se cortó antes de que Nazareno completara la
devolución del JWT):
- `POST /register`: hashea la contraseña con `Bun.password.hash()` (Argon2id, confirmado por
  el hash real visto en la terminal: `$argon2id$v=19$m=65536...`) y la inserta en SQLite.
- `POST /login`: busca el usuario por email, compara con `Bun.password.verify()`. El comentario
  `// 4. Retornar un JWT con Jose` quedó sin código — no se alcanzó a ver cómo se firma/valida
  el token, ni ninguna lógica de qué puede tocar cada usuario una vez logueado.
- **Bug real encontrado en el código mostrado:** las consultas arman el SQL pegando el input
  del usuario directo en el string (`` `select * from users where email = "${request.body.email}"` ``,
  líneas 51 y 75 de su `main.js`) — es **inyección SQL** de manual. Anotado como hallazgo útil,
  no como crítica — es justo el tipo de cosa que las consultas parametrizadas del cliente de
  Supabase evitan de raíz en CowControl.

### Veredicto — no se adopta

**CowControl ya tiene el equivalente, y más completo.** Supabase Auth ya emite y valida un JWT
en cada sesión (es lo que arma Nazareno a mano) — la diferencia es que CowControl además tiene
**RLS** (`auth.uid() = productor_id` en cada política) encima, que es la pieza que decide *qué
filas* puede tocar cada usuario — justo lo que las capturas nunca llegaron a mostrar
construyendo. Un JWT por sí solo prueba identidad, no protege datos por fila; eso lo hace RLS.
Armar un backend nuevo de cero para CowControl habría sido mucho trabajo para terminar en un
lugar *menos* seguro (inyección SQL de por medio) resolviendo algo que Supabase ya resuelve.

**Lo que sí vale la pena de esto:**
1. Lo que armó Nazareno le sirve a **él**, para su propio proyecto aparte (el de MongoDB/
   backend básico — ver conversación de esa misma sesión) — no se mezcla con CowControl.
2. **Para la presentación:** buen argumento ya armado y verificado — CowControl usa JWT (vía
   Supabase Auth) **+ RLS** por fila, un modelo más completo que JWT solo. Se puede explicar
   con confianza, es cierto y ya está funcionando (no es una promesa a futuro).
3. Reafirma la prioridad real de seguridad pendiente: **arreglar `restablecer.html`** (el bug
   de PKCE del ítem 21) — ese sí es un agujero real y conocido hoy, a diferencia del hashing de
   contraseñas o el JWT, que ya están bien resueltos por Supabase.

---

## 28. PENDIENTE (a futuro, explícitamente no arrancar todavía) — material de explicación a bajo nivel para la presentación

Anotado 2026-09-11, a pedido de Santiago. Idea: armar material que explique el proyecto
**mucho más desmenuzado** que lo que existe hoy (`Guia_Repaso-CowControl.pdf` da un repaso
general; esto sería un nivel más profundo) — por **archivo** y por **bloque de código completo**
(no línea por línea), cubriendo qué hace cada bloque y por qué, al mismo nivel de detalle que
el análisis JWT-vs-RLS del ítem 27 de arriba (ese quedó como el ejemplo de referencia del tipo
de explicación que se busca).

**Formatos que Santiago quiere para esto:** una mezcla de videos (generados con NotebookLM u
otros recursos similares) y PDFs — no un solo documento, varias piezas por tema/carpeta.

**Alcance esperado (a definir mejor cuando se retome):**
- Explicación archivo por archivo de `lib/` (qué hace cada `model`, `service`, `screen`,
  `widget` — no solo la lista como en la Guía de Repaso, sino entrar a cada bloque importante
  de cada archivo).
- Todo el tema de base de datos a fondo: qué es RLS, qué es GRANT, cómo funciona cada política
  concreta de CowControl línea por línea, qué es una migración, etc.
- Cualquier otro bloque de código central del proyecto (services que hablan con Supabase,
  Realtime, el ciclo de vida de `conteos`, etc.).

**Organización de referencias:** todo el material de apoyo (capturas, videos, código de
ejemplo de compañeros como el del ítem 27) se va guardando en subcarpetas dentro de
`documentacion.md/fotos_adjuntas.md/` (o similar), una por tema — mismo patrón ya usado para
`fotos_cod_guia/`. Se puede seguir usando esa misma convención para lo que se junte después.

**Explícitamente no arrancar esto todavía** — queda anotado como plan para retomar más
adelante, cuando Santiago lo pida.

---

## 29. HECHO (2026-09-13) — llamado a la acción para pasar animales de a poco en el primer conteo

Anotado 2026-09-13. Surgió charlando de la función de "animal sin identificar" (ítem 23, recién
implementada). La idea: en el primer conteo de un campo nuevo (cuando hay muchos tags sin
identificar todavía), mostrar un cartel/aviso recomendando pasar los animales **de a 5** por
el brete, para darle tiempo al productor de asignarle categoría a cada uno a medida que pasa,
en vez de que se le acumulen todos juntos al final.

**Decisión tomada con Santiago:**
- **De a 5, no de a 10** — Claude recomendó 5 (más manejable, no se acumulan tantos "sin
  identificar" de una, más fácil de recordar) y Santiago no lo contradijo al pedir dejarlo
  anotado para después.
- **Texto propuesto** (a confirmar cuando se retome):
  > "Cada 5 animales, pausá para completar género y tipo — así quedan guardados para los
  > próximos conteos."
- **Color propuesto:** un bordó apagado, `#8B4038` (nombre sugerido: `AppColors.bordoAlerta`)
  — mucho menos saturado que un rojo puro, para que combine con la paleta marrón/naranja ya
  usada en vez de saltar como una alerta genérica.

**Dónde iría:** probablemente como un banner en la Pantalla 3 (Conteo en vivo), visible mientras
haya animales en la sección "Sin identificar" del ítem 23 — a definir mejor cuándo se retome
(¿siempre visible al haber "sin identificar"? ¿solo la primera vez que se abre un conteo nuevo?
¿se puede cerrar?).

**Implementado (2026-09-13):** `AppColors.bordoAlerta`/`bordoAlertaFondo` agregados a
`app_theme.dart`; el cartel se agregó en `conteo_screen.dart`, entre el contador y la lista,
visible solo mientras `_sinIdentificar` no está vacío — con el texto y el color exactos que
quedaron acordados arriba. `flutter analyze` → "No issues found!".
