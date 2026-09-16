# Base de Datos — CowControl

Documento dedicado exclusivamente a todo lo que pasa **en la base de datos de Supabase**: qué SQL se corrió, cuándo, por qué, y en qué quedó el schema después de cada cambio. La documentación funcional de la app (pantallas, flujo, decisiones de producto) sigue viviendo en [memory.md](memory.md) — acá solo entra lo que se ejecuta en el SQL Editor o afecta directamente a las tablas/políticas de Supabase.

**Proyecto Supabase:** `jucndmefmewkjalqnrrv` — https://supabase.com/dashboard/project/jucndmefmewkjalqnrrv

---

## Estado del proyecto — 2026-07-26

El dashboard de Supabase mostró temprano ese día **"Restoration in progress"** (restauración de un backup). Ya terminó — la migración de abajo se corrió con éxito ese mismo día, confirmado por "Success. No rows returned" en el SQL Editor.

---

## Schema actual (antes de cualquier migración pendiente)

4 tablas, aplicadas el 2026-06-21 (ver detalle completo del diccionario de campos en `../../memory.md`, en la raíz de `C:\dev\CowControl\`):

- `datos_campo` (`id`, `nombre_campo`, `ubicacion`, `created_at`)
- `datos_animales` (`id`, `rfid_uid`, `nombre`, `sexo`, `raza`, `fecha_nacimiento`, `estado_vital`, `observaciones`, `campo_id`, `created_at`)
- `datos_vacuna` (`id`, `id_animal`, `nombre_vacuna`, `numero_dosis`, `fecha_vacuna`, `veterinaria`, `created_at`)
- `datos_lectura` (`id`, `rfid_uid`, `id_animal`, `campo_id`, `fecha_hora`, `observaciones`)

RLS activado en las 4 tablas con una política provisoria `"acceso autenticado"` (cualquier usuario logueado ve todo — se reemplaza por la migración de abajo).

Datos de prueba cargados: campo "Campo Principal" (Zona Norte), animales Milka (`147-24-83-210`, vaca) y Oscar (`123-23-45-312`, ternero).

---

## Historial de migraciones SQL

### Migración v1 — 2026-07-13 (✅ ejecutada 2026-07-26)

Confirmado por captura del SQL Editor de Supabase: `Success. No rows returned`. Las 3 migraciones (condición corporal, eliminar fecha_nacimiento, multi-tenant + RLS) ya están aplicadas en el proyecto `jucndmefmewkjalqnrrv`.

**Pendiente inmediato:** Milka/Oscar/"Campo Principal" quedaron con `productor_id = NULL` (invisibles para cualquier usuario) hasta correr el `UPDATE` manual de la sección de abajo — necesita que Santiago tenga una cuenta creada primero (vía registro en la app o desde el dashboard de Supabase → Authentication).

### Detalle de la migración (referencia)

**Por qué:** agrega la escala de condición corporal validada con productores del INTA, elimina `fecha_nacimiento` (la edad no es confiable a mano, se estima por dentadura), y suma multi-tenant (Auth + Row Level Security) para que cada productor vea solo sus propios datos.

**Qué cambia:**
1. `datos_animales` gana `condicion_corporal numeric(2,1)` con CHECK de 1 a 5 en medios puntos.
2. `datos_animales` pierde `fecha_nacimiento`.
3. `datos_campo` gana `productor_id uuid REFERENCES auth.users(id)`.
4. Las políticas `"acceso autenticado"` de las 4 tablas se reemplazan por políticas que filtran por `productor_id` (heredado vía `campo_id` para `datos_animales`, `datos_vacuna`, y solo lectura para `datos_lectura` — la Raspberry Pi sigue insertando con la `service_role` key, que bypassea RLS).

```sql
-- ============================================================
-- CowControl — Migración v1 (2026-07-13)
-- Pegar todo este bloque en el SQL Editor de Supabase y ejecutar.
-- ============================================================

-- 1) Condición corporal (reemplaza al "Estado" del mockup original)
ALTER TABLE datos_animales
  ADD COLUMN condicion_corporal numeric(2,1)
  CHECK (condicion_corporal IN (1,1.5,2,2.5,3,3.5,4,4.5,5));

-- 2) Eliminar edad (fecha_nacimiento) — no es confiable a mano, se estima por dentadura
ALTER TABLE datos_animales DROP COLUMN IF EXISTS fecha_nacimiento;

-- 3) Multi-tenant: cada productor con sus propios datos (Auth + Row Level Security)
ALTER TABLE datos_campo
  ADD COLUMN productor_id uuid REFERENCES auth.users(id);

DROP POLICY IF EXISTS "acceso autenticado" ON datos_campo;
CREATE POLICY "solo su propio campo" ON datos_campo
  FOR ALL TO authenticated
  USING (productor_id = auth.uid())
  WITH CHECK (productor_id = auth.uid());

DROP POLICY IF EXISTS "acceso autenticado" ON datos_animales;
CREATE POLICY "solo animales de su campo" ON datos_animales
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM datos_campo
    WHERE datos_campo.id = datos_animales.campo_id
      AND datos_campo.productor_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM datos_campo
    WHERE datos_campo.id = datos_animales.campo_id
      AND datos_campo.productor_id = auth.uid()
  ));

DROP POLICY IF EXISTS "acceso autenticado" ON datos_vacuna;
CREATE POLICY "solo vacunas de su campo" ON datos_vacuna
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM datos_animales
    JOIN datos_campo ON datos_campo.id = datos_animales.campo_id
    WHERE datos_animales.id = datos_vacuna.id_animal
      AND datos_campo.productor_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM datos_animales
    JOIN datos_campo ON datos_campo.id = datos_animales.campo_id
    WHERE datos_animales.id = datos_vacuna.id_animal
      AND datos_campo.productor_id = auth.uid()
  ));

DROP POLICY IF EXISTS "acceso autenticado" ON datos_lectura;
CREATE POLICY "solo lecturas de su campo" ON datos_lectura
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM datos_campo
    WHERE datos_campo.id = datos_lectura.campo_id
      AND datos_campo.productor_id = auth.uid()
  ));
```

**Efecto secundario esperado:** después de correr esto, Milka/Oscar/"Campo Principal" quedan con `productor_id = NULL` — invisibles para cualquier usuario hasta el paso manual de abajo.

**Paso manual pendiente (después de registrarse en la app):**
```sql
UPDATE datos_campo SET productor_id = '<uuid-de-la-cuenta-de-santiago>' WHERE nombre_campo = 'Campo Principal';
```

---

### Migración — 2026-09-14: `fertilidad` → `condicion_corporal`, y tabla nueva `datos_observacion`

**Por qué:**
- Se decidió volver a llamar "Condición Corporal" a la categoría que se venía llamando
  "Fertilidad" desde el 2026-08-03 (ver `prompts.md` sección 9) — es el mismo dato de
  siempre (`buena`/`regular`/`mala`), solo cambia el nombre. Los rangos que ahora muestra la
  app al lado de cada opción ("Buena de 4 a 5", "Regular de 2.5 a 3.5", "Mala de 1 a 2") son
  la escala de Condición Corporal de 1 a 5 que usan los técnicos del INTA — son solo texto de
  referencia en la pantalla, **no se guardan como número**, la columna sigue siendo `text`.
- Se agregó una tabla nueva, `datos_observacion`, para que un animal pueda acumular varias
  observaciones en vez de una sola que se pisaba cada vez que se tocaba "Guardar" — mismo
  patrón que ya usa `datos_vacuna` para el historial de vacunas.

**Ojo — aclaración sobre el schema real vs. lo que decía este documento:** la sección "Schema
actual" más arriba (Migración v1) muestra `condicion_corporal numeric(2,1)` — esa columna se
había borrado y reemplazado por `fertilidad text` el 2026-08-03, un cambio que en su momento
solo quedó anotado en `prompts.md` sección 9 y nunca se agregó acá. La columna que se renombra
hoy (`fertilidad` → `condicion_corporal`) **sigue siendo `text` con los valores
`'buena'/'regular'/'mala'`** — es una coincidencia de nombre con la columna numérica vieja de
Migración v1, no es la misma columna ni vuelve a la escala numérica.

**Qué cambia:**
1. `datos_animales.fertilidad` (`text`) se renombra a `datos_animales.condicion_corporal` —
   mismo tipo, mismos valores, no se pierde nada de lo que ya estaba cargado.
2. El `CHECK` que ya tenía esa columna (`IN ('buena','regular','mala')`) se renombra junto con
   la columna — Postgres no lo hace solo, si no se corre este paso el constraint queda
   funcionando bien pero con un nombre que sigue diciendo "fertilidad" por dentro.
3. Tabla nueva `datos_observacion` (`id`, `id_animal`, `texto`, `creado_en`) — una fila por
   observación, igual que `datos_vacuna` tiene una fila por vacuna.
4. RLS en `datos_observacion`: mismo criterio que ya usa `datos_vacuna` — un productor solo ve
   o inserta observaciones de animales que están en uno de sus propios campos (se resuelve con
   un `JOIN` de `datos_animales` a `datos_campo` para llegar hasta `productor_id`).
5. `GRANT SELECT, INSERT` a `authenticated` sobre `datos_observacion` — la capa de permisos de
   Postgres que es **distinta** de RLS (RLS filtra filas, el `GRANT` decide si el rol puede
   tocar la tabla siquiera). Sin este paso da `permission denied` aunque la política de RLS
   esté perfecta — ya pasó una vez con las primeras 4 tablas, ver sección "10.3" más abajo en
   este mismo documento.

```sql
-- ============================================================
-- CowControl — Migración 2026-09-14
-- Corrida en dos bloques separados en el SQL Editor de Supabase.
-- ============================================================

-- 1) Renombrar "fertilidad" a "condicion_corporal" (mismo dato, solo el nombre)
ALTER TABLE datos_animales RENAME COLUMN fertilidad TO condicion_corporal;

-- Postgres no renombra el CHECK solo al renombrar la columna — se hace a mano
-- para que el nombre interno del constraint no quede diciendo "fertilidad"
ALTER TABLE datos_animales
  RENAME CONSTRAINT datos_animales_fertilidad_check
  TO datos_animales_condicion_corporal_check;

-- 2) Tabla nueva para que un animal tenga varias observaciones (no una sola que se pisa)
CREATE TABLE datos_observacion (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  id_animal uuid NOT NULL REFERENCES datos_animales(id),
  texto text NOT NULL,
  creado_en timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE datos_observacion ENABLE ROW LEVEL SECURITY;

-- Mismo criterio de seguridad que ya usa datos_vacuna: el productor solo ve/
-- inserta observaciones de animales que viven en uno de sus propios campos
CREATE POLICY "solo observaciones de su campo" ON datos_observacion
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM datos_animales
    JOIN datos_campo ON datos_campo.id = datos_animales.campo_id
    WHERE datos_animales.id = datos_observacion.id_animal
      AND datos_campo.productor_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM datos_animales
    JOIN datos_campo ON datos_campo.id = datos_animales.campo_id
    WHERE datos_animales.id = datos_observacion.id_animal
      AND datos_campo.productor_id = auth.uid()
  ));

-- GRANT aparte de RLS — sin esto, "permission denied" aunque la politica de
-- arriba este perfecta (ver seccion 10.3 mas abajo en este mismo documento)
GRANT SELECT, INSERT ON public.datos_observacion TO authenticated;
```

**Confirmado ejecutado (2026-09-14):** las dos partes corrieron con "Success. No rows
returned" en el SQL Editor de Supabase (confirmado por captura de Santiago). La columna vieja
`datos_animales.observaciones` (el texto único de antes) queda intacta sin tocar — el código
Flutter todavía no migró a usar `datos_observacion`, ese es el próximo paso pendiente del lado
de la app.

**Impacto en el hardware (ESP32, a cargo de Germaioni): ninguno, en las dos partes.** El
firmware del ESP32 solo interactúa con dos tablas — `INSERT` en `datos_lectura` (cada vez que
el lector detecta un tag) y `SELECT` de `conteos` (el polling cada 5 segundos para saber si hay
un conteo activo, ver sección 4 de este documento y `Guia_Raspberry_Pi-CowControl.pdf`). Ni
`datos_animales.condicion_corporal` ni la tabla nueva `datos_observacion` están en ese
contrato — son datos que carga el productor a mano desde la app (fertilidad/condición corporal
del animal, observaciones sueltas), nunca algo que el lector RFID pueda medir o que el hardware
necesite leer o escribir. **No hace falta avisarle a Germaioni ni tocar el firmware por esto.**
La única vez que un cambio de esquema sí le afectó fue cuando se sacó `id_animal` de
`datos_lectura` (sección 16.2 de `prompts.md`, 2026-08-31) — ahí sí hubo que avisarle porque
esa columna estaba en la tabla que él escribe.

---

### Migración pendiente — `sesiones_conteo` (decidido 2026-07-26, no aplicada aún)

**Por qué:** Santiago planteó dos formas de manejar el conteo: (a) que la Raspberry Pi retenga las lecturas localmente durante el conteo y las mande todas juntas a la app recién al finalizar, o (b) que las lecturas sigan llegando en tiempo real (como ya está decidido) y se agrupen en una sesión con inicio/fin para poder guardar/descartar la tanda completa. Se eligió **(b)** — la opción (a) rompía el ✓ en tiempo real de la Pantalla 3 (Conteo en vivo), que es la función principal del proyecto según la carpeta técnica.

Esto retoma el punto que estaba anotado como diferido en `cosas_pendientes.md` (sección 1), ahora aceptado para la v1.

**Qué agrega:**
1. Tabla nueva `sesiones_conteo` (inicio/fin/estado, referenciada a `datos_campo`).
2. Columna `sesion_id` en `datos_lectura` (FK a `sesiones_conteo`), para poder agrupar y luego guardar/descartar una tanda entera.
3. Políticas RLS para `sesiones_conteo`, siguiendo el mismo criterio multi-tenant que las demás tablas (solo el productor dueño del campo ve/edita sus sesiones).

```sql
-- ============================================================
-- CowControl — Migración sesiones_conteo (2026-07-26)
-- Pendiente de revisar y ejecutar en el SQL Editor de Supabase.
-- ============================================================

CREATE TABLE sesiones_conteo (
  id           uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  campo_id     uuid REFERENCES datos_campo(id),
  fecha_inicio timestamptz DEFAULT now(),
  fecha_fin    timestamptz,
  estado       text DEFAULT 'activa' CHECK (estado IN ('activa', 'finalizada', 'descartada')),
  created_at   timestamptz DEFAULT now()
);

ALTER TABLE datos_lectura
  ADD COLUMN sesion_id uuid REFERENCES sesiones_conteo(id);

ALTER TABLE sesiones_conteo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "solo sesiones de su campo" ON sesiones_conteo
  FOR ALL TO authenticated
  USING (EXISTS (
    SELECT 1 FROM datos_campo
    WHERE datos_campo.id = sesiones_conteo.campo_id
      AND datos_campo.productor_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM datos_campo
    WHERE datos_campo.id = sesiones_conteo.campo_id
      AND datos_campo.productor_id = auth.uid()
  ));
```

**Nota:** esta migración todavía no se revisó a fondo con Santiago para confirmar que el SQL es el definitivo — queda pendiente de aprobación antes de correrla (a diferencia del bloque anterior, que ya está aplicado).

---

## Por qué Supabase y no un servidor propio en la Raspberry Pi

Se anota esto en detalle porque hubo una discusión de grupo al respecto (2026-07-26): un compañero había armado, para una demo de hardware de hace un mes, un servidor corriendo directamente en la Raspberry Pi, donde los tags de 3-4 animales quedaban alojados ahí al pasar por el lector, con la idea de que después "pasen directo a la aplicación" sin que el dato circule tanto por una base de datos externa. Es un planteo válido para probar que el hardware (lector + Pi) funciona de forma aislada, pero no es el mismo problema que resuelve la app completa. Vale la pena dejar clara la diferencia.

### Qué tendría que resolver un servidor propio en la Pi (y no resuelve)

| Problema | Con servidor propio en la Pi | Con Supabase |
|---|---|---|
| **Acceso desde el celular del productor** | La Pi está en un campo, típicamente detrás del router de un ISP rural, sin IP pública fija. Para que la app la consulte desde el celular haría falta abrir puertos, port-forwarding, o un servicio de túnel — configuración de redes que no es parte del proyecto y que además puede fallar según el proveedor de internet del productor. | Supabase ya es un servicio con URL pública HTTPS estable. La app solo necesita internet, no necesita saber nada de la red del campo. |
| **Múltiples productores, múltiples campos** | Cada Raspberry Pi tendría su propio servidor con su propia IP/URL. La app tendría que guardar y mantener una lista de direcciones distintas por productor — no escala, y es justo el problema que ya resolvimos con `campo_id` + multi-tenant. | Un solo backend central. Todas las Raspberry Pi (de cualquier campo) le hablan al mismo proyecto de Supabase; la app filtra por `campo_id`/`productor_id`. |
| **Historial y respaldo de datos** | Si se rompe la SD de la Pi, se va la luz, o hay que resetear el hardware, se pierde todo lo guardado ahí salvo que alguien programe backups a mano. | Supabase hace backups automáticos — de hecho, **el mismo 2026-07-26 vimos el proyecto en "Restoration in progress"**: es la plataforma restaurando un backup, algo que un script casero en la Pi no tendría sin construirlo aparte. |
| **Conteo en tiempo real (✓ en la Pantalla 3)** | Para que la app viera las lecturas "en vivo" con un servidor propio en la Pi, habría que programar desde cero un mecanismo de push (WebSocket, Server-Sent Events, o polling) además del servidor HTTP. | Ya viene resuelto: **Supabase Realtime** empuja el cambio a la app apenas la Pi hace el POST — sin escribir un servidor de tiempo real propio. |
| **Login / aislar datos por productor** | Habría que programar autenticación propia en el servidor de la Pi (usuarios, contraseñas, sesiones, hashing). | Supabase Auth + RLS ya lo resuelve, es código que no hay que escribir ni mantener. |
| **Mantenimiento** | El servidor "vive" en un dispositivo físico en el campo — actualizarlo, parchear seguridad, o simplemente reiniciarlo si se cuelga depende de que alguien esté físicamente ahí o tenga acceso remoto configurado. | Es un servicio gestionado — Supabase se encarga de que el backend esté corriendo, escalado y actualizado. |

### Dónde sí tiene razón el planteo del compañero

Para una demo puntual de hardware (mostrar que el lector detecta el tag y "algo" pasa), un servidor local en la Pi es más simple de armar y no depende de tener internet — tiene sentido para esa consigna específica, que era probar el hardware en sí, no el sistema completo. Pero ese servidor local resolvía un problema distinto (validar que el lector físico funciona) al que resuelve la arquitectura de la app (que múltiples productores, en distintos campos, con múltiples celulares, vean sus datos de forma confiable y en tiempo real).

### Conclusión — el rol de cada pieza

```
Tag NFC/RFID → Lector → Raspberry Pi → POST Supabase (backend gestionado) ← GET/Realtime App (Flutter)
```

- **Raspberry Pi:** un cliente delgado. Solo lee el tag y hace un POST. No guarda estado, no sirve datos, no tiene login.
- **Supabase:** el "servidor" real del sistema — base de datos + API REST + autenticación + tiempo real, todo gestionado, sin tener que programarlo ni mantenerlo a mano.
- **App Flutter:** otro cliente delgado — consulta y escucha a Supabase, nunca habla directo con la Raspberry Pi.

Esto es justamente el patrón que se usa en apps reales (no es una decisión "para la materia"): separar quién **lee el hardware**, quién **guarda/sirve los datos**, y quién **los muestra**, en vez de que un solo dispositivo (la Pi) haga las tres cosas.

---

## Nota — segunda versión de la app (Raspberry Pi)

Santiago mencionó (2026-07-26) que va a haber una segunda versión/variante de la app orientada al lado del servidor Raspberry Pi (cómo lee/escribe la base de datos desde el hardware), a explicar en detalle más adelante. Anotado acá para no perder el hilo — sin definir todavía.

---

## Cómo se actualiza este documento

Cada vez que se corra SQL nuevo contra Supabase (migración, cambio de política, fix de datos), se agrega acá: el SQL exacto ejecutado, la fecha, el motivo, y el efecto sobre el schema. Así queda un historial completo y auditable de la base de datos, separado de las decisiones de producto/UI que documenta `memory.md`.


"La base de datos se queda tal cual está hoy —datos_campo, datos_animales (con categoría, fertilidad y el resto de los campos que ya tiene), datos_lectura y datos_vacuna— no se borra ni se reemplaza ninguna de esas tablas. Lo único que se agrega es la tabla de sesiones de conteo que ya teníamos planeada, usando las tres funciones que armaste para iniciar/pausar/finalizar (con el estado "pausada" sumado, que a nosotros nos faltaba, y ligada al campo de cada productor para que no se mezclen conteos entre distintos usuarios). Las políticas de seguridad siguen exigiendo login y filtrando por productor —no se abren a "anon" como estaba en tu propuesta, porque eso dejaría los datos de todos los productores visibles y editables por cualquiera sin loguearse—; para que la Raspberry pueda escribir sin necesidad de ese login, ya usamos la service_role key, que tiene permiso total sin tener que abrir nada para el resto. El polling de la Raspberry cada 5 segundos preguntando el estado del conteo sí se toma tal cual, y el tilde en tiempo real que ve el productor en el celular sigue funcionando con Supabase Realtime, sin tocarlo. Como agregado nuevo, sumamos la idea de guardar las lecturas de tags que todavía no tienen un animal asociado en una lista de "no identificados", para que un productor nuevo pueda ponerles nombre la primera vez que cuenta su ganado. Y no volvemos a agregar la fecha de nacimiento del animal, porque ya se había sacado antes por una decisión tomada con el INTA
esto me mando claude acerca del doc de la base de datos
asi por ahora queda asi, mañana mando la primer version, igual, vamos viendo
La base de datos se queda tal cual está hoy —datos_campo, datos_animales (con categoría, fertilidad y el resto de los campos que ya tiene), datos_lectura y datos_vacuna— no se borra ni se reemplaza ninguna de esas tablas. Lo único que se agrega es la tabla de sesiones de conteo que ya teníamos planeada, usando las tres funciones que armaste para iniciar/pausar/finalizar (con el estado "pausada" sumado, que a nosotros nos faltaba, y ligada al campo de cada productor para que no se mezclen conteos entre distintos usuarios). Las políticas de seguridad siguen exigiendo login y filtrando por productor —no se abren a "anon" como estaba en tu propuesta, porque eso dejaría los datos de todos los productores visibles y editables por cualquiera sin loguearse—; para qu
cucha
1. igual hay q modificarles el nombre a los campos de datos_animales y datos_lectura
o se modifica en la base fe datos o en todo el codigo de la RPi
y ns si vos hiciste alguna configuracon con ese nombre
y habría q avisarle a keila tmb porq algo del codigo q yo le mande q haga habría w modificarlo
igual hay q modificarles el nombre a los campos de datos_animales y datos_lectura
Y bueno hay q cambiar todo entonces, pq como explicaste esos datos, hacen lo mismo que hacen los de supa
y habría q avisarle a keila tmb porq algo del codigo q yo le mande q haga habría w modificarlo
Dale, yo le aviso
Lo q si voy a ver para poner es lo de inicio, fin y pausa
En realidad, inicio y fin ya están pero no pausa, lo bueno es q como todavía no está escrito lo puedo cambiar, en cambio, cambiar los nombres por lo mismo es medio alpe
Igual mañana paso a la tarde la app, y ahí van probando si les manda, el correo, si pueden agendar vacas, etc
2. en "datos_lectura" hay 2 campos parecidos
hay id, rfid_uid y id_animal
el rfid_uid es del tag
el id_animal me imagino q es el identificador del senasa
y el id?
de q es
Dale, yo le aviso
justo vi
q ya hizo todo xd
le vas a encabronar
pero bueno
EU
NO LE DIJIMOS Q HAG LO DEL TRELLO
y el profe dijo q hasta hoy
Cajeta
decile ya
por da
Y bueno hay q cambiar todo entonces, pq como explicaste esos datos, hacen lo mismo que hacen los de supa
no entendí
Me da cosa, voy a poner yo nms
Por lo menos las fechas
En realidad, inicio y fin ya están pero no pausa, lo bueno es q como todavía no está escrito lo puedo cambiar, en cambio, cambiar los nombres por lo mismo es medio alpe
entonces cambip en el codigo de la RP
RPi?
Me da cosa, voy a poner yo nms
dale a ella bolud9
y de ultima desoues le modificamos
algo hay q darle
ademas se va a sentir mal si la excluimos asi
dejale q haga eso
La base de datos se queda tal cual está hoy —datos_campo, datos_animales (con categoría, fertilidad y el resto de los campos que ya tiene), datos_lectura y datos_vacuna— no se borra ni se reemplaza ninguna de esas tablas. Lo único que se agrega es la tabla de sesiones de conteo que ya teníamos planeada, usando las tres funciones que armaste para iniciar/pausar/finalizar (con el estado "pausada" sumado, que a nosotros nos faltaba, y ligada al campo de cada productor para que no se mezclen conteos entre distintos usuarios). Las políticas de seguridad siguen exigiendo login y filtrando por productor —no se abren a "anon" como estaba en tu propuesta, porque eso dejaría los datos de todos los productores visibles y editables por cualquiera sin loguearse—; para qu
todo lo otro no entendí
Ok, dale
pero confo en vos
por fa no te olvides tmp de documentar
así entiendo un cacho
Bueno, mañana documneto
le dijiste a keila?
lo del ttello
Si
decile x el geipo
ah bueno
ok
y lo otro tmb
de la base de datos
Y si vos decís q ya hizo ya está
No puedo hacer nada
Y si vos decís q ya hizo ya está
y no y lo borra nomas
hizo otro poeyecto
no borro el otro
Ah ok
no tenes alguna forma de mandarme lo de los logs y eso
corte codigo
asi le pregunto ya a claude
o hacemos como dije en el audio nomad
esperamos q yo vuelva
no quiero perder una semana más nomas
ese es el tema"

---

## Respuesta técnica al chat de WhatsApp de arriba (2026-08-06)

Esto es para que tu compañero (y quien más lo necesite, incluido otro Claude si le pasan
este archivo) tenga las respuestas concretas a lo que preguntó, sin depender de audios ni de
mensajes sueltos. Va punto por punto, en el mismo orden en que aparecieron las dudas.

### 1. "¿De qué es el campo `id` en `datos_lectura`? ¿`id_animal` es el de SENASA?"

No — **`id_animal` no es el CUIG/SENASA**. Los tres campos de `datos_lectura` son:

| Campo | Qué es |
|---|---|
| `id` | El identificador propio de **esa fila de lectura** (cada vez que un tag pasa por el lector, nace una fila nueva acá con su propio `id` — no tiene que ver con el animal ni con el tag, es solo "esta es la lectura número tal"). |
| `rfid_uid` | El código que viene del chip de la caravana — esto es lo único que la Raspberry Pi lee directamente del hardware. |
| `id_animal` | Una referencia interna a la fila del animal en `datos_animales` (su `id`, no el CUIG de SENASA). Se completa **después**, cuando alguien (la app, o una función en Supabase) cruza el `rfid_uid` leído contra la tabla `datos_animales` y encuentra a qué animal corresponde. |

**Importante para el código de la Raspberry Pi:** no hace falta que la Raspberry sepa ni mande
`id_animal` — ella solo conoce el `rfid_uid` que acaba de leer. El cruce con el animal
correspondiente ya lo hace la app (mirando `datos_animales.rfid_uid`), así que ese campo
puede quedar vacío al insertar la lectura.

### 2. "Hay que modificarle el nombre a los campos de `datos_animales` y `datos_lectura`"

No hace falta tocar nuestras tablas — se quedan con los nombres que ya tienen (son los que
usa la app Flutter, ya probados). Lo que sí hay que hacer es que el código de la Raspberry
Pi (y lo que le hayas pedido a Keila) escriba **exactamente** estos nombres, en vez de los
que estaban en tu propuesta original. Tabla de equivalencia para traducir directo:

| Tu propuesta original | Se usa en su lugar | Tipo real |
|---|---|---|
| tabla `conteos` | tabla `sesiones_conteo` | — |
| `conteos.id` (bigint) | `sesiones_conteo.id` | `uuid` |
| `conteos.estado` | `sesiones_conteo.estado` | `text` — valores: `'activa' / 'pausada' / 'finalizada' / 'descartada'` (falta sumar `'pausada'`, ver punto 3) |
| `conteos.fecha` | `sesiones_conteo.fecha_inicio` / `fecha_fin` | `timestamptz` (son dos campos separados, no uno solo) |
| — (no existía) | `sesiones_conteo.campo_id` | `uuid`, FK a `datos_campo.id` — **obligatorio**, ver punto 4 |
| tabla `lecturas_rfid` | tabla `datos_lectura` | — |
| `lecturas_rfid.uid` | `datos_lectura.rfid_uid` | `text` |
| `lecturas_rfid.conteo_id` | `datos_lectura.sesion_id` | `uuid`, FK a `sesiones_conteo.id` (todavía no existe la columna, se agrega junto con `sesiones_conteo`) |
| `lecturas_rfid.leido_en` | `datos_lectura.fecha_hora` | `timestamptz` |
| tabla `animales` | tabla `datos_animales` | — |
| `animales.uid` | `datos_animales.rfid_uid` | `text` |
| `animales.nombre` | `datos_animales.nombre` | `text` (coincide) |
| — (no existía) | `datos_animales.sexo` | `text` (categoría: vaca/toro/ternero/ternera/vaquillona) |
| — (no existía) | `datos_animales.fertilidad` | `text` (`'buena' / 'regular' / 'mala'`) |
| — (no existía) | `datos_animales.campo_id` | `uuid`, FK a `datos_campo.id` — **obligatorio** |
| `animales.fecha_nacimiento` | *(no se agrega)* | ya se había sacado por decisión con el INTA |

Con esta tabla, tanto vos como Keila pueden traducir mecánicamente cualquier código que ya
tengan escrito, sin tener que adivinar nombres.

### 3. "Lo de inicio/pausa/fin: inicio y fin ya están, pausa no, pero como no está escrito lo puedo cambiar"

Perfecto, es exactamente lo que hace falta — sumale el estado `'pausada'` a la función que
maneja el ciclo de vida del conteo. Recordatorio de los tres ajustes que necesitan tus
funciones para funcionar contra nuestras tablas (ya lo hablamos, lo dejo acá para que quede
en un solo lugar):
1. Que apunten a `sesiones_conteo`, no a una tabla `conteos` nueva.
2. Que el parámetro de conteo/sesión sea `uuid`, no `bigint` (Postgres genera el id solo con
   `gen_random_uuid()`, no hace falta calcularlo a mano).
3. Que reciban también el `campo_id` y lo usen para filtrar — ver el punto siguiente, es la
   parte más importante y la única que todavía no se había resuelto del todo.

### 4. Algo que nadie preguntó todavía pero hay que resolver: ¿cómo sabe la Raspberry Pi a qué campo pertenece?

Esto no salió en el chat, pero es necesario antes de que el código de la Raspberry funcione
de verdad: cada Raspberry Pi está instalada físicamente en un campo/establecimiento
puntual — no es como el login de la app, que cambia de usuario dinámicamente. La solución
más simple: que el script de Python tenga una constante fija con el `campo_id` (el UUID de
`datos_campo`) de **ese** establecimiento, configurada una sola vez cuando se instala esa
Raspberry en ese campo. Ese mismo valor es el que se manda en cada `INSERT` a `datos_lectura`
y el que se le pasa a las funciones de iniciar/pausar/finalizar conteo. Sin esto, no hay
forma de que las políticas de seguridad (RLS) sepan de qué productor son esos datos.

### 5. Punto de atención — "hizo otro proyecto, no borró el otro" (sobre Keila)

Esto quedó bastante confuso en el chat, pero si Keila llegó a crear **un proyecto de
Supabase distinto** al nuestro (`jucndmefmewkjalqnrrv`), es importante confirmarlo y
corregirlo cuanto antes: si su código apunta a otra URL/proyecto, sus datos van a quedar en
una base completamente separada, invisible para la app y para el resto del equipo, aunque
todo el código "funcione" de forma aislada. Antes de que ella siga escribiendo código,
confirmarle el **mismo** `SUPABASE_URL` y que use la `service_role key` de este proyecto
(no una `anon key` de un proyecto propio).

### 6. Lo que ya va bien encaminado (para que no se pierda en medio de las correcciones)

- La idea de sumar `'pausada'` — ya la tenía pensada él mismo, coincide con lo que hacía
  falta.
- La disposición a ajustar los nombres de su lado en vez de insistir con los propios — es
  justo el ajuste que permite no tocar nada de lo que ya funciona en la app.
- Las 3 funciones de ciclo de vida del conteo (iniciar/pausar/finalizar) siguen siendo la
  base correcta, con los 3 ajustes del punto 3.

### 7. Pregunta de seguimiento — "¿necesitás `datos_campo` y `datos_vacuna` para no sacarlas?"

Sí, las dos son necesarias, ninguna se saca:

- **`datos_campo`** — no es "el login" en sí mismo (eso lo maneja Supabase Auth, un sistema
  aparte), pero es la tabla que **conecta** a cada productor logueado con sus propios
  animales — de ella cuelgan las políticas de seguridad (RLS) de `datos_animales`,
  `datos_vacuna`, `datos_lectura` y `sesiones_conteo`. Sin esta tabla no hay forma de separar
  los datos entre productores distintos.
- **`datos_vacuna`** — no tiene relación con el login. Es donde se guarda el historial de
  vacunas de cada animal, que se muestra en la ficha de detalle (Pantalla 4 de la app) —
  funcionalidad real, ya construida y en uso.

**En resumidas cuentas (para el chat):** se agrega únicamente la tabla de sesiones de
conteo; las otras 4 tablas (`datos_campo`, `datos_animales`, `datos_lectura`,
`datos_vacuna`) quedan tal cual están, y del lado de la Raspberry Pi se ajustan los nombres
según la tabla de equivalencia del punto 2.

### 8. "¿Cómo haría el punto 4?" — el `campo_id` fijo, paso a paso en código

Son dos partes: el script de Python de la Raspberry, y la función SQL.

**1. Buscar el UUID real del campo** donde está instalada esa Raspberry puntual:
```sql
SELECT id, nombre_campo FROM datos_campo;
```
Copiar el `id` de la fila que corresponda.

**2. Agregar una constante nueva en el script**, junto a `SUPABASE_URL` y `SUPABASE_KEY`:
```python
CAMPO_ID = "el-uuid-que-copiaste-arriba"
```

**3. Usarla en cada lectura que se manda** (dentro de `mandar_tick`, agregada al payload):
```python
payload = {"rfid_uid": str(uid), "sesion_id": conteo_id, "campo_id": CAMPO_ID}
```

**4. Usarla también al llamar iniciar/pausar/finalizar**, como parámetro extra:
```python
payload = {"campo_id_param": CAMPO_ID}
```

**Importante — esto no es solo del lado de Python:** la función SQL de
`iniciar_o_retomar_conteo` también tiene que recibir ese `campo_id_param` nuevo y usarlo en
su `WHERE` (`where estado = 'pausada' and campo_id = campo_id_param`), para buscar "el
último pausado de **este** campo" en vez de "el último pausado de toda la tabla". Si se
cambia solo el script y no la función, el filtro por campo no hace nada.

### 9. Cómo mostrar dos productores distintos en la expo con una sola Raspberry Pi

Esto une varias dudas sueltas (de Germaioni y de Santiago) sobre cómo armar la demo en vivo.

**El problema real:** con un `campo_id` fijo en el script (punto 8), esa Raspberry queda
atada a un solo campo — no puede mostrar en el mismo momento las vacas de dos productores
distintos, porque en la vida real cada Raspberry está instalada en un único
establecimiento para siempre. Para la expo, con una sola Raspberry física simulando "dos
instalaciones", hace falta poder cambiar de campo entre una parte de la demo y la otra.

**La idea de Germaioni (cambiarlo en vivo) es la correcta** — el único ajuste es *cómo*
cambiarlo, para que sea seguro hacerlo en el momento y no dependa de editar el archivo de
Python en vivo (riesgo de typo, de olvidar guardar, etc.). En vez de eso, un menú simple al
arrancar el script:
```python
CAMPOS = {
    "1": "uuid-del-campo-de-pepe",
    "2": "uuid-del-campo-de-carmelo",
}
campo_elegido = input("¿Qué campo simula esta Raspberry ahora? (1=Pepe, 2=Carmelo): ")
CAMPO_ID = CAMPOS[campo_elegido]
```
Entre una parte de la demo y la otra: cortar el script (`Ctrl+C`), volver a correrlo,
tipear `1` o `2`, listo. No hace falta tocar ni abrir el código en ningún momento durante la
expo. Esto **no es "hacer trampa"** — es la misma separación por `campo_id` que ya protege
todo el sistema en producción; para la demo solo se simula con una Raspberry lo que en la
vida real serían dos Raspberrys distintas, cada una instalada en su propio campo.

**Guion completo de esa parte de la demo, uniendo todo lo ya decidido:**
1. Login con la cuenta de "Pepe" → la app muestra solo el campo/animales de Pepe.
2. Raspberry corriendo con `CAMPO_ID` = campo de Pepe → se acerca un tag ya cargado → tilde
   en tiempo real en la pantalla de conteo (esto **ya funciona hoy**, probado en el
   emulador).
3. Se corta el script de la Raspberry, se vuelve a correr eligiendo el campo de Carmelo.
4. Se cierra sesión en la app, se loguea con la cuenta de Carmelo → la app muestra el campo
   de Carmelo, **nunca** las vacas de Pepe.
5. Se acerca un tag que no está cargado todavía → queda como "no identificado" → se le pone
   nombre ahí mismo, en vivo, delante del jurado.

**Ojo con el paso 5:** esa parte (tag desconocido → aparece como "no identificado" → se le
pone nombre en el momento) **todavía no está programada**, solo está diseñada
conceptualmente (ver `prompts.md` sección 10.6). Si quieren mostrar exactamente ese momento
en la expo, hay que construirla antes — avisar con tiempo para meterla en la lista de
pendientes a implementar.

**Corrección sobre el plan real de la expo (aclarado por Santiago después de escribir esto):**
lo de "acercar un tag desconocido y ponerle nombre en vivo" (paso 5) era solo un ejemplo
ilustrativo dentro de la explicación, **no es lo que se va a probar en la práctica**. Lo que
sí se va a probar es más simple: dos personas cargando su email real en la app, que les
llegue el correo de confirmación, que entren, y que cada una vea su propia interfaz de
productor de forma independiente — eso ya funciona hoy, no depende de nada por construir
(ver resumen del punto 10 más abajo).

---

## 10. Resumen conciso — puntos 7 a 9, en dos versiones

### Versión para mandar por WhatsApp

> "Resumiendo todo lo de hoy: `datos_campo` y `datos_vacuna` quedan las dos, no se tocan —
> una es la base de separar los datos por productor, la otra es el historial de vacunas de
> cada animal, ya en uso. Lo único que se agrega es la tabla de sesiones de conteo.
>
> Para que la Raspberry sepa de qué campo son las lecturas que manda, le agregamos una
> constante fija (`CAMPO_ID`), con un mini-menú al arrancar el script para poder elegir entre
> el campo de prueba 1 o el 2 sin tocar código — así en la expo, para simular dos
> instalaciones distintas con una sola Raspberry, alcanza con reiniciar el script y tipear
> 1 o 2.
>
> Y una corrección sobre lo que vamos a mostrar en la expo: no vamos a probar lo de 'acercar
> un tag nuevo y ponerle nombre en el momento' — eso fue solo un ejemplo, no está programado
> todavía. Lo que sí vamos a probar es más simple: dos personas cargando su email real,
> confirmando por correo, entrando, y cada una viendo su propia interfaz de productor por
> separado — eso ya anda, lo probé esta semana."

### Versión para mí (Santiago) — qué significa esto en criollo

- **No hay que tocar nada de `datos_campo` ni `datos_vacuna`** — quedan exactamente como
  están hoy en la app.
- **El `CAMPO_ID` fijo es un tema pura y exclusivamente de la Raspberry Pi**, para que sepa a
  qué campo mandar las lecturas de tags. No tiene nada que ver con el login de la app — el
  login (email, contraseña, confirmación) es Supabase Auth, un sistema completamente aparte
  que ya funciona.
- **El ejemplo de "acercar un tag desconocido y ponerle nombre en vivo" no es el plan real**
  — lo puse como ilustración de una función que todavía no existe, pero no es lo que van a
  probar en la expo por ahora. No hay que construir nada nuevo para eso todavía.
- **Lo que sí van a probar (dos emails, confirmación, login, interfaz independiente por
  productor) ya está construido y confirmado funcionando** — es exactamente el flujo que se
  probó esta semana en el emulador (sección 10 de `prompts.md`). No falta nada de código
  para esa prueba puntual, solo repetirla con una segunda cuenta.

## 11. Aclaración de hardware — el RFID del prototipo NO es el de las caravanas electrónicas reales

Pregunta de Santiago (2026-08-07): confirmar qué frecuencia/tipo de tag tiene que leer la
Raspberry Pi. Respuesta, releyendo `Carpeta técnica-CowControl.pdf`:

El documento original tiene **dos secciones que no coinciden entre sí**, y vale la pena
tenerlo claro para no confundirse:
- **"Descripción Técnica > Identificación del animal" (página 7):** describe el sistema
  *ideal*, calcado de la caravana electrónica real que usa la ganadería argentina —
  "El sistema RFID trabaja con 134.2 kHz (LF - Baja Frecuencia)... Consta de un módulo
  lector RFID 134.2 kHz FDX-B con antena incluida", y el tag contiene el CUIG (la
  identificación oficial de SENASA).
- **"Componentes a Adquirir" (página 12):** lista lo que se compra de verdad para el
  prototipo — **Módulo RFID RC522**, que es un lector económico de 13.56 MHz (protocolo
  MIFARE), la tecnología estándar que se consigue en Mercado Libre para proyectos con
  Arduino/Raspberry Pi. No es el mismo estándar que la 134.2 kHz de la sección anterior.

**Confirmado: el prototipo usa el RC522 + los "minitags" genéricos (13.56 MHz), no
caravanas electrónicas reales de 134.2 kHz.** Es la decisión correcta para un prototipo de
secundaria — conseguir lectores/tags que cumplan el estándar real de SENASA sería caro y
innecesario, porque el objetivo del prototipo es demostrar el circuito completo (tag → Pi →
Supabase → app en tiempo real), no fabricar un producto agropecuario certificado. La
frecuencia/protocolo exacto del tag no cambia nada del lado de Supabase ni de la app — para
el sistema, un UID es un UID, venga de la tecnología que venga.

## 12. Cómo se integra un productor nuevo con "su" Raspberry Pi

Pregunta de Santiago (2026-08-07): cuando alguien se registra en la app, ¿cómo queda
conectado con la Raspberry Pi correspondiente?

**No hay ningún emparejamiento automático — es un paso manual, una sola vez, al instalar el
hardware.** El flujo real:
1. El productor se registra en la app y crea su campo → Supabase genera un `id` (uuid)
   nuevo para ese `datos_campo`, solo.
2. Alguien (hoy, el equipo de CowControl) toma ese uuid y lo carga a mano como la constante
   `CAMPO_ID` en el script de Python de la Raspberry Pi que se va a instalar en ese campo
   puntual (ver `base_datos.md` sección "8. ¿Cómo haría el punto 4?").
3. De ahí en más, esa Raspberry específica siempre manda sus lecturas con ese `campo_id` —
   no hay forma de que se mezcle con otro productor, porque nunca "elige" un campo, ya
   viene configurada con uno solo.

No es un problema a resolver, es simplemente así — parecido a configurar el nombre de red
en un router WiFi nuevo: se hace una vez, a mano, al instalar el equipo en el lugar físico
donde va a quedar. Para la demo con una sola Raspberry simulando dos campos, la solución ya
charlada (menú `1`/`2` al arrancar el script) es justamente para no tener que repetir este
paso de configuración manual en el medio de la expo.

---