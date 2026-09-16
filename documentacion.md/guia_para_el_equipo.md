# Guía para el equipo — CowControl

Este documento es para cualquiera del equipo que retome el proyecto — pensado especialmente
para poder **probar la app y avanzar con la integración de la Raspberry Pi** durante una
semana en la que la persona que venía llevando el desarrollo no va a estar disponible.

No hace falta leer todo de una — la sección 6 (Raspberry Pi) es la más importante si ya se
tiene el hardware a mano.

---

## 1. Qué es CowControl (resumen)

App de conteo de ganado por tag NFC/RFID. Un lector montado en el brete detecta el tag de
cada animal que pasa; una Raspberry Pi recibe esa lectura y la sube a Supabase (la base de
datos y backend del proyecto); la app en Flutter la muestra en tiempo real, marcando cada
animal detectado con un ✓ sobre la planilla, sin que el usuario tenga que refrescar nada.
Supabase es el único "servidor" del sistema — la app nunca habla directo con la Raspberry
Pi, y cada productor solo ve sus propios campos y animales (login con email/contraseña +
separación de datos por cuenta).

---

## 2. Qué está hecho hoy (2026-08-13)

- **Las 6 pantallas construidas y funcionando:** login/registro, selector de campo, planilla
  general, conteo en vivo (tiempo real vía Supabase Realtime), ficha de animal, historial de
  lecturas.
- **Multi-tenant probado funcionando de verdad:** dos cuentas distintas, cada una ve solo su
  propio campo y sus propios animales — probado en un celular Android físico.
- **Login y registro probados de punta a punta**, incluyendo la confirmación de email por
  correo (funciona con cualquier proveedor de mail, no solo Gmail).
- **Ficha de animal (Pantalla 4) editable:** fertilidad, vacunas y observaciones — los tres
  datos que el lector RFID no puede leer solo, así que los carga el productor a mano desde
  la app. Cada uno vive en su propia pantalla, accedida por un botón con ícono desde la ficha
  principal del animal. Ya prueban guardar en Supabase de verdad.
- **Íconos de categoría propios** (vaca/toro/ternero/ternera/vaquillona), reemplazando los
  símbolos genéricos que traía Flutter — dibujados a medida, diferenciados por orientación
  (machos mirando para un lado, hembras para el otro) además de por anatomía. Puede estar
  terminado de integrar o no según el momento en que se lea esto — revisar el ítem 10 de
  `cosas_pendientes.md` para confirmar el estado exacto.
- **Primer APK de instalación generado y probado en un celular físico.**

---

## 3. Qué falta (en orden de importancia)

1. **Migración `sesiones_conteo`** — el botón "Finalizar" del conteo en vivo hoy no
   guarda/descarta la tanda como una unidad (cada lectura ya se guarda individualmente en
   tiempo real, pero no hay agrupación en "sesiones"). El SQL ya está escrito
   (`base_datos.md`, sección "Migración pendiente — sesiones_conteo"), pero **quedó marcado
   como pendiente de revisar a fondo antes de correrlo** — no aplicarlo sin que alguien
   responsable del proyecto lo confirme primero.
2. **Integración real con la Raspberry Pi, el lector y los tags** — todavía no se probó con
   hardware físico. Es lo más importante para avanzar mientras tanto — ver sección 6 de este
   documento, tiene un script listo para probar sin depender del punto 1.
3. **Terminar de integrar los íconos nuevos** (si no se llegó a hacer) — código completo y
   lista para copiar en `cosas_pendientes.md`, ítem 10.
4. **Alta de animales "no identificados"** para cuando un productor nuevo (sin ningún animal
   cargado todavía) usa la app por primera vez — diseñado conceptualmente, no implementado
   (depende del punto 1). Detalle en `base_datos.md`, sección 12, y `prompts.md`.
5. **Revisar uno por uno el resto de los campos del mockup original** que se habían sacado
   (preñez, crías, "para carnear", alertas puntuales, maternidad, edad aproximada) — sin
   decisión tomada sobre ninguno, ver `cosas_pendientes.md` ítem 3.
6. **iOS/Xcode — bloqueado, no es opcional.** Ver sección 5 de este documento, es importante.
7. **Inicializar git** — el proyecto todavía no tiene control de versiones. Es una acción
   local segura y reversible (`git init`), no se hizo todavía por decisión de ir paso a paso.
8. Verificar el schema real de Supabase (Table Editor) contra lo documentado en
   `../memory.md` — pendiente viejo, nunca se llegó a confirmar del todo.

---

## 4. Cómo probar la app — dos caminos

### Camino rápido: instalar el APK directo (recomendado si solo se quiere ver/probar la app)

No hace falta instalar nada de Flutter ni Android Studio. Buscar el archivo `.apk` más
reciente en esta misma carpeta del proyecto (debería estar en la raíz o en una carpeta
claramente indicada como "APK para probar" — si no aparece, hay que generarlo de nuevo, ver
abajo "Cómo generar un APK nuevo"). Pasarlo al celular (por cable, Drive, o WhatsApp a uno
mismo) y tocarlo para instalar — Android va a pedir permiso para "instalar apps de origen
desconocido" la primera vez, hay que aceptarlo.

**Cómo generar un APK nuevo** (si el que está no es reciente, o hizo falta cambiar código):
```
flutter build apk --release
```
El resultado queda en `build\app\outputs\flutter-apk\app-release.apk`.

### Camino completo: correr el proyecto desde el código (para poder editarlo)

Hace falta:
1. **Flutter SDK** instalado (https://flutter.dev — seguir el instalador para Windows/Mac
   según corresponda).
2. **Android Studio** instalado, con el Android SDK y al menos un emulador o un celular
   físico conectado por USB con "Depuración USB" activada.
3. Confirmar que todo está bien con:
   ```
   flutter doctor
   ```
4. Desde la carpeta del proyecto (`app_cowcontrol/`):
   ```
   flutter pub get
   flutter run
   ```
   (si hay más de un dispositivo conectado, agregar `-d <nombre-del-dispositivo>` — se ve la
   lista con `flutter devices`).

**El archivo `.env`** con las credenciales de Supabase (`SUPABASE_URL` y
`SUPABASE_ANON_KEY`) ya viene incluido en esta carpeta — sin él la app no compila ni se
conecta a la base de datos. No hace falta pedir ni generar nada nuevo para esto.

Para una explicación más detallada de qué es cada archivo del proyecto y qué hace cada
comando de terminal (con el "por qué", no solo el comando), ver `info.md` en esta misma
carpeta — se fue armando específicamente para eso.

---

## 5. Cosas importantes para tener en cuenta

- **iOS no funciona todavía, y no es un capricho — es un requisito real del proyecto que
  está bloqueado por hardware.** Para compilar para iPhone hace falta sin excepción una Mac
  con Xcode instalado — no se puede hacer desde Windows, es una limitación de Apple, no del
  proyecto. No perder tiempo intentándolo desde una PC con Windows.
- **Hay un solo proyecto de Supabase para todo el equipo — no crear uno aparte.** Si alguien
  necesita las credenciales, ya están en el archivo `.env` de esta carpeta (la URL y la
  `anon key`). Crear un proyecto de Supabase distinto significa que esos datos quedan en una
  base separada, invisible para el resto del equipo, aunque el código "funcione" igual.
- **El archivo `.env` no se sube a ningún repositorio público** si en algún momento se usa
  git/GitHub — ya está en `.gitignore`, pero vale la pena confirmarlo antes de cualquier
  `git push` a un repo compartido.
- **El hardware real del prototipo usa un módulo RFID RC522 (13.56 MHz, tags genéricos de
  Mercado Libre)** — no caravanas electrónicas reales de ganado (esas son 134.2 kHz, un
  estándar distinto). Es la decisión correcta para un prototipo, no hace falta conseguir
  hardware más caro.
- **Las carpetas `linux/`, `macos/` y `web/`** dentro de `lib/`/la raíz del proyecto son
  generadas automáticamente por Flutter para plataformas que este proyecto **no** usa — se
  pueden ignorar (o borrar, si se quiere una carpeta más liviana). `android/` e `ios/` sí son
  necesarias, no tocarlas.

---

## 6. Cómo probar con la Raspberry Pi, el lector y los tags (lo más importante)

El código completo (script de Python listo para copiar, con explicación de cada credencial
que hace falta conseguir) está en **`cosas_pendientes.md`, ítem 11** — no se duplica acá para
no tener dos versiones del mismo script desactualizándose por separado.

Resumen de la idea antes de ir para allá: cada Raspberry Pi tiene que tener configurado, una
sola vez, el UUID del campo al que pertenece (`CAMPO_ID` en el script) — no hay ningún
emparejamiento automático entre una Raspberry y una cuenta, es una constante fija que se
carga a mano en el archivo del script. Con eso configurado, el script ya se puede probar
**sin necesitar ninguna migración nueva de la base de datos** — alcanza para confirmar que
el circuito completo funciona (tag físico → Raspberry → Supabase → aparece solo en la app),
que es la función central de todo el proyecto.

Ir a `cosas_pendientes.md` ítem 11 para el script completo y el paso a paso de qué
credenciales conseguir y dónde.

---

## 7. Mapa del resto de la documentación

Todo dentro de la carpeta `documentacion.md/`:
- **`info.md`** — qué es cada archivo/carpeta del proyecto, y comandos de terminal
  explicados en detalle (Flutter, ADB).
- **`cosas_pendientes.md`** — la lista de tareas activas y diferidas, con código listo para
  copiar en varias de ellas (incluida la integración con la Raspberry Pi, ítem 11).
- **`base_datos.md`** — historial completo de migraciones SQL (aplicadas y pendientes),
  justificación de por qué Supabase y no un servidor propio en la Raspberry Pi, y varias
  respuestas técnicas puntuales (RLS vs. GRANT, cómo se integra el `campo_id`, etc.).
- **`prompts.md`** — el registro de decisiones grandes tomadas sesión por sesión, para quien
  quiera entender el "por qué" detrás de una decisión puntual.
- **`memory.md`** — decisión de stack, plan de pantallas, diccionario de campos.
- Los PDFs originales del proyecto (carpeta técnica, explicación de cada función) y las
  imágenes de referencia de los íconos nuevos, en `fotos_adjuntas.md/`.
