# Memory — App CowControl (Flutter)

_Contexto completo del sistema (schema de Supabase, hardware, estado previo en App Inventor) está dos carpetas arriba: `../../memory.md` y `../../propuestas.md` (en la raíz de `C:\dev\CowControl\`). Este archivo es solo para lo que pasa **dentro** de esta app nueva._

---

## Decisión de stack — 2026-07-09

Se descarta **App Inventor** y se reemplaza por una app de código real. Se evaluaron:

| Opción | Resultado |
|---|---|
| **Thunkable** | Descartada. Sigue siendo no-code (bloques, como App Inventor). No tiene SDK oficial de Supabase — solo REST manual, con reportes de problemas en su comunidad. No encaja con el objetivo de entender la lógica del código. |
| **React Native** | Descartada. La sugirió un profesor por supuesta ventaja de documentación/comunidad, pero los datos de 2026 no confirman esa ventaja (Flutter tiene más preguntas en Stack Overflow y más estrellas en GitHub). |
| **Flutter** | ✅ **Elegida.** Ya estaba instalado en el equipo. SDK oficial de Supabase (`supabase_flutter`) mantenido por el propio equipo de Supabase. Documentación pareja o mejor que React Native. |

**Arquitectura (no cambia con el framework):**
```
Tag NFC/RFID → Lector → Raspberry Pi → POST Supabase ← GET App (Flutter)
```
La app **nunca se conecta directo con la Raspberry Pi**, solo con Supabase.

### Otras alternativas revisadas (2026-07-09) — ¿hay algo mejor que Flutter?

Búsqueda puntual, comparando solo contra Flutter (Thunkable y React Native ya quedaron descartados):

| Opción | Por qué no se eligió |
|---|---|
| **.NET MAUI (C#)** | Tiene cliente comunitario de Supabase (`supabase-csharp`), funciona bien, pero está pensado para equipos ya metidos en el ecosistema .NET/enterprise. Menos contenido para principiantes específico de Supabase. |
| **Ionic + Capacitor** (HTML/CSS/JS empaquetado como app nativa) | Buen soporte de Supabase (usa el SDK de JS) y apps más livianas. Pero Ionic discontinuó productos comerciales para clientes nuevos (señal de un rumbo menos sólido a futuro) y el resultado se siente menos "nativo". Tendría sentido solo si ya supiéramos HTML/CSS/JS de antes. |
| **Kotlin Multiplatform + Compose Multiplatform** (JetBrains) | La alternativa más seria: tiene SDK propio de Supabase (`supabase-kt`), comparte ~99% del código, y está creciendo fuerte en 2026. Pero es más joven, más pensada para equipos ya Android-nativos, y tiene menos tutoriales/comunidad en español que Flutter. |

**Conclusión:** ninguna alternativa supera a Flutter para este proyecto puntual. Se confirma Flutter.

**Nota sobre NFC:** ninguna de estas opciones lee NFC directo desde el celular sin módulos nativos extra (es una limitación de la industria, no de Flutter). No es un problema acá porque el que lee el tag NFC es la Raspberry Pi, no el celular — la app solo consulta Supabase.

### Verificación del SDK de Supabase para Flutter — 2026-07-09

Santiago pidió confirmar que el SDK oficial (`supabase_flutter`) realmente existe y funciona con lo que tenía instalado, antes de arrancar a codear.

- **Qué es un SDK:** librería que arma las peticiones HTTP a Supabase por vos (evita escribir a mano URLs/headers/JSON, que es lo que se hacía en App Inventor/Thunkable).
- **`supabase_flutter` existe y está activo:** lo publica `supabase.io` (verified publisher en pub.dev). Última versión en el momento de chequear: 2.16.0, publicada 2 días antes.
- **Estado inicial de la PC:** Flutter 3.22.0 / Dart 3.4.0 (de mayo 2024, ~2 años desactualizado). La versión 2.16.0 del SDK pedía Flutter ≥3.35.0 / Dart ≥3.9.0 — no cumplía.
- **Acción tomada:** se corrió `flutter upgrade --force` (el único "cambio local" que bloqueaba el upgrade era `bin/nuget.exe`, un binario que el propio Flutter descarga para desarrollo Windows desktop, no algo de Santiago). Resultado: **Flutter 3.44.6 / Dart 3.12.2**, cumple de sobra los requisitos. Confirmado: `supabase_flutter` en su última versión funciona con la instalación actual.
- **Pendiente de entorno (no bloqueante todavía):** `flutter doctor` marca que falta el Android SDK (Android Studio no instalado) y no detecta Chrome. Vamos a necesitar instalar Android Studio antes de poder correr la app en un celular/emulador Android.

### Reubicación del proyecto — 2026-07-26

Al armar la estructura del proyecto Flutter y probar un smoke-test en Windows desktop (`flutter run -d windows`), el build de C++ falló con un error de CMake/MSBuild (`DirectoryNotFoundException` al generar un archivo `.tlog`). La causa: el proyecto vivía en una ruta muy larga y con espacios dentro de OneDrive —
`C:\Users\santi\OneDrive\Trabajos de Secundaria\Claude Tiktok Personal  Agent\Workflow n8n for CowControl\app_cowcontrol\...` — y al anidar las carpetas de compilación (`build\windows\x64\CMakeFiles\...`) se superaba el límite clásico de Windows para longitud de ruta (`MAX_PATH`, 260 caracteres).

Se evaluó habilitar rutas largas de Windows (registro) vs. mover el proyecto, y se eligió **mover todo el proyecto** (`app_cowcontrol/`, `memory.md`, `propuestas.md`) a una ruta corta y sin espacios fuera de OneDrive:

```
C:\dev\CowControl\
├── app_cowcontrol\
├── memory.md
└── propuestas.md
```

**Por qué esta y no la otra opción:** el soporte de rutas largas en CMake/MSBuild/Gradle es inconsistente incluso con el registro habilitado, y de todos modos no resolvía el segundo problema — OneDrive sincronizando en tiempo real una carpeta `build/` de miles de archivos mientras se compila. Este mismo límite de ruta también podría haber afectado más adelante al build de Android (Gradle en Windows es sensible a rutas largas), así que convenía resolverlo ahora en vez de en medio de la instalación de Android Studio.

**Cómo se hizo:** se copió todo con `robocopy` (excluyendo `build/`, `.dart_tool/` y `.idea/`, que son cachés regenerables), se borraron las carpetas `ephemeral` de cada plataforma (`windows/flutter/ephemeral`, `linux/flutter/ephemeral`, `macos/Flutter/ephemeral`, `ios/Flutter/ephemeral` — contienen symlinks que apuntaban a la ruta vieja) y se corrió `flutter pub get` de nuevo en la ubicación nueva.

**Confirmado funcionando:** con el proyecto en `C:\dev\CowControl\app_cowcontrol`, `flutter run -d windows` compiló y arrancó la app, con el log `supabase.supabase_flutter: INFO: ***** Supabase init completed *****` confirmando que la conexión a Supabase (vía `.env`) funciona de punta a punta.

**Pendiente:** la carpeta vieja dentro de OneDrive (`...\Workflow n8n for CowControl\`) todavía no se borró — queda como copia de respaldo hasta que Santiago confirme que quiere eliminarla. **De ahora en adelante, todo el trabajo de código sigue en `C:\dev\CowControl\`.**

---

## Cómo se va a trabajar el código (acordado 2026-07-09)

- Claude escribe el código de la app. Santiago no lo tipea a mano.
- Cada acción/bloque importante lleva un comentario corto explicando **para qué sirve** (no una traducción línea por línea), para que Santiago pueda repasarlo después y explicarlo en la presentación del proyecto.
- **Todavía no se arrancó a codear.** Falta que Santiago explique el caso de uso completo de la app (pantallas, flujo, funcionalidad) para fijar la lógica desde el principio y no tener que rehacer cosas a mitad de camino.

## Caso de uso — carpeta técnica leída (2026-07-13)

Santiago compartió `Carpeta técnica-CowControl.pdf` (en esta carpeta) con la fundamentación, objetivos, mockups y descripción técnica del sistema. Resumen de lo que define la lógica de la app:

- **Función principal: conteo.** El usuario tiene una planilla del ganado y presiona "iniciar conteo" → la app se sincroniza con el lector RFID/NFC montado en el brete → cada animal detectado se marca visualmente (✓) en la planilla en tiempo real → "detener" / "reanudar" / "finalizar".
- Dos pantallas base en el mockup: (1) planilla general del ganado con filtros, (2) ficha detallada de un animal individual.
- Mockup muestra campos que NO están en el schema real (preñez, fertilidad, crías, "para carnear", alertas puntuales) — **descartados** tras consultar con productores del INTA. Ver decisión de `condicion_corporal` abajo.

### Decisiones de arquitectura (2026-07-13)

| Tema | Decisión |
|---|---|
| Conteo en vivo (✓ en la planilla al pasar un animal) | **Supabase Realtime** (websocket) — la app escucha inserts nuevos en `datos_lectura`, no polling. |
| Sesión de conteo (guardar/borrar/ver conteos anteriores) | **Aceptado en v1 (2026-07-26).** Se agrega tabla `sesiones_conteo` (inicio/fin/estado) + FK `sesion_id` en `datos_lectura`. El conteo sigue llegando **en tiempo real** vía Realtime (no se pierde la demo en vivo); al tocar "Finalizar" el productor guarda o descarta la tanda completa. Se descartó la alternativa de que la Raspberry Pi retenga los datos localmente y los mande recién al final, porque eso elimina el ✓ en vivo. Migración SQL pendiente de aplicar — ver `base_datos.md`. |
| Cámara/video vinculado a cada lectura | **Diferido.** Hardware físico (Raspberry Pi + cámara) todavía no armado. Ver `cosas_pendientes.md`. |
| Campos nuevos del mockup | Solo se agrega **`condicion_corporal`** (escala 1–5, medios puntos) a `datos_animales` — validado con productores del INTA, reemplaza al "Estado" del mockup. Resto de campos: evaluar de a uno, no en bloque. SQL de la migración en `../../memory.md`. **Pendiente de re-evaluar (sin decisión final todavía):** de cara al prototipo de demo, este campo se ve más como algo útil "si el proyecto prospera" que como algo necesario para mostrar el prototipo — candidato a simplificar/sacar de la demo. Ver detalle en `prompts.md`, sección "Sesión siguiente — pausa por créditos". |
| Edad aproximada (`fecha_nacimiento`) | **Se elimina** (decidido 2026-07-13, al revisar el documento explicativo). Los productores del INTA habían dicho que la edad no se calcula de forma confiable con una fecha cargada a mano — se estima mirando la dentadura del animal. No aporta al objetivo central (conteo), así que se saca de la app y se elimina la columna. SQL en `../../memory.md`. |

**Pendiente de correr en Supabase, en orden:** (1) `ALTER TABLE` de `condicion_corporal`, (2) `ALTER TABLE ... DROP COLUMN fecha_nacimiento`, (3) migración de `productor_id` + políticas RLS — las tres están en `../../memory.md`, sección "Migración pendiente". **Ya ejecutadas y confirmadas el 2026-07-26** (ver `base_datos.md`).

## Plan de pantallas — versión final acordada (2026-07-13)

Ajustado después de que Santiago revisó de nuevo qué mockup se les mostró realmente a los productores del INTA. Regla general: mostrar lo mínimo necesario, todo lo demás va en `observaciones` a criterio del productor.

| Pantalla | Qué muestra | Fuente de datos |
|---|---|---|
| **0. Login / Registro** | Email + contraseña vía Supabase Auth. Un productor nuevo se registra y arranca sin campos cargados (se lo manda a crear el primero). Ver decisión de multi-tenant abajo. | Supabase Auth |
| **1. Selector de campo** | Lista de `datos_campo` **del productor logueado** (`productor_id = auth.uid()`, vía RLS). Se autoselecciona si solo tiene uno. Si no tiene ninguno, pantalla para crear el primero. | `datos_campo` |
| **2. Planilla general** | Por animal: **rfid_uid** (como "ID"), **categoría** (vaca/toro/ternero/ternera/vaquillona — se muestra como badge/ícono, sin la etiqueta "Sexo:"), **condición corporal**. Sin nombre, sin maternidad, sin edad. Filtra por defecto `estado_vital = 'vivo'`. Botón "Iniciar conteo". | `datos_animales` (filtrado por `campo_id`) |
| **3. Conteo en vivo** | Igual que la planilla general pero solo con **categoría + rfid_uid**, marcando ✓ en tiempo real vía **Supabase Realtime** cuando llega un insert nuevo a `datos_lectura` para ese animal. Botón **"Iniciar conteo"** crea una `sesión_conteo` nueva; **detener/reanudar** mientras está activa; **"Finalizar"** la cierra y el productor elige **guardar** o **descartar** la tanda completa. "Ver más" en cada fila → Pantalla 4. | `datos_animales` + Realtime sobre `datos_lectura` + `sesiones_conteo` |
| **4. Detalle de animal** ("Ver más") | **rfid_uid**, **condición corporal**, **resumen de vacunas** (última vacuna aplicada + fecha, no el listado completo — si el productor quiere detallar algo puntual de una vacuna lo anota en observaciones), **observaciones** (texto libre). Sin nombre, sexo, maternidad, crías, fertilidad, alertas puntuales, ni edad — todo eso vive en observaciones si hace falta. | `datos_animales` + `datos_vacuna` (solo el registro más reciente por animal) |
| **5. Historial de lecturas** | Últimas lecturas del campo, ordenadas por fecha. | `datos_lectura` |

**Decisiones de detalle:**
- El "ID" visible en toda la app es `rfid_uid` (no se agrega un número secuencial nuevo — evita tocar el schema de nuevo).
- "Vacunas" en el detalle es un resumen (última vacuna + fecha), no una lista completa del historial.
- Paleta de colores: tonos marrones/tierra, siguiendo la estética del mockup de la carpeta técnica.
- `alertas` y `estadisticas` (que estaban en el plan viejo de App Inventor, `propuestas.md`) quedan **afuera de esta v1** — no las pidió el mockup validado con INTA. Se evalúan a futuro si hace falta.

### Multi-tenant: cada productor con sus propios datos (decidido 2026-07-13)

Santiago quiere que cada productor (cada usuario de la app) tenga su ganado aislado del de otros productores. Se comparó "una base de Supabase por productor" (descartado, poco práctico) contra **Auth + Row Level Security en un solo proyecto de Supabase** (✅ elegido — patrón estándar de cualquier SaaS real). **Migración ya ejecutada y confirmada el 2026-07-26** (ver `base_datos.md`); re-confirmado ese mismo día tras evaluar sacar el login — se decidió mantenerlo. Detalle técnico completo y el SQL de la migración están en `../../memory.md`, sección "Migración pendiente — multi-tenant con Auth + Row Level Security".

Implicancias para la app:
- Se suma la Pantalla 0 (login/registro) a la tabla de arriba.
- La Raspberry Pi no se toca — sigue usando la `service_role` key para insertar lecturas, que bypassea RLS.
- Los datos de prueba actuales (Milka, Oscar, "Campo Principal") van a quedar sin dueño hasta que Santiago cree su cuenta y se los asigne a mano.

## Pendiente

- [x] Santiago explica el caso de uso completo de la app (carpeta técnica + mockups + decisiones de arquitectura).
- [x] Acordar con Santiago el plan de pantallas Flutter — ver tabla arriba.
- [x] Definir estrategia multi-tenant (Auth + RLS) — ver sección arriba.
- [x] Correr en Supabase el bloque consolidado de 3 migraciones (`condicion_corporal`, `DROP COLUMN fecha_nacimiento`, `productor_id` + políticas RLS) — confirmado 2026-07-26, ver `base_datos.md`.
- [x] Conseguir de Santiago la URL de Supabase + la anon/public key — recibida 2026-07-26.
- [x] Definir cómo guardar esas credenciales en el proyecto — `.env` + `flutter_dotenv`, confirmado 2026-07-26.
- [x] Arrancar con la estructura del proyecto Flutter + `supabase_flutter` (2026-07-26): `flutter create`, dependencias, `.env`, tema, 4 modelos, 6 servicios, 3 widgets reutilizables y las 6 pantallas (login, selector de campo, planilla, conteo en vivo, detalle de animal, historial). `flutter analyze` sin errores.
- [ ] Asignar `productor_id` a los datos de prueba (Milka, Oscar, "Campo Principal") — pendiente de que Santiago se registre desde la pantalla de login real (decidido probarlo así, no con un `UPDATE` manual).
- [ ] Revisar y aplicar la migración de `sesiones_conteo` (SQL en `base_datos.md`, todavía no ejecutada) — el código de `ConteoScreen` ya está preparado para el tiempo real, pero el guardar/descartar la tanda queda pendiente de esa migración.
- [ ] Instalar Android Studio/SDK antes de poder correr la app en emulador o celular — sigue pendiente (`flutter doctor` confirma que falta el Android SDK). Avisar a Santiago cuando se llegue a este punto, como quedó acordado.
- [ ] Corroborar con Santiago el schema real actual en Supabase (Table Editor) contra lo documentado en `../../memory.md` — sigue pendiente de verificar.
- [ ] Leer y evaluar junto con Santiago el documento de un compañero de equipo que propone cambiar el flujo de la base de datos — todavía no lo leyó. No implementar nada hasta revisarlo con Claude.
- [ ] Re-evaluar `condicion_corporal` (y posibles otros campos del mockup) de cara al prototipo de demo — ver tabla de "Decisiones de arquitectura" arriba y `prompts.md` sección "Sesión siguiente — pausa por créditos". **Trabajo a encarar paso a paso y guiado, no en una sola sesión de Claude aplicando todo** (acordado por el consumo de créditos de Claude Code).
