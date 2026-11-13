
import 'package:flutter/material.dart';
import '../models/grupo.dart';

class ParticipacionScreen extends StatefulWidget {
  final Grupo grupo;
  final Sesion sesion;

  const ParticipacionScreen({
    super.key,
    required this.grupo,
    required this.sesion,
  });

  @override
  State<ParticipacionScreen> createState() =>
      _ParticipacionScreenState();
}

class _ParticipacionScreenState extends State<ParticipacionScreen> {
  int obtenerSiguienteId() {
    int mayor = 0;

    for (var registro in widget.sesion.participaciones) {
      if (registro.id > mayor) {
        mayor = registro.id;
      }
    }

    return mayor + 1;
  }

  int obtenerTotalPuntos(int estudianteId) {
    int total = 0;

    for (var registro in widget.sesion.participaciones) {
      if (registro.estudianteId == estudianteId) {
        total += registro.puntos;
      }
    }

    return total;
  }

  int obtenerTotalGeneral() {
    int total = 0;

    for (var registro in widget.sesion.participaciones) {
      total += registro.puntos;
    }

    return total;
  }

  void mostrarFormulario() {
    final actividadController = TextEditingController();
    final puntosController = TextEditingController(text: '1');

    final estudiantes = widget.grupo.estudiantes
        .where((estudiante) => estudiante.estado == 'Activo')
        .toList();

    if (estudiantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay estudiantes activos en este grupo.'),
        ),
      );
      return;
    }

    int estudianteSeleccionado = estudiantes.first.id;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualizarDialogo) {
            return AlertDialog(
              title: const Text('Registrar participación'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: estudianteSeleccionado,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Estudiante',
                        border: OutlineInputBorder(),
                      ),
                      items: estudiantes.map((estudiante) {
                        return DropdownMenuItem<int>(
                          value: estudiante.id,
                          child: Text(
                            estudiante.nombreCompleto,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        if (valor != null) {
                          actualizarDialogo(() {
                            estudianteSeleccionado = valor;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: actividadController,
                      decoration: const InputDecoration(
                        labelText: 'Actividad realizada',
                        hintText: 'Ej. Participación en clase',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: puntosController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Puntos asignados',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final actividad = actividadController.text.trim();
                    final puntos = int.tryParse(
                      puntosController.text.trim(),
                    );

                    if (actividad.isEmpty ||
                        puntos == null ||
                        puntos <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ingresa una actividad y puntos mayores a cero.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      widget.sesion.participaciones.add(
                        Participacion(
                          id: obtenerSiguienteId(),
                          estudianteId: estudianteSeleccionado,
                          actividad: actividad,
                          puntos: puntos,
                          fecha: DateTime.now(),
                        ),
                      );
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      actividadController.dispose();
      puntosController.dispose();
    });
  }

  void eliminarParticipacion(Participacion registro) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar participación'),
          content: const Text(
            '¿Deseas eliminar este registro de puntos?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.sesion.participaciones.remove(registro);
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  String nombreEstudiante(int estudianteId) {
    for (var estudiante in widget.grupo.estudiantes) {
      if (estudiante.id == estudianteId) {
        return estudiante.nombreCompleto;
      }
    }

    return 'Estudiante no encontrado';
  }

  String formatoFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    final estudiantes = widget.grupo.estudiantes
        .where((estudiante) => estudiante.estado == 'Activo')
        .toList();

    final participaciones = widget.sesion.participaciones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Participación y puntos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Asignar puntos'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF101827),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.grupo.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Sesión: ${widget.sesion.titulo}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Puntos asignados en esta sesión',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  '${obtenerTotalGeneral()} puntos',
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Puntaje por estudiante',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(
            height: 125,
            child: estudiantes.isEmpty
                ? const Center(
                    child: Text('No hay estudiantes activos.'),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: estudiantes.length,
                    itemBuilder: (context, index) {
                      final estudiante = estudiantes[index];

                      return Container(
                        width: 155,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.person,
                              color: Color(0xFF38BDF8),
                            ),
                            const Spacer(),
                            Text(
                              estudiante.nombreCompleto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${obtenerTotalPuntos(estudiante.id)} puntos',
                              style: const TextStyle(
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Historial de actividades',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            child: participaciones.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.stars_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text('Todavía no hay puntos asignados'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: participaciones.length,
                    itemBuilder: (context, index) {
                      final registro = participaciones[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.star),
                          ),
                          title: Text(
                            registro.actividad,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${nombreEstudiante(registro.estudianteId)}\n'
                            '${formatoFecha(registro.fecha)}',
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '+${registro.puntos}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (valor) {
                                  if (valor == 'eliminar') {
                                    eliminarParticipacion(registro);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
