import '../services/exportador_reportes.dart';
import 'package:flutter/material.dart';
import '../models/grupo.dart';

class ReportesScreen extends StatelessWidget {
  final Grupo grupo;

  const ReportesScreen({
    super.key,
    required this.grupo,
  });

  int contarAsistencia(String estado) {
    int total = 0;

    for (var sesion in grupo.sesiones) {
      total += sesion.asistencias
          .where((registro) => registro.estado == estado)
          .length;
    }

    return total;
  }

  int totalPuntosEstudiante(int estudianteId) {
    int total = 0;

    for (var sesion in grupo.sesiones) {
      for (var participacion in sesion.participaciones) {
        if (participacion.estudianteId == estudianteId) {
          total += participacion.puntos;
        }
      }
    }

    return total;
  }

  int totalPuntosGrupo() {
    int total = 0;

    for (var sesion in grupo.sesiones) {
      for (var participacion in sesion.participaciones) {
        total += participacion.puntos;
      }
    }

    return total;
  }

  int totalRegistrosAsistencia() {
    int total = 0;

    for (var sesion in grupo.sesiones) {
      total += sesion.asistencias.length;
    }

    return total;
  }

  Widget tarjetaResumen(String titulo, int cantidad, IconData icono) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, color: const Color(0xFF38BDF8), size: 26),
              const SizedBox(height: 8),
              Text(
                '$cantidad',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estudiantes = grupo.estudiantes
        .where((estudiante) => estudiante.estado == 'Activo')
        .toList();

    return Scaffold(
      appBar: AppBar(
  title: const Text('Reportes del grupo'),
  actions: [
    IconButton(
      tooltip: 'Exportar PDF',
      icon: const Icon(Icons.picture_as_pdf),
      onPressed: () async {
        try {
          await ExportadorReportes.exportarPDF(grupo);
        } catch (e) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al generar PDF: $e')),
          );
        }
      },
    ),
    IconButton(
      tooltip: 'Exportar Excel',
      icon: const Icon(Icons.table_chart),
      onPressed: () async {
        try {
          await ExportadorReportes.exportarExcel(grupo);
        } catch (e) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al generar Excel: $e')),
          );
        }
      },
    ),
  ],
),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF101827),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REPORTE ACADÉMICO',
                  style: TextStyle(
                    color: Color(0xFF38BDF8),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  grupo.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Código: ${grupo.codigo}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Periodo: ${grupo.periodo}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Resumen general',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              tarjetaResumen(
                'Estudiantes',
                estudiantes.length,
                Icons.people,
              ),
              tarjetaResumen(
                'Sesiones',
                grupo.sesiones.length,
                Icons.calendar_month,
              ),
              tarjetaResumen(
                'Puntos',
                totalPuntosGrupo(),
                Icons.star,
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Text(
            'Resumen de asistencia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Presentes'),
                  trailing: Text('${contarAsistencia('Presente')}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.orange),
                  title: const Text('Tardanzas'),
                  trailing: Text('${contarAsistencia('Tardanza')}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.red),
                  title: const Text('Faltas'),
                  trailing: Text('${contarAsistencia('Falta')}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description, color: Colors.blue),
                  title: const Text('Justificados'),
                  trailing: Text('${contarAsistencia('Justificado')}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: const Text('Registros de asistencia'),
                  trailing: Text('${totalRegistrosAsistencia()}'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Rendimiento por estudiante',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          if (estudiantes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No hay estudiantes activos en este grupo.'),
              ),
            ),

          ...estudiantes.map((estudiante) {
            int presentes = 0;
            int tardanzas = 0;
            int faltas = 0;
            int justificados = 0;
            int registros = 0;

            for (var sesion in grupo.sesiones) {
              for (var asistencia in sesion.asistencias) {
                if (asistencia.estudianteId == estudiante.id) {
                  registros++;

                  if (asistencia.estado == 'Presente') {
                    presentes++;
                  } else if (asistencia.estado == 'Tardanza') {
                    tardanzas++;
                  } else if (asistencia.estado == 'Falta') {
                    faltas++;
                  } else if (asistencia.estado == 'Justificado') {
                    justificados++;
                  }
                }
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(
                  estudiante.nombreCompleto,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Código: ${estudiante.codigo}'),
                trailing: Text(
                  '${totalPuntosEstudiante(estudiante.id)} pts',
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Text('Asistencias registradas: $registros'),
                        Text('Presentes: $presentes'),
                        Text('Tardanzas: $tardanzas'),
                        Text('Faltas: $faltas'),
                        Text('Justificados: $justificados'),
                        const SizedBox(height: 8),
                        Text(
                          'Puntos acumulados: ${totalPuntosEstudiante(estudiante.id)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 18),

          const Text(
            'Sesiones registradas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          if (grupo.sesiones.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Todavía no hay sesiones registradas.'),
              ),
            ),

          ...grupo.sesiones.map((sesion) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.event_note),
                title: Text(sesion.titulo),
                subtitle: Text(
                  '${sesion.tema}\n'
                  'Asistencias: ${sesion.asistencias.length} | '
                  'Participaciones: ${sesion.participaciones.length}',
                ),
                isThreeLine: true,
                trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Text(sesion.estado),
    IconButton(
      tooltip: 'Exportar asistencias a Excel',
      icon: const Icon(Icons.file_download),
      onPressed: () async {
        try {
          await ExportadorReportes.exportarAsistencias(grupo, sesion);

          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Excel de asistencias generado.'),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al exportar: $e')),
          );
        }
      },
    ),
  ],
),
              ),
            );
          }),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
