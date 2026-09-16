# Prompt de continuidad — CowControl App

Este archivo existe para que un chat **nuevo** de Claude Code, abierto en esta carpeta
(`C:\dev\CowControl\app_cowcontrol`), pueda seguir trabajando en el proyecto sin que
Santiago tenga que re-explicar todo desde cero. Está escrito para que Claude lo lea
primero y entienda: quién es el usuario, cómo quiere trabajar, qué se decidió, qué se
construyó, y qué falta.

**Instrucción para el chat nuevo:** leé este archivo completo antes de tocar nada. Después,
para el contexto técnico exhaustivo (schema de Supabase completo, spec funcional de cada
pantalla, diccionario de campos), leé también los archivos que se listan en la sección
"Mapa de archivos" más abajo — este documento resume, no reemplaza a esos.

---

## 1. Quién es el usuario y cómo trabajar con él

- **Santiago Cuenca Cabrera** — estudiante de secundaria, CowControl es su proyecto final
  ("Trabajos de Secundaria"). Lo está armando con compañeros de equipo.
- **Santiago no tipea código.** Todo el código lo escribe Claude.
- **Cada bloque de código importante lleva un comentario corto explicando para qué sirve**
  (no una traducción línea por línea) — Santiago necesita poder explicar el código en la
  presentación final sin descifrarlo de cero.
- **No arrancar a construir sin spec completa.** Cuando algo es ambiguo o es una decisión de
  arquitectura real (no un detalle menor), preguntar antes de asumir — Santiago prefiere que
  se le pregunte a que se adivine mal y haya que rehacer trabajo.
- Todavía no hay repositorio git inicializado en este proyecto.
- El equipo tiene un compañero que trabajó por su cuenta con la Raspberry Pi (armó un
  servidor propio ahí para una demo de hardware) — si vuelve a proponer que la Pi haga de
  "servidor" en vez de Supabase, ver la sección 5 de `base_datos.md` (ya se discutió esto a
  fondo y se decidió mantener Supabase; ahí está el razonamiento completo para no tener que
  repetirlo).
- **Cuidado con el consumo de créditos/uso de Claude Code.** Santiago prefiere avanzar en
  pasos chicos y guiados en vez de sesiones largas donde Claude aplica muchos cambios de
  código de una sola vez — le cuesta seguir el hilo de tanto código a la vez y además
  consume créditos más rápido. Para trabajos grandes (rediseño del flujo de base de datos,
  revisión de campos del mockup — ver sección 9), el plan acordado es ir guiándolo paso a
  paso para que Santiago mismo vaya haciendo los cambios con instrucciones de Claude, en vez
  de que Claude los aplique todos de una. No arrancar ese trabajo de forma autónoma — esperar
  a que Santiago lo pida explícitamente y de a poco.
- **Modo aprendizaje (desde 2026-08-03):** Santiago quiere aprender Flutter por su cuenta.
  Se le pasaron recursos (docs oficiales, codelab de Google, curso de freeCodeCamp, canal de
  videos oficial de Flutter, awesome-flutter en GitHub — repetírselos si los pide de nuevo,
  no hace falta guardarlos todos acá). **Para cambios de código puntuales, Claude explica y
  da el fragmento exacto para pegar, pero es Santiago quien edita el archivo** (con el editor
  y la terminal integrada de VS Code) — ver sección 9 para el primer caso real de esto (el
  cambio de `condicion_corporal` por `fertilidad`) y los errores típicos que cometió, útiles
  para guiar mejor la próxima vez (ej: crear archivos nuevos solo con el nombre, no con la
  ruta completa, si ya se está parado en esa carpeta; pedir explícitamente "borrá la línea
  X" en vez de asumir que al agregar la línea nueva se borra sola la vieja).

---

## 2. Qué es CowControl (resumen ejecutivo)

App de conteo de ganado por tag NFC/RFID. Un lector montado en el brete (manga ganadera)
detecta el tag de cada animal que pasa; una Raspberry Pi recibe esa lectura y la sube a
Supabase; la app Flutter la muestra en tiempo real, marcando cada animal detectado con un ✓
sobre la planilla, sin que el usuario tenga que refrescar nada.

```
Tag NFC/RFID → Lector → Raspberry Pi --POST (service_role)--> Supabase ← Realtime/REST -- App Flutter
```

La app **nunca habla directo con la Raspberry Pi** — todo pasa por Supabase, que actúa como
el "servidor" real del sistema (base de datos + API REST + autenticación + tiempo real,
todo gestionado). Ver `base_datos.md` para la justificación completa de por qué esto es
mejor que un servidor propio corriendo en la Raspberry Pi.

---

## 3. Stack y arquitectura definitiva

- **Flutter** (`supabase_flutter` 2.16.0 + `flutter_dotenv` 6.0.1), reemplaza una versión
  vieja pensada para App Inventor.
- **Supabase** — un solo proyecto (`jucndmefmewkjalqnrrv`), multi-tenant vía **Supabase Auth
  + Row Level Security** (no bases de datos separadas por productor).
- **Conteo en tiempo real** vía **Supabase Realtime** (websocket) — no polling.
- 4 tablas: `datos_campo`, `datos_animales`, `datos_lectura`, `datos_vacuna` + una 5ta
  tabla `sesiones_conteo` **pendiente de migrar** (ver sección 6).
- 6 pantallas: 0) login/registro, 1) selector de campo, 2) planilla general, 3) conteo en
  vivo, 4) detalle de animal, 5) historial de lecturas.
- Campos por animal en la v1 (deliberadamente reducidos frente al mockup original): solo
  `rfid_uid` (como "ID"), categoría (del campo `sexo`: vaca/toro/ternero/ternera/vaquillona),
  y `fertilidad` (`'buena' / 'regular' / 'mala'` — **reemplazó a `condicion_corporal` el
  2026-08-03**, ver sección 9). Todo lo demás (nombre, edad, maternidad, preñez, etc.) queda
  fuera por ahora — el productor lo anota en `observaciones` si quiere, pero está en revisión
  campo por campo (ver sección 7). **No agregar campos nuevos del mockup sin confirmar antes
  con Santiago.**

---

## 4. Mapa de archivos (dónde está cada cosa)

Raíz del proyecto general (`C:\dev\CowControl\`, un nivel arriba de esta carpeta):
- **`../memory.md`** — schema exacto de Supabase (histórico + actual), diccionario de
  campos completo, las 3 migraciones SQL ya aplicadas, contexto del hardware, y el estado
  viejo del proyecto en App Inventor (ya no aplica, es solo referencia histórica).
- **`../propuestas.md`** — lógica de multi-campo por productor, referencia funcional vieja
  (pensada para App Inventor, pero la lógica de negocio sigue sirviendo).

Dentro de esta carpeta (`app_cowcontrol/`):
- **`lib/`** — el código Flutter completo (ver sección 5).
- **`.env`** — `SUPABASE_URL` y `SUPABASE_ANON_KEY` (no se sube a git, ya está en
  `.gitignore`).
- **`documentacion.md/`** (esta carpeta, un nombre con `.md` pero es una carpeta) —
  contiene:
  - **`memory.md`** — decisión de stack Flutter (con alternativas descartadas y por qué),
    cómo trabajar el código, plan de pantallas v1 completo con el detalle de qué muestra
    cada una, decisión de multi-tenant, y el checklist de pendientes de la app.
  - **`cosas_pendientes.md`** — funcionalidades diferidas (cámara/video vinculado a cada
    lectura, resto de campos del mockup) y el **requisito no negociable**: la app tiene que
    andar bien en Android **y** iOS, mobile-first desde el diseño, no como ajuste de último
    momento.
  - **`base_datos.md`** — historial completo de migraciones SQL (aplicadas y pendientes,
    con el código exacto), y la justificación arquitectónica de por qué Supabase y no un
    servidor propio en la Raspberry Pi (útil tal cual para la presentación).
  - **`Guia_Raspberry_Pi-CowControl.pdf`** (+ `rfid_tick.py` al lado, mismo contenido en texto
    plano para copiar sin arrastrar saltos de línea del PDF) — generado el 2026-08-30 para
    pasarle a un compañero con hardware ya armado: credenciales que necesita conseguir, el
    formato exacto del POST a `datos_lectura`, y el script de referencia. Resume lo mismo que
    ya estaba en `cosas_pendientes.md` ítem 11, en formato para compartir por fuera del repo.
  - **`explicacion_cada_funcion.pdf`** — spec funcional y técnica completa: protocolos de
    comunicación entre cada componente (radiofrecuencia, serial, HTTPS, websocket), la
    estructura de carpetas de `lib/` tal como se implementó, diccionario de campos, y cómo
    funciona el JWT + RLS de punta a punta. Es el documento más detallado — consultarlo
    ante cualquier duda de "cómo se supone que funciona esto".
  - **`Carpeta técnica-CowControl.pdf`** — el documento original del proyecto (mockups,
    fundamentación). Sus mockups están desactualizados frente a lo validado con
    productores del INTA — no asumir que un campo de ahí va en la app sin confirmar.
  - **`dale.md`** (+ `image.png`, `image-1.png` a `image-5.png` en la misma carpeta) —
    documento de un compañero de equipo proponiendo el flujo de conteo (tabla de sesiones,
    funciones SQL de iniciar/pausar/finalizar). Análisis completo y qué se toma/no se toma
    en `prompts.md` secciones 9 y 10 — no implementar nada de ahí sin pasar primero por ese
    análisis.

Fuera de esta carpeta, en la PC de Santiago (no forma parte del repositorio del proyecto):
- **`C:\Users\santi\Downloads\proyecto_rfid_guia_completa.md`** — versión más vieja y más
  completa de la propuesta del mismo compañero (de antes de arrancar la app Flutter), con un
  script de Python funcional para la Raspberry Pi y el diseño de manejo de tags
  desconocidos. Ver sección 10 para qué se aprovecha de ahí.

---

## 5. Estado actual del código Flutter (2026-07-26)

Estructura completa y funcionando, `flutter analyze` **sin errores**:

```
lib/
├── main.dart                        → init .env + Supabase, AuthGate (decide login vs selector de campo)
├── theme/app_theme.dart             → paleta marrón/tierra
├── models/
│   ├── campo.dart / animal.dart / lectura.dart / vacuna.dart
├── services/
│   ├── supabase_service.dart        → cliente único de Supabase
│   ├── auth_service.dart            → login/registro/logout
│   ├── campos_service.dart          → traer/crear campos del productor logueado
│   ├── animales_service.dart        → traer animales de un campo + detalle
│   ├── lecturas_service.dart        → historial + suscripción Realtime (conteo en vivo)
│   └── vacunas_service.dart         → última vacuna de un animal
├── screens/
│   ├── login_screen.dart            → Pantalla 0
│   ├── selector_campo_screen.dart   → Pantalla 1 (autoselecciona si hay 1 solo campo)
│   ├── planilla_screen.dart         → Pantalla 2 (búsqueda + filtro por categoría)
│   ├── configuracion_screen.dart    → menú de Configuración (Historial + Cerrar sesión), desde el ícono de tuerca de la Planilla
│   ├── conteo_screen.dart           → Pantalla 3 (Realtime, detener/reanudar/finalizar)
│   ├── detalle_animal_screen.dart   → Pantalla 4
│   └── historial_screen.dart        → Pantalla 5 (ya no se entra directo desde la Planilla, ver Configuración)
└── widgets/
    ├── animal_card.dart, categoria_badge.dart, fertilidad_chip.dart
```
(`fertilidad_chip.dart` reemplazó a `condicion_corporal_chip.dart` el 2026-08-03, ver sección 9)

**Nota importante sobre `ConteoScreen`:** el botón "Finalizar" todavía **no** guarda/descarta
la tanda como una unidad — cada lectura ya se guarda individualmente en `datos_lectura` en
tiempo real. Guardar/descartar la sesión completa queda pendiente de aplicar la migración de
`sesiones_conteo` (sección 6). Hay un comentario en el código de `conteo_screen.dart` que
señala esto mismo.

**Smoke-test confirmado:** `flutter run -d windows` compila y corre, con el log
`supabase.supabase_flutter: INFO: ***** Supabase init completed *****` confirmando que la
conexión real a Supabase funciona de punta a punta. Windows desktop no es el target final
(tiene que ser Android/iOS), solo sirvió para validar que el código compila sin necesitar
Android Studio todavía.

---

## 6. Decisiones tomadas en la sesión anterior (no están en el PDF ni en el mockup original)

1. **Migración consolidada de Supabase — ejecutada y confirmada (2026-07-26).** Agregó
   `condicion_corporal`, eliminó `fecha_nacimiento`, y agregó `productor_id` + políticas RLS
   multi-tenant. SQL completo y confirmación en `base_datos.md`.
2. **Se evaluó y se descartó** que la Raspberry Pi retenga las lecturas localmente en su
   propio servidor y las mande recién al finalizar el conteo (propuesta influenciada por lo
   que había hecho un compañero de equipo en una demo de hardware). Se descartó porque
   elimina el ✓ en tiempo real, que es la función principal del proyecto.
3. **En su lugar, se aceptó agregar `sesiones_conteo`** (tabla nueva + FK `sesion_id` en
   `datos_lectura`) manteniendo Supabase Realtime intacto. El SQL está en `base_datos.md`,
   pero **todavía no se aplicó** — quedó marcado como "pendiente de revisar a fondo antes de
   correr" (a diferencia de la migración anterior, que sí se revisó del todo).
4. **Se reconfirmó mantener el login/multi-tenant** (Auth + RLS) — se evaluó sacarlo para
   simplificar, pero se decidió que vale la pena mantenerlo tal como está.
5. **Credenciales:** `.env` + `flutter_dotenv` (no `--dart-define`) — ya cargadas con los
   valores reales de producción (URL + anon key).
6. **Se construyó toda la base del proyecto Flutter** (detalle en sección 5).
7. **Se movió todo el proyecto de OneDrive a `C:\dev\CowControl\`** porque la ruta vieja
   (`...OneDrive\...\Workflow n8n for CowControl\app_cowcontrol\...`, larga y con espacios)
   rompía el build de Windows por límite de `MAX_PATH`. Se verificó que el build funciona en
   la ubicación nueva. La carpeta vieja de OneDrive **ya se borró** — no queda respaldo ahí.
8. Se creó un acceso directo en el Escritorio (`CowControl.lnk`) apuntando a
   `C:\dev\CowControl\app_cowcontrol`.
9. Se reorganizaron los documentos dentro de una subcarpeta `documentacion.md/` (a pedido de
   Santiago) — todas las referencias relativas entre archivos ya se corrigieron para reflejar
   esto.

---

## 7. Pendientes (en orden lógico)

1. ~~Terminar de instalar Android Studio~~ **Hecho (2026-07-28).** Ver sección 8.
2. ~~Probar la app primero en un emulador Android~~ **Hecho (2026-07-28).** El celular físico
   sigue quedando para más adelante (todavía no) — cuando llegue ese momento: activar
   "Depuración USB" en Opciones de desarrollador del celular, conectar por cable,
   `flutter devices` lo detecta solo.
3. ~~Registrarse, confirmar email, loguearse, y asignar `productor_id` a Milka/Oscar/"Campo
   Principal"~~ **Hecho por completo (2026-08-06).** Ver sección 10 para el detalle (incluye
   dos bugs nuevos que aparecieron y se resolvieron en el camino: link de confirmación
   vencido, y permisos GRANT faltantes).
4. ~~Revisar a fondo y aplicar la migración de `sesiones_conteo`~~ **Superado, no hizo falta
   (2026-08-31/09-13).** Germaioni creó por su cuenta una tabla más simple, `conteos` (id,
   fecha, estado — 3 estados: `en_curso`/`pausado`/`finalizado`), directo en la base
   compartida. En vez de retomar `sesiones_conteo`, se conectó la app a esa tabla ya
   existente: `ConteosService` (`iniciarOReanudar`/`pausar`/`reanudar`/`finalizar`) +
   `conteo_screen.dart` la llama en cada botón. Se le agregó `campo_id` + GRANT + política RLS
   (le faltaban las 3). Ver sección 16.2.
5. **Verificar el schema real de Supabase** (Table Editor) contra lo documentado en
   `../memory.md` — pendiente viejo, nunca se llegó a confirmar.
6. **iOS/Xcode:** diferido explícitamente por Santiago — compilar para iPhone va a requerir
   una Mac con Xcode más adelante, no se puede hacer desde esta PC con Windows. No es
   urgente todavía, pero es un requisito no negociable del proyecto (ver
   `cosas_pendientes.md`) — no perderlo de vista.
7. ~~Leer y evaluar los documentos del compañero sobre el flujo de BD~~ **Hecho (2026-08-03 y
   2026-08-06).** Ver sección 9 (primera lectura, `dale.md` en texto) y sección 10 (capturas
   con SQL concreto + `proyecto_rfid_guia_completa.md`, el análisis completo y el párrafo
   final que Santiago le mandó a su compañero). **A la espera de la respuesta del
   compañero** antes de implementar nada del rework de BD.
8. ~~Reconsiderar `condicion_corporal`~~ **Hecho (2026-08-03), probado visualmente
   (2026-08-06).** Ver sección 9 para el cambio y sección 10 para la prueba end-to-end.
9. **Revisar uno por uno el resto de los campos que el INTA había pedido sacar del mockup**
   (preñez, crías, "para carnear", alertas puntuales, maternidad, edad aproximada) — Santiago
   aclaró que esa exclusión aplicaba a otro contexto (financiamiento) y no es una regla fija
   acá. Sin decisiones tomadas todavía sobre ninguno de estos.
10. ~~Inicializar git~~ **Hecho (2026-08-30).** Ver sección 15 — repo público en
    `github.com/Lovelyx-del/cowcontrol`, con GitHub Pages sirviendo la página de confirmación
    de mail desde `docs/`.
11. ~~Diseñar/implementar el alta de animales "no identificados"~~ **Hecho (2026-09-13).** Ver
    sección 16.9 — `conteo_screen.dart` ahora muestra una sección "Sin identificar" con cada
    `rfid_uid` que no matcheó ningún animal; tocarlo abre un diálogo para elegir categoría, y
    `AnimalesService.crearAnimal()` (nuevo) crea la fila en `datos_animales`. Sin cambios de
    SQL — el GRANT/RLS ya existentes alcanzaban. **Falta probar con hardware real** (Santiago
    no tiene tags a mano todavía).
12. **Ojo con los GRANT de Postgres en cualquier tabla nueva.** El 2026-08-06 apareció un bug
    (`permission denied`, code 42501) porque a las 4 tablas actuales les faltaba el `GRANT`
    explícito a `authenticated` (aparte de las políticas RLS — son dos capas distintas, ver
    sección 10). Cuando se cree `sesiones_conteo` u otra tabla nueva, correr el `GRANT`
    correspondiente en el mismo momento que se activa RLS, para no repetir este bug.
13. **Terminar de migrar el mail de confirmación a SendGrid** (para dejar de depender del
    límite/reputación de Gmail SMTP) — la cuenta de SendGrid quedó trabada a medio crear con
    `santiagoargentote18@gmail.com`. Ver sección 15 y `cosas_pendientes.md` ítem 17 para el
    detalle y el próximo paso sugerido (probar con otro mail).
14. **Confirmar con un celular de un compañero (no el de Santiago) que el registro/login
    funciona ahora** con el APK ya regenerado después del fix del permiso `INTERNET` (sección
    15.7-15.9) — el bug de meses quedó explicado y corregido, y ya se reenvió el APK nuevo al
    equipo, pero falta la confirmación real de que funcionó.
15. **Arreglar `docs/restablecer.html`** (recuperación de contraseña) — se queda trabada en
    "Verificando el link..." para siempre. Causa confirmada por código: choque entre el flujo
    PKCE de Supabase y que el link se abra en un contexto de storage distinto al que lo pidió
    (la app vs. el navegador). 4 alternativas evaluadas con Santiago el 2026-08-30 (cambiar a
    `AuthFlowType.implicit` — recomendada; deep links; flujo por-llamada — no soportado; dejarlo
    documentado) — **eligió no aplicar ninguna todavía**, quiere decidir con calma. Detalle
    completo en sección 15.10 y en `cosas_pendientes.md` ítem 21.
16. **Funcionalidad de cámara — alcance ya definido, arquitectura sin decidir del todo.**
    Ver sección 16.6/16.9 y `cosas_pendientes.md` ítem 26 (con la sección 9 agregada el
    2026-09-11): hay **dos caminos evaluados y documentados a fondo**, sin decidir cuál —
    Camino A (clips cortos de 2-3s por lectura, ya con arquitectura elegida vía workflow de 4
    agentes) vs. Camino B (un video completo con texto superpuesto + salto a un segundo,
    propuesta del equipo). Todo el análisis de Supabase Storage (límite de 50MB/archivo) está
    en `Funcion_Camara-CowControl.pdf`. Nada implementado todavía — Pantalla 4 ya tiene el
    botón "Video" como placeholder (`video_screen.dart`, pantalla vacía).
17. **Pivot de hardware: Raspberry Pi → ESP32.** El equipo (Germaioni) decidió cambiar por
    problemas de confiabilidad de la Pi (no prendía / no se dejaba flashear, típico de
    corrupción de SD). Confirmado que no choca con nada del lado de Supabase/Flutter — ver
    sección 16.11. Falta: firmware nuevo (equivalente a `rfid_tick.py` en Arduino/C++, a la
    espera del modelo exacto de ESP32), actualizar `Guia_Raspberry_Pi-CowControl.pdf`, y
    reescribir la carpeta técnica justificando el cambio de hardware (mencionado por Germaioni,
    sin hacer todavía).
18. **Probar con hardware/tags reales todo lo construido en la sesión del 2026-09-13**
    (sin identificar, cartel, Pantalla 4 rediseñada) — Santiago no tiene tags a mano, lo va a
    probar Germaioni cuando se le mande el APK nuevo.

---

## 8. Sesión 2026-07-28 — Android Studio, emulador, y primer login real

**1. Instalación de Android Studio y del SDK de Android** (todo hecho por Claude, sin que
Santiago tuviera que tocar nada de consola):
- Se instaló Android Studio vía `winget install --id Google.AndroidStudio`.
- Se corrió el asistente de primer inicio (Setup Wizard, tipo "Standard") — Santiago hizo
  clic en las ventanas gráficas, Claude no puede automatizar esa parte porque es 100% GUI.
- Faltaba el paquete **"Android SDK Command-line Tools"**, que no viene con el Setup Wizard
  estándar — se instaló a mano desde **SDK Manager → SDK Tools** dentro de Android Studio.
- Se corrió `flutter doctor --android-licenses` para aceptar todas las licencias del SDK.
- Resultado: `flutter doctor` quedó en verde para "Android toolchain" (el único ítem en rojo
  que queda es Chrome para desarrollo web, que no aplica a este proyecto).

**2. Creación del emulador — bug encontrado con `avdmanager` y su solución:**
- Se instaló la system image `system-images;android-35;google_apis;x86_64` (Android 15) vía
  `sdkmanager` (requiere `JAVA_HOME` apuntando al JDK que trae Android Studio:
  `C:\Program Files\Android\Android Studio\jbr`, porque `cmdline-tools` no trae uno propio).
- **Bug:** `avdmanager create avd ... -d pixel` (o cualquier perfil `-d`) tira el error
  `Could not load devices from ...\system-images\...\devices.xml` — la versión del
  `cmdline-tools` instalada (22.0) busca mal ese archivo. **Solución:** crear el AVD **sin**
  el flag `-d` (usa un perfil de hardware genérico, funciona igual para probar la app):
  ```
  avdmanager create avd -n Pixel_CowControl -k "system-images;android-35;google_apis;x86_64"
  ```
- Emulador creado: **`Pixel_CowControl`**, Android 15 (API 35). Se arranca con
  `flutter emulators --launch Pixel_CowControl`.
- **Nota para cuando un compañero de equipo replique este setup en su propia PC:** si les da
  el mismo error de `devices.xml`, aplicar la misma solución (omitir `-d`), o usar
  directamente el **Virtual Device Manager gráfico** de Android Studio, que no tiene este bug.

**3. Primer `flutter run` exitoso en el emulador:**
- Primer build tardó ~8 minutos porque Gradle tuvo que descargar de más el NDK
  (`28.2.13676358`) y el Android SDK Platform 36 (el proyecto pide compileSdk 36 aunque el
  emulador corre Android 15/API 35 — no es un problema, son cosas independientes). Builds
  siguientes son mucho más rápidos porque ya está todo cacheado.
- Confirmado en el log: `supabase.supabase_flutter: INFO: ***** Supabase init completed *****`
  — la conexión real a Supabase funciona de punta a punta también en Android, no solo en
  Windows desktop.
- El emulador se cerró solo en algún momento entre sesiones (no relacionado con la app) —
  se volvió a levantar sin problema con `flutter emulators --launch Pixel_CowControl` y
  `flutter run` de nuevo.

**4. Primer registro real y bug encontrado — error crudo de Supabase en pantalla:**
- Santiago se registró desde la app con un email real de Gmail. El registro se completó
  bien. Al intentar loguearse inmediatamente después, la app mostró en rojo:
  `AuthApiException(message: Email not confirmed, statusCode: 400, code: email_not_confirmed)`.
- **Esto no es un bug de la app ni de Supabase** — es el comportamiento por defecto de
  Supabase Auth: exige confirmar el email (clic en el link que manda por correo) antes de
  permitir el primer login. Falta ese paso, no falta código.
- **Bug real que sí se corrigió:** [`login_screen.dart`](../lib/screens/login_screen.dart)
  mostraba el `toString()` crudo de la excepción de Supabase directamente en la UI — mala
  práctica de UX (y de seguridad, expone detalles internos). Se agregó una función
  `_mensajeError()` que traduce los códigos de error más comunes de Supabase Auth
  (`email_not_confirmed`, `invalid_credentials`, `user_already_exists`, `weak_password`,
  `over_email_send_rate_limit`) a mensajes en español entendibles por un productor, con un
  mensaje genérico de respaldo para cualquier otro código. `flutter analyze` sigue sin
  errores después del cambio.
- **Decisión tomada con Santiago:** se le preguntó si prefería mantener la confirmación de
  email obligatoria (más segura, default de Supabase) o desactivarla en el dashboard para
  facilitar las pruebas. **Eligió mantenerla como está** — para probar el login ahora, hay
  que entrar al Gmail usado en el registro y tocar el link de confirmación que mandó
  Supabase.

---

## 9. Sesión 2026-08-03 — documento del compañero, modo aprendizaje, y primer cambio de schema guiado

**1. Recursos de Flutter + nuevo modo de trabajo.** Santiago pidió aprender Flutter por su
cuenta. Se le compartieron: Flutter learning pathway y codelab de Google, curso completo de
freeCodeCamp en YouTube (enfocado en iOS+Android), `docs.flutter.dev/resources/videos`
(incluye "Widget of the Week"), cookbook oficial de fuentes, y awesome-flutter en GitHub. Se
confirmó el alcance de plataformas: solo Android + iPhone (Windows desktop fue solo para el
smoke-test inicial). Se explicó qué es git y para qué serviría (respaldo automático de cada
cambio) — sigue sin inicializarse, quedó ofrecido no pedido (ver sección 7). Ver sección 1
para el detalle del nuevo modo de trabajo acordado.

**2. Se leyó y evaluó `dale.md`** (documento de un compañero de equipo, en esta misma
carpeta), que detalla un flujo de conteo con una tabla `conteos` (estado
activo/pausado/finalizado) y la Raspberry Pi consultando ese estado cada 5 segundos en vez
de recibir un push. Conclusiones:
- **No contradice que Supabase sea el "servidor"** — la Raspberry Pi solo consulta y empuja
  datos, nunca decide sola. Compatible con `base_datos.md` sección 5.
- **Coincide fuertemente con la migración `sesiones_conteo`** ya escrita pero no aplicada —
  el documento aporta el detalle de implementación que faltaba: hoy los botones
  Detener/Reanudar de `conteo_screen.dart` solo pausan el listener del celular, **nunca le
  avisan nada a la Raspberry Pi** (ese mecanismo no existe todavía).
- Puntos a reconciliar antes de implementar (no bloqueantes, para cuando se retome): falta el
  estado `'pausada'` en el `CHECK` de `sesiones_conteo` (hoy solo admite
  activa/finalizada/descartada); el documento no contempla multi-tenant (`campo_id`/RLS);
  usa IDs numéricos consecutivos en vez de los `uuid` ya usados; ambigüedad sobre si la
  lógica de "reanudar vs. crear sesión nueva" se dispara en cada poll de la Pi o solo al
  tocar "iniciar" (debe ser esto último); falta una restricción que impida dos sesiones
  "activa" simultáneas.
- **El rework de este flujo (sesiones_conteo + estado pausada + polling de la Raspberry Pi)
  queda pendiente para una sesión futura, guiado paso a paso** — no se tocó código de esto.

**3. Primer cambio de schema hecho por Santiago mismo, guiado paso a paso: `fertilidad`
reemplaza a `condicion_corporal`.** Motivo (decisión de Santiago): `fertilidad` sí está en
el mockup original y la quiere mostrar; `condicion_corporal` no aporta al prototipo de demo
(no lo mide el sistema, no vale la pena explicarlo en la presentación). La exclusión de
`fertilidad` acordada con el INTA en julio queda sin efecto — esa conversación fue en otro
contexto (financiamiento), no aplica como regla fija acá. **El resto de los campos que el
INTA pidió sacar (preñez, crías, "para carnear", alertas puntuales, maternidad, edad
aproximada) quedan pendientes de revisar uno por uno** (sección 7, ítem 9) — no se tocaron.

- `fertilidad` quedó como texto con categorías fijas: `'buena' / 'regular' / 'mala'`.
- **SQL corrido en Supabase (confirmado por Santiago):**
  ```sql
  ALTER TABLE datos_animales ADD COLUMN fertilidad text CHECK (fertilidad IN ('buena', 'regular', 'mala'));
  ALTER TABLE datos_animales DROP COLUMN condicion_corporal;
  ```
- **Archivos editados por Santiago con guía de Claude** (primera vez que edita él el código
  Flutter): `lib/models/animal.dart`, se borró `lib/widgets/condicion_corporal_chip.dart` y
  se creó `lib/widgets/fertilidad_chip.dart`, `lib/widgets/animal_card.dart` (parámetro
  `mostrarCondicionCorporal` → `mostrarFertilidad`), `lib/screens/detalle_animal_screen.dart`,
  `lib/screens/conteo_screen.dart`. **Confirmado con `flutter analyze`: "No issues found!"**
- **Errores cometidos en el camino (anotados para guiar mejor futuras ediciones):**
  a. Crear un archivo nuevo escribiendo la ruta completa (`lib/widgets/archivo.dart`)
     estando ya parado dentro de esa carpeta en el explorador de VS Code la anida mal (creó
     `lib/widgets/lib/widgets/fertilidad_chip.dart`). Corregido vía terminal (`Move-Item` +
     `Remove-Item`). **Lección:** decirle a Santiago que cree archivos nuevos con el nombre
     solo, sin repetir la ruta si ya está parado en esa carpeta.
  b. Al reemplazar una línea vieja por la nueva, la agregó al lado en vez de borrar la vieja
     (pasó dos veces: dejó `CondicionCorporalChip(...)` junto a `FertilidadChip(...)`, y al
     corregir eso borró de más `CategoriaBadge(...)`, que no correspondía tocar). **Lección:**
     en las guías futuras, separar explícitamente "borrá la línea X" de "agregá la línea Y"
     como dos pasos distintos, no asumir que se reemplaza sola.
- **Probado y confirmado visualmente el 2026-08-06** (ver sección 10) — funcionó de punta a
  punta, aunque en el camino aparecieron dos bugs nuevos (email vencido, permisos GRANT) que
  no tenían nada que ver con este cambio puntual.

---

## 10. Sesión 2026-08-06 — prueba end-to-end, dos bugs nuevos, guía completa del compañero, y diseño de alta de productores nuevos

### 10.1. Confirmación de email vencida + login probado de punta a punta

El link de confirmación que Supabase le mandó a Santiago en la sesión del 2026-07-28 ya
había vencido (los links de confirmación de Supabase expiran, por defecto en ~24hs, y
pasaron varios días reales entre sesiones). En vez de registrarse de nuevo, se confirmó la
cuenta a mano por SQL:
```sql
update auth.users set email_confirmed_at = now() where email = 'santi.cc2018@gmail.com';
```
**Cuidado al repetir esto:** la primera vez Santiago corrió la consulta con el placeholder de
ejemplo (`'tu_email@gmail.com'`) sin reemplazarlo por su email real — no rompió nada porque
esa fila no existe (0 filas afectadas), pero conviene verificar con un `SELECT` antes de
asumir que un `UPDATE` no hizo nada. Con el email real, el login funcionó en el emulador.

### 10.2. `productor_id` asignado a los datos de prueba — y confirmado que es un parche de una sola vez

Se corrió (y confirmó con un `SELECT` posterior, mostrando el UUID real):
```sql
UPDATE datos_campo
SET productor_id = (SELECT id FROM auth.users WHERE email = 'santi.cc2018@gmail.com')
WHERE nombre_campo = 'Campo Principal';
```
Santiago preguntó si un productor real va a tener que hacer esto — **no**: se confirmó en
[`campos_service.dart:18-25`](../lib/services/campos_service.dart#L18-L25) que
`crearCampo()` ya arma `productor_id` solo, tomándolo de `auth.currentUser!.id`, cada vez que
alguien crea un campo nuevo desde la Pantalla 1. El `UPDATE` manual de arriba es
**exclusivamente** para arreglar a Milka/Oscar/"Campo Principal", cargados a mano antes de
que existiera el sistema de login — no se repite nunca más para productores nuevos.

### 10.3. Bug nuevo: permisos GRANT faltantes (distinto de RLS)

Al recargar la pantalla de campos apareció:
```
PostgrestException(message: permission denied for table datos_campo, code: 42501, ...
hint: Grant the required privileges to the current role with: GRANT SELECT ON public.datos_campo TO authenticated;)
```
**Concepto clave para recordar:** RLS decide *qué filas* puede ver cada usuario; el `GRANT`
de Postgres es una capa **más básica y separada** — decide si el rol `authenticated` puede
siquiera intentar leer/escribir esa tabla, antes de que RLS entre a evaluar algo. A las 4
tablas actuales les faltaba ese `GRANT` (probablemente un descuido de las migraciones
anteriores, que solo tenían `ALTER TABLE`/`CREATE POLICY`, nunca `GRANT`). Solución aplicada
y confirmada ("Success"):
```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON public.datos_campo TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.datos_animales TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.datos_vacuna TO authenticated;
GRANT SELECT ON public.datos_lectura TO authenticated;
```
(`datos_lectura` solo necesita `SELECT` porque quien inserta ahí es la Raspberry Pi con la
`service_role` key, que bypassea tanto RLS como los GRANT). **Importante para el futuro:**
cualquier tabla nueva (`sesiones_conteo` cuando se aplique, por ejemplo) va a necesitar este
mismo `GRANT` explícito además de sus políticas RLS — no alcanza con activar RLS solo.

### 10.4. Confirmación visual final del cambio fertilidad/condición corporal

Con los dos bugs de arriba resueltos, la app mostró correctamente "Campo Principal" con
Milka y Oscar, cada uno con el chip **"Fertilidad: sin dato"** (esperado — son animales
viejos que no tienen ese campo cargado todavía, no es un error). Cierra el ciclo completo
del cambio empezado en la sección 9: base de datos → modelo → widgets → pantallas →
confirmado en un dispositivo Android real.

### 10.5. Detalle operativo: la terminal de Claude y la terminal de Santiago son procesos distintos

Cuando Claude corre `flutter run` con sus propias herramientas, esa sesión vive en una
terminal separada de la que Santiago ve en VS Code — por eso VS Code mostraba "R: (not
attached)" y Santiago no podía usar las teclas de hot reload. **Solución adoptada:** para
cualquier prueba donde Santiago necesite interactuar (apretar `r`/`R`/`q`), que él mismo
corra `flutter run -d emulator-5554` en su propia terminal de VS Code — la sesión de Claude
se desconecta sola ("Lost connection to device") sin que eso sea un problema, es lo
esperado cuando otra sesión toma el control del mismo dispositivo.

### 10.6. Diseño conceptual: cómo se da de alta un productor nuevo sin animales cargados

Santiago preguntó cómo haría un productor nuevo (ej. "Julio Ledesma" con vacas "Ricky" y
"Silvia") para cargar sus animales, dado que no puede saber de antemano el `rfid_uid` de
cada tag (no se lee a simple vista). **Diseño acordado, no implementado todavía:**
- El tag lo aporta el hardware automáticamente al escanear — el productor nunca necesita
  escribirlo a mano.
- Cuando llega una lectura (`datos_lectura`) cuyo `rfid_uid` no coincide con ningún animal
  ya cargado en `campo_id` de esa sesión, hoy el código simplemente la ignora (ver
  `conteo_screen.dart`, función `_marcarLectura`: `if (animalCoincidente == null) return;`).
  Habría que cambiar eso para que esa lectura quede visible como "no identificada" en vez de
  perderse.
- El productor, con el animal físicamente en frente durante el primer conteo (o revisando la
  lista de "no identificados" después), le pone nombre/categoría — recién ahí nace la fila
  completa en `datos_animales`.
- **Por qué no se mezcla entre productores:** la fila nueva hereda el `campo_id` de la sesión
  de conteo activa, que solo puede existir si el productor la inició logueado en su propia
  cuenta — la misma garantía de RLS que ya protege todo lo demás.
- Esta idea coincide y se completa con lo que ya tenía pensado el compañero de equipo en su
  guía completa (ver 10.7) — no hace falta "inventar" un animal automáticamente, alcanza con
  no descartar la lectura y mostrarla en una lista aparte.

### 10.7. Documentos del compañero de equipo — capturas con SQL concreto + guía completa vieja

**Capturas nuevas en `dale.md`** (imágenes `image.png` a `image-5.png`, insertadas dentro del
mismo archivo de texto que ya se había leído el 2026-08-03): traen el SQL concreto de lo que
antes solo estaba en prosa — tabla `conteos`, tabla `lecturas_rfid`, tabla `animales`
(reducida), vista `planilla_conteo`, las 3 funciones (`iniciar_o_retomar_conteo`,
`pausar_conteo`, `finalizar_conteo` — resuelven bien la ambigüedad que había quedado
pendiente el 2026-08-03: es una función RPC atada al botón "iniciar", no al polling), y
políticas RLS abiertas a `anon`.

**Archivo aparte, más completo y más viejo** (`C:\Users\santi\Downloads\proyecto_rfid_guia_completa.md`
— **fuera de la carpeta del proyecto**, ojo con la ruta): según aclaró Santiago, es de una
etapa anterior a que arrancara la app (cuando todavía se pensaba en un servidor propio), pero
aporta piezas que las capturas no traían:
- **Script Python completo y funcional para la Raspberry Pi** (`rfid_tick.py`) — primer
  código real que existe para el lado hardware (antes solo se había hablado en teoría). Usa
  `anon key` + polling cada 5s + un debounce de 5s para no re-mandar la misma tarjeta leída
  seguido. Para adoptarlo: cambiar a la `service_role key` (así no hace falta la RLS abierta
  a `anon`) y apuntar las URLs a las tablas reales del proyecto.
- **Manejo de tags desconocidos ya diseñado:** sin foreign key obligatoria entre
  `lecturas_rfid.uid` y `animales.uid`, más una consulta (`obtenerDesconocidos`) que lista
  las lecturas sin animal asociado — confirma y completa la idea del punto 10.6.
- El código de pantallas (sección 4 del archivo) está en **JavaScript/React** — no sirve para
  copiar tal cual en Flutter, pero la lógica (qué función de Supabase llamar y cuándo) sí es
  reutilizable, hay que traducirla a Dart.
- **Aclaración importante:** el documento dice "se descartó Realtime por complejidad" — eso
  aplica *solo* al canal Raspberry↔Supabase (ahí el polling está bien, es más simple). **No
  aplica a la app** — el ✓ en tiempo real que ve el productor sigue siendo Supabase Realtime,
  ya funciona, no se toca ni se cuestiona por este comentario.

**Veredicto consolidado (de ambos documentos), explicado con analogías para que Santiago se
lo pueda explicar a su compañero por audio:**

| Se toma | No se toma |
|---|---|
| Las 3 funciones de ciclo de vida del conteo (adaptadas a `sesiones_conteo`, sumando `'pausada'` y `campo_id`) | RLS abierta a `anon` — "como dejar la llave puesta afuera de la puerta" |
| El polling de la Raspberry cada 5s preguntando el estado | Reemplazar `datos_campo`/`datos_animales` por tablas nuevas — "tirar abajo una casa ya amueblada para hacer una carpa al lado" |
| El script `rfid_tick.py` (con `service_role` en vez de `anon`) | El código de pantallas en JavaScript — "una receta en inglés cuando cocinamos en español", hay que traducir la idea, no pegarla |
| La idea de lista de "no identificados" para tags nuevos | Reintroducir `fecha_nacimiento` — ya se había sacado por decisión con el INTA |
| — | La idea de que "se descartó Realtime" se aplique a la app — esa parte no se toca |

**Párrafo final que Santiago le mandó a su compañero** (guardado acá tal cual, por si hace
falta repetirlo o retomar la conversación con él):

> "La base de datos se queda tal cual está hoy —`datos_campo`, `datos_animales` (con
> categoría, fertilidad y el resto de los campos que ya tiene), `datos_lectura` y
> `datos_vacuna`— no se borra ni se reemplaza ninguna de esas tablas. Lo único que se agrega
> es la tabla de sesiones de conteo que ya teníamos planeada, usando las tres funciones que
> armaste para iniciar/pausar/finalizar (con el estado "pausada" sumado, que a nosotros nos
> faltaba, y ligada al campo de cada productor para que no se mezclen conteos entre distintos
> usuarios). Las políticas de seguridad siguen exigiendo login y filtrando por productor —no
> se abren a "anon" como estaba en tu propuesta, porque eso dejaría los datos de todos los
> productores visibles y editables por cualquiera sin loguearse—; para que la Raspberry pueda
> escribir sin necesidad de ese login, ya usamos la `service_role key`, que tiene permiso
> total sin tener que abrir nada para el resto. El polling de la Raspberry cada 5 segundos
> preguntando el estado del conteo sí se toma tal cual, y el tilde en tiempo real que ve el
> productor en el celular sigue funcionando con Supabase Realtime, sin tocarlo. Como agregado
> nuevo, sumamos la idea de guardar las lecturas de tags que todavía no tienen un animal
> asociado en una lista de "no identificados", para que un productor nuevo pueda ponerles
> nombre la primera vez que cuenta su ganado. Y no volvemos a agregar la fecha de nacimiento
> del animal, porque ya se había sacado antes por una decisión tomada con el INTA."

**Estado al cierre de esta sesión:** a la espera de que el compañero responda a esto. No
implementar nada del rework de `sesiones_conteo` hasta esa devolución, y aun con devolución
positiva, hacerlo guiado paso a paso (ver sección 1).

### 10.8. Devolución del compañero por WhatsApp — dudas técnicas respondidas en `base_datos.md`

El compañero respondió por WhatsApp (chat pegado tal cual, con audios que no se pudieron
transcribir, en `base_datos.md` a partir de la línea 213) con dudas puntuales: para qué sirve
cada campo de `datos_lectura` (confundía `id_animal` con el CUIG de SENASA — no lo es, es la
referencia interna a `datos_animales.id`), si hay que renombrar campos (no de nuestro lado,
sí del código de la Raspberry/Keila — se armó una tabla de equivalencia completa), y confirmó
que va a sumar el estado `'pausada'` él mismo. También mencionó, de forma confusa, que Keila
podría haber creado **un proyecto de Supabase aparte** — sin confirmar todavía, pero
importante de verificar antes de que ella siga escribiendo código (si apunta a otra URL, sus
datos quedan en una base invisible para el resto). **Respuesta técnica completa, punto por
punto, en `base_datos.md`** (sección "Respuesta técnica al chat de WhatsApp de arriba
(2026-08-06)") — incluye además un punto que nadie había resuelto todavía: cómo configura la
Raspberry Pi a qué `campo_id` pertenece (constante fija por instalación física, no es
dinámico como el login de la app).

---

## 11. Sesión 2026-08-07 — primer APK, aclaración de iOS, y bug pendiente en dispositivo físico

**1. Se generó el primer APK de release.** `flutter build apk --release` →
`build\app\outputs\flutter-apk\app-release.apk` (50.1 MB). El `.env` ya estaba declarado
como asset en `pubspec.yaml` (`assets: - .env`), así que el APK queda autocontenido, no
depende de nada más para conectarse a Supabase. También existe un `app-debug.apk` más viejo
(generado antes, de paso, por `flutter run`) — el que hay que usar para compartir es el
**release**.

**2. Cómo compartir la carpeta completa del proyecto con un compañero — aclarado con
detalle:** excluir `build/`, `.dart_tool/`, `windows\flutter\ephemeral`,
`android\app\debug`, `android\app\profile`, `android\app\release` (cachés/artefactos que se
regeneran solos; las carpetas `ephemeral` además pueden traer symlinks rotos apuntando a
esta PC específica, mismo problema que la mudanza de OneDrive en julio). **`.env` sí hay que
incluirlo** — a diferencia de por qué se excluye en `.gitignore` (ahí es para no subirlo al
historial de un repo), acá el compañero lo necesita para que la app le compile y conecte a
Supabase.

**3. iOS — aclarado que un APK no sirve para nada ahí.** La carpeta `ios/` del proyecto es
solo el scaffold que Flutter genera automáticamente para **todas** las plataformas al crear
el proyecto (la tengas usada o no) — nunca se compiló ni probó nada ahí. Para generar algo
instalable en un iPhone hace falta sin excepción una Mac con Xcode (no se puede desde
Windows, es un requisito de Apple) — ya estaba anotado como pendiente diferido (sección 7,
ítem 6). Además, distribuir a otra persona sin pasar por la App Store normalmente requiere
una cuenta Apple Developer paga (u$s99/año) para TestFlight, o instalar por cable con cuenta
gratuita (pero esa build expira a los 7 días). **Mientras no haya Mac disponible, la
compañera con iPhone no va a poder tener la app instalada** — alternativa para la expo: que
vea la demo corriendo en un Android en vez de en su propio celular.

**4. Problemas prácticos (no de la app) al mover el archivo del APK en Windows** — anotado
por si se repite: buscar el archivo por el buscador de "Inicio" de Windows no encuentra nada
si el archivo está en una ruta no indexada como `C:\dev\...` (hay que navegar directo
pegando la ruta completa en la barra de direcciones del Explorador). Además, doble-clickear
un `.apk` en Windows puede abrir un instalador de terceros ya instalado en esa PC ("EZ APK
App Installer") que pide ADB — no hace falta nada de eso, alcanza con clic derecho → Copiar
sobre el archivo, sin abrirlo, para pasarlo al celular por USB/Drive/WhatsApp.

**5. Bug — RESUELTO el 2026-08-30, ver sección 15 (era el permiso `INTERNET` faltante en el
manifest de release; se confunde fácil porque `flutter run` siempre funcionaba y ocultaba el
problema). Al cierre de esta sesión, sin resolver:** instalado el APK en un celular
Android físico, tanto el login (con cuenta ya usada antes) como el registro de un usuario
nuevo fallan con el mensaje genérico `"No se pudo iniciar sesion/registrar. Intenta de
nuevo."` — es el mensaje de respaldo de `_mensajeError()` en `login_screen.dart`, que sale
igual para un error de credenciales que para un error de red, así que no distingue la causa
real. Que falle **igual en login y en registro** hace sospechar de un problema de conexión
del celular hacia Supabase, más que de las cuentas en sí. Se descartó que sea por
minificación/ofuscación del build release (revisado `android/app/build.gradle.kts`: no hay
`minifyEnabled` activado). **Diagnóstico en curso:** primero confirmar que el celular tiene
internet (abrir cualquier página en el navegador), y si la tiene, conectarlo por USB con
Depuración USB activada y correr `flutter run` para ver el error real en la terminal en vez
del mensaje genérico. **Santiago lo va a hacer él mismo** (ver punto 6) y va a traer el
resultado a la próxima sesión.

**6. Modo aprendizaje, reafirmado y extendido a debugging.** Santiago recordó explícitamente
la preferencia ya anotada en la sección 1: de acá en más, **salvo que él diga lo contrario**,
Claude da el paso a paso y es Santiago quien ejecuta los comandos (no solo para cambios de
código — ahora también aplica a tareas de diagnóstico/debugging, como lo del punto 5). Esto
no aplica retroactivamente a lo que ya se venía haciendo por Claude directamente (setup de
Android Studio, compilar el APK, etc.) — esas siguen siendo tareas que Claude puede resolver
directo salvo que se indique lo contrario; el cambio es específicamente para investigar y
resolver bugs de la app de acá en más.

---

## 12. Sesiones 2026-08-10 a 2026-08-13 — Pantalla 4 rediseñada, íconos propios, y viaje de Santiago

Resumen (el detalle línea por línea, con todo el código, está en `cosas_pendientes.md`
ítems 6 a 11 — acá va solo el panorama general):

1. **Pantalla 4 (ficha de animal) rediseñada dos veces** hasta llegar a la versión final:
   primero se hizo editable de corrido (fertilidad/vacunas/observaciones todas visibles y
   editables en una sola pantalla, confirmado guardando bien en Supabase). Después, a pedido
   de Santiago (se veía muy plana), se rediseñó en **3 botones** ("Fertilidad", "Vacunas",
   "Observaciones"), cada uno llevando a su propia pantalla nueva
   (`fertilidad_screen.dart`, `vacunas_screen.dart`, `observaciones_screen.dart`) —
   reutilizando toda la lógica de guardado ya probada. Confirmado funcionando en el celular.
2. **Íconos de categoría propios, generados con Gemini.** Se reemplazaron los símbolos
   genéricos de Flutter (♀/♂/bebé) por ilustraciones a medida de vaca/toro/ternero/
   ternera/vaquillona — llevó varias vueltas de ida y vuelta con Gemini hasta lograr que los
   5 quedaran diferenciados entre sí (el truco que funcionó: orientación por sexo — machos
   mirando para un lado, hembras para el otro — además de la anatomía). Se descartó
   vectorizar a SVG (las herramientas buenas son pagas) a favor de PNG con fondo transparente
   (gratis, remove.bg, mismo resultado visual para el tamaño de ícono que usa la app). Código
   listo en `cosas_pendientes.md` ítem 10 — puede estar terminado de integrar o no, revisar
   el estado ahí.
3. **Varios bugs de "no se aplicaron los cambios" resueltos en el camino** — todos por el
   mismo tipo de causa: copiar de más (texto de Markdown junto con el código) o de menos
   (mezclar el contenido de dos pasos en un mismo archivo) al pegar desde `cosas_pendientes.md`,
   y confusión sobre qué terminal tenía `flutter run` activo vs. cuál estaba libre para
   `flutter analyze`. Ninguno fue un bug real de la app.
4. **Bug de conexión USB inestable con el celular de prueba** (Moto G23, chip MediaTek) — se
   corta la sesión de `flutter run` sola a los 20-30 segundos con `Lost connection to
   device.`. No es un bug de código (confirmado con `flutter analyze` limpio en paralelo).
   Solución de trabajo: en vez de depender de una sesión `flutter run` en vivo, generar un
   APK (`flutter build apk --debug` o `--release`) e instalarlo directo con
   `adb install -r` — evita el problema de raíz.
5. **Santiago se va de viaje una semana** y le va a dar la carpeta completa del proyecto a un
   compañero de equipo, que tiene la Raspberry Pi, el lector RFID y los tags físicos, para
   que pueda avanzar con la integración de hardware mientras tanto. Se creó
   `documentacion.md/guia_para_el_equipo.md` — documento de traspaso completo (qué está
   hecho, qué falta, cómo probar la app en dos caminos, cosas importantes a tener en cuenta,
   y cómo probar con la Raspberry Pi) escrito en tono neutro, sin nombres propios. Se agregó
   además un script de Python completo y listo para probar el circuito básico
   (tag → Raspberry → Supabase → app en tiempo real) sin depender de la migración pendiente
   de `sesiones_conteo`, en `cosas_pendientes.md` ítem 11.
6. **Antes de compartir la carpeta:** confirmado qué borrar — `linux/`, `macos/`, `web/`
   (plataformas nunca usadas), `build/` y `.dart_tool/` (cachés que se regeneran solas).
   **`ios/` no se borra** — es un requisito no negociable del proyecto, solo que todavía no
   se pudo compilar por falta de una Mac con Xcode. Pendiente: generar un APK fresco (el que
   había, del 7 de agosto, quedó desactualizado con los cambios de este resumen) y copiarlo a
   un lugar que no se borre junto con `build/` antes de armar el paquete para compartir.

---

## 13. Sesión 2026-08-25 — compañero no podía registrarse durante el viaje, SMTP propio configurado

Una semana después de que Santiago viajara y le pasara la carpeta comprimida al equipo (grupo
de WhatsApp "proyecto: Lector automático de caravana", con Germaioni y kei), un compañero
instaló el APK sin problema pero no pudo registrarse: nunca le llegó el mail de confirmación
de Supabase, y sin confirmarlo tampoco pudo iniciar sesión.

Se revisó `Authentication → Users` en el dashboard de Supabase y no apareció ninguna fila con
su mail — descartando que el problema fuera solo la entrega del correo: el pedido de registro
nunca llegó al servidor. El "Total: 10 users (estimated)" que muestra el dashboard resultó ser
un conteo aproximado de Postgres (no en vivo) — la tabla real solo tenía 1 fila (la cuenta de
Santiago). Diagnóstico de Santiago, coincidente con la evidencia: el celular del compañero no
tenía conexión a internet en el momento de registrarse.

Aun así, se resolvió una causa raíz real y ya sospechada desde agosto: el mail de confirmación
por defecto de Supabase tiene límite bajo de envíos y mala entrega. Se configuró SMTP propio
con Gmail (host `smtp.gmail.com`, puerto `587`, cuenta `santiagoargentote18@gmail.com` +
contraseña de aplicación) en `Authentication → Emails → SMTP Settings` — sube el límite a 30
mails/hora y mejora la entrega para cualquier compañero que se registre de acá en adelante,
sin depender de la conexión de Santiago. Detalle completo del paso a paso en
`cosas_pendientes.md` ítem 12.

Se regeneró el APK de release (idéntico, 50,7MB — la config de SMTP es enteramente del lado de
Supabase, no requirió tocar código) para reenviarlo al equipo.

Surgió una pregunta de alcance más grande, sin decidir: si un productor real está en un campo
sin señal, ¿la app funciona? Registrarse/loguearse por primera vez sí necesita internet, pero
la sesión queda guardada localmente; lo que sí depende de conexión en tiempo real es la
pantalla de Conteo en vivo (Supabase Realtime). Un "modo offline" real sería un cambio de
arquitectura más grande — queda anotado en `cosas_pendientes.md` ítem 13, sin implementar,
para retomar cuando Santiago pueda revisarlo con calma.

Probando el flujo de confirmación de punta a punta apareció un segundo hallazgo, este sin
relación con el SMTP: el link de confirmación de mail redirige a `localhost:3000/?code=...`,
que en el celular tira "localhost rechazó la conexión" — porque la "Site URL" del proyecto
quedó en el valor por defecto (pensado para una web local que este proyecto no tiene). La
confirmación en sí funciona igual (se valida en el servidor de Supabase antes de ese
redirect roto — Santiago pudo loguearse después sin problema), pero la pantalla que ve el
usuario queda fea y puede espantar a un productor real. Dos caminos de arreglo (cambiar el
Site URL por una página simple, o configurar un deep link a la app) quedaron anotados sin
implementar en `cosas_pendientes.md` ítem 14.

También se confirmó, reproduciendo con `flutter run` por USB, que un intento de registro
fallido (mensaje genérico "No se pudo completar el registro") era en realidad el rate limit
de seguridad de Supabase (`over_email_send_rate_limit` — no dejaba pedir otro mail antes de
cierta cantidad de segundos) por probar varios registros seguidos durante las pruebas —
esperable en testing, no un problema para uso real. Se agregó un `debugPrint` del error crudo
en `login_screen.dart` (dentro del catch de `_enviar()`) para poder diagnosticar así de rápido
la próxima vez, sin tener que adivinar por el mensaje genérico que ve el usuario.

---

## 14. Sesión 2026-08-26 — política de contraseñas, aviso de registro exitoso, y limpieza total de datos de prueba

Continuación directa de la sesión anterior (mismo hilo de trabajo, compañero seguía sin poder
entrar). Tres cambios de código y una limpieza de base de datos, todos ya aplicados:

**1. Requisitos de contraseña + UX en `login_screen.dart` (código completo en
`cosas_pendientes.md` ítem 15):**
- Al registrarse ahora se exige mínimo 8 caracteres + al menos una letra + al menos un número
  (antes eran 6 caracteres sin ninguna regla). Al iniciar sesión NO se exige — una cuenta vieja
  no tiene que quedar bloqueada por una regla que no existía cuando se creó.
- Checklist visual en vivo debajo del campo de contraseña (○ gris → ✓ verde por cada regla
  cumplida), visible solo en el formulario de registro.
- Botón de "mostrar/ocultar contraseña" (ícono de ojo) y `autocorrect: false` +
  `enableSuggestions: false` en los campos de email y contraseña — apuntado directo a la
  sospecha de que el teclado del celular de un compañero autocorrigió/autocompletó la
  contraseña sin que él lo note (bug reportado: "a mí me deja entrar con esa cuenta, a él no",
  mismo mail, misma contraseña, mismo APK).

**2. Aviso de éxito/ya-existe al registrarse (código en `cosas_pendientes.md` ítem 16):**
- Bug real encontrado: al "registrarse" con un mail que ya tenía cuenta confirmada, Supabase
  no tira ningún error (a propósito — es una medida de seguridad para no revelar qué mails ya
  tienen cuenta) pero tampoco cambia la contraseña vieja. La app no avisaba nada, así que
  parecía que había funcionado, y después el login fallaba con la contraseña nueva.
- Arreglo: se lee `respuesta.user?.identities` después de `signUp()` — si viene vacío, es un
  mail que ya existía (se muestra "Ya existe una cuenta registrada con ese email."); si no,
  es un registro nuevo de verdad (se muestra en verde "Te registraste con exito. Revisa tu
  correo..."). No hizo falta tocar `auth_service.dart`, ya devolvía el `AuthResponse` completo.

**3. Diagnóstico por USB confirmó que un error de registro era el rate limit esperable de
Supabase** (`over_email_send_rate_limit`, por probar varios registros seguidos en poco tiempo
durante las pruebas — no es un bug, no afecta el uso real). Se aprovechó para agregar un
`debugPrint` del error crudo en el catch de `_enviar()`, así la próxima vez que algo falle se
puede ver el código real de Supabase corriendo `flutter run -d <celular>` por USB, en vez de
adivinar por el mensaje genérico que ve el usuario.

**4. Limpieza total de datos de prueba (Supabase, sin código):** con las cuentas viejas
quedando en un estado inconsistente (contraseñas de antes de la regla nueva, sin forma de
"actualizarlas" simplemente registrándose de nuevo por el punto 2), y sin ningún productor
real usando la app todavía, se decidió arrancar de cero:
```sql
delete from datos_vacuna;
delete from datos_lectura;
delete from datos_animales;
delete from datos_campo;
```
seguido de borrar las 4 cuentas de `Authentication → Users` a mano (el primer intento de borrado
en bloque fallo con "Database error deleting user" porque `datos_campo.productor_id` tiene una
foreign key hacia `auth.users(id)` sin `ON DELETE CASCADE` — no se puede borrar un usuario
mientras tenga un campo todavia apuntandole; por eso hubo que borrar los datos primero). Quedó
confirmado: **"No users in your project"** — la base de datos de auth y las 4 tablas de datos
quedaron completamente vacías. Cualquiera que se registre ahora (vos o tus compañeros) parte de
cero, con la regla de contraseña nueva desde el principio, y `campos_service.dart` le va a
asignar el `productor_id` automáticamente al crear su primer campo (sin necesitar el `UPDATE`
manual que hizo falta la primera vez, en la sección "Migración inicial" de `base_datos.md`).

**APK:** regenerado dos veces en esta sesión (una vez por punto 1, otra por punto 2) y
sobreescrito en los mismos dos lugares de siempre: `C:\dev\CowControl.apk` (para mandar por
WhatsApp) y `app_cowcontrol\apk_para_probar\CowControl.apk`. `flutter analyze` sin errores las
dos veces.

**Sin terminar al cierre de esta sesión:** falta aplicar la misma regla de contraseña también
del lado de Supabase (no solo en la app) — retomado y cerrado en la sesión siguiente.

---

## 15. Sesión 2026-08-30 — git/GitHub, página de confirmación, íconos, y el bug del permiso INTERNET (mes y medio sin resolver)

Sesión larga, varios frentes distintos. En orden:

### 15.1. Regla de contraseña también del lado de Supabase (cierre del pendiente de la sesión 14)

La pantalla correcta era `Authentication → Sign In / Providers` → clic en la fila **"Email"**
para expandirla. Ahí:
- **"Minimum password length"**: `6` → `8`.
- **"Password requirements"**: entre las opciones (*No required characters*, *Letters and
  digits*, *Lowercase, uppercase letters and digits*, *…and symbols*), se eligió **"Letters
  and digits"** — coincide exacto con la regla de la app (8 caracteres + letra + número, sin
  exigir mayúscula específicamente). Una opción más estricta hubiera podido rechazar en el
  servidor una contraseña que la app ya aceptó como válida.

Guardado y confirmado. Regla exigida ahora en las dos capas (app y servidor).

### 15.2. Se inicializó git y se creó el repo público en GitHub

Santiago pidió pasar a git y, de paso, unificar todo en un solo repo (en vez de pensar en
repos separados para app/hardware/docs). Antes de hacerlo público se revisó que no hubiera
ninguna clave real pegada en los documentos (solo se menciona la palabra `service_role` como
referencia, nunca el valor) — `.gitignore` ya excluía `.env` y `/build/` correctamente.

- `git init` en `app_cowcontrol/`, identidad configurada localmente (Santiago Cuenca Cabrera /
  santiagoargentote18@gmail.com), commit inicial (123 archivos).
- Se agregó `/apk_para_probar/` al `.gitignore` — un binario de 50MB no debe crecer el
  historial de git cada vez que se regenera el APK.
- Repo creado con `gh` (ya logueado en la cuenta `Lovelyx-del`, confirmada como la de
  Santiago): **`https://github.com/Lovelyx-del/cowcontrol`** (público — necesario para GitHub
  Pages gratis).
- **Nota de proceso:** tanto crear el repo en GitHub como correr comandos de git quedaron
  bloqueados por el clasificador de "modo auto" del harness (acciones que afectan algo fuera
  de la PC piden aprobación explícita) — Santiago aprobó el permiso de Bash para que Claude lo
  hiciera directo, en vez de correr el comando él mismo.

### 15.3. Página de confirmación de mail + GitHub Pages (cierre del ítem 14 de `cosas_pendientes.md`)

Con el repo ya creado, se resolvió el pendiente viejo del link de confirmación roto
(`localhost:3000` → `ERR_CONNECTION_REFUSED` en el celular):

- Se creó `docs/confirmacion.html` — página estática con la paleta de colores de la app
  (fondo crema, tarjeta, tilde verde, "COWCONTROL"), mensaje "Cuenta confirmada — volvé a la
  app CowControl e iniciá sesión".
- Se activó **GitHub Pages** (`gh api repos/Lovelyx-del/cowcontrol/pages`) apuntando a
  `master` / `/docs`. URL pública: **`https://lovelyx-del.github.io/cowcontrol/confirmacion.html`**
  (verificada con `200 OK`).
- En Supabase (`Authentication → URL Configuration`): **Site URL** cambiado de `localhost:3000`
  a esa URL, y agregada también a **Redirect URLs**. Confirmado guardado por Santiago en
  ambos campos.
- Sin probar todavía con un registro real de punta a punta (queda para la próxima vez que
  alguien se registre).

### 15.4. Intento de migrar a SendGrid — cuenta trabada, quedó pendiente

Para mejorar la entrega del mail (con Gmail SMTP cae seguido en spam), Santiago eligió migrar
a SendGrid. Al crear la cuenta con `santiagoargentote18@gmail.com` en signup.sendgrid.com
(redirige a Twilio Login, el sistema unificado desde que Twilio compró SendGrid):
- El signup dice "The user already exists", pero login y "olvidé mi contraseña" no encuentran
  ningún usuario con ese mail.
- Según la propia documentación de Twilio (`Troubleshooting account login issues`), la causa
  más probable es una cuenta vieja a medio crear (empezada, nunca confirmada por mail) que
  bloquea un registro nuevo sin ser ella misma recuperable.
- **Sin resolver — queda en `cosas_pendientes.md` ítem 17.** Próximo paso sugerido: probar de
  nuevo con otro mail. Mientras tanto sigue todo con el SMTP de Gmail configurado en la
  sesión del 25/08.

### 15.5. Íconos de categoría (vaca/toro/ternero/ternera/vaquillona) — terminado de aplicar

Este cambio ya estaba completamente especificado desde el 2026-08-13 (`cosas_pendientes.md`
ítem 10) pero nunca se había llegado a aplicar en el código — `categoria_badge.dart` seguía
usando símbolos genéricos de Flutter (♀/♂/bebé) en vez de las 5 ilustraciones ya generadas con
Gemini. Aplicado ahora, guiado paso a paso con Santiago editando él mismo (modo aprendizaje):
- `pubspec.yaml`: se agregó `- assets/images/` a la sección `assets:`.
- `lib/widgets/categoria_badge.dart`: reemplazado completo para usar `Image.asset(...)` con
  `color` + `colorBlendMode: BlendMode.srcIn` (pinta el dibujo del marrón de la app,
  sea cual sea el color original del PNG). `animal_card.dart` y `detalle_animal_screen.dart`
  no se tocaron — ya usaban `CategoriaBadge` tal cual.
- **Verificado:** `flutter analyze` → "No issues found!".

### 15.6. Ícono de la app (launcher) + nombre feo "app_cowcontrol"

Pedido de Santiago: el ícono de la app en el celular seguía siendo el genérico de Flutter
(nunca personalizado), y el nombre que aparece abajo del ícono decía literalmente
`"app_cowcontrol"` en vez de "CowControl".

- **Nombre:** corregido `android:label` en `android/app/src/main/AndroidManifest.xml`
  (`"app_cowcontrol"` → `"CowControl"`) y `CFBundleDisplayName` en `ios/Runner/Info.plist`
  (`"App Cowcontrol"` → `"CowControl"`) — este último no se puede probar todavía (falta Mac
  con Xcode) pero queda consistente para cuando se pueda.
- **Ícono:** se generó a partir de la misma ilustración de `vaca.png` (Gemini), recoloreada a
  blanco sobre fondo sólido naranja (`AppColors.naranjaTostado`, `#C77C3B`) — con Python/Pillow
  (`assets/icon/icon.png` para el ícono plano/iOS, `assets/icon/icon_foreground.png` para la
  capa de "ícono adaptable" de Android 8+, con la vaca dentro de la zona segura del 66%).
  Probado en miniatura (48px y 96px) antes de aplicar — se ve legible incluso al tamaño más
  chico real del ícono en Android.
- Se agregó `flutter_launcher_icons` como `dev_dependency` en `pubspec.yaml`, con su bloque de
  configuración (`image_path`, `adaptive_icon_background`, `adaptive_icon_foreground`) — genera
  automáticamente todos los tamaños de mipmap al correr `dart run flutter_launcher_icons`.
  **Pendiente de confirmar si Santiago ya lo corrió** — si no, es el primer paso para retomar.

### 15.7. El bug de mes y medio: faltaba el permiso `INTERNET` en el manifest de release

**El hallazgo más importante de la sesión.** Un compañero (Federico) instaló el último APK y
no pudo ni registrarse ni iniciar sesión — mismo mensaje genérico en los dos casos ("No se
pudo completar el registro/iniciar sesión. Intenta de nuevo."), con capturas de pantalla
confirmando que los datos ingresados cumplían todas las reglas (checklist en verde). Este es
el mismo bug reportado sin resolver desde la sesión del 2026-08-07 (sección 11, punto 5) y
vuelto a sospechar el 2026-08-25 — cada vez atribuido a "puede ser el internet del celular" o
"puede ser el autocorrector", sin confirmarse nunca porque nadie podía conectar el celular que
fallaba por USB para ver el error real.

**Causa raíz encontrada por revisión de código:** `android/app/src/main/AndroidManifest.xml`
**nunca declaró el permiso `android.permission.INTERNET`**. Ese permiso sí está en
`android/app/src/debug/AndroidManifest.xml` (con un comentario del propio template de Flutter:
"required for development... hot reload") — pero **ese manifest de debug solo se mezcla en
builds debug y profile, nunca en release**. Consecuencia:
- Cada vez que alguien probó con `flutter run` (Santiago, siempre por USB) → build debug →
  permiso de internet agregado automáticamente → funciona sin problema.
- Cada vez que alguien instaló el **APK de release** real (el que se comparte por WhatsApp) →
  sin el permiso declarado en ningún lado → **la app no tiene acceso a internet en absoluto** →
  cualquier llamada a Supabase (login o registro, da igual cuál) falla con una excepción de
  red genérica, que el `catch` de `_enviar()` traduce al mensaje de respaldo.

Esto explica **perfectamente** el patrón que nunca terminaba de cerrar: por qué fallaba
siempre igual en login y en registro (ninguno de los dos llegaba a tocar la red), por qué
"andaba en la PC de Santiago" (ahí siempre se probó con `flutter run`, nunca con el APK real
instalado), y por qué cada intento de diagnóstico anterior (revisar conexión del celular,
sospechar del autocorrector, revisar `minifyEnabled`) no encontraba nada — el código Dart
nunca tuvo el bug, era un permiso de Android faltante, invisible mientras se siga probando por
USB en vez de con el archivo `.apk` real.

**Arreglo aplicado:**
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
agregado a `android/app/src/main/AndroidManifest.xml`, a nivel raíz del `<manifest>` (fuera de
`<application>`), para que se incluya en **todos** los build types. Verificado con
`flutter analyze` → "No issues found!".

**Pendiente para cerrar del todo:** regenerar el APK de release (`flutter build apk --release`)
e instalarlo en un celular que **no sea el de Santiago** (o al menos no vía `flutter run`) para
confirmar que ahora sí deja registrarse/iniciar sesión — es la primera vez que se va a probar
el bug arreglado con el método real de reproducción (el `.apk` instalado a mano), no con
`flutter run`. Santiago va a probar con otro celular próximamente.

### 15.8. Continuación: colores por sexo, ajustes de dropdown, recuperación de contraseña, y primer commit real del día

Resto de la sesión del 2026-08-30 (detalle completo en `cosas_pendientes.md` ítems 19-21, acá
solo el resumen):

- **Íconos de categoría, ronda 2:** se confirmó visualmente que `ternero.png`/`ternera.png` se
  veían más chicos que los otros 3 — no por el texto largo, sino porque esos PNG tenían mucho
  margen transparente sin usar (49-56% de su lienzo vs. 87-100% de los otros). Se recortó el
  margen de las 5 imágenes y se agregó `fit: BoxFit.contain`. Se sumó color por sexo (celeste
  macho / rosa hembra) porque la sola silueta no alcanzaba para distinguir categorías a 28px —
  primer intento con pasteles quedó muy apagado contra el fondo crema, se subió la saturación
  (Material Blue 500 / Pink 500). En el dropdown "Todas" el ícono quedaba pegado al texto por
  un `mainAxisSize: min` — cambiado a `spaceBetween` para que vaya al borde derecho del menú.
  **Confirmado por Santiago, quedó bien.** Pendiente a futuro (no urgente): probar íconos de
  cara en vez de cuerpo entero, capaz se note más la diferencia entre categorías.
- **Recuperación de contraseña implementada** (botón "¿Olvidaste tu contraseña?" en
  `login_screen.dart` + página nueva `docs/restablecer.html` en el mismo GitHub Pages). Se
  evaluó y descartó explícitamente la idea de una "pregunta secreta" antes de mandar el mail
  (práctica de seguridad obsoleta desde 2017 según NIST) a favor del estándar actual: link de
  un solo uso a un mail verificado, que es lo que Supabase ya hace de fábrica. Se eligió no
  usar deep links (el mail abre una página web, no la app directo) para minimizar riesgo antes
  de la presentación. Detalle completo, pensado para poder explicarlo en la presentación, en
  `cosas_pendientes.md` ítem 21.
- **Primer commit real del día con todo lo de arriba** (ícono de la app, íconos de categoría,
  fix del permiso INTERNET, recuperación de contraseña) — pusheado a
  `github.com/Lovelyx-del/cowcontrol`. Falta agregar la URL de `restablecer.html` a las
  Redirect URLs de Supabase antes de probar el flujo (paso ofrecido a Santiago, sin confirmar
  todavía que lo haya hecho).
- Mencionado por Santiago, sin abordar todavía en esta sesión: reenviar el APK actualizado al
  equipo, y una funcionalidad de cámara que quiere sí o sí — quedan como próximos temas.

### 15.9. Bug real en `restablecer.html`, regeneración del APK, y guía de la Raspberry Pi para el equipo

- **`docs/restablecer.html` no funciona — se queda trabada en "Verificando el link..." para
  siempre**, probado por Santiago con una captura real. **Diagnóstico (sin arreglar todavía,
  ver `cosas_pendientes.md` ítem 21 sección "PENDIENTE" para el detalle completo):** el
  proyecto usa el flujo **PKCE** de Supabase Auth. En PKCE, completar el link de recuperación
  necesita un "code verifier" que Supabase guarda **en el mismo lugar donde se pidió el link**
  — como el botón "¿Olvidaste tu contraseña?" se toca desde la app Flutter (que guarda ese
  verifier en el almacenamiento interno del celular) pero el link se abre en el navegador
  (almacenamiento completamente distinto, sin acceso a lo que guardó la app), el navegador
  nunca puede terminar el intercambio del código — se cuelga para siempre. **No es un bug de
  tipeo del HTML, es un choque de arquitectura entre dos contextos de storage distintos.**
  **Posible solución anotada (sin aplicar):** cambiar `Supabase.initialize()` en `main.dart` a
  `authFlowType: AuthFlowType.implicit` — con ese flujo el link trae el token directo en la URL
  (`#access_token=...`), autocontenido, sin necesitar nada guardado de antemano. Ojo: afecta el
  flujo de auth de **toda la app** (login, registro, confirmación de mail), no solo esta
  pantalla — hay que volver a probar el ciclo completo de auth si se aplica, no solo esto.
  Queda pendiente para una próxima sesión, evaluado con calma.
- **Se regeneró el APK de release** con absolutamente todo lo de esta sesión (ícono nuevo,
  colores de categoría, fix del permiso INTERNET, botón de recuperación de contraseña) y se
  sobreescribió en los dos lugares de siempre (`C:\dev\CowControl.apk` y
  `apk_para_probar\CowControl.apk`) — **es el primer APK que se genera después de arreglar el
  bug del permiso INTERNET, así que es clave para confirmar si de verdad se solucionó** lo que
  llevaba mes y medio sin poder registrarse/loguearse en celulares ajenos al de Santiago.
  Pendiente: que Santiago lo reenvíe al equipo y confirme el resultado.
- **Se armó `documentacion.md/Guia_Raspberry_Pi-CowControl.pdf`** (+ `rfid_tick.py` al lado,
  mismo script en texto plano para copiar sin arrastrar saltos de línea del PDF) — para pasarle
  a un compañero que ya tiene bastante código del lado del hardware hecho, con las credenciales
  exactas que necesita conseguir (`SUPABASE_URL`, `service_role key`, `campo_id`) y el formato
  exacto del POST a `datos_lectura`, para que pueda adaptar su propio código sin tener que
  arrancar de cero. Resume el ítem 11 de `cosas_pendientes.md` en un documento standalone,
  pensado para compartirse por fuera del repo.
- **SQL entregado (sin confirmar si se corrió)** para cargar 5 animales de prueba (uno por
  categoría) en el campo del compañero que se va a registrar, parametrizado por su email —
  mismo patrón que se usó para el campo de Santiago ("Horacio SRL") más temprano en la sesión.
- **Mencionado por Santiago para la próxima sesión, sin definir todavía:** quiere la
  funcionalidad de cámara sí o sí (vinculada a cada lectura — ver el pendiente viejo en
  `cosas_pendientes.md`), y retomar el arreglo de `restablecer.html` de arriba.

### 15.10. Retomado el mismo día: diagnóstico confirmado por código, sin aplicar el fix

Se confirmó por código (`main.dart` sin `authFlowType` → usa PKCE por defecto) el diagnóstico
de 15.9, y se afinó el mecanismo exacto: el intercambio de código PKCE sin "code verifier" deja
colgado un lock interno del SDK de JS de Supabase, y como el `getSession()` de respaldo del
`setTimeout` necesita ese mismo lock, también queda esperando para siempre — por eso nunca
llega a mostrar el mensaje de error, se cuelga en "Verificando el link..." de verdad.

Se le explicó a Santiago PKCE vs. flujo implícito (analogía de la caja fuerte de doble llave) y
se evaluaron 4 alternativas — detalle completo, con el análisis de riesgo, en
`cosas_pendientes.md` ítem 21. **Decisión: Santiago eligió dejarlo pendiente por ahora**, sin
aplicar ningún cambio — prefirió entender bien el trade-off antes de decidir, y no tocar el
flujo de auth de toda la app todavía. Sigue roto tal cual estaba, pero con el terreno allanado
para una decisión rápida cuando se retome.

---

## 16. Sesiones 2026-08-31 a 2026-09-13 — conteos, id_animal, git, landing aparte, cámara (2 caminos), ESP32, NotebookLM, Pantalla 4 rediseñada, animales sin identificar

Sesión larguísima (por eso se cierra acá y se abre un chat nuevo — ver el cierre al final).
Resumen por tema, no cronológico estricto.

### 16.1. `restablecer.html` — sigue sin arreglar, a propósito

Se retomó el diagnóstico del ítem 15 de esta lista (PKCE, ver sección 15.9/15.10) y se afinó el
mecanismo exacto (un lock interno del SDK de JS de Supabase queda colgado, por eso nunca
termina de mostrar el error). Se le explicó a Santiago la diferencia PKCE vs. flujo implícito
con la analogía de la caja fuerte de doble llave, y se evaluaron 4 alternativas otra vez.
**Santiago volvió a elegir dejarlo pendiente** — sigue exactamente igual que en la sesión 15,
sin aplicar nada. Detalle en `cosas_pendientes.md` ítem 21.

### 16.2. `id_animal` sacado de `datos_lectura`, y la tabla `conteos` conectada a la app

Un compañero (Germaioni) preguntó por WhatsApp sobre el diagrama de tablas de Supabase — se
aprovechó para confirmar con `pg_constraint` que las 6 foreign keys reales del proyecto están
bien armadas (incluida `productor_id → auth.users.id`, que no aparecía en una consulta con
`information_schema` por una limitación de esa vista con tablas de otro schema/dueño). Se
confirmó que `id_animal` en `datos_lectura` nunca lo llenaba nadie — se sacó
(`ALTER TABLE ... DROP COLUMN`, `lectura.dart` y `conteo_screen.dart` actualizados para
emparejar solo por `rfid_uid`).

Germaioni también había creado, por su cuenta y sin avisar, una tabla `conteos` (id, fecha,
estado) esperando que la app escribiera ahí al iniciar un conteo — pero esa parte nunca se
había construido (la app solo escuchaba Realtime). Se armó `ConteosService`
(`iniciarOReanudar`/`pausar`/`reanudar`/`finalizar`) y se conectó en `conteo_screen.dart`. Se
le agregó a la tabla `campo_id` + GRANT + política RLS, que le faltaban. **Hallazgo importante:**
el `CHECK` real de `estado` es `'en_curso'/'pausado'/'finalizado'`, no `'activo'` como decían
las notas de Germaioni — hubo que avisarle para que ajuste el polling de su lado (Raspberry
Pi/ESP32). Confirmado funcionando en el emulador sin hardware (se ve la fila en Supabase al
tocar los botones).

### 16.3. Git: se sacó "Claude" de los Contributors de GitHub

A pedido de Santiago, se reescribieron los 6 commits del historial (sacando el pie
`Co-Authored-By: Claude...` de cada uno, vía `git filter-branch`) y se hizo force-push. El
harness bloqueó automáticamente que Claude corriera `git push`/`filter-branch` directo — se le
dieron los comandos exactos a Santiago y los corrió él mismo, con éxito. **Ojo si se retoma
este repo desde otra copia/clon vieja:** hay que clonar de nuevo, un `git pull` normal no va a
funcionar después de esto.

### 16.4. Trabajo "aparte" que NO es CowControl (pero vive en esta carpeta)

Para otra materia/proyecto del colegio (servidores, con un servidor "Sandbox Playground" al
que se accede por Tailscale+SSH — `documentacion.md/nueva_task.md`), y a pedido de un
compañero (Naza) de "hacer una base de datos y un backend básico", se armó una carpeta
**totalmente aparte del código de CowControl**: `landing/` — un backend chico en Bun +
MongoDB que sirve una página explicando la app y un link de descarga del APK (con contador de
descargas). Se resolvió un bug real de conexión (DNS SRV de `mongodb+srv://` fallando en
Windows, arreglado forzando el DNS de Google solo para ese proceso). El APK se subió como
GitHub Release (`v1.0.0-apk`) para tener un link público de descarga sin pesar el repo. Se
generó también un par de claves SSH para el `nueva_task.md` (Tailscale/servidor del profesor).
**Nada de esto toca el código de la app Flutter** — es infraestructura de otro trabajo que
comparte carpeta por conveniencia de Santiago.

### 16.5. `Guia_Repaso-CowControl.pdf` — para la segunda revisión del proyecto

PDF de repaso rápido (Flutter/Dart en criollo, comandos de terminal más usados, estructura de
`lib/`, resumen de los cambios grandes, RLS vs. GRANT, y una sección de preguntas frecuentes
con respuesta corta ya armada) — pensado para que Santiago se prepare antes de una revisión
del proyecto. En `documentacion.md/`.

### 16.6. Cámara — arquitectura evaluada con workflow de 4 agentes, después el equipo propuso otra

Se corrió un `Workflow` (3 propuestas independientes de arquitectura + un chairman que las
evalúa) para decidir cómo grabar con la notebook "Juana Manso" y generar clips por lectura sin
n8n — ganó la opción "todo local" (Python + ffmpeg en la notebook, sin subir el video pesado a
ningún lado). Se armó `Funcion_Camara-CowControl.pdf` con el análisis completo (en
`documentacion.md/archivos.pdf/`, junto con el resto de los PDFs del proyecto — Santiago movió
ahí todos los PDFs sueltos que antes estaban directo en `documentacion.md/`).

Más adelante, revisando un export de WhatsApp del grupo de hardware
(`proyecto_ Lector automático de caravana.zip`), apareció que el equipo (Germaioni) está
armando algo distinto: **un solo video completo**, con el UID del animal superpuesto en el
momento justo (filtro `drawtext` de ffmpeg) en vez de cortar clips, y en la app un link que
salta directo al segundo exacto (como un timestamp de YouTube). Se agregó una sección 9 al
mismo PDF explicando los dos caminos **sin decidir por ninguno** (a pedido explícito de
Santiago) — con foco en explicar a fondo los límites reales de Supabase Storage (1GB total,
**50MB por archivo** — este último es el que puede chocar con un video completo largo, a
diferencia de los clips cortos que nunca se acercan). **Sigue sin decidirse cuál camino
tomar.**

### 16.7. Backend propio con JWT (Nazareno) — analizado, no se adopta

Santiago pidió revisar 25 capturas de una videollamada donde otro compañero (Nazareno) armaba
un backend con Fastify+Bun+SQLite+`jose` ("José, JSON" en la transcripción de voz = JWT), para
evaluar si aplicar algo similar a CowControl. Se encontró un bug real de inyección SQL en ese
código (concatenación directa de strings en las queries). Conclusión: **no hace falta** —
CowControl ya tiene JWT (vía Supabase Auth) + RLS por fila encima, más completo que lo que
mostraban las capturas, que nunca llegaron a construir ninguna lógica de autorización. Buen
argumento para la presentación, documentado en `cosas_pendientes.md` ítem 27.

### 16.8. `notebook.md` + PDF único de código fuente, para armar videos con NotebookLM

A pedido de Santiago, se armó un plan de 6 videos explicativos (`documentacion.md/notebook.md`)
para grabar con NotebookLM, empezando por lo que Flutter/Android generaron solos (Gradle,
config raíz) y siguiendo con `models/`, `services/`, `screens/`. Cada video tiene su prompt ya
redactado. Todo el código de fuente (25 archivos) quedó juntado en un solo PDF
(`archivos.pdf/codigo_fuente_notebooklm.pdf`), organizado por sección "VIDEO N", para subirlo
una sola vez como fuente y que cada prompt le diga a NotebookLM en qué apartado enfocarse.
Queda pendiente una segunda tanda (widgets/theme, base de datos a fondo, el análisis JWT del
16.7) para cuando Santiago la pida.

### 16.9. Pantalla 4 rediseñada (estilo menú de Instagram) + animales sin identificar

Varios cambios en cadena, todos probados y funcionando:
- **Rediseño de la Pantalla 4** (ficha del animal): de 3 cuadrados con ícono a una lista de
  filas estilo "Configuración y actividad" de Instagram (ícono + texto + flecha a la derecha,
  navega deslizando desde la derecha). Se agregó una 4ta fila, **"Video"**, con
  `video_screen.dart` como placeholder vacío (la función real depende de qué camino de cámara
  se elija — ver 16.6).
- Ajuste siguiente: el ícono de categoría dejó de estar solo — ahora comparte renglón con el
  ID del animal (mismo patrón que ya usan las tarjetas de la Planilla), y el AppBar de la
  Pantalla 4 volvió a mostrar el **nombre del campo** (no el ID del animal), consistente con el
  resto de las pantallas. Esto obligó a agregar un parámetro `campo` a `DetalleAnimalScreen` y
  actualizar los 2 lugares que navegan ahí (`planilla_screen.dart`, `conteo_screen.dart`).
- **Bug de copiado en el camino:** Santiago pegó un reemplazo en el lugar equivocado de
  `planilla_screen.dart` (rompió el botón de "Historial" en vez de tocar la navegación de
  `DetalleAnimalScreen`, porque el archivo tiene dos bloques `Navigator.push` parecidos) — se
  le dio el archivo completo corregido para pegar de una, sin ambigüedad.
- **Función real nueva: "animal sin identificar" (ítem 23, ya no pendiente).** Cuando una
  lectura no matchea ningún animal cargado, `conteo_screen.dart` la agrega a una lista
  `_sinIdentificar` en vez de descartarla — aparece en una sección aparte de la Pantalla 3, y
  tocarla abre un diálogo para elegir categoría; al confirmar, `AnimalesService.crearAnimal()`
  (nuevo) inserta el animal en Supabase. No hizo falta tocar SQL, el GRANT/RLS ya alcanzaba.
- **Cartel/llamado a la acción (ítem 29, ya no pendiente):** un aviso bordó (`#8B4038`,
  `AppColors.bordoAlerta`/`bordoAlertaFondo`, nuevos) visible en la Pantalla 3 mientras haya
  animales sin identificar, recomendando pasarlos de a 5 para dar tiempo a cargar género y
  tipo. Para esta parte puntual, Claude aplicó los cambios directo (no guiado) por la fricción
  reciente con el copiado manual — a confirmar con Santiago si prefiere volver al modo guiado
  para los próximos cambios chicos.
- **Pendiente:** probar todo esto con hardware/tags reales — Santiago no tiene tags a mano, lo
  va a probar Germaioni.

### 16.10. Ícono del splash nativo (ítem 22, ya no pendiente)

Se sacó el ícono mal recortado de la pantalla de carga de Android. La causa real: Android 12+
tiene su propia pantalla de splash de sistema, separada de `windowBackground`, y sin un
`values-v31/styles.xml` usa el ícono del launcher metido en una máscara circular que lo
recorta mal. Se creó ese archivo (más `values-night-v31` para modo oscuro) con el ícono puesto
en transparente y el mismo fondo crema de toda la app (`AppColors.fondo`), y se actualizó
también el splash viejo (pre-Android 12, antes blanco liso) al mismo crema. **Bug encontrado en
el camino:** los comentarios XML no aceptan `--` adentro — Gradle tiraba error de compilación
hasta que se cambió por raya (—). Confirmado con `flutter build apk --debug` exitoso.

### 16.11. Pivot de hardware: Raspberry Pi → ESP32

Revisando el export de WhatsApp del grupo de hardware, se confirmó que el equipo decidió
cambiar de Raspberry Pi a ESP32 — motivo real: la Pi de Germaioni a veces no prendía o no se
dejaba flashear (problema típico de corrupción de tarjeta SD), y para "pocos tags, prototipo"
un ESP32 es más confiable (arranca instantáneo, sin SD, más fácil de reflashear). Se confirmó
con Santiago que **esto no choca con nada de Supabase/Flutter** — la app y la base de datos no
saben ni les importa qué hardware escribe el POST. Pendiente, del lado del equipo: firmware
nuevo (equivalente a `rfid_tick.py` en Arduino/C++, a la espera del modelo exacto de ESP32),
actualizar la guía de hardware, y reescribir la carpeta técnica justificando el cambio.

### 16.12. Estado al cierre — pausado antes de regenerar el APK

Todo lo de la sección 16.9 y 16.10 está aplicado y compila limpio (`flutter analyze` → "No
issues found!", `flutter build apk --debug` exitoso), pero **sin probar con hardware real**
(Santiago no tiene tags). El plan era regenerar el APK de release y subirlo a GitHub (tanto el
archivo como el commit) para que Germaioni lo pruebe con tags de verdad. **Santiago pidió
esperar** — quiere revisar referencias de diseño (colores probablemente no cambian, pero sí
puede haber ajustes de forma/estilo) antes de generar ese APK. Este archivo se actualiza y se
cierra la sesión acá porque el chat se puso muy largo — **el chat nuevo que se abra debería
retomar directamente en: terminar de definir esas referencias de diseño con Santiago, aplicar
lo que corresponda, y recién ahí `flutter build apk --release` + commit + push a GitHub.**

---

## 17. Sesión 2026-09-13 (parte 2) — rediseño iterativo de la Planilla, y pantalla de Configuración con Cerrar sesión

Retoma exactamente donde cerró la sección 16.12: las referencias de diseño pendientes antes de
generar el APK de release. Se hizo a pura foto-y-ajuste: Santiago probaba por USB con
`flutter run` desde su propia terminal, mandaba una captura de WhatsApp por cada ronda, y se
corregía el detalle puntual que señalaba — unas 6 rondas en total sobre `planilla_screen.dart`
y `lib/widgets/animal_card.dart`. **Workflow mixto:** para los primeros cambios Santiago pidió
volver al modo aprendizaje (Claude da el archivo completo para pegar con Ctrl+A, Santiago lo
prueba); a mitad de sesión pidió que Claude vuelva a aplicar los cambios directo — ninguno de
los dos modos es "el definitivo", hay que preguntar/seguir la señal de cada pedido.

**Estado final de la Pantalla 2 (Planilla):**
- Buscador: sin label ni fondo blanco, solo el ícono de lupa, ahora dentro de un recuadro con
  borde marrón (`AppColors.marronPrincipal`) y fondo `AppColors.fondo` — mismo estilo que el
  filtro "Todas".
- Filtro "Todas": mismo recuadro con borde marrón, con `dropdownColor: AppColors.fondo` para
  que el menú desplegado (vaca/toro/ternero/ternera/vaquillona) use el mismo fondo que la
  pantalla en vez del beige más oscuro que traía por defecto Flutter; `underline: SizedBox()`
  le saca el subrayado que trae por default `DropdownButton`.
- Los dos recuadros (lupa y "Todas") están en `Expanded` con un `SizedBox(width: 16)` en el
  medio — ocupan cada uno la mitad de la fila sin tocarse — y los dos con `height: 48` fijo
  para que midan exactamente lo mismo verticalmente (antes el de la lupa quedaba más alto por
  el `TextField` adentro).
- Filas de animales (`AnimalCard` con `estiloPlanilla: true`): pasaron por 3 diseños distintos
  en esta sesión (tarjeta con círculo → fila plana con línea divisoria estilo Instagram →
  recuadro bordeado → **fila plana sin recuadro, solo separada por más espacio vertical**, que
  es donde quedó). El tick (círculo detectado/no detectado) volvió a estar presente aunque en
  la Planilla nunca se marca (siempre queda vacío, `detectado` no se le pasa) — es el mismo
  ícono que en el Conteo, solo que ahí sí cambia de color al pasar el tag. Separación vertical
  entre animales duplicada (de 10 a 20px de padding arriba/abajo de cada fila).
- Alineación horizontal: el título del campo (AppBar, `centerTitle: false` + `titleSpacing: 12`),
  el ícono de la lupa y el círculo de cada animal quedan a la misma distancia del borde
  izquierdo que el ícono de Configuración (ver más abajo) tiene del borde derecho — se calculó
  con el modelo real de cajas de Flutter (un `IconButton` mide 48px con el ícono de 24px
  centrado adentro, de ahí sale el margen de 12px), no a ojo sobre la captura.
- Botón "Iniciar Conteo": fondo `AppColors.marronPrincipal` (antes usaba el naranja por
  default del tema) y el texto con mayúscula en "Conteo" (antes "conteo", que en el celular de
  Santiago se veía cortado como "onteo").

**Pantalla nueva: `ConfiguracionScreen`.** El ícono de Historial que estaba directo en el AppBar
de la Planilla se reemplazó por un ícono de tuerca (`Icons.settings`) que navega a esta pantalla
nueva, con dos filas estilo menú (mismo patrón `_FilaMenu`/`ListTile` que ya usaba la Pantalla 4):
- **Historial de lecturas** — mismo destino de antes (`HistorialScreen`), ahora un nivel más
  adentro.
- **Cerrar sesión** — pide confirmación (`AlertDialog` con "Sí"/"No"); si confirma, llama a
  `AuthService().cerrarSesion()` y navega con
  `Navigator.pushAndRemoveUntil(LoginScreen, (route) => false)`. **Ojo con esto si se toca el
  logout que ya existía en `selector_campo_screen.dart`:** ese botón viejo confía en que
  `AuthGate` (en `main.dart`) reaccione solo al cambio de sesión — funciona ahí porque
  `SelectorCampoScreen` es literalmente lo que `AuthGate` renderiza en ese momento. Pero cuando
  hay un solo campo, `SelectorCampoScreen` navega a la Planilla con **`pushReplacement`** (no
  `push`), lo que saca a `AuthGate` del árbol de widgets por completo — si se cerrara sesión
  desde ahí sin navegar a mano, la app se quedaría trabada en una pantalla con la sesión ya
  vencida. Por eso `ConfiguracionScreen` no confía en `AuthGate` y navega explícitamente.

**Sin probar en el celular todavía** (esta sección se cierra con `flutter analyze` limpio nada
más) — es lo primero que hay que confirmar en la próxima ronda: que el logout funcione tanto
viniendo del camino de un solo campo como del de varios, y que la nueva Configuración se vea
bien. Después de eso, retomar el pendiente real de la 16.12: `flutter build apk --release` +
commit + push a GitHub.

---

## 18. Sesión 2026-09-14 — sin flechas en los botones, filas estilo Google, Condición Corporal, vacunas/observaciones como lista

Chat nuevo (el anterior se cerró largo, ver cierre de la sección 17). Confirmado con capturas
al arrancar: los 8 cambios de la sesión 17 (Configuración con logout, recuadros de la Planilla)
funcionan bien en el celular por USB.

**Sin flechas.** Se sacó el símbolo `>`/`▾`/`▶` de los 8 elementos pedidos: cada fila de
animal, "Historial de lecturas", "Fertilidad"/"Vacunas"/"Observaciones"/"Video", el
desplegable "Todas", y "Iniciar Conteo" (este último obligó a cambiar `ElevatedButton.icon` por
`ElevatedButton` simple, porque esa variante exige un ícono). Ojo señalado: sin el `>` se pierde
la pista visual de que las filas son tocables — Santiago lo tiene presente, no se revirtió nada.

**Filas de animales, estilo "Cuenta de Google".** A pedido de Santiago (con captura del menú de
cuenta de la Play Store como referencia), `AnimalCard` con `estiloPlanilla: true` volvió a tener
recuadro — esta vez muy redondeado (`BorderRadius.circular(20)`, borde marrón, fondo
`AppColors.fondo`), imitando las filas "Cuenta de Google" / "Obtené un plan Google AI" de esa
captura. Se sacó el truco del `SizedBox(width: 48)` que alineaba el tick con la lupa (ya no
aplica con recuadros individuales).

**Vacunas — historial completo en vez de "última vacuna".** `VacunasService.traerUltimaVacuna`
(con `.limit(1)`) se reemplazó por `traerVacunas` (sin límite, mismo orden por `fecha_vacuna`
descendente). `vacunas_screen.dart` ahora tiene el formulario de carga arriba y la lista
completa abajo, la más nueva primero.

**"Fertilidad" vuelve a llamarse "Condición Corporal".** Segunda vuelta de nombre para el mismo
dato (`buena`/`regular`/`mala`) — la primera vez fue al revés, `condicion_corporal` →
`fertilidad`, el 2026-08-03 (sección 9). Se mantiene el mismo dropdown de 3 opciones, sin
migrar a una escala numérica real — Santiago lo confirmó explícitamente al preguntarle (no
quería el trabajo extra de cambiar el tipo de dato ni el formulario). Se le agregó al lado de
cada opción el rango de referencia de la escala de Condición Corporal 1 a 5 que usa el INTA
("Buena de 4 a 5", "Regular de 2.5 a 3.5", "Mala de 1 a 2") — es solo texto en la pantalla, no
se guarda como número. Migración corrida por Santiago en el SQL Editor de Supabase
(`fertilidad` → `condicion_corporal`, columna y constraint), confirmada con captura. Detalle
completo del SQL, con la aclaración de que este es un nombre de columna reciclado y no la
misma columna numérica que tuvo `condicion_corporal` en la Migración v1, en `base_datos.md`.

**Observaciones — pasa a ser una lista, no un solo texto que se pisa.** Mismo patrón que
`datos_vacuna`: tabla nueva `datos_observacion` (`id`, `id_animal`, `texto`, `creado_en`), RLS
igual que vacunas, `GRANT SELECT, INSERT` incluido de entrada. **Ya creada en Supabase**
(confirmada por Santiago con captura, "Success. No rows returned"). **Pendiente: el código
Flutter todavía no la usa** — `observaciones_screen.dart` sigue leyendo/escribiendo
`datos_animales.observaciones` (el texto viejo, que queda intacto sin tocar). Falta: modelo
`Observacion`, `ObservacionesService` (`traerObservaciones`/`agregarObservacion`, calcado de
`VacunasService`), y rehacer `observaciones_screen.dart` con un cuadro de texto chico arriba
para cargar una nueva y la lista completa abajo (más nueva primero, ordenada por `creado_en`,
no por una fecha que el productor elija — a diferencia de vacunas, acá no hay selector de
fecha). **Es el primer pendiente para retomar en el próximo mensaje de este mismo chat.**

**Paleta de colores nueva (2026-09-14, misma tarde).** Santiago trajo `colores_para_app.png`
(degradé de 7 marrones/naranjas de una herramienta de paletas) porque el marrón del AppBar se
sentía "súper oscuro" para un productor/peón. Se preguntó antes de tocar el tema global
(`app_theme.dart`) — Santiago confirmó la propuesta tal cual: `marronPrincipal` (AppBar,
botones, bordes) pasa de `#6F4A31` a `#964B00`; `marronOscuro` (texto) de `#4A2E1E` a
`#422100`; `naranjaTostado` (acentos) de `#C77C3B` a `#B25900`; y se sumó `tostadoClaro`
(`#DE924F`, tono nuevo que no existía) para el borde de los `OutlinedButton` ("Finalizar",
"Elegir fecha"), dándoles una identidad visual distinta a los botones principales.

**Pantalla nueva: `InformacionPersonalScreen`.** Se agregó entre "Historial de lecturas" y
"Cerrar sesión" en Configuración. Muestra el email y el nombre de los campos del productor,
pero **tapados con un blur marrón** (`ImageFiltered` + `Container` semitransparente encima) hasta
que el productor escribe su contraseña actual y toca "Ver datos" — la contraseña se **verifica
de verdad** contra Supabase (`AuthService.verificarPasswordActual`, reintenta el login con el
mismo mail; no existe un endpoint de "verificar sin loguear" en Supabase Auth, así que el login
mismo hace de verificación). Dos filas más abajo, separadas por un `Divider`:
- **"Cambiar contraseña"** → pantalla nueva `CambiarPasswordScreen`, mismo checklist visual que
  el registro (8 caracteres + letra + número, `_reglaPassword` calcado de `login_screen.dart`).
  A diferencia del registro, pide la contraseña **actual** primero y la verifica antes de dejar
  poner la nueva (`AuthService.cambiarPassword`, usa `auth.updateUser` — no manda ningún mail,
  actúa directo sobre la sesión activa, por eso funciona ya mismo).
- **"¿Olvidaste tu contraseña?"** → mismo flujo de siempre (`restablecerPassword`, manda mail).
  Explícitamente **sigue sin funcionar del todo** — depende del problema de entrega/spam del
  mail (`cosas_pendientes.md` ítem 21) que sigue sin resolverse. Santiago lo pidió igual acá "por
  las dudas" (le pasó alguna vez olvidarse la contraseña con la sesión abierta en otro lado) y
  aceptó explícitamente dejarlo así hasta que se arregle el mail — no es un bug nuevo, es el
  mismo pendiente viejo asomando en un lugar más.

**Condición Corporal — números a la izquierda, categoría a la derecha.** El desplegable pasó de
un solo `Text('Buena (de 4 a 5)')` a una fila `_FilaCondicion` con `spaceBetween` (rango
numérico a la izquierda, "Buena"/"Regular"/"Mala" a la derecha) — mismo patrón que ya usaba el
filtro de categoría de la Planilla.

**Sin probar en el celular todavía** — cierra con `flutter analyze` limpio nada más. Falta
confirmar por USB: el blur se ve bien, la verificación de contraseña anda (correcta e
incorrecta), y el cambio de contraseña funciona de punta a punta.

**Se retomó el problema del mail/PKCE (mismo día, más tarde) — resuelto sin tocar el flujo
global.** Santiago pidió atacar en serio el pendiente viejo de `docs/restablecer.html`
trabado (ver ítem 21 de `cosas_pendientes.md`) y de paso rediseñar `confirmacion.html` y
`restablecer.html` con los colores nuevos. Se investigó con un agente en background (con
acceso a internet, dado que el conocimiento de Claude tiene fecha de corte de enero de 2026 y
Supabase pudo haber cambiado desde entonces) qué hace falta para arreglar esto de verdad.

- **Hallazgo:** Supabase ya manda un código de 6 dígitos en el mail de recuperación (variable
  de plantilla `{{ .Token }}`), pero la plantilla default de "Reset Password" no lo incluye.
  Confirmando el código **adentro de la app** (no tocando ningún link), el problema de origen
  (PKCE guardado en el storage de la app, usado después en el navegador) directamente no
  existe — no hace falta cambiar `AuthFlowType` global ni armar deep links, las dos opciones
  invasivas que se habían evaluado en agosto y nunca se aplicaron.
- **Implementado:** `AuthService.confirmarCodigoRecuperacion()` (`verifyOTP` +
  `updateUser`), pantalla nueva `VerificarCodigoScreen` (código + contraseña nueva con el
  mismo checklist de siempre), conectada desde los dos lugares que piden el mail
  (`login_screen.dart` y `informacion_personal_screen.dart`). De paso, el checklist de
  contraseña (que ya se repetía en 3 pantallas) se extrajo a un widget compartido,
  `widgets/password_checklist.dart`.
- **Pendiente de un paso manual de Santiago en el dashboard de Supabase:** editar la plantilla
  de mail "Reset Password" (`Authentication → Email Templates`) para que muestre
  `{{ .Token }}` — sin ese cambio, el mail nunca va a traer el código, aunque el código Flutter
  ya esté listo para recibirlo. `docs/restablecer.html` (el link viejo) queda como estaba, sin
  arreglar — ya no es el camino principal, pero sigue ahí de respaldo.
- **Deliverability del mail (spam):** se investigó migrar a Resend, pero requiere comprar un
  dominio propio (~10 USD/año) para las verificaciones SPF/DKIM. **Santiago eligió no hacerlo
  por ahora** (falta poco para la expo, prefiere no sumar costo/superficie de fallo) — sigue
  con el SMTP de Gmail configurado en agosto (ítem 12 de `cosas_pendientes.md`), sin cambios.
- **Sin probar de punta a punta todavía** — falta que Santiago edite la plantilla en Supabase y
  pruebe el flujo completo (pedir código, recibir el mail, escribirlo en la app, confirmar que
  cambia la contraseña de verdad).

---

## 20. Sesión 2026-09-15 a 2026-09-16 — bug de contraseña corrompida, feedback de Germaioni, APK que no actualizaba, y Observaciones como lista

Continúa directo desde el cierre de la sección 18 (el pendiente de Observaciones quedó
"primero para retomar en el próximo mensaje de este mismo chat" — se retomó en esta sesión, al
final, punto 20.7). En el medio pasaron varias cosas más, todas en el mismo chat largo.

### 20.1. Bug real encontrado: `onChanged: setState` en un `TextField` puede corromper lo que se está tipeando

Santiago reportó que, probando el cambio de contraseña dos veces por dos flujos distintos,
el login fallaba después con "credenciales inválidas" sin ningún error visible en el momento
de cambiarla. Se investigó con un **agente en background** (autorizado explícitamente por
Santiago) descartando primero explicaciones más simples (rate limit, necesidad de re-login,
carrera de sesión) con evidencia concreta (códigos de error HTTP, lectura del código fuente de
`gotrue_client.dart`).

**Causa real encontrada:** en `login_screen.dart`, `cambiar_password_screen.dart` y
`verificar_codigo_screen.dart`, el campo de contraseña tenía `onChanged: (_) => setState(() {})`
para actualizar en vivo el checklist visual (○/✓ por regla cumplida). Eso fuerza a Flutter a
reconstruir el `TextField` en cada tecla — en Android, si el teclado (IME) todavía tiene una
"composing region" activa (típico de autocorrección/predicción), esa reconstrucción puede
desincronizar lo que el teclado está armando de lo que el controller realmente tiene guardado,
**sin ningún error visible**: la contraseña que termina en el controller no es necesariamente
la que el usuario ve escrita en pantalla.

**Arreglo aplicado en los 3 archivos:** se sacó el `onChanged` del `TextField` (que ya no se
reconstruye nunca) y el checklist se movió a un `ValueListenableBuilder<TextEditingValue>`
escuchando al mismo `TextEditingController` — se actualiza solo, sin tocar el campo de texto.
Mismo patrón reutilizado después en el buscador de la Planilla (ver 20.3).

### 20.2. `docs/confirmacion.html` y `docs/restablecer.html` — rediseño con la paleta de marca

De paso con lo de arriba, se rediseñaron las dos páginas HTML (`docs/`, servidas por GitHub
Pages) para que dejen de sentirse genéricas: se sacó el verde del tilde de éxito y el rojo
genérico de error (`#B3261E`), reemplazado por `AppColors.bordoAlerta` (`#8B4038`) para
errores y los marrones/naranjas de la app para todo lo demás; se agregó el emoji 🐾 y la
palabra "COWCONTROL" como cabecera de marca, tarjeta con bordes redondeados. **La lógica en
JavaScript de `restablecer.html` no se tocó** (el `onAuthStateChange`/`getSession` que
todavía se cuelga por el problema de PKCE, sección 15.9/16.1/18 — sigue sin arreglarse a
propósito, es solo un camino de respaldo ahora que el flujo principal es el código OTP dentro
de la app).

### 20.3. Feedback real de un compañero (Germaioni, por WhatsApp) — dos bugs corregidos

Germaioni probó el APK y reportó por WhatsApp (chat exportado, compartido tal cual) varios
puntos; Santiago aclaró cuáles corregir y cuáles no ("lo de las vacunas no toques, pero sí lo
del código muerto"):

- **Buscador de la Planilla no mostraba resultados al escribir.** Mismo bug de fondo que 20.1
  (`onChanged: (valor) => setState(() => _busqueda = valor)` directo en el `TextField` de
  búsqueda de `planilla_screen.dart`). Arreglado con el mismo patrón: `TextEditingController`
  sin `onChanged`, lista de animales envuelta en `ValueListenableBuilder<TextEditingValue>`.
  `_filtrar()` pasó a recibir la búsqueda como parámetro en vez de leer un campo de estado.
- **"No se guarda la info de fertilidad ni observaciones."** No era un bug de guardado —
  Supabase sí recibía el `UPDATE`. El bug real: `DetalleAnimalScreen` (Pantalla 4) recibía el
  `Animal` por parámetro una sola vez al entrar y nunca lo volvía a pedir, así que después de
  editar Condición Corporal y volver, la pantalla seguía mostrando el dato viejo — parecía que
  no se había guardado nada. **Arreglo:** se agregó `Animal.copyWith(...)` (con un sentinel
  privado `_noTocado` para poder distinguir "no tocar este campo" de "ponerlo en null" a
  propósito), `CondicionCorporalScreen` ahora hace `Navigator.pop(animalActualizado)`, y
  `DetalleAnimalScreen` pasó de `StatelessWidget` a `StatefulWidget` con un helper `_abrir()`
  que espera el resultado y actualiza `_animal` con `setState`.

### 20.4. Bug de Android: el `versionCode` de `pubspec.yaml` nunca se había incrementado

Con los dos bugs de arriba corregidos, Santiago reenvió el APK por WhatsApp y varios
compañeros seguían viendo la UI vieja. Investigado por código y confirmado con
`git log -p -- pubspec.yaml`: la línea `version: 1.0.0+1` **jamás cambió desde que se creó el
proyecto**. Android usa ese `+N` como `versionCode`, y el instalador de Android **se niega a
tratar un APK como "actualización" si el `versionCode` no es estrictamente mayor** al ya
instalado — por eso tocar "actualizar" desde WhatsApp no hacía nada visible. Esto quedaba
oculto en todas las pruebas de Santiago porque él siempre instala con
`adb install -r` (que sí fuerza el reemplazo sin mirar el `versionCode`). **Arreglo:**
`version: 1.0.0+1` → `1.0.1+2`. Confirmado en el APK generado con
`aapt2 dump badging` (`versionCode='2' versionName='1.0.1'`).

### 20.5. `C:\dev\CowControl.apk` revertido solo a un archivo de dos semanas atrás — causa desconocida

Un compañero probó en un celular que **nunca había tenido la app instalada** y aun así vio la
UI de antes del 13 de septiembre. Se comparó `C:\dev\CowControl.apk` contra
`apk_para_probar\CowControl.apk` (las dos copias de siempre, deberían ser idénticas): tamaño
distinto (~53.9MB vs. ~54.16MB) y hash MD5 distinto — `C:\dev\CowControl.apk` había vuelto a
ser, literalmente, el archivo del 1° de septiembre. **No se pudo confirmar la causa** (se le
preguntó directo a Santiago si recordaba haber sobrescrito el archivo; no lo confirmó). Se
descartó que fuera un symlink/junction raro. **Arreglo:** se volvió a copiar el build actual
sobre ese archivo y se confirmó con MD5 que las dos copias vuelven a ser byte-por-byte
idénticas.

### 20.6. Investigación en el Moto E13 por ADB — el código y el APK están bien, el problema queda aislado a WhatsApp

Con los dos bugs de arriba ya corregidos, Santiago reenvió el APK por WhatsApp una vez más y
**seguía viendo la UI vieja** en el mismo celular de prueba. Se activaron Opciones de
Desarrollador + Depuración USB en el Moto E13 con Santiago (le costó encontrar el menú) y se
conectó por ADB (`ZY22JFVHTK`). Con `adb shell dumpsys package com.cowcontrol.app_cowcontrol`
se confirmó que la app instalada **seguía marcando `versionCode=1`/`versionName=1.0.0`**, a
pesar de que Santiago acababa de "actualizarla" desde WhatsApp esa misma sesión — prueba
directa de que el archivo que le llegó por WhatsApp **no era** el corregido.

Para separar de una vez "problema de código" de "problema de transferencia", se instaló el
APK correcto directo por `adb install -r`, se confirmó `versionCode=2`/`versionName=1.0.1` con
el mismo `dumpsys`, y se sacó una captura de pantalla real (`adb exec-out screencap`) mostrando
la app corriendo con la UI nueva (ícono de tuerca, "Iniciar Conteo" con mayúscula, recuadros
sin flechas). **Conclusión confirmada con evidencia dura, no solo por reporte visual:** el
código y el APK generado están 100% correctos; el problema restante vive específicamente en
**cómo WhatsApp entrega/cachea el archivo** al celular receptor — mecanismo exacto sin
confirmar (un agente de investigación encontró baja confianza para "WhatsApp cachea por
nombre de archivo"; lo único documentado es que WhatsApp normalmente agrega "(1)" al nombre en
vez de servir un archivo viejo silenciosamente). **Mitigación dada a Santiago** (no un arreglo
de código): adjuntar el archivo de nuevo cada vez desde el selector de archivos (no reenviar
un mensaje viejo), verificar la fecha que muestra el chat antes de instalar, y borrar del
celular receptor cualquier descarga previa con el mismo nombre antes de instalar la nueva.
**Este punto queda abierto** — no se le va a poder hacer más seguimiento sin que alguien
reporte que se repite.

### 20.7. Observaciones pasa a ser una lista de verdad (cierre del pendiente de la sección 18) + swap de Condición Corporal

Santiago reportó que "las observaciones no terminan de cargar": escribía una, tocaba
"Guardar", la pantalla cargaba, pero el texto se borraba y no aparecía nada guardado debajo.
**No era un bug nuevo** — era el pendiente que había quedado abierto al cierre de la sesión 18:
la tabla `datos_observacion` ya existía en Supabase desde el 14/09, pero el código Flutter
todavía nunca se había actualizado para usarla (seguía leyendo/escribiendo el campo viejo
`datos_animales.observaciones`, que se pisa entero cada vez). Confirmado con Santiago vía
pregunta directa — eligió terminar la funcionalidad ahora, con el mismo patrón que ya usa
Vacunas (cuadro chico arriba para cargar una nueva, lista completa abajo, la más nueva
primero):

- **`lib/models/observacion.dart`** (nuevo) — `idAnimal`/`texto`/`creadoEn`, con
  `Observacion.fromMap`.
- **`lib/services/observaciones_service.dart`** (nuevo) — `ObservacionesService` calcado de
  `VacunasService`: `traerObservaciones(animalId)` (`.order('creado_en', ascending: false)`) y
  `agregarObservacion({idAnimal, texto})` (`insert`, sin fecha manual — la pone Supabase sola).
- **`lib/screens/observaciones_screen.dart`** reescrita completa: `TextField` +
  "Agregar observación" arriba, `FutureBuilder<List<Observacion>>` + `ListView.separated` con
  el historial completo debajo. Ya no depende de `Animal.observaciones` ni devuelve nada al
  hacer `pop()` — es autónoma, como `VacunasScreen`.
- **`lib/services/animales_service.dart`** — `actualizarAnimal()` se simplificó, ya no recibe
  ni escribe `observaciones` (solo `condicionCorporal`); el campo
  `datos_animales.observaciones` queda intacto en la base pero sin uso desde la app de acá en
  más (se decidió no borrar la columna ni el campo del modelo — no rompe nada dejarlo).
- **`lib/screens/detalle_animal_screen.dart`** — el comentario de la clase se corrigió para
  reflejar que solo Condición Corporal devuelve el animal actualizado al hacer `pop`;
  Observaciones sigue pasando por el mismo helper `_abrir()` sin problema (si el `pop` no trae
  valor, simplemente no actualiza `_animal`).
- **De paso, pedido explícito de Santiago:** en el desplegable de Condición Corporal se
  intercambiaron los lados — ahora la categoría (Buena/Regular/Mala) queda a la **izquierda** y
  el rango numérico de referencia a la **derecha** (`_FilaCondicion` en
  `condicion_corporal_screen.dart`), al revés de como había quedado en la sesión 18.

**Verificado en esta sesión:** `flutter analyze` limpio ("No issues found!") con todo el lote
junto. Se generó `flutter build apk --release` y se copió a las dos ubicaciones de siempre
(`C:\dev\CowControl.apk` y `apk_para_probar\CowControl.apk`), confirmando MD5 idéntico entre
las tres copias y `versionCode=2`/`versionName=1.0.1` con `aapt2`. **No se pudo verificar
visualmente en el Moto E13** (ya no estaba conectado por USB al momento de probar) — queda
para la próxima vez que se conecte, instalar con `adb install -r` y confirmar con captura que
la lista de Observaciones y el swap de Condición Corporal se ven bien.

### 20.8. Estado de git al cierre de esta sesión — nada commiteado a propósito

Por pedido explícito de Santiago ("en GitHub no tocar nada por ahora sino solucionar sí o sí
el APK... así reenvío nuevamente con las modificaciones hechas"), **todo lo de esta sesión
(20.1 a 20.7) sigue sin commitear** — vive solo en el working directory y ya horneado en el
`.apk` regenerado. `git status` al cierre:
```
M lib/models/animal.dart
M lib/screens/condicion_corporal_screen.dart
M lib/screens/detalle_animal_screen.dart
M lib/screens/observaciones_screen.dart
M lib/screens/planilla_screen.dart
M lib/services/animales_service.dart
M pubspec.yaml
?? lib/models/observacion.dart
?? lib/services/observaciones_service.dart
```
(además de carpetas de fotos para Trello y `landing/`, que ya se excluyen de los commits de
CowControl por convención — ver sección 16.4). **No commitear ni pushear nada de esto sin que
Santiago lo pida explícitamente** — la instrucción se repitió más de una vez en el proyecto.

---

## 21. Mapa rápido para el próximo chat — cámara y lectura de tags

Santiago pidió dejar esto bien aclarado antes de cerrar este chat (se compactó mucho), porque
son las dos partes del proyecto donde más se pregunta "¿esto dónde estaba?". Ninguna de las dos
tiene código de cámara real todavía — son, sobre todo, arquitectura ya definida y documentos de
diseño, con la parte de tags (RFID/NFC) sí funcionando de punta a punta en la app.

### Función de cámara (video por lectura) — nada implementado en la app todavía

- **`documentacion.md/archivos.pdf/Funcion_Camara-CowControl.pdf`** — el documento con **todo**
  el análisis: arquitectura elegida (Camino A: clips cortos de 2-3s, Python+ffmpeg local en la
  notebook, sin subir video pesado a ningún lado) vs. la que después propuso el equipo de
  hardware (Camino B: un video completo con el UID superpuesto vía `drawtext` de ffmpeg + un
  link en la app que salta al segundo exacto), y el análisis de los límites de Supabase Storage
  (1GB total, **50MB por archivo** — el límite que puede chocar con el Camino B). **Sigue sin
  decidirse cuál camino tomar** — ver sección 16.6 de este archivo para el resumen narrado.
- **`lib/screens/video_screen.dart`** — el único código que existe hoy del lado de la app: un
  placeholder vacío. Se accede tocando "Video" en la Pantalla 4 (ficha del animal,
  `lib/screens/detalle_animal_screen.dart`). No hace nada todavía porque la función real
  depende de qué camino (A o B) se termine eligiendo.
- **`documentacion.md/cosas_pendientes.md`**, ítem 26 — la entrada original del pendiente, con
  el detalle más largo de cómo se llegó a este punto.

### Lectura de tags NFC/RFID (que un animal se vea marcado al pasar por el lector) — esto sí funciona de punta a punta

- **Cómo llega el dato:** un lector físico (antes Raspberry Pi, ahora **ESP32** — pivot de
  hardware confirmado en la sección 16.11 de este archivo) lee el tag y hace un `POST` a la
  tabla `datos_lectura` en Supabase usando la `service_role key` (bypassea login/RLS). La app
  nunca habla directo con el hardware — todo pasa por Supabase (ver sección 2 de este archivo).
- **`lib/services/lecturas_service.dart`** — se suscribe a `datos_lectura` por **Supabase
  Realtime** (websocket, no polling) para que el tilde de "detectado" aparezca en el momento en
  que el lector marca al animal, sin que el productor tenga que refrescar nada.
- **`lib/screens/conteo_screen.dart`** — Pantalla 3, conteo en vivo. Acá está toda la lógica de
  qué hacer con cada lectura que llega:
  - Si el `rfid_uid` de la lectura coincide con un animal ya cargado en `datos_animales`, se
    marca con el tilde correspondiente en la lista.
  - **Si el tag no coincide con ningún animal cargado** ("tag desconocido"), no se descarta: se
    agrega a una lista aparte, `_sinIdentificar` (ver sección 16.9 de este archivo), visible en
    su propia sección de la pantalla. Tocarlo abre un diálogo para elegir categoría, y
    `AnimalesService.crearAnimal()` (en `lib/services/animales_service.dart`) da de alta el
    animal nuevo en Supabase con ese `rfid_uid`.
  - Hay un cartel bordó que avisa mientras haya animales sin identificar, sugiriendo pasarlos
    de a 5 para dar tiempo a cargarles la categoría (mismo lugar, sección 16.9).
- **`lib/services/conteos_service.dart`** — maneja el ciclo de vida del conteo en sí
  (`iniciarOReanudar`/`pausar`/`reanudar`/`finalizar`, tabla `conteos`), independiente de la
  lectura de tags puntual pero en la misma pantalla (sección 16.2 de este archivo).
- **Documentación para el equipo de hardware** (fuera del código Flutter, pero explica el
  contrato exacto que espera la app):
  - **`documentacion.md/Guia_Raspberry_Pi-CowControl.pdf`** + `rfid_tick.py` (mismo contenido en
    texto plano al lado) — credenciales que necesita el hardware, formato exacto del `POST` a
    `datos_lectura`, y un script de referencia funcional en Python (sección 15.9 de este
    archivo). El nombre quedó con "Raspberry Pi" por historia, aunque el hardware real ya
    pivotó a ESP32 (sección 16.11) — el contrato con Supabase no cambió, solo el chip que lo
    implementa.
  - **`documentacion.md/base_datos.md`** — schema completo de `datos_lectura` y el resto de las
    tablas, con el razonamiento de por qué la app nunca habla directo con el hardware.
- **Sin probar con hardware/tags físicos reales todavía** — Santiago no tiene tags a mano; lo
  prueba Germaioni cuando recibe el APK actualizado (ítem 18 de la sección 7, sigue abierto).

---

## 22. Meta

Este archivo lo generó Claude a pedido de Santiago, al cierre de una sesión larga, porque el
sistema de memoria interno de Claude Code queda atado a la carpeta de trabajo — y como el
proyecto se mudó de carpeta (OneDrive → `C:\dev\CowControl\`), un chat nuevo abierto acá no
hereda esa memoria automáticamente. Este documento reemplaza esa continuidad. **Mantenerlo
actualizado** cuando haya decisiones grandes nuevas, para que sirva el día que haga falta
abrir otro chat desde cero.

**Cierre de la sesión 2026-09-16:** chat compactado varias veces por lo largo que se puso —
se cierra acá y Santiago va a abrir uno nuevo. **El chat nuevo debería leer primero la sección
20 completa** (todo lo que se hizo desde el cierre de la sección 18: bug de contraseña
corrompida, feedback de Germaioni, bug de versionado de Android, APK revertido, investigación
en el Moto E13, y el cierre de Observaciones como lista) y **la sección 21** si la próxima
tarea tiene que ver con cámara o con lectura de tags. Recordar que todo lo de la sección 20
sigue **sin commitear a git** (20.8) — no pushear nada sin que Santiago lo pida.
