/// Representa una fila de datos_campo — un establecimiento ganadero del productor logueado.
class Campo {
  final String id;
  final String nombreCampo;
  final String? ubicacion;

  
//Crea los objetos de campo, llamando obligatoriametne a id y nombre, dejando como opcional ubicacion.
//No se pueden modificar, son const
  const Campo({required this.id, required this.nombreCampo, this.ubicacion});

 //De los datos traidos de map, aclara sus tipos de variables 
  factory Campo.fromMap(Map<String, dynamic> map) {
    return Campo(
      id: map['id'] as String,
      nombreCampo: map['nombre_campo'] as String,
      ubicacion: map['ubicacion'] as String?,
    );
  }
}
