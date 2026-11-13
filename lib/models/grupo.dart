
class Estudiante {
  int id;
  String codigo;
  String nombres;
  String apellidos;
  String estado;

  Estudiante({
    required this.id,
    required this.codigo,
    required this.nombres,
    required this.apellidos,
    this.estado = 'Activo',
  });

  String get nombreCompleto => '$nombres $apellidos';
}

class Grupo {
  int id;
  String codigo;
  String nombre;
  String periodo;
  List<Estudiante> estudiantes;
  List<Sesion> sesiones;

  Grupo({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.periodo,
    List<Estudiante>? estudiantes,
    List<Sesion>? sesiones,
  })  : estudiantes = estudiantes ?? [],
        sesiones = sesiones ?? [];
}

class Sesion {
  int id;
  String titulo;
  String tema;
  DateTime fecha;
  String estado;
  List<RegistroAsistencia> asistencias;
  List<Participacion> participaciones;

  Sesion({
    required this.id,
    required this.titulo,
    required this.tema,
    required this.fecha,
    this.estado = 'Programada',
    List<RegistroAsistencia>? asistencias,
    List<Participacion>? participaciones,
  })  : asistencias = asistencias ?? [],
        participaciones = participaciones ?? [];
}

class RegistroAsistencia {
  int estudianteId;
  String estado;

  RegistroAsistencia({
    required this.estudianteId,
    required this.estado,
  });
}

class Participacion {
  int id;
  int estudianteId;
  String actividad;
  int puntos;
  DateTime fecha;

  Participacion({
    required this.id,
    required this.estudianteId,
    required this.actividad,
    required this.puntos,
    required this.fecha,
  });
}
