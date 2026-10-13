# Código explicado — lib/screens/

Esta es mi guía mental de las 16 pantallas de la app. Para cada archivo cuento
qué hace, qué hace cada bloque importante y por qué lo armé así, y al final
dejo las preguntas que me pueden llegar a hacer en la presentación. No
reemplaza al código: el detalle fino está en los comentarios de cada `.dart`.
Acá está la versión más explayada, para repasar antes de exponer.

## Índice

1. [login_screen.dart](#login_screendart)
2. [selector_campo_screen.dart](#selector_campo_screendart)
3. [planilla_screen.dart](#planilla_screendart)
4. [conteo_screen.dart](#conteo_screendart)
5. [detalle_animal_screen.dart](#detalle_animal_screendart)
6. [configuracion_screen.dart](#configuracion_screendart)
7. [historial_screen.dart](#historial_screendart)
8. [condicion_corporal_screen.dart](#condicion_corporal_screendart)
9. [estado_fertil_screen.dart](#estado_fertil_screendart)
10. [etapa_vida_screen.dart](#etapa_vida_screendart)
11. [vacunas_screen.dart](#vacunas_screendart)
12. [observaciones_screen.dart](#observaciones_screendart)
13. [video_screen.dart](#video_screendart)
14. [informacion_personal_screen.dart](#informacion_personal_screendart)
15. [cambiar_password_screen.dart](#cambiar_password_screendart)
16. [verificar_codigo_screen.dart](#verificar_codigo_screendart)

---

## login_screen.dart

**Pantalla 0 — Login y registro**

**Qué hace:** Es la puerta de entrada de la app. En una sola pantalla junté el
login y el registro: arriba van el email y la contraseña, y abajo hay un botón
que cambia de modo. También tiene el "¿Olvidaste tu contraseña?", que manda un
mail con un código. Cuando el login sale bien no navego a mano: de eso se
encarga AuthGate, en main.dart.

**Bloques:**

### Imports

Acá explico una sola vez las librerías que se repiten en casi todas las
pantallas. `flutter/material.dart` es la base: todos los widgets visuales
salen de ahí. `supabase_flutter` es el paquete de Supabase, y en el login lo
uso por `AuthException`, el tipo de error que devuelve Supabase Auth. Después
importo `AuthService` (el que hace las llamadas de login y registro), el
widget `PasswordChecklist` y la pantalla `VerificarCodigoScreen`.

### _LoginColors

Es una clase chiquita con los cuatro colores del login: fondo, celeste claro
para los bordes, el principal para botones y links, y el del texto. El resto
de la app usa AppTheme, pero para el login quise una identidad celeste. Tenerlos
como constantes con nombre me evita repetir códigos hex por toda la pantalla, y
si quiero cambiar un tono lo hago en un solo lugar.

### _mensajeError

Supabase devuelve errores con códigos en inglés, como `invalid_credentials` o
`email_not_confirmed`. Esta función los traduce a frases que un productor
entiende ("Email o contraseña incorrectos", "Todavía no confirmaste tu
email"...). Si llega un código que no tengo en la lista, devuelvo un mensaje
genérico que me pasa quien la llama. La uso en `_enviar` y en
`_recuperarPassword`, así los mensajes son iguales en los dos lados.

### _LoginScreenState

Es el estado de la pantalla. Tiene los dos `TextEditingController` (email y
contraseña), la `GlobalKey` del formulario y varias banderas. La más
importante es `_esRegistro`: con eso la misma pantalla sirve para entrar o
para crear cuenta, y cambian el texto del botón, el checklist de contraseña y
la función que llamo. `_cargando` bloquea los botones mientras espero a
Supabase.

### _enviar

Es lo que corre cuando toco el botón principal. Primero valido el formulario
(email con @, contraseña no vacía y, si me estoy registrando, que cumpla los
requisitos). En modo registro llamo a `registrarse` y reviso si la lista
`identities` vino vacía: es la única forma de saber que el mail ya tenía
cuenta, porque Supabase no tira error para no revelar qué mails están
registrados. En modo login llamo a `iniciarSesion` y no hago nada más.

### _recuperarPassword

Es el botón de "¿Olvidaste tu contraseña?". Agarro el email que ya está
escrito en el campo de arriba, y si está vacío o no tiene @ aviso que lo
completen primero. Después le pido a `AuthService` que mande el mail de
restablecer y abro `VerificarCodigoScreen` con ese email. Así el usuario
escribe el código de 6 dígitos adentro de la app y no tiene que abrir un link
en el navegador.

### _temaLogin

Arma un `ThemeData` que vale solo dentro de esta pantalla. Parto del tema
general con `Theme.of(context)` y le piso los colores con los de `_LoginColors`:
fondo, botones elevados, botones de texto, bordes de los campos y el color
del label cuando el campo tiene foco. En `build` envuelvo todo con un widget
`Theme`, y así el celeste no se filtra al resto de la app.

### build

Arma la pantalla: el logo de la vaca, el título "CowControl", los dos campos y
los botones. Todo va adentro de un `Form`, que es lo que me deja validar los
campos de una. Según `_esRegistro` muestro el checklist o el link de
recuperar contraseña. El checklist está dentro de un `ValueListenableBuilder`,
así se redibuja solo esa parte en cada tecla y no el campo entero (redibujarlo
completo daba problemas con el teclado de Android).

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué no navegás a la siguiente pantalla después del login?** — Porque
  AuthGate, en main.dart, escucha los cambios de sesión de Supabase. Apenas
  hay sesión, cambia la pantalla solo. Si navegara a mano, serían dos lugares
  decidiendo lo mismo.
- **¿Cómo sabés si un mail ya está registrado si Supabase no da error?** —
  Porque cuando el mail ya existe, la respuesta trae la lista `identities`
  vacía, y en un registro nuevo viene con datos.
- **¿Por qué la regla de contraseña solo se pide al registrarse?** — Porque
  una cuenta vieja puede tener una contraseña más corta que la regla de ahora,
  y no quiero dejarla afuera.

---

## selector_campo_screen.dart

**Pantalla 1 — Selector de campo**

**Qué hace:** Es la primera pantalla después del login. Muestro la lista de
campos del productor, y cada campo abre su planilla. Si el productor tiene un
solo campo, me salteo la lista y lo mando directo a la planilla. Si no tiene
ninguno, le muestro un botón para crear el primero. Desde acá también se puede
cerrar sesión.

**Bloques:**

### Imports

Sumo dos cosas que no estaban en el login. `models/campo.dart` tiene la clase
`Campo`, que representa un campo con su id, su nombre y su ubicación. Y
`services/campos_service.dart` es el que habla con Supabase para traer y crear
campos. También importo `planilla_screen.dart`, porque es adonde voy cuando el
usuario elige un campo.

### _cargarCampos

Le pido a `CamposService` la lista de campos. No filtro por usuario en la app:
Supabase tiene RLS (Row Level Security), que hace que cada productor vea solo
sus filas. Si la lista tiene un solo campo, uso `addPostFrameCallback` para
esperar a que termine de dibujarse la pantalla y recién ahí hago un
`pushReplacement` a la planilla. Es "replacement" para que el botón de atrás no
vuelva a una lista de un solo elemento.

### _recargar

Es una función de una línea que vuelve a llamar a `_cargarCampos` adentro de
un `setState`. Al cambiar el `Future`, el `FutureBuilder` del `build` arranca
de nuevo: muestra la ruedita y después la lista actualizada. La uso después de
crear un campo, para que el nuevo aparezca sin tener que salir y volver a
entrar.

### _crearCampo

Abre `_FormularioNuevoCampo` con `showDialog` y se queda esperando lo que
devuelve. Si el usuario tocó "Cancelar", el diálogo devuelve null y corto
ahí. Si completó los datos, recibo un `_DatosNuevoCampo`, se lo paso a
`CamposService.crearCampo` y después llamo a `_recargar`. Lo usan tanto el
botón flotante "+" como el botón de "Crear mi primer campo".

### build

La pantalla se apoya en un `FutureBuilder`, que dibuja según el estado del
`Future` de campos. Hay cuatro casos: cargando (ruedita), error (texto con el
error), lista vacía (mensaje y botón de crear) y lista con datos
(`ListView.builder` con un `ListTile` por campo). En la barra de arriba está el
botón de cerrar sesión: solo llama a `cerrarSesion`, y AuthGate me devuelve al
login.

### _DatosNuevoCampo

Es una clase chiquita, sin lógica, que guarda el nombre y la ubicación del
campo nuevo. Existe porque `Navigator.pop` devuelve un solo valor, y yo
necesitaba sacar dos datos del diálogo. Entonces los empaqueto en este objeto
y el que abrió el diálogo los desarma. La ubicación es `String?` porque es
opcional.

### _FormularioNuevoCampo

Es el diálogo de "Nuevo campo". Es un `StatefulWidget` porque necesita sus
propios controllers para los dos campos de texto, y los libera en `dispose`.
El nombre es obligatorio (el validador no deja pasar un texto vacío) y la
ubicación es opcional. Al tocar "Crear" valido y cierro con `pop` devolviendo
los datos, y si la ubicación quedó vacía la mando como null.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Cómo sabe la app qué campos son de cada productor?** — No lo filtro yo:
  Supabase tiene RLS, que según el usuario logueado devuelve solo sus filas.
- **¿Por qué usás `addPostFrameCallback` para entrar directo?** — Porque no se
  puede navegar mientras se está dibujando la pantalla. Espero a que termine
  el frame y ahí navego.
- **¿Qué pasa si falla la creación de un campo?** — Hoy `_crearCampo` no
  atrapa el error con un try/catch, así que no se muestra un mensaje lindo. Es
  una mejora pendiente.

---

## planilla_screen.dart

**Pantalla 2 — Planilla general del campo**

**Qué hace:** Es la pantalla principal del día a día. Muestro todos los
animales vivos del campo que se eligió, con un buscador y un filtro por
categoría. Abajo aparecen los tags RFID que leyó el lector pero que todavía no
son de ningún animal ("No registrados"), y se pueden borrar o dar de alta. Al
final está el botón "Iniciar Conteo", y arriba el engranaje de configuración.

**Bloques:**

### Imports

Esta pantalla usa bastantes piezas nuevas. Del lado de los datos: el modelo
`Animal`, `AnimalesService` (traer y crear animales) y `LecturasService` (las
lecturas del lector RFID, de donde salen los no registrados). Del lado visual:
`app_theme.dart` (con `AppColors`), `AnimalCard` (la tarjeta de cada animal),
`CategoriaBadge` (la etiqueta de color por categoría) y `DialogoAltaAnimal`
(el formulario para dar de alta un animal).

### _PlanillaScreenState

Es el estado de la pantalla. En `initState` arranco dos pedidos a la vez: los
animales del campo y los tags no registrados. Cada uno queda guardado como un
`Future`, y cada `FutureBuilder` del `build` dibuja el suyo. `_categoriaFiltro`
guarda lo que se eligió en el desplegable (null quiere decir "Todas") y
`_categorias` es la lista fija: vaca, toro, ternero, ternera y vaquillona.

### _recargar

Vuelve a pedir las dos listas a Supabase y reemplaza los `Future` dentro de un
`setState`, así los `FutureBuilder` se redibujan con los datos nuevos. Es
`async` porque el `RefreshIndicator` (tirar la lista para abajo) necesita una
función que devuelva un `Future`. También la llamo después de agregar o borrar
un tag y al volver de la pantalla de conteo, porque ahí pueden haber cambiado
los datos.

### _eliminarNoRegistrado

Le pide a `LecturasService` que descarte un tag en este campo y después
recarga, así el tag desaparece de la lista de "No registrados". Recibe el
`rfidUid`, que es el código que tiene grabado cada tag RFID. El botón
"Eliminar" no la llama directamente: pasa primero por `_confirmarEliminar`.
Lo separé así para que la confirmación y el borrado real queden en dos
funciones distintas.

### _confirmarEliminar

Muestra un diálogo de "¿Estás seguro?" con el código del tag. El diálogo
devuelve `true` si tocan "Eliminar" y `false` si tocan "Cancelar" (o null si
lo cierran tocando afuera). Solo si vuelve exactamente `true` llamo a
`_eliminarNoRegistrado`. Es una protección simple para que nadie borre un tag
por un toque sin querer.

### _agregarNoRegistrado

Es la otra salida de un tag no registrado: convertirlo en un animal. Abro
`DialogoAltaAnimal`, donde se carga la categoría, el animalId, el apodo y la
raza. Si no cancelan, llamo a `AnimalesService.crearAnimal` con esos datos más
el `rfidUid` del tag y el id del campo. Después recargo, así el tag sale de
"No registrados" y el animal aparece en la planilla.

### _filtrar

Recibe la lista completa de animales y lo que está escrito en el buscador, y
devuelve solo los que pasan los dos filtros. El buscador compara contra el
`animalId` del animal, pasando todo a minúsculas para que no importe cómo se
escriba. El filtro de categoría compara contra `_categoriaFiltro`. Si alguno
de los dos está vacío ("Todas" o buscador en blanco), esa condición deja pasar
a todos.

### build

Está armado en una columna. Arriba van el buscador y el desplegable de
categoría (cada opción con su `CategoriaBadge`). En el medio, la lista de
animales: un `FutureBuilder` y adentro un `ValueListenableBuilder`, así en
cada tecla del buscador se redibuja solo la lista y no el campo de texto.
Abajo, la sección "No registrados" con "Eliminar" y "Añadir" por tag, y el
botón "Iniciar Conteo", que espera la lista de animales, abre `ConteoScreen` y
al volver recarga.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Qué es un "no registrado"?** — Un tag RFID que el lector leyó en el campo
  pero que no está asociado a ningún animal. Lo puedo dar de alta como animal
  nuevo o descartarlo.
- **¿Por qué el buscador usa un `ValueListenableBuilder`?** — Para que en cada
  tecla se redibuje solo la lista. Si se redibujaba el campo de texto
  completo, el teclado de Android a veces guardaba algo distinto de lo que se
  escribió.
- **¿Por qué el conteo recibe la lista de animales ya cargada?** — Porque la
  planilla ya la trajo de Supabase. Se la paso a `ConteoScreen` y me ahorro
  pedirla dos veces.

---

## conteo_screen.dart

**Pantalla 3 — Conteo en vivo**

**Qué hace:** Es la pantalla que se usa mientras los animales pasan por la
manga. Escucho las lecturas del lector RFID en tiempo real (Supabase Realtime)
y voy marcando cada animal apenas pasa, con un contador "X / Y detectados".
Además manejo la fila del conteo en la tabla `conteos`, que es la que consulta
la Raspberry Pi para saber a qué conteo mandarle lo que va leyendo. Los tags
que no son de ningún animal quedan en "Sin identificar" y se pueden dar de alta
ahí mismo.

**Bloques:**

### Imports

Lo nuevo acá es `supabase_flutter`, que lo necesito por el tipo
`RealtimeChannel` (el canal que queda escuchando). Del lado de los datos sumo
el modelo `Lectura` (una fila de `datos_lectura`), `ConteosService` (la fila
del conteo en la tabla `conteos`) y `LecturasService` (abrir y cerrar la
escucha). `AnimalesService` y `DialogoAltaAnimal` los reuso de la planilla para
dar de alta los tags sin identificar.

### _ConteoScreenState

Es el estado del conteo. `_idsDetectados` es un `Set`, que no repite
elementos: si un animal pasa dos veces por el lector, cuenta una sola.
`_sinIdentificar` es la lista de tags que no son de nadie. `_animales` es una
copia de la lista que me pasa la planilla, así le puedo sumar los animales que
doy de alta durante el conteo. `_canal` es la escucha de Realtime, `_conteoId`
la fila del conteo en Supabase y `_enPausa` dice qué botón mostrar.

### _inicializarConteo

La llamo desde `initState`. Le pido a `ConteosService.iniciarOReanudar` un
conteo para este campo: si había uno pausado lo retoma, y si no, crea uno
nuevo. Me guardo su id y recién después abro la escucha de lecturas, así
cuando empiezan a llegar ya tengo el conteo armado.

### _empezarAEscuchar

Le pido a `LecturasService` que se suscriba a las lecturas nuevas de este
campo. Cada vez que el lector registra un tag, Supabase me avisa y se ejecuta
`_marcarLectura` con esa lectura. El canal queda guardado en `_canal` para
poder cerrarlo después: al detener, al finalizar o al salir de la pantalla.

### _marcarLectura

Es lo que pasa con cada lectura que llega. Recorro los animales buscando el
que tenga el mismo `rfidUid` que la lectura. Si lo encuentro, agrego su id a
`_idsDetectados` y su tarjeta pasa a mostrarse como detectada. Si no es de
ningún animal, el tag va a "Sin identificar", pero una sola vez aunque el
lector lo vuelva a leer.

### _asignarCategoria

Es para dar de alta un tag sin identificar en el momento, viendo al animal
pasar. Abro el mismo `DialogoAltaAnimal` que en la planilla. Si no cancelan,
creo el animal en Supabase con el `rfidUid` del tag, lo saco de "Sin
identificar", lo sumo a la lista de animales y lo marco como detectado, porque
ya pasó por el lector.

### _detener

Pausa el conteo. Cierro la escucha de Realtime y le aviso a `ConteosService`
que el conteo queda pausado en la tabla `conteos`. El botón pasa a decir
"Reanudar". Antes del `setState` chequeo `mounted`, por si el usuario ya se fue
de la pantalla mientras esperaba la respuesta de Supabase.

### _reanudar

Es lo contrario de `_detener`: reanudo el conteo en Supabase y vuelvo a abrir
la escucha. Lo que ya estaba detectado no se pierde, porque `_idsDetectados`
sigue en memoria mientras la pantalla esté abierta.

### _finalizar

Cierra el conteo del todo. Dejo de escuchar, marco el conteo como finalizado
en Supabase y vuelvo a la planilla con `Navigator.pop`. La planilla, al volver,
recarga sus datos (eso está en `planilla_screen.dart`).

### dispose

Cuando se cierra la pantalla, cierro el canal de Realtime. Si no lo hiciera,
Supabase seguiría mandando lecturas a una pantalla que ya no existe. Ojo: acá
solo dejo de escuchar, no pauso ni finalizo el conteo en Supabase (está
marcado como TODO en el código para revisarlo).

### build

Arriba muestro el contador "X / Y detectados". Si hay tags sin identificar
aparece un aviso bordó que pide pausar para completar los datos. En el medio
está la lista de `AnimalCard` (cada una abre el detalle del animal) y debajo
los "Sin identificar", que al tocarlos abren `_asignarCategoria`. Abajo van
dos botones: Detener/Reanudar (cambia según `_enPausa`) y Finalizar.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Cómo se entera la app de que pasó un animal?** — Por Supabase Realtime.
  La Pi guarda cada lectura en `datos_lectura` y Supabase le avisa a la app al
  instante, sin que la app tenga que estar preguntando todo el tiempo.
- **¿Qué pasa si un animal pasa dos veces?** — Cuenta una sola. Los detectados
  se guardan en un `Set`, que no admite repetidos.
- **¿Para qué sirve la tabla `conteos`?** — Para que la Pi sepa qué conteo está
  en curso y a cuál asociar las lecturas. Por eso pausar, reanudar y finalizar
  también se guardan en Supabase, no solo en la pantalla.
- **¿Qué pasa si salen del conteo con la flecha de atrás?** — Se cierra la
  escucha, pero el conteo no queda pausado en Supabase. Es un punto que
  tenemos anotado para revisar.

---

## detalle_animal_screen.dart

**Pantalla 4 — Detalle (ficha) de un animal**

**Qué hace:** Es la ficha de un animal. Se abre desde el `onVerMas` de una
`AnimalCard`, tanto en la planilla como en el conteo. Arriba muestro la
categoría y el nombre del animal, con un lápiz para editar sus datos básicos.
Abajo hay un menú con cada dato: raza, condición corporal, estado fértil (solo
hembras), etapa de vida, vacunas, observaciones y video. Cada fila abre su
sub-pantalla.

**Bloques:**

### Imports

Lo nuevo son los tres chips (`CondicionCorporalChip`, `EstadoFertilChip` y
`EtapaVidaChip`), que muestran el valor actual con un color a la derecha de
cada fila, y las seis sub-pantallas de edición que se abren desde el menú.
`AnimalesService` y `DialogoAltaAnimal` los reuso para editar los datos
básicos con el lápiz.

### _DetalleAnimalScreenState

Guardo una copia del animal en `_animal`. Arranca con el que me pasó la
pantalla anterior, y la reemplazo cada vez que una sub-pantalla o el lápiz me
devuelven el animal ya guardado. Así la ficha siempre muestra lo último, sin
tener que volver a pedirlo a Supabase.

### _abrir

Es la forma común de abrir una sub-pantalla. Hago `push` y espero a que el
usuario vuelva. Si la sub-pantalla me devuelve un `Animal` (porque se guardó
un cambio), lo pongo en `_animal` con `setState` y los chips se redibujan con
el valor nuevo. Si vuelven sin guardar, llega `null` y no toco nada.

### _editar

Lo llama el lápiz de arriba y también la fila de Raza. Reuso
`DialogoAltaAnimal`, el mismo del alta, pero precargado con los datos actuales
(animalId, apodo, categoría y raza). Si no cancelan, guardo con
`AnimalesService.actualizarDatosAnimal` y me quedo con el animal que devuelve
Supabase.

### _categoriasHembra

Es el conjunto de categorías que son hembras: vaca, ternera y vaquillona. Lo
uso en `build` para decidir si muestro la fila de Estado Fértil, porque para
un toro o un ternero no tiene sentido.

### build

Arriba, el `CategoriaBadge` y el nombre del animal, centrados. El `SizedBox`
de 48 a la izquierda está para compensar el ancho del lápiz de la derecha, así
el nombre queda en el medio de verdad. Abajo, una `_FilaMenu` por cada dato.
Condición corporal, estado fértil, etapa de vida y observaciones se abren con
`_abrir`; Vacunas y Video, con un `push` común, sin esperar nada de vuelta.

### _FilaMenu

Es una fila del menú: un `ListTile` con un ícono (o una imagen de assets, como
la vaca de Raza), el nombre del dato y, a la derecha, el chip con el valor. El
`assert` obliga a pasar al menos un ícono o una imagen. Al chip le pongo un
ancho máximo de 170 para que no le tape el texto a la etiqueta.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué Estado Fértil no aparece en todos los animales?** — Porque solo
  aplica a hembras. Si la categoría no es vaca, ternera o vaquillona, la fila
  no se muestra.
- **¿Cómo se actualiza la ficha después de editar algo?** — La sub-pantalla me
  devuelve el animal ya guardado y lo reemplazo en `_animal` con `setState`. No
  hace falta volver a consultar Supabase.
- **¿Por qué se reusa el diálogo del alta para editar?** — Porque son los
  mismos campos. Le paso los valores actuales para que aparezcan precargados.

---

## configuracion_screen.dart

**Sub-pantalla de la Pantalla 2 — Configuración (engranaje de la planilla)**

**Qué hace:** Es un menú chico al que se entra desde el engranaje de la
planilla. Tiene tres opciones: Historial de lecturas, Información Personal y
Cerrar sesión. Antes el historial estaba directo en la barra de arriba de la
planilla; lo pasé acá para juntar todo lo que no es del día a día en un solo
lugar.

**Bloques:**

### Imports

Lo nuevo es `../main.dart`, de donde saco `AuthGate` (la pantalla que decide
si mostrar el login o entrar directo), y `AuthService`, que es el que cierra la
sesión en Supabase. Además importo las dos pantallas a las que se puede ir
desde acá: `HistorialScreen` e `InformacionPersonalScreen`.

### _confirmarCerrarSesion

Primero muestro un diálogo de "¿Estás seguro?" con "No" y "Sí". Solo si
vuelve `true` cierro la sesión con `AuthService().cerrarSesion()`. Después uso
`pushAndRemoveUntil` para borrar toda la pila de pantallas y dejar solo
`AuthGate`. Vuelvo a `AuthGate` y no a un `LoginScreen` suelto porque así,
cuando alguien inicia sesión de nuevo, la app avanza sola (está explicado en
el comentario dentro del código).

### build

Es una lista con tres `ListTile`: Historial de lecturas (abre
`HistorialScreen` con el campo actual), Información Personal (abre
`InformacionPersonalScreen`) y Cerrar sesión (llama a
`_confirmarCerrarSesion`). Es un `StatelessWidget` porque no guarda nada que
cambie: solo navega.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué al cerrar sesión no se puede volver atrás?** — Porque uso
  `pushAndRemoveUntil` con `(route) => false`, que borra todas las pantallas
  anteriores. Si no, con el botón de atrás se volvía a la planilla sin sesión.
- **¿Por qué es `StatelessWidget`?** — Porque no tiene datos propios que
  cambien. Solo recibe el campo y abre otras pantallas.
- **¿Por qué hay una confirmación antes de cerrar sesión?** — Para que nadie
  cierre la sesión por un toque sin querer, sobre todo en el campo.

---

## historial_screen.dart

**Pantalla 5 — Historial de lecturas**

**Qué hace:** Muestra las últimas lecturas que hizo el lector RFID en el campo
actual, la más reciente primero. Cada fila muestra la fecha y la hora de una
lectura. Se entra desde Configuración (el engranaje de la planilla).

**Bloques:**

### Imports

Solo sumo el modelo `Lectura` (de cada lectura uso su `fechaHora`) y
`LecturasService`, que es el que trae el historial desde Supabase con
`traerHistorial`, pasándole el id del campo.

### _HistorialScreenState

En `initState` arranco el pedido del historial y guardo el `Future` en
`_futureLecturas`. Lo hago ahí y no adentro del `build` porque el `build` se
puede ejecutar muchas veces, y cada vez estaría pidiendo los datos de nuevo a
Supabase.

### _formatearFecha

Recibe un `DateTime` y lo devuelve como texto "dd/mm/aaaa hh:mm". Primero lo
paso a la hora local con `toLocal()`, porque Supabase guarda las fechas en
UTC y si no se verían tres horas corridas. Después uso `padLeft(2, '0')` para
que los números de un dígito tengan un cero adelante ("05/03" en vez de
"5/3").

### build

Todo está dentro de un `FutureBuilder`, que cubre los cuatro casos posibles:
mientras carga muestro una ruedita, si hay error muestro el mensaje, si la
lista viene vacía muestro "Todavía no hay lecturas registradas", y si hay
datos armo un `ListView.builder` con una fila por lectura. `ListView.builder`
solo dibuja las filas que se ven en pantalla, así no se pone lento si hay
muchas lecturas.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué se llama a `toLocal()`?** — Porque Supabase guarda la fecha en
  UTC. Con `toLocal()` la paso a la hora del celular, que en Argentina es UTC-3.
- **¿Por qué el pedido está en `initState` y no en `build`?** — Porque el
  `build` se repite cada vez que la pantalla se redibuja. En `initState` se
  pide una sola vez.
- **¿Cómo sabe de qué campo mostrar las lecturas?** — Configuración le pasa
  el campo actual, y yo le paso su id a `traerHistorial`.

---

## condicion_corporal_screen.dart

**Sub-pantalla de la Pantalla 4 — Condición corporal**

**Qué hace:** Se abre desde la fila "Condición Corporal" de la ficha del
animal. Tiene un desplegable con tres opciones (Buena, Regular y Mala) y un
botón Guardar. Al lado de cada opción muestro el rango de la escala de
condición corporal de 1 a 5 que usa el INTA, pero es solo de referencia: en
Supabase se guarda la palabra ("buena", "regular" o "mala"), no un número.

**Bloques:**

### Imports

Solo sumo `AnimalesService`, que es el que guarda el cambio en Supabase. El
modelo `Animal` ya lo conocía de las pantallas anteriores.

### _CondicionCorporalScreenState

Tiene dos datos. `_condicionSeleccionada` arranca con el valor que ya tenía el
animal (o `null` si nunca se cargó) y cambia cuando elijo otra opción.
`_guardando` está en `true` mientras espero la respuesta de Supabase; lo uso
para deshabilitar el botón, así nadie lo toca dos veces y se guarda doble.

### _guardar

Pongo `_guardando` en `true`, actualizo el animal con
`AnimalesService.actualizarAnimal` y hago `pop` devolviendo una copia del
animal con el valor nuevo (`copyWith`). Esa copia es la que recibe `_abrir` en
la ficha para actualizar el chip sin volver a consultar Supabase. El `finally`
apaga `_guardando` aunque algo falle.

### build

Es una columna con el `DropdownButtonFormField` y el botón Guardar. Cada
opción del desplegable es una `_FilaCondicion`. Si el animal no tenía dato, se
ve "Sin dato". Mientras guarda, el botón queda deshabilitado y muestra una
ruedita chiquita en lugar del texto.

### _FilaCondicion

Es una opción del desplegable: la categoría a la izquierda y el rango en gris
a la derecha. La etiqueta va dentro de un `Expanded`, que ocupa todo el
espacio que sobra y empuja el rango contra el borde. Así siempre queda
separación entre los dos; antes se veía "3.5Regular" todo pegado.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué se guarda "buena/regular/mala" y no el número de 1 a 5?** —
  Porque la base ya guardaba esas tres categorías desde antes. El rango del
  INTA lo sumé solo como referencia visual, sin cambiar lo que se guarda.
- **¿Cómo se entera la ficha del cambio?** — Al guardar hago `pop` con el
  animal ya actualizado, y la ficha lo recibe y lo reemplaza.
- **¿Para qué sirve `_guardando`?** — Para deshabilitar el botón mientras se
  guarda. Si no, un doble toque podía mandar el pedido dos veces.

---

## estado_fertil_screen.dart

**Sub-pantalla de la Pantalla 4 — Estado fértil**

**Qué hace:** Se abre desde la fila "Estado Fértil" de la ficha del animal, y
esa fila solo aparece si el animal es hembra (vaca, ternera o vaquillona). Tiene
un desplegable con tres estados (Preñada, Amamantando y No fecundada) y un
botón Guardar. Está armada igual que la de condición corporal.

**Bloques:**

### Imports

Igual que en condición corporal: solo sumo `AnimalesService` para guardar el
cambio en Supabase.

### _EstadoFertilScreenState

`_estadoSeleccionado` arranca con el estado que ya tenía el animal (o `null`
si nunca se cargó) y cambia al elegir otra opción. `_guardando` deshabilita el
botón mientras espero la respuesta de Supabase, para que no se guarde dos
veces.

### _guardar

Pongo `_guardando` en `true`, actualizo el animal con
`AnimalesService.actualizarAnimal` pasándole solo el `estadoFertil`, y hago
`pop` con una copia del animal que ya tiene el valor nuevo. La ficha recibe
esa copia y actualiza el chip. El `finally` apaga `_guardando` aunque falle.

### build

Una columna con el desplegable y el botón Guardar. Cada opción tiene un
`value`, que es lo que se guarda en Supabase ("preñada", "amamantando" o
"no-fecundada"), y un texto, que es lo que ve el usuario. Si el animal no
tenía dato, se ve "Sin dato". Mientras guarda, el botón muestra una ruedita.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué solo se puede cargar en hembras?** — Porque preñez o
  amamantamiento no aplican a toros ni terneros. La ficha esconde la fila si la
  categoría no es de hembra.
- **¿Por qué esta pantalla se parece tanto a la de condición corporal?** —
  Porque hacen lo mismo: elegir un valor de una lista corta y guardarlo en el
  animal. Usé la misma estructura para que sean fáciles de mantener.
- **¿Qué se guarda en la base?** — El `value` de la opción elegida, por
  ejemplo "no-fecundada", no el texto que se ve en pantalla.

---

## etapa_vida_screen.dart

**Sub-pantalla de la Pantalla 4 — Etapa de vida**

**Qué hace:** Se abre desde la fila "Etapa de Vida" de la ficha del animal.
Tiene un desplegable con cinco etapas (Muy joven, Para destetar, Para
vender/carnear, Adulto fértil y Adulto mayor) y un botón Guardar. A diferencia
de estado fértil, aparece para todos los animales. Está armada igual que las
de condición corporal y estado fértil.

**Bloques:**

### Imports

Igual que las otras dos: solo sumo `AnimalesService` para guardar el cambio en
Supabase.

### _EtapaVidaScreenState

`_etapaSeleccionada` arranca con la etapa que ya tenía el animal (o `null` si
nunca se cargó). `_guardando` deshabilita el botón mientras espero la
respuesta de Supabase.

### _guardar

Actualizo el animal con `AnimalesService.actualizarAnimal` pasándole solo la
`etapaVida`, y hago `pop` con una copia del animal que ya tiene el valor
nuevo, para que la ficha actualice el chip. El `finally` apaga `_guardando`
aunque falle.

### build

Una columna con el desplegable y el botón Guardar. Cada opción tiene un
`value` escrito sin espacios ni mayúsculas (por ejemplo `para_vender_carnear`),
que es lo que se guarda en Supabase, y un texto que es lo que ve el usuario.
Si no tenía dato, se ve "Sin dato".

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué los valores se guardan con guion bajo?** — Para que en la base
  sean siempre iguales, sin espacios ni mayúsculas, y comparar sea fácil. El
  texto lindo es solo para mostrar.
- **¿Las tres sub-pantallas de edición son iguales?** — Sí, condición
  corporal, estado fértil y etapa de vida tienen la misma estructura: un
  desplegable, un botón Guardar y un `pop` con el animal actualizado. Lo único
  que cambia son las opciones y el campo que se guarda.

---

## vacunas_screen.dart

**Sub-pantalla de la Pantalla 4 — Vacunas**

**Qué hace:** Se abre desde la fila "Vacunas" de la ficha del animal. Arriba
hay un formulario para cargar una vacuna nueva (nombre y fecha) y abajo la
lista de todas las vacunas del animal, la más nueva primero. A diferencia de
las otras sub-pantallas, acá no edito el animal en sí: las vacunas se guardan
en otra tabla (`datos_vacuna`). Por eso la ficha la abre con un `push` común,
sin esperar nada de vuelta.

**Bloques:**

### Imports

Sumo el modelo `Vacuna` (nombre y fecha de una vacuna) y `VacunasService`, que
trae y agrega vacunas en la tabla `datos_vacuna` de Supabase.

### _VacunasScreenState

`_nombreVacunaController` guarda lo que se escribe en el campo del nombre.
`_fechaVacunaSeleccionada` guarda la fecha elegida, o `null` si todavía no
eligieron. `_futureVacunas` es el pedido de la lista, que arranco en
`initState`. En `dispose` libero el controller, como en cualquier pantalla con
campos de texto.

### _formatearFecha

Pasa la fecha a "dd/mm/aaaa". Es la misma idea que en el historial, pero sin
la hora, porque de una vacuna solo importa el día. Con `padLeft` le pongo un
cero adelante a los números de un dígito.

### _elegirFecha

Abre el calendario de Flutter (`showDatePicker`). Se puede elegir cualquier
día desde 2020 hasta hoy; las fechas futuras no aparecen, porque no tiene
sentido cargar una vacuna que todavía no se dio. Si cierran el calendario sin
elegir, llega `null` y no cambio nada.

### _agregarVacuna

Si el nombre está vacío no hago nada. Si no, guardo la vacuna con
`VacunasService.agregarVacuna`, limpio el campo de texto y la fecha, vuelvo a
pedir la lista (así aparece la nueva) y muestro un `SnackBar` que dice
"Vacuna agregada.". La fecha es opcional: si no eligen, el servicio no la
manda (está marcado como TODO qué queda guardado en ese caso).

### build

Arriba, en una fila, el campo del nombre y al lado el botón de fecha (dice
"Elegir fecha" o la fecha ya elegida). Debajo, el botón "Agregar vacuna". El
resto de la pantalla es un `FutureBuilder` con la lista: cada fila muestra el
nombre y, si tiene fecha, la fecha al lado. Si no hay ninguna, muestro "Sin
vacunas registradas.".

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué las vacunas no se guardan en la tabla del animal?** — Porque un
  animal puede tener muchas vacunas. Van en `datos_vacuna`, cada una apuntando
  al animal por su id.
- **¿Se puede cargar una vacuna con fecha futura?** — No. El calendario llega
  como máximo hasta hoy.
- **¿Qué pasa si falla la carga de la lista?** — El `FutureBuilder` no separa
  el caso de error, así que se vería "Sin vacunas registradas.". Es algo a
  mejorar.

---

## observaciones_screen.dart

**Sub-pantalla de la Pantalla 4 — Observaciones**

**Qué hace:** Se abre desde la fila "Observaciones" de la ficha del animal.
Arriba hay un campo para escribir una observación nueva y abajo la lista de
todas las observaciones del animal, la más nueva primero, cada una con su
fecha. Cada observación es una fila en la tabla `datos_observacion`. Antes era
una sola columna de texto en `datos_animales` que se pisaba cada vez que se
escribía algo nuevo.

**Bloques:**

### Imports

Sumo el modelo `Observacion` (el texto y la fecha en que se cargó) y
`ObservacionesService`, que trae y agrega observaciones en la tabla
`datos_observacion` de Supabase.

### _ObservacionesScreenState

`_nuevaObservacionController` guarda lo que se escribe en el campo,
`_futureObservaciones` es el pedido de la lista (lo arranco en `initState`) y
`_guardando` deshabilita el botón mientras espero a Supabase. En `dispose`
libero el controller.

### _formatearFecha

Es la misma función que en vacunas: pasa la fecha a "dd/mm/aaaa", con un cero
adelante en el día y el mes si tienen un solo dígito.

### _agregarObservacion

Si el texto está vacío (o son solo espacios, por el `trim()`) no hago nada. Si
no, pongo `_guardando` en `true`, guardo con
`ObservacionesService.agregarObservacion`, limpio el campo y vuelvo a pedir la
lista para que aparezca la nueva. El `finally` apaga `_guardando` aunque algo
falle.

### build

Arriba, el campo de texto de 3 líneas y el botón "Agregar observación", que
muestra una ruedita mientras guarda. Abajo, un `FutureBuilder` con la lista:
cada fila muestra el texto de la observación y, debajo, la fecha en que se
cargó. Si no hay ninguna, muestro "Sin observaciones.".

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué las observaciones van en otra tabla?** — Porque antes era una
  sola columna en el animal y cada observación nueva borraba la anterior.
  Ahora cada una es una fila aparte y queda el historial completo.
- **¿De dónde sale la fecha de cada observación?** — Del campo `creadoEn` de
  cada observación, que es cuándo se guardó en Supabase.
- **¿Por qué el botón se deshabilita mientras guarda?** — Para que un doble
  toque no cargue la misma observación dos veces.

---

## video_screen.dart

**Sub-pantalla de la Pantalla 4 — Video del animal**

**Qué hace:** Se abre desde la fila "Video" de la ficha del animal. Busca el
video del último conteo en el que pasó ese animal y lo muestra completo, con
play/pausa y una barra para adelantar o retroceder. Abajo hay un botón que
salta directo al momento en que el lector leyó al animal (un segundo antes,
para verlo llegar).

**Bloques:**

### Imports

Lo nuevo es `video_player`, el paquete oficial de Flutter para reproducir
videos: de ahí salen `VideoPlayerController` (maneja el video), `VideoPlayer`
(lo dibuja) y `VideoProgressIndicator` (la barra de progreso). También sumo
`VideoService`, que busca el segmento de video del animal y me da la URL para
bajarlo.

### _VideoScreenState

`_antesDelAnimal` es una constante de 1 segundo: cuánto antes del animal salta
el botón. `_c` es el controlador del video (vale `null` hasta que termina de
cargar), `_seg` es el segmento que encontré para este animal (de ahí saco en
qué segundo aparece), y `_cargando` y `_error` me dicen qué mostrar mientras
tanto.

### _momentoAnimal

Es un getter que calcula a qué momento del video tiene que saltar el botón.
`_seg.inicio` viene en segundos: lo paso a milisegundos y le resto el segundo
de `_antesDelAnimal`. Si el animal aparece en el segundo 0, la resta daría
negativo, así que en ese caso uso 0.

### _formatear

Pasa una duración a "m:ss" (por ejemplo "2:05") para mostrarla en el texto del
botón. Con `padLeft` le pongo el cero a los segundos de un dígito.

### _cargar

Se llama desde `initState`. Le pido a `VideoService` el último segmento donde
aparece el `rfidUid` del animal. Si no hay ninguno, apago `_cargando` y la
pantalla muestra "todavía no tiene video". Si hay, pido la URL firmada del
archivo, creo un `VideoPlayerController` con esa URL y lo inicializo. Está
todo en un `try/catch`: si algo falla, guardo el error para mostrarlo. Los
`debugPrint` son solo para ver en la consola qué RFID se buscó y qué se
encontró.

### _alternarPlayPause

Es el botón de play/pausa: si el video se está reproduciendo lo pauso, y si
no, lo reproduzco.

### _irAlAnimal

Es el botón grande de abajo. Muevo el video al `_momentoAnimal` con `seekTo`
y le doy play, así se ve al animal pasar sin tener que buscarlo a mano.

### _cuerpo

Lo llama el `build` y decide qué mostrar. Mientras carga, una ruedita. Si
hubo error, el mensaje. Si el animal no tiene video, un aviso con el RFID que
se buscó (sirve para revisar si el tag está bien cargado). Si hay video: el
reproductor con su proporción original, la barra de progreso (se puede
arrastrar), el botón de play/pausa y el botón "Ir a donde aparece este
animal". El ícono de play/pausa está en un `ValueListenableBuilder` que
escucha al controlador, así cambia solo cuando el video se pausa o arranca.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Cómo sabe la app en qué segundo aparece el animal?** — El segmento que
  devuelve `VideoService` trae el campo `inicio`, que es el segundo del video
  en el que se leyó el tag. Yo salto a ese momento menos un segundo.
- **¿Qué es la URL firmada?** — Es un link que da Supabase para bajar un
  archivo privado de su Storage. Dura una hora (3600 segundos); sin ese link,
  el video no se puede reproducir desde la app.
- **¿Por qué el botón está fuera de un `Row`?** — Porque el tema de la app le
  pide a los botones ancho infinito, y dentro de un `Row` eso hace que no se
  dibujen. Afuera, con un `SizedBox` de ancho completo, se ve bien.

---

## informacion_personal_screen.dart

**Sub-pantalla de Configuración (a la que se llega desde el engranaje de la Pantalla 2) — Información personal**

**Qué hace:** Se abre desde Configuración. Muestra el mail del usuario y los
nombres de sus campos, pero tapados con un desenfoque marrón. Para verlos hay
que escribir la contraseña actual, y Supabase tiene que confirmar que es la
correcta. Abajo están las opciones "Cambiar contraseña" y "¿Olvidaste tu
contraseña?".

Información Personal es sub-pantalla de Configuración, no de la Planilla. La
Planilla (Pantalla 2) nunca la abre directo: desde la Planilla toco el
engranaje y voy a Configuración, y recién ahí, al tocar "Información Personal"
en la lista, se abre esta pantalla. Es el único lugar de toda la app desde
donde se llega acá, así que el camino es siempre Planilla → Configuración →
Información Personal (dos saltos).

**Bloques:**

### Imports

Lo raro acá es `dart:ui`, una librería de Dart de donde saco `ImageFilter`,
el filtro que desenfoca el texto. Además uso `CamposService` (para traer los
campos), `AuthService` (verificar la contraseña, saber el mail del usuario y
mandar el mail de recuperación) y las dos pantallas a las que se puede ir
desde acá: `CambiarPasswordScreen` y `VerificarCodigoScreen`.

### _InformacionPersonalScreenState

En `initState` arranco el pedido de los campos. `_desbloqueado` dice si ya
pusieron bien la contraseña. `_verificando` está en `true` mientras espero la
respuesta de Supabase (deshabilita el botón y muestra una ruedita). `_error`
guarda el mensaje en rojo, si hay. El controller del campo de contraseña lo
libero en `dispose`.

### _verDatos

Si el campo de contraseña está vacío, muestro "Escribí tu contraseña para ver
los datos". Si no, llamo a `AuthService.verificarPasswordActual`, que
chequea la contraseña contra Supabase. Si es correcta, pongo `_desbloqueado`
en `true` y todos los datos se destapan; si no, muestro "Contraseña
incorrecta.". Se llama desde el botón "Ver datos" y también al apretar Enter
en el teclado.

### build

Arriba, el mail (lo saco del usuario logueado) y la lista de campos, todo
pasado por `_datoOculto`. Mientras no esté desbloqueado, aparecen el campo de
contraseña y el botón "Ver datos"; cuando se desbloquea, desaparecen. Abajo,
"Cambiar contraseña" abre `CambiarPasswordScreen`, y "¿Olvidaste tu
contraseña?" le pide a `AuthService` que mande el mail de recuperación y abre
`VerificarCodigoScreen` para escribir el código. Antes figuraba que ese mail
tenía problemas de spam/entrega; está marcado como TODO para confirmarlo.

### _datoOculto

Recibe un texto y decide cómo mostrarlo. Si ya está desbloqueado, lo muestra
normal. Si no, uso un `Stack` (widgets uno encima del otro): abajo, el texto
desenfocado con `ImageFilter.blur`, y arriba una capa marrón
semitransparente. Así no se puede leer, pero se nota que ahí hay un dato.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué los datos aparecen tapados?** — Para que si alguien agarra el
  celular con la sesión abierta no pueda ver el mail ni los campos sin saber
  la contraseña.
- **¿La contraseña se compara en el celular?** — No. Se manda a Supabase con
  `verificarPasswordActual` y Supabase dice si es correcta. Esta pantalla no
  la guarda en ningún lado.
- **¿Cómo se hace el efecto de desenfoque?** — Con `ImageFiltered` y
  `ImageFilter.blur`, y encima una capa marrón semitransparente dentro de un
  `Stack`.

---

## cambiar_password_screen.dart

**Sub-pantalla de Información Personal — Cambiar contraseña**

**Qué hace:** Se abre desde "Cambiar contraseña" en Información Personal.
Sirve para cambiar la contraseña estando ya logueado: pido la contraseña
actual (que Supabase verifica) y la nueva, con el mismo checklist de
requisitos que en el registro (8 caracteres, una letra y un número). No
depende de ningún mail, así que funciona aunque falle el flujo de "olvidé mi
contraseña".

**Bloques:**

### Imports

Sumo `supabase_flutter` solo por `AuthException`, que es el tipo de error que
tira Supabase cuando algo de la autenticación sale mal. También uso
`PasswordChecklist`, el widget con la lista de requisitos que se van tildando
mientras se escribe.

### _CambiarPasswordScreenState

Tengo un controller por campo (actual y nueva) y un `_formKey` para validar
los dos juntos. `_mostrarActual` y `_mostrarNueva` manejan el ojito de cada
campo (mostrar u ocultar lo escrito). `_cargando` deshabilita el botón y
`_error` guarda el mensaje en rojo. El getter `_passwordEsValida` le pregunta
a `PasswordChecklist.esValida` si la nueva cumple todo.

### _cambiar

Primero corro los validadores del formulario; si alguno falla, corto. Después
le pido a `AuthService` que verifique la contraseña actual contra Supabase.
Si está mal, muestro "La contraseña actual es incorrecta." y corto. Si está
bien, guardo la nueva con `cambiarPassword`, vuelvo a la pantalla anterior y
muestro un `SnackBar` de éxito. Si Supabase tira un `AuthException`, muestro
su mensaje. El `finally` apaga `_cargando`.

### build

Es un `Form` con dos `TextFormField`. Cada uno tiene su `validator` (que no
esté vacío y, en la nueva, que cumpla los requisitos) y un ojito para mostrar
u ocultar lo que se escribe. Debajo de la nueva va el checklist dentro de un
`ValueListenableBuilder`, así en cada tecla se redibuja solo el checklist y
no el campo (el motivo está en el comentario del código: un problema del
teclado de Android). Al final, el error si hay, y el botón.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué se pide la contraseña actual?** — Para que nadie pueda cambiarla
  solo porque encontró el celular con la sesión abierta.
- **¿Qué requisitos tiene la contraseña nueva?** — Los del `PasswordChecklist`,
  los mismos del registro: 8 caracteres, una letra y un número.
- **¿Por qué el checklist usa `ValueListenableBuilder`?** — Para redibujar
  solo el checklist en cada tecla. Si se redibujaba el campo entero, el
  teclado de Android a veces se desincronizaba con lo escrito.

---

## verificar_codigo_screen.dart

**Sub-pantalla de recuperación de contraseña (desde la Pantalla 0 o desde Información Personal)**

**Qué hace:** Es la última parte de "olvidé mi contraseña". Se abre justo
después de pedir el mail de recuperación, desde el login o desde Información
Personal. Funciona en dos pasos: primero se escribe y confirma el código que
llegó por mail, y recién cuando es correcto aparece el campo para la
contraseña nueva. Antes se usaba un link que abría `docs/restablecer.html`;
ahora todo pasa adentro de la app.

**Bloques:**

### Imports

Sumo `supabase_flutter` por `AuthException`: además del mensaje, me da un
código de error, y así puedo reconocer cuando el código del mail venció
(`otp_expired`). También uso `PasswordChecklist` para los requisitos de la
contraseña nueva.

### _VerificarCodigoScreenState

`_codigoVerificado` es lo que decide qué paso se ve: en `false` se pide el
código y en `true` la contraseña nueva. Tengo un controller para cada campo,
`_mostrarPassword` para el ojito, `_cargando` para deshabilitar los botones
mientras espero a Supabase y `_error` para el mensaje en rojo.

### _verificarCodigo

Es el paso 1. Si el campo está vacío, muestro "Ingresá el código que te
mandamos". Si no, le paso el mail y el código a
`AuthService.verificarCodigoRecuperacion`. Si es correcto, cierro el teclado
(el comentario en el código explica por qué: Android a veces se queda con el
teclado numérico) y paso `_codigoVerificado` a `true`. Si el error es
`otp_expired`, muestro "El código está vencido o es incorrecto. Pedí uno
nuevo."; si es otro, muestro el mensaje de Supabase.

### _guardarPassword

Es el paso 2. Si la contraseña no cumple el checklist, aviso y corto. Si
cumple, la guardo con `AuthService.cambiarPassword` y vuelvo a la primera
pantalla de la pila con `popUntil((route) => route.isFirst)`. Si Supabase
tira un `AuthException`, muestro su mensaje. A qué pantalla cae exactamente
en cada camino está marcado como TODO para revisarlo.

### build

Arriba hay un texto que cambia según el paso ("Te mandamos un código a..." o
"Código confirmado..."). En el paso 1, un campo de código con teclado
numérico y el botón "Confirmar código". En el paso 2, el campo de contraseña
con ojito, el `PasswordChecklist` (dentro de un `ValueListenableBuilder`,
igual que en cambiar contraseña) y el botón "Guardar contraseña". Al final, el
error si hay.

**Posibles preguntas que nos pueden hacer sobre este archivo:**

- **¿Por qué se usa un código y no un link en el mail?** — Porque con el link
  la recuperación se terminaba en una página web, fuera de la app, y chocaba
  con PKCE, que es una protección de Supabase para que el proceso se termine
  en el mismo lugar donde empezó. Con el código, todo pasa en la app.
- **¿Por qué está dividida en dos pasos?** — Para no pedir la contraseña
  nueva antes de saber que el código es válido. Si el código está mal, ni
  aparece el campo.
- **¿Qué pasa si el código venció?** — Supabase devuelve el error
  `otp_expired` y muestro un mensaje que pide uno nuevo.
