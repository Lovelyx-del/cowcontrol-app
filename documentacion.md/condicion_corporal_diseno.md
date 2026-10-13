# Condición corporal — Diseño de cámara según INTA

Documento con la información que dio José Roselló del INTA sobre cómo se evalúa condición
corporal y qué implica eso en el diseño de la cámara del sistema.

## Qué dijo José (13/10/2026)

Los técnicos del INTA evalúan la condición corporal mirando el animal desde dos ángulos:

1. **Costado completo:** vista de perfil del animal, desde la cabeza hasta la cola. Tiene
   que entrar el cuerpo entero en un solo cuadro.
2. **Desde arriba mirando de atrás hacia adelante:** como parado en un escalón detrás del
   animal, mirando su lomo y columna hacia la cabeza. En jerga ganadera esto se llama
   vista dorsal posterior. NO es una vista perpendicular desde arriba: es un ángulo
   inclinado que abarca el lomo, la cadera y el arranque de la cola.

José no dio información sobre cantidad exacta de cámaras, ubicación específica ni
resolución. Eso queda a definir por el equipo.

## Qué cambia en el diseño de cámara

La propuesta anterior asumía 3 cámaras distribuidas en el costado del brete. La
información de José sugiere que **con 2 cámaras alcanza**:

- **Cámara 1 — Costado:** montada en el costado lateral del brete, perpendicular al
  cuerpo del animal, a unos 1,5m de altura. Cubre el perfil completo de la cabeza a la
  cola. Esta es la que ya estaba planteada como "cámara del costado".
- **Cámara 2 — Arriba y hacia adelante:** montada arriba del brete (dentro del mismo
  gabinete que la cámara principal, o en un soporte junto a ella), apuntando hacia abajo
  Y hacia adelante (no perpendicular al piso). Ángulo aproximado: 30-45° respecto a la
  horizontal, con el punto de vista "desde atrás del animal hacia la cabeza". Cubre el
  lomo, la cadera y el arranque de la cola.

La tercera cámara que se había planteado antes (a 1,2m de altura apuntando a la cadera)
NO es necesaria según la información de José.

## Correcciones necesarias en las imágenes

### Imagen de UNA cámara (la del sistema actual con una sola cámara)

Si mantenemos una sola cámara como diseño de la primera etapa, la corrección sería que
esa única cámara tiene que estar montada en el costado del brete (no arriba), apuntando
perpendicularmente al cuerpo del animal. Pero según José, con una sola cámara no se puede
captar la vista dorsal posterior — así que **para condición corporal se necesitan las
dos**. La imagen de una cámara queda como "sistema sin condición corporal", no como una
versión reducida del sistema con IA.

### Imagen de DOS cámaras (nueva)

Hay que regenerar la imagen de dos cámaras con estas posiciones:
- Cámara del costado: perpendicular al flanco del animal, ~1,5m de altura.
- Cámara superior: arriba del gabinete principal, apuntando hacia abajo y hacia adelante
  en diagonal (no perpendicular al piso).

La tercera cámara del costado que estaba en la propuesta anterior se saca.

Prompt de Gemini para regenerar la imagen de 2 cámaras (guardar acá para futuro uso):

```text
Photorealistic documentary photograph of an Argentine cattle ranch, side profile view.
A weathered wooden cattle chute (brete) with wooden side rails. A brown and white cow
stands inside the chute, seen in full side profile. The cow wears a yellow plastic RFID
ear tag.

Two camera units, both integrated into one single weatherproof enclosure system:

Camera 1 (side view camera): mounted on the side rail of the chute at approximately 1.5
meters height, pointing perpendicular to the cow's flank, capturing the full body profile
from head to tail in a single frame. Small dark gray housing (approx 8x6cm) attached
flush against the wooden side rail.

Camera 2 (top-down and forward camera): mounted on top of the chute's upper rail, inside
a compact dark gray IP65 enclosure (approx 15x10cm), with the camera lens angled downward
AND forward at approximately 40 degrees from horizontal — as if standing on a step behind
the animal looking down at its back and spine toward the head. This captures the dorsal
posterior view of the cow (loin, hip, tail base).

Both enclosures connect via a single thin black cable running along the wooden beams.
The top enclosure contains the processing unit (visible small green circuit board through
a transparent panel) and a small RFID reader module. The side camera is just a lens in a
small housing with a cable to the top unit.

Natural overcast daylight, soft shadows. Background: green pasture, wooden fence, distant
trees. Medium wide side shot, camera at approximately the cow's back height. Sharp focus,
real-world proportions, no text, no watermarks, no logos. Documentary photography, not
CGI.
```

## Qué queda pendiente

- Regenerar la imagen de 2 cámaras en Gemini con el prompt de arriba.
- Decidir si la imagen de una cámara se mantiene como "sistema sin condición corporal" o
  se reemplaza por la de 2 cámaras en la comunicación al INTA.
- Confirmar con José si la distancia de las cámaras al animal debería ser otra — él
  mencionó que las vio cerca en las imágenes, pero no dio un número.
- Confirmar el lente: para captar el costado completo del animal (vaca de ~2m de largo)
  desde el costado del brete (~1m de distancia), se necesita un lente con ángulo amplio.
  Verificar qué lente tiene la Imx519 y si alcanza.
