Para qué sirve cada archivo/carpeta de app_cowcontrol
=======================================================

Esto explica, uno por uno, todos los archivos y carpetas que hay en la raíz de
C:\dev\CowControl\app_cowcontrol — para que Santiago entienda qué es cada cosa antes de
decidir qué se puede borrar y qué no. Es la base para, más adelante, armar la documentación
línea por línea / bloque por bloque en PDF (eso es una tarea aparte, todavía no se hizo).

No se borró nada todavía. Esto es solo explicación.


1. DE DÓNDE SALIÓ TODO ESTO (para la duda de "qué instalé")
-------------------------------------------------------------
El SDK de Flutter (el programa que sabe compilar este proyecto) está instalado una sola vez
en la PC, en C:\flutter_sdk\flutter — está FUERA de esta carpeta del proyecto, porque es una
herramienta de la PC, no algo que viaje con el código. Cualquier proyecto Flutter que se cree
en esta PC usa ese mismo SDK compartido.

Esta carpeta (app_cowcontrol) nació con el comando `flutter create`, que arma automáticamente
toda la estructura de abajo — un montón de estas carpetas y archivos los genera Flutter solo,
sin que nadie los haya escrito a mano.


2. NUESTRO CÓDIGO — lo único que escribimos nosotros
-------------------------------------------------------------

lib/
  Toda la app está acá adentro. Es lo único que de verdad "programamos". Se organiza en:

  main.dart
    El punto de arranque de la app. Carga el archivo .env, inicializa la conexión a
    Supabase, y decide si mostrar la pantalla de login o la de selector de campo (según si
    ya hay una sesión guardada).

  theme/app_theme.dart
    La paleta de colores (marrón/tierra) y los estilos generales (botones, tipografía) que
    usa toda la app, en un solo lugar para no repetir estilos en cada pantalla.

  models/
    Cuatro archivos, uno por cada tabla de Supabase que la app necesita leer. Cada uno es
    solo una "forma" de datos en Dart (una clase), sin lógica — representan una fila de la
    tabla correspondiente:
      - campo.dart    -> datos_campo
      - animal.dart   -> datos_animales
      - lectura.dart  -> datos_lectura
      - vacuna.dart   -> datos_vacuna

  services/
    Seis archivos. Cada uno sabe hablar con Supabase para UNA cosa puntual (traer datos,
    guardar, escuchar cambios). Las pantallas nunca hablan con Supabase directo, siempre
    pasan por un service:
      - supabase_service.dart  -> el cliente único de Supabase, del que dependen todos los
                                   demás services.
      - auth_service.dart      -> login, registro, cerrar sesión.
      - campos_service.dart    -> traer los campos del productor logueado, crear uno nuevo.
      - animales_service.dart  -> traer los animales de un campo, y el detalle de uno solo.
      - lecturas_service.dart  -> historial de lecturas + la suscripción en tiempo real
                                   (Realtime) que hace posible el tilde en vivo.
      - vacunas_service.dart   -> la última vacuna aplicada a un animal.

  screens/
    Seis archivos, uno por cada pantalla de la app (las 6 que se definieron en el plan):
      - login_screen.dart            -> Pantalla 0: login/registro.
      - selector_campo_screen.dart   -> Pantalla 1: elegir/crear campo.
      - planilla_screen.dart         -> Pantalla 2: planilla general del ganado.
      - conteo_screen.dart           -> Pantalla 3: conteo en vivo (tiempo real).
      - detalle_animal_screen.dart   -> Pantalla 4: ficha de un animal.
      - historial_screen.dart        -> Pantalla 5: historial de lecturas.

  widgets/
    Tres piezas visuales chicas que se reusan en más de una pantalla, para no repetir
    código:
      - animal_card.dart       -> la tarjeta de un animal (se usa en Planilla y Conteo).
      - categoria_badge.dart   -> la etiqueta de categoría (vaca/toro/ternero/etc).
      - fertilidad_chip.dart   -> la etiqueta de fertilidad (buena/regular/mala).

.env
  Las dos credenciales de Supabase (SUPABASE_URL y SUPABASE_ANON_KEY), en un archivo aparte
  en vez de escritas directo en el código — así, si algún día hay que cambiarlas, se edita
  un solo archivo chico y no hay que tocar el código de la app. Se declara como "asset" en
  pubspec.yaml para que la app pueda leerlo al arrancar (con el paquete flutter_dotenv).

test/
  Carpeta donde Flutter espera que vivan los tests automatizados del proyecto (pruebas de
  código que se corren solas para detectar errores). Hoy está vacía — no se armó ningún test
  todavía. No es un error, es una tarea pendiente y opcional para más adelante si el equipo
  quiere sumar pruebas automáticas.


3. ARCHIVOS DE CONFIGURACIÓN EN LA RAÍZ (los tocamos poco o nada, pero son necesarios)
-------------------------------------------------------------

pubspec.yaml
  El "manifiesto" del proyecto: nombre, versión, qué paquetes externos usa (supabase_flutter,
  flutter_dotenv, etc.) y qué "assets" (archivos extra, como el .env) hay que incluir al
  compilar. Es el archivo de configuración más importante de todos, se edita a mano cuando
  hace falta agregar una librería nueva.

pubspec.lock
  Anota la versión EXACTA de cada paquete que se terminó usando (para que todos en el equipo
  usen las mismas versiones). Lo genera y actualiza Flutter solo, nunca se edita a mano.

analysis_options.yaml
  Configura qué reglas de estilo/errores chequea el comando `flutter analyze` (el que
  venimos usando para confirmar "sin errores" después de cada cambio). Viene con un set de
  reglas recomendadas (flutter_lints), no hace falta tocarlo.

.metadata
  Archivo interno de Flutter: guarda qué versión de Flutter se usó para crear el proyecto.
  Uso exclusivo de la herramienta, no se edita a mano.

.flutter-plugins-dependencies
  Otro archivo interno, lleva la cuenta de qué plugins nativos (Android/iOS/etc.) usa el
  proyecto. Se regenera solo cada vez que se corre `flutter pub get`. No se edita a mano.

.dart_tool/
  Carpeta de caché de compilación — se regenera sola con `flutter pub get`. No viaja con el
  proyecto (está en .gitignore), no hace falta ni copiarla ni tocarla nunca.

.gitignore
  Lista de qué archivos NO subir si algún día se usa git en este proyecto (todavía no está
  inicializado). Ya tiene anotado, por ejemplo, que .env no debe subirse a un repositorio
  público.

app_cowcontrol.iml
  Archivo que genera Android Studio/IntelliJ solo, para indexar el proyecto en el editor. No
  lo escribimos nosotros, se regenera solo, no importa si se borra.

README.md
  El texto de bienvenida genérico que pone Flutter automáticamente en todo proyecto nuevo
  ("A new Flutter project."). Nunca se personalizó — se podría reescribir con una
  descripción real de CowControl más adelante, no es urgente.


4. CARPETAS DE PLATAFORMA — Flutter genera TODAS estas siempre, se usen o no
-------------------------------------------------------------
Flutter es multiplataforma: apenas se crea un proyecto nuevo, arma una carpeta para cada
sistema operativo posible, sin preguntar cuáles se van a usar de verdad. Achica la lista acá
para saber qué es cada una y cuáles hacen falta para CowControl (que apunta solo a Android y
iPhone):

android/
  SE NECESITA — es el target principal del proyecto. Acá adentro vive todo lo específico de
  Android: el archivo de configuración de Gradle (con el que compilamos el APK), el
  manifest, los íconos, permisos, etc. Todo lo que hicimos con Android Studio y el emulador
  pasa por esta carpeta.

ios/
  SE VA A NECESITAR (requisito no negociable del proyecto), pero todavía no se tocó ni se
  compiló nada acá — hace falta una Mac con Xcode, que hoy no está disponible. No borrar.

windows/
  NO es un target final del proyecto. Se usó una sola vez, al principio, para el primer
  smoke-test rápido (confirmar que el código compilaba, antes de tener instalado el SDK de
  Android). Candidata a eliminar si quieren aligerar la carpeta — no molesta si se deja,
  tampoco sirve para nada de acá en más.

linux/
  Nunca se usó, no es un target del proyecto. Candidata a eliminar.

macos/
  Nunca se usó, no es un target del proyecto. Ojo: esto es la versión de escritorio para
  Mac (una app que correría en una computadora Mac), no tiene nada que ver con compilar
  para iPhone — son cosas distintas aunque las haga la misma empresa (Apple) y estén
  relacionadas por debajo. Candidata a eliminar.

web/
  Nunca se usó, no es un target del proyecto (una versión que correría en un navegador).
  Candidata a eliminar.

(Nota: no hay ninguna carpeta ni configuración de "AWS" — Amazon Web Services — en este
proyecto. Si te sonaba alguna de estas, seguramente era "web" o alguna de las otras de
arriba.)


5. CARPETAS QUE NO SON CÓDIGO DEL PROYECTO EN SÍ
-------------------------------------------------------------

build/
  Acá caen los resultados de compilar (el APK, por ejemplo). Se regenera entera cada vez
  que se compila — nunca hay que compartirla ni editarla a mano.

.claude/
  Configuración de Claude Code para este proyecto (hoy vacía). No tiene nada que ver con
  Flutter ni con la app en sí.

documentacion.md/
  Esta misma carpeta (nombre confuso porque tiene ".md" pero es una carpeta, no un archivo)
  — toda la documentación del proyecto: memory.md, prompts.md, base_datos.md,
  cosas_pendientes.md, los PDFs originales, y ahora este info.md.


6. RESUMEN — candidatas a eliminar (decisión pendiente, no se tocó nada)
-------------------------------------------------------------
Si el objetivo es Android + iPhone únicamente, estas 3 carpetas no aportan nada al proyecto
final y se podrían borrar para simplificar:
  - linux/
  - macos/
  - web/

windows/ es un caso aparte: no es un target final, pero sigue siendo útil como forma rápida
de probar que el código compila sin abrir el emulador — se puede dejar un tiempo más y
sacarla después, no hay apuro.

android/ e ios/ se quedan sí o sí.


7. COMANDOS DE TERMINAL EXPLICADOS (se va completando a medida que se usan)
-------------------------------------------------------------
El objetivo de esta sección es que Santiago pueda explicar en la presentación qué hace cada
comando que se usó, aunque no lo haya escrito él la primera vez. Se va sumando una entrada
cada vez que aparece un comando nuevo.

flutter run -d ZY22H8WK3S
  (2026-08-07, para correr la app en el Moto G23 de Santiago por USB)

  - `flutter run`: compila el código Dart, instala el resultado en un dispositivo (emulador
    o celular real), y lo abre. Deja la conexión activa para el "hot reload" (tecla `r`)
    mientras se sigue trabajando — es el comando principal para desarrollar con Flutter.

  - `-d` (de "device"): le dice a Flutter EN CUÁL de los dispositivos conectados tiene que
    instalar la app. Hace falta porque puede haber varios disponibles a la vez (en este caso:
    Windows de escritorio, el navegador Edge, y el celular) — sin `-d`, Flutter no sabe cuál
    elegir.

  - `ZY22H8WK3S`: el número de serie **del celular en sí** (Moto G23), grabado por el
    fabricante — NO tiene nada que ver con la PC ni con el puerto USB usado. Es una
    identidad del dispositivo: si se conecta el mismo celular a otra computadora, o por otro
    puerto, el número es siempre el mismo. Si se conecta un celular distinto, cambia.

  - De dónde sale ese número: lo lee **ADB (Android Debug Bridge)**, la herramienta que
    permite que una PC le hable a un dispositivo Android (instalar apps, ver logs, etc.).
    Flutter usa ADB por debajo para todo esto. Para ver el número de serie de un dispositivo
    conectado sin pasar por Flutter, se puede correr directamente:
    ```
    adb devices -l
    ```
    (lista todos los dispositivos Android que la PC tiene conectados en ese momento, junto
    con su número de serie y modelo).

  **Paso a paso completo de cómo se llegó a este comando** (para poder repetirlo sin ayuda):
  1. Activar Opciones de desarrollador en el celular: Ajustes → Acerca del teléfono → tocar
     7 veces seguidas "Número de compilación".
  2. Adentro de Opciones de desarrollador, activar "Depuración USB".
  3. Conectar el celular a la PC por cable, y aceptar en el celular el diálogo "¿Permitir
     depuración USB desde esta computadora?" (tildando "Confiar siempre en esta
     computadora" para no tener que repetirlo cada vez).
  4. Correr `adb devices -l` para confirmar que aparece como `device` (no `unauthorized`) y
     copiar el número de serie que muestra.
  5. Correr `flutter run -d <ese-número-de-serie>`.

`C:\Users\santi\AppData\Local\Android\sdk\platform-tools\adb.exe install -r ...`
  (2026-08-10, para instalar un APK directo por USB sin depender de una sesión de
  `flutter run` en vivo — ver sección 8 más abajo del porqué)

  - **Por qué a veces `adb` funciona solo escribiendo `adb`, y otras veces hace falta
    escribir la ruta completa** (`C:\Users\santi\...\adb.exe`) — esto pasa por el **PATH**
    (una variable de configuración de Windows): es una lista de carpetas donde el sistema
    busca automáticamente cada vez que escribís el nombre corto de un programa (`adb`,
    `flutter`, `git`) sin decirle dónde está. `flutter` funciona escribiendo solo `flutter`
    porque la carpeta del SDK de Flutter quedó agregada al PATH cuando se instaló. La
    carpeta `platform-tools` (donde vive `adb.exe`) **no** quedó agregada al PATH cuando se
    instaló Android Studio — por eso escribir `adb` solo tira
    `El término 'adb' no se reconoce...`, mientras que escribir la ruta completa siempre
    funciona, sin importar el PATH, porque le estás diciendo a Windows exactamente dónde
    está el archivo en vez de pedirle que lo busque.
  - **Se podría arreglar de forma permanente** agregando esa carpeta al PATH del sistema
    (así alcanzaría con escribir `adb` de ahí en más, como con `flutter`) — no se hizo
    todavía, queda como mejora opcional si en algún momento molesta tener que escribir la
    ruta completa cada vez.

`Remove-Item -Recurse -Force <carpeta>` — a veces falla con carpetas de Android/Gradle
  (2026-08-15, al limpiar `build\` antes de compartir el proyecto)

  - **Qué pasó:** al intentar borrar la carpeta `build\` (que junta miles de archivos
    chiquitos generados por Gradle, con nombres de carpeta muy largos — por ejemplo
    `...\transformed\bundleLibRuntimeToDirDebug\...\SharedPreferencesPlugin$algo.dex`),
    PowerShell tiró cientos de errores del tipo
    `No se puede encontrar una parte de la ruta de acceso` y
    `El directorio no está vacío`, sin llegar a borrar la carpeta completa.
  - **Por qué pasa:** es un bug conocido de `Remove-Item -Recurse` en PowerShell 5.1 (el que
    trae Windows por defecto) — cuando hay muchísimos archivos anidados en rutas largas,
    `Remove-Item` arma la lista de qué borrar antes de empezar, y si algo cambia en el medio
    (o la ruta se acerca al límite de 260 caracteres que tiene Windows para rutas de
    archivo), se pierde y tira estos errores en cadena. No es un problema del proyecto ni de
    la carpeta `build\` en sí — le pasa a cualquier carpeta con muchos archivos anidados.
  - **Solución que funcionó:** usar el comando de borrado nativo de Windows en vez del de
    PowerShell:
    ```powershell
    cmd /c rmdir /s /q build
    ```
    `rmdir` (heredado del viejo `cmd.exe`) maneja mejor estos casos. Sirve para cualquier
    carpeta que `Remove-Item` se niegue a borrar por este motivo — solo cambiar el nombre al
    final del comando.
