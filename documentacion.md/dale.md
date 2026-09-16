Documentación de Procesos de CowControl:


Elementos del sistema:


HARDWARE
SOFTWARE
USUARIO
Raspberry Pi 4
Base de Datos (3 tablas: conteos, lecturas, animales)
Dar corriente al HW
Módulo RFID RC522
Script en python para las lecturas (módulo RFID)
Seleccionar “Activar Conteo” desde la app
Tags de lectura
App móvil (Cuenca, por fa desarrolla esta parte, dividiendo en secciones si es necesario. Ejemplo, frontend, backend)
_
Otros:Componentes de conexión, de alimentación y Wifi disponible


_


Flujo del sistema explicado con palabras:

El usuario enciende la RPi (Raspberry Pi); Se deben esperar unos 30 seg, que es el tiempo que tarda la placa en inicializarse. Una vez iniciado el SO de la placa, se corre automáticamente el script rfid_lecturas.py, poniendo ya en trabajo al módulo RFID. Durante este tiempo, se leerán los tags, pero hasta que desde la app no se inicie el conteo, la RPi no envía nada a Supabase, o sea, puede decirse que lo ignora.
Desde la app, el usuario inicializa el conteo (con el botón “iniciar conteo”); al presionar el botón, se envía una instrucción a Supabase: en la tabla “conteos”, cuyos campos son conteo_id (número del conteo, es predeterminado), fecha_conteo, estado (activo, pausado, finalizado) → se crea una nueva fila (con la función INSERT), donde los datos se rellenan automáticamente…

conteo_id: consecutivamente al conteo anterior. Ej, 1, 2 ,3, …
fecha_conteo: se introduce la fecha automáticamente
estado: indica si el conteo está siendo realizado o se detuvo/terminó. Cuando se crea la fila, se autocompleta con activo, luego se modifica.

Se envían las lecturas a Supabase, una vez estado=activo. Las lecturas son insertadas en la tabla “lecturas”, en la columna lectura_uid. Se inserta el uid como texto. Contiene el campo conteo_id, de la tabla conteos, y el campo leido_en, especificando la fecha.
La app une las tablas lecturas y animales para mostrar la planilla con los ✅ (aquellos donde el campo lectura_id este vacío, no se mostrará con un tick). Primero consulta por lecturas, y luego une ambas tablas con JOIN. Esto es en tiempo real. 

tabla animales:
categoría, fertilidad, estado, etc…
tabla lecturas:
lectura_id, conteo_id, leido_en
tabla animales + lecturas (solo el campo lectura_id):
lectura_id, categoría, fertilidad, estado, etc…

Se finaliza el conteo con “detener” o “finalizar, donde se modifica estado=activo por estado = pausado/finalizado, cerrando el bucle while. La RPi pregunta cada 5 segundos a la tabla conteos por el campo estado, es decir, ¿estado=activo, pausado o finalizado?

Cómo funciona la función SQL de “pausado”: la RPi consulta cada 5 segundos a la tabla conteos si hay alguna fila que tenga el campo de estado con el valor “activo”. Supabase le responde el valor de la fila correspondiente, o sea conteo_id = ___ (en caso de no haber, le responde el array vacío [ ] ). Supabase, antes de responderle a RPi, se consulta “hay algún valor pausado?”, es decir, pausado > 0 ? si es el caso, le devuelve el valor del último conteo_id, en caso de que no, crea un nuevo valor para conteo_id, basandose en el último valor y siguiendo consecutivamente. De más está decir, que con esto crea una fila nueva.




lee aqui claude"  ![alt text](image.png)![alt text](image-1.png)![alt text](image-2.png)![alt text](image-3.png)![alt text](image-4.png)![alt text](image-5.png)"



















Diagrama de flujo secuencial:





Ejemplo del funcionamiento del sistema con pseudocódigo:
 
se enciende manualmente la RPi
luego de 30 seg, se inicia el SO de la misma y se corre automáticamente el script rfid_lecturas.py
RPi pregunta a Supabase: que conteo_id tiene estado = activo ?
Supabase responde: conteo_id: [ ]
el usuario presiona “iniciar”
Supabase se pregunta: de los conteo_id que tengo, hay alguna con estado=pausado ? 
en caso de que SI→conteo_id= 1 tiene estado = pausado. Ahora estado=pausado será estado=activo
en caso de que NO→ se crea una nueva fila en la tabla conteos, con conteo_id = 2, fecha: 13/09, estado = activo

suponiendo, pasaron 5 seg, pueden ser más, la cuestión es que la RPI pregunta cada 5 →

RPi pregunta a Supabase: que conteo_id tiene estado = activo ?
Supabase responde: conteo_id: 1 o 2 (dependiendo si era estado=pausado o no, en el ejemplo)
La RPi manda 12345 a la tabla lecturas, en el campo lectura_uid, con el conteo_id=1 o 2
La RPi manda 54321 a la tabla lecturas, en el campo lectura_uid, con el conteo_id=1 o 2
…
el usuario presiona finalizar
RPi pregunta a Supabase: que conteo_id tiene estado = activo ?
Supabase responde: conteo_id: [ ]



