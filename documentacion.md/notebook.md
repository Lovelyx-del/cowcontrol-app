# NotebookLM — plan de videos explicativos de CowControl

Este archivo es la lista de trabajo para ir armando los videos explicativos (NotebookLM u
otro recurso similar) para la presentación — ítem 28 de `cosas_pendientes.md`.

**Fuente única para los 6 videos:**
```
documentacion.md/archivos.pdf/codigo_fuente_notebooklm.pdf
```
Este PDF tiene el código real de todos los archivos, organizado en 6 secciones
("VIDEO 1" a "VIDEO 6"). **Subí este mismo PDF como única fuente en NotebookLM para los 6
videos** — no hace falta pegar código a mano en cada uno. Cada prompt de abajo ya le indica a
NotebookLM en qué apartado del PDF tiene que enfocarse.

**Cómo se armó el orden:** arrancamos por lo que Flutter/Android generaron solos (nunca los
tocaste vos, así que es lo que menos entendés) y recién después seguimos con el código de
`lib/` que sí fuiste modificando. Se armaron 6 para empezar (3 por día, por el límite gratis
de NotebookLM) — cuando termines estos, aviso y sigo con la tanda siguiente.

**Sugerencia para que el video muestre el código en pantalla:** además de este PDF (que
NotebookLM lee como texto), podés sumar una **captura de pantalla del archivo abierto en VS
Code** como fuente aparte para cada video — así el generador tiene también material visual
real para mostrar mientras narra.

---

## Video 1 — Config de Android/Gradle (lo que Flutter generó solo)

**Fuente:** `archivos.pdf/codigo_fuente_notebooklm.pdf` → apartado **VIDEO 1**.

**Prompt para NotebookLM:**
```
Mirá el apartado "VIDEO 1 — Config de Android/Gradle" del PDF que te compartí como fuente
(ignorá el resto de las secciones, son para otros videos). Sos un profesor explicándole a un
estudiante de secundaria (Santiago) que no escribe código él mismo, pero necesita entender
qué hace cada archivo para poder explicarlo en la presentación final de su proyecto
("CowControl", una app de conteo de ganado con RFID hecha en Flutter). Estos archivos son
parte de la carpeta android/ — Flutter los generó automáticamente al crear el proyecto, nadie
los escribió a mano. Explicá, archivo por archivo, bloque por bloque (no línea por línea): qué
es Gradle y para qué sirve en un proyecto Android, qué hace cada uno de estos archivos
concretos, y por qué existen aunque nadie los haya tocado. Usá analogías simples. Al final,
contá esta anécdota real del proyecto como ejemplo de por qué estos archivos importan aunque
parezcan "solo configuración": el AndroidManifest.xml no tenía declarado el permiso de
INTERNET en el build de release (solo lo tenía el de debug, que Flutter agrega solo) — por eso
la app anduvo bien un mes y medio probando con `flutter run`, pero nadie podía registrarse ni
loguearse desde el APK compartido de verdad, hasta que se encontró y agregó esa línea (que se
ve en el propio archivo del PDF, con el comentario que lo explica). Tono claro, sin
tecnicismos innecesarios, para alguien que recién está aprendiendo.
```

---

## Video 2 — Config raíz del proyecto Flutter (lo que no está en `lib/`)

**Fuente:** `archivos.pdf/codigo_fuente_notebooklm.pdf` → apartado **VIDEO 2**.

**Prompt para NotebookLM:**
```
Mirá el apartado "VIDEO 2 — Config raíz del proyecto Flutter" del PDF que te compartí como
fuente (ignorá el resto de las secciones, son para otros videos). Sos un profesor explicándole
a un estudiante de secundaria (Santiago) que no escribe código él mismo, para su presentación
final de "CowControl" (app Flutter de conteo de ganado con RFID). Estos son los archivos que
están en la raíz del proyecto, fuera de la carpeta lib/ (que es donde vive el código de la app
en sí) — la mayoría los generó Flutter automáticamente al crear el proyecto. Explicá cada uno,
bloque por bloque: qué es pubspec.yaml y la diferencia con pubspec.lock (por qué uno lo edita
una persona y el otro lo genera la herramienta sola), qué hace .gitignore y por qué ahí están
excluidos .env y /apk_para_probar/ (explicá la diferencia entre "no subir esto a git nunca"
para .env, con datos sensibles, y "no ensuciar el historial con un archivo pesado que se
regenera solo" para el apk), qué es analysis_options.yaml (activa las reglas de flutter
analyze), y qué es .metadata (uso interno de Flutter, no se edita a mano). Explicá también,
aunque no haya archivo de fuente para esto, que además existen las carpetas build/ (se
regenera sola al compilar, no se sube a git), assets/ (las imágenes de íconos de categoría y
el ícono de la app) y docs/ (las páginas web de confirmación de mail y recuperación de
contraseña, publicadas gratis con GitHub Pages). Tono claro, con analogías, para alguien sin
experiencia previa en programación.
```

---

## Video 3 — Las librerías del proyecto (`pubspec.yaml` a fondo)

**Fuente:** `archivos.pdf/codigo_fuente_notebooklm.pdf` → apartado **VIDEO 3**.

**Prompt para NotebookLM:**
```
Mirá el apartado "VIDEO 3 — Las librerías del proyecto" del PDF que te compartí como fuente
(ignorá el resto de las secciones, son para otros videos). Sos un profesor explicándole a un
estudiante de secundaria (Santiago), que no escribe código él mismo, cómo funcionan las
librerías (paquetes) en un proyecto Flutter, para que lo pueda explicar con confianza en la
presentación final de "CowControl". Explicá primero el concepto general: qué es pub.dev (el
repositorio oficial de paquetes de Dart/Flutter, equivalente a npm en JavaScript), cómo se
agrega un paquete nuevo (se escribe el nombre y la versión en pubspec.yaml, y se corre
"flutter pub get" — no hace falta descargar ni instalar nada a mano), y qué significa el
símbolo "^" antes de una versión (acepta actualizaciones menores automáticas, pero no un
cambio grande de versión que podría romper el código). Después, explicá específicamente cada
paquete que usa este proyecto y para qué sirve en el contexto de CowControl: supabase_flutter
(cliente oficial de Supabase — login, base de datos, tiempo real, todo en uno), flutter_dotenv
(lee el archivo .env con las credenciales sin hardcodearlas en el código, usalo como ejemplo
real leyendo lib/main.dart que está en el mismo apartado), cupertino_icons (íconos con estilo
iOS), flutter_lints (reglas de estilo que usa flutter analyze), y flutter_launcher_icons
(genera el ícono de la app en todos los tamaños a partir de un solo PNG, se corre una vez con
"dart run flutter_launcher_icons"). Tono claro, con analogías, para alguien sin experiencia
previa en programación.
```

---

## Video 4 — `lib/models/` (las 4 clases de datos)

**Fuente:** `archivos.pdf/codigo_fuente_notebooklm.pdf` → apartado **VIDEO 4**.

**Prompt para NotebookLM:**
```
Mirá el apartado "VIDEO 4 — lib/models/" del PDF que te compartí como fuente (ignorá el resto
de las secciones, son para otros videos). Sos un profesor explicándole a un estudiante de
secundaria (Santiago), que no escribe código él mismo, la carpeta lib/models/ de su proyecto
Flutter "CowControl" (app de conteo de ganado con RFID + Supabase), para que lo explique en la
presentación final. Explicá primero el concepto general: qué es una "clase" en programación
orientada a objetos, y qué rol cumplen específicamente estos "models" — representan cada tabla
de la base de datos (Supabase) como un objeto de Dart, y cada uno tiene un método fromMap() que
convierte la respuesta cruda que llega de Supabase (un Map, básicamente un JSON) en ese objeto.
Después, andá archivo por archivo (Animal, Campo, Lectura, Vacuna), bloque por bloque: qué
campos tiene cada clase y a qué columna real de la base de datos corresponde cada uno, cuáles
son opcionales (marcados con "?" en Dart) y por qué. Contá también, como anécdota real del
proyecto, que el campo "fertilidad" de Animal reemplazó a uno que se llamaba
"condicion_corporal" — fue una decisión de producto (no técnica): condición corporal no
aportaba a la demo, mientras que fertilidad sí está en el mockup original que se quería
mostrar. Tono claro, con analogías, para alguien sin experiencia previa en programación.
```

---

## Video 5 — `lib/services/` (la capa que habla con Supabase)

**Fuente:** `archivos.pdf/codigo_fuente_notebooklm.pdf` → apartado **VIDEO 5**.

**Prompt para NotebookLM:**
```
Mirá el apartado "VIDEO 5 — lib/services/" del PDF que te compartí como fuente (ignorá el
resto de las secciones, son para otros videos). Sos un profesor explicándole a un estudiante
de secundaria (Santiago), que no escribe código él mismo, la carpeta lib/services/ de su
proyecto Flutter "CowControl" (app de conteo de ganado con RFID + Supabase como backend), para
la presentación final. Explicá primero el concepto general: por qué las pantallas de la app
nunca hablan directo con Supabase, siempre pasan por un "service" — así, si mañana cambia cómo
se pide un dato, solo hay que tocar un lugar. Explicá qué es "async/await" y "Future" en Dart
(una operación que tarda, como pedirle datos a Supabase por internet, no congela el resto de
la app mientras espera). Después, andá archivo por archivo, bloque por bloque:
SupabaseService (el cliente único compartido), AuthService (login/registro/logout/recuperar
contraseña), CamposService, AnimalesService, LecturasService (incluye la suscripción en tiempo
real por websocket con Supabase Realtime, explicá qué significa eso), VacunasService, y
ConteosService (el más nuevo — maneja el ciclo de vida de un conteo: iniciarOReanudar, pausar,
reanudar, finalizar, escribiendo el estado en la tabla "conteos" para que la Raspberry Pi sepa
a qué conteo activo mandarle las lecturas RFID que va leyendo). Tono claro, con analogías, para
alguien sin experiencia previa en programación.
```

---

## Video 6 — `lib/screens/` (panorama de las pantallas)

**Fuente:** `archivos.pdf/codigo_fuente_notebooklm.pdf` → apartado **VIDEO 6**.

**Prompt para NotebookLM:**
```
Mirá el apartado "VIDEO 6 — lib/screens/" del PDF que te compartí como fuente (ignorá el resto
de las secciones, son para otros videos). Sos un profesor explicándole a un estudiante de
secundaria (Santiago), que no escribe código él mismo, la carpeta lib/screens/ de su proyecto
Flutter "CowControl" (app de conteo de ganado con RFID + Supabase), para la presentación
final. Explicá primero la diferencia entre StatelessWidget y StatefulWidget (una pantalla que
no cambia sola vs. una que sí, como la de conteo en vivo, que se redibuja cada vez que llega
una lectura nueva, usando setState()). Después, dale un panorama de cada pantalla en orden de
uso real (login → selector de campo → planilla → conteo en vivo → ficha de animal con sus 3
sub-pantallas → historial): qué muestra cada una, a qué service llama para traer sus datos, y
qué decisión de diseño importante tiene (por ejemplo: la ficha del animal pasó de mostrar todo
junto a 3 botones separados — Fertilidad, Vacunas, Observaciones —, y la pantalla de conteo
escribe en la tabla "conteos" al iniciar/pausar/reanudar/finalizar, no solo escucha lecturas).
Algunos archivos del PDF tienen el build() recortado por espacio (marcado con un comentario
"ver el archivo real") — no hace falta inventar ese detalle visual, alcanza con explicar qué
arma esa parte de la pantalla en términos generales. No hace falta ir línea por línea de cada
una — priorizá el panorama general y los bloques más importantes de cada pantalla. Este es un
primer video panorama; si hace falta más profundidad de alguna pantalla puntual, se puede
armar un video aparte después. Tono claro, con analogías, para alguien sin experiencia previa
en programación.
```

---

## Pendiente para la próxima tanda (no armar prompts todavía)

- `lib/widgets/` + `lib/theme/` (AnimalCard, CategoriaBadge, FertilidadChip, app_theme).
- Profundizar `lib/screens/conteo_screen.dart` solo (es la pantalla más compleja — Realtime +
  ciclo de vida de `conteos` — puede merecer su propio video en vez de compartir con las otras
  8 pantallas). El PDF actual ya tiene su código completo en el apartado VIDEO 6, así que
  alcanza con un prompt nuevo apuntando a esa misma sección si se quiere profundizar.
- Todo el bloque de base de datos/Supabase a fondo: qué es RLS con cada política real
  explicada, qué es GRANT, el bug real de permisos (42501) que pasó, las migraciones
  aplicadas — sacar el contenido de `base_datos.md`. Va a necesitar un PDF nuevo (con SQL, no
  código Dart) o sumarse al mismo PDF como una sección VIDEO 7.
- El análisis JWT vs. RLS del ítem 27 de `cosas_pendientes.md` (por qué no hizo falta un
  backend propio) — buen tema para un video aparte, ya está redactado y listo para usar como
  fuente (sección VIDEO 8, o un PDF aparte).
