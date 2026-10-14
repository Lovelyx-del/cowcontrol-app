// =====================================================================
// Carcasa CowControl — base cerrada + tapa deslizante (impresión FDM)
// =====================================================================
// Dos piezas separadas, sin tornillos ni bisagras:
//   - BASE: caja abierta solo por arriba, con dos rieles por fuera de
//     los lados largos y un tope en un extremo.
//   - TAPA: placa plana que entra deslizando por los rieles desde el
//     extremo abierto hasta chocar con el tope.
// Única abertura lateral: agujero redondo para el cable del ESP32.
//
// Ejes: X = largo (110), Y = ancho (90), Z = alto (50).
// La base se imprime parada (piso contra la cama) y la tapa acostada.
// =====================================================================


// ---------------------------------------------------------------------
// PARÁMETROS
// ---------------------------------------------------------------------

// --- Qué pieza dibujar ---
pieza = "ambas";        // "ambas" = las dos lado a lado, "base" o "tapa" = una sola (para exportar cada STL por separado)
separacion = 15;        // distancia en mm entre la base y la tapa cuando se dibujan las dos

// --- Cuerpo de la base (medidas exteriores, sin contar los rieles) ---
largo_ext = 110;        // largo exterior de la caja
ancho_ext = 90;         // ancho exterior de la caja
alto_ext  = 50;         // alto exterior de la caja (hasta donde apoya la tapa)
pared     = 2.5;        // espesor de las 4 paredes laterales
piso      = 2.5;        // espesor del piso

// --- Tapa deslizante ---
tapa_espesor   = 3;     // espesor de la tapa
tapa_sobresale = 2;     // cuánto sobresale la tapa de cada pared larga (esa parte entra en el riel)
tope_largo     = 5;     // largo del tope que cierra los rieles en un extremo

// --- Rieles (perfil en L por fuera de cada pared larga) ---
juego        = 0.2;     // holgura entre tapa y riel, en alto y en profundidad
riel_pared   = 1.5;     // espesor de la pared exterior del riel
riel_labio   = 1.5;     // espesor del labio que queda arriba de la tapa y no la deja levantarse
riel_base    = 1.5;     // material macizo debajo de la ranura, en el borde exterior, antes de la rampa

// --- Agujero para el cable del ESP32 ---
cable_diametro = 8;     // diámetro del agujero
cable_altura   = 10;    // altura del CENTRO del agujero, medida desde la cara de abajo de la base

// --- Protoboards (solo para verificar que entran, no se dibujan) ---
proto_largo    = 82;    // largo de cada protoboard
proto_ancho    = 55;    // ancho de cada protoboard
proto_alto     = 8.5;   // alto de cada protoboard
proto_cantidad = 2;     // cuántas van apiladas

// --- Logo opcional sobre la tapa (ver bloque comentado en el módulo tapa) ---
logo_archivo = "logo_cowcontrol.svg"; // archivo SVG, en la misma carpeta que este .scad
logo_alto    = 1;       // cuánto sobresale el logo arriba de la tapa
logo_ancho   = 60;      // tamaño del logo a lo largo de la tapa (el otro lado se ajusta solo)

// --- Calidad y detalles de modelado ---
$fn = 64;               // cantidad de lados de los círculos (más = más redondo)
e   = 0.01;             // solape mínimo para que uniones y cortes no dejen caras coincidentes


// ---------------------------------------------------------------------
// MEDIDAS CALCULADAS (no tocar: salen de los parámetros de arriba)
// ---------------------------------------------------------------------

interior_largo = largo_ext - 2 * pared;          // 105
interior_ancho = ancho_ext - 2 * pared;          // 85
interior_alto  = alto_ext - piso;                // 47.5

tapa_ancho = ancho_ext + 2 * tapa_sobresale;     // 94
tapa_largo = largo_ext - tope_largo;             // 105

ranura_alto = tapa_espesor + juego;              // 3.2  (alto del hueco donde entra el borde de la tapa)
ranura_prof = tapa_sobresale + juego;            // 2.2  (profundidad del hueco)
riel_ancho  = ranura_prof + riel_pared;          // 3.7  (cuánto sobresale el riel de la pared)
riel_alto   = ranura_alto + riel_labio;          // 4.7  (cuánto sube el riel por encima del borde de la caja)

ancho_total = ancho_ext + 2 * riel_ancho;        // 97.4 (ancho en la zona de los rieles)
alto_total  = alto_ext + riel_alto;              // 54.7 (alto en la zona de los rieles)

proto_alto_total = proto_cantidad * proto_alto;  // 17


// ---------------------------------------------------------------------
// VERIFICACIONES (se muestran en la consola de OpenSCAD)
// ---------------------------------------------------------------------

// Si algo no entra, OpenSCAD frena y muestra el mensaje en vez de dibujar.
assert(proto_largo <= interior_largo && proto_ancho <= interior_ancho,
       "Las protoboards no entran en el piso de la caja");
assert(proto_alto_total <= interior_alto,
       "Las protoboards apiladas son más altas que el interior");
assert(cable_altura - cable_diametro / 2 >= piso,
       "El agujero del cable corta el piso de la base");

echo(str("Base exterior (cuerpo): ", largo_ext, " x ", ancho_ext, " x ", alto_ext, " mm"));
echo(str("Base con rieles: ", largo_ext, " x ", ancho_total, " x ", alto_total, " mm"));
echo(str("Interior: ", interior_largo, " x ", interior_ancho, " x ", interior_alto, " mm"));
echo(str("Tapa: ", tapa_largo, " de largo x ", tapa_ancho, " de ancho x ", tapa_espesor, " de espesor (mm)"));
echo(str("Ranura del riel: ", ranura_alto, " alto x ", ranura_prof, " profundidad (juego ", juego, " mm)"));
echo(str("Agujero cable: diámetro ", cable_diametro, ", centro a ", cable_altura,
         " mm de abajo y a ", ancho_ext / 2, " mm de cada costado"));
echo(str("Margen protoboards: ", interior_largo - proto_largo, " mm de largo, ",
         interior_ancho - proto_ancho, " mm de ancho, ",
         interior_alto - proto_alto_total, " mm libres arriba"));


// ---------------------------------------------------------------------
// MÓDULOS
// ---------------------------------------------------------------------

// Caja hueca: un bloque macizo al que se le resta el interior,
// dejando las 4 paredes y el piso. Queda abierta por arriba.
module cuerpo() {
    difference() {
        cube([largo_ext, ancho_ext, alto_ext]);
        translate([pared, pared, piso])
            cube([interior_largo, interior_ancho, interior_alto + e]);
    }
}

// Perfil del riel izquierdo, dibujado en el plano Y-Z (Y negativo = hacia afuera).
// De abajo hacia arriba: rampa a 45° pegada a la pared (para imprimir sin
// soportes), ranura donde entra el borde de la tapa, y labio arriba.
// Los puntos que tocan la pared se meten "e" adentro para que se unan bien.
module perfil_riel() {
    polygon([
        [ e,           alto_ext - riel_base - riel_ancho], // arranque de la rampa, contra la pared
        [-riel_ancho,  alto_ext - riel_base],              // fin de la rampa (45°), borde exterior
        [-riel_ancho,  alto_ext + riel_alto],              // arriba, afuera
        [ 0,           alto_ext + riel_alto],              // arriba, punta del labio
        [ 0,           alto_ext + ranura_alto],            // abajo del labio
        [-ranura_prof, alto_ext + ranura_alto],            // fondo de la ranura, arriba
        [-ranura_prof, alto_ext],                          // fondo de la ranura, abajo
        [ e,           alto_ext]                           // piso de la ranura, al ras del borde de la pared
    ]);
}

// Riel izquierdo: estira el perfil a lo largo de toda la caja (eje X).
// rotate([90, 0, 90]) lleva el plano del perfil a Y-Z y la extrusión a X.
module riel() {
    rotate([90, 0, 90])
        linear_extrude(height = largo_ext)
            perfil_riel();
}

// Tope: bloque que cierra los dos rieles en el extremo del fondo.
// La tapa entra por el otro extremo (X = 0) y frena acá.
module tope() {
    translate([largo_ext - tope_largo, -riel_ancho, alto_ext - e])
        cube([tope_largo, ancho_total, riel_alto + e]);
}

// Agujero del cable: cilindro acostado que atraviesa la pared corta
// del lado del tope, centrado en el ancho y a cable_altura del piso exterior.
module agujero_cable() {
    translate([largo_ext - pared - e, ancho_ext / 2, cable_altura])
        rotate([0, 90, 0])
            cylinder(d = cable_diametro, h = pared + 2 * e);
}

// Base completa: cuerpo + los dos rieles + tope, menos el agujero del cable.
// El riel derecho es el izquierdo reflejado sobre la pared opuesta.
module base() {
    difference() {
        union() {
            cuerpo();
            riel();
            translate([0, ancho_ext, 0])
                mirror([0, 1, 0])
                    riel();
            tope();
        }
        agujero_cable();
    }
}

// Tapa: placa plana. Apoya sobre el borde de las paredes y sus 2 mm
// sobrantes de cada lado corren dentro de las ranuras de los rieles.
module tapa() {
    cube([tapa_largo, tapa_ancho, tapa_espesor]);

    // --- Logo opcional (desactivado para la primera impresión) ---
    // Para activarlo:
    //   1. Poné el SVG (vaca con caravana RFID y arcos) en la misma carpeta que este .scad.
    //   2. Si tiene otro nombre, cambiá logo_archivo en los parámetros.
    //   3. Borrá las "//" de las 4 líneas de abajo.
    // El logo tiene que quedar a más de 2.2 mm de los bordes largos de la tapa
    // (esa franja entra en los rieles): o sea, como mucho ~85 mm de ancho.
    //
    // translate([tapa_largo / 2, tapa_ancho / 2, tapa_espesor - e])
    //     linear_extrude(height = logo_alto + e)
    //         resize([logo_ancho, 0], auto = true)
    //             import(logo_archivo, center = true);
}


// ---------------------------------------------------------------------
// DIBUJO
// ---------------------------------------------------------------------

// Con "ambas", la tapa se dibuja al lado de la base (corrida en Y) para
// ver las dos piezas. Con "base" o "tapa" se dibuja solo esa, en el origen.
if (pieza != "tapa")
    base();

if (pieza != "base")
    translate(pieza == "ambas" ? [0, ancho_ext + riel_ancho + separacion, 0] : [0, 0, 0])
        tapa();


// ---------------------------------------------------------------------
// EXPORTAR A STL
// ---------------------------------------------------------------------
// 1. Arriba, poné  pieza = "base";
// 2. F6 (Design → Render) y esperá a que termine.
// 3. Design → Export → Export as STL  →  guardalo como base.stl
// 4. Repetí con  pieza = "tapa";  →  tapa.stl
// (Con pieza = "ambas" también se puede exportar: sale un solo STL con las
//  dos piezas, ya separadas y apoyadas en la cama.)
