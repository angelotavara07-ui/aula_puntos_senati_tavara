
import 'package:flutter/material.dart';
import '../models/grupo.dart';
import '../database/database_helper.dart';
import 'asistencia.dart';
import 'participacion.dart';

class SesionesScreen extends StatefulWidget {
  final Grupo grupo;

  const SesionesScreen({
    super.key,
    required this.grupo,
  });

  @override
  State<SesionesScreen> createState() => _SesionesScreenState();
}

class _SesionesScreenState extends State<SesionesScreen> {
  List<Sesion> sesiones = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarSesiones();
  }

  Future<void> cargarSesiones() async {
    final datos = await DatabaseHelper.instance.obtenerSesiones(
      widget.grupo.id,
    );

    final resultado = datos.map((fila) {
      return Sesion(
        id: fila['id'],
        titulo: fila['titulo'],
        tema: fila['tema'],
        fecha: DateTime.parse(fila['fecha']),
        estado: fila['estado'],
      );
    }).toList();

    if (!mounted) return;

    setState(() {
      sesiones = resultado;
      cargando = false;
    });

    widget.grupo.sesiones
      ..clear()
      ..addAll(resultado);
  }

  String formatoFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  Future<void> mostrarFormulario({Sesion? sesion}) async {
    final tituloController = TextEditingController(
      text: sesion?.titulo ?? '',
    );

    final temaController = TextEditingController(
      text: sesion?.tema ?? '',
    );

    DateTime fechaSeleccionada = sesion?.fecha ?? DateTime.now();
    String estadoSeleccionado = sesion?.estado ?? 'Programada';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualizarDialogo) {
            return AlertDialog(
              title: Text(
                sesion == null ? 'Nueva sesión' : 'Editar sesión',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título de la sesión',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: temaController,
                      decoration: const InputDecoration(
                        labelText: 'Tema académico',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha'),
                      subtitle: Text(formatoFecha(fechaSeleccionada)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final fecha = await showDatePicker(
                          context: dialogContext,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (fecha != null) {
                          actualizarDialogo(() {
                            fechaSeleccionada = fecha;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: estadoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Programada',
                          child: Text('Programada'),
                        ),
                        DropdownMenuItem(
                          value: 'Finalizada',
                          child: Text('Finalizada'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          actualizarDialogo(() {
                            estadoSeleccionado = valor;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tituloController.text.trim().isEmpty ||
                        temaController.text.trim().isEmpty) {
                      return;
                    }

                    final datos = {
                      'grupo_id': widget.grupo.id,
                      'titulo': tituloController.text.trim(),
                      'tema': temaController.text.trim(),
                      'fecha': fechaSeleccionada.toIso8601String(),
                      'estado': estadoSeleccionado,
                    };

                    if (sesion == null) {
                      await DatabaseHelper.instance.insertarSesion(datos);
                    } else {
                      await DatabaseHelper.instance.actualizarSesion(
                        sesion.id,
                        datos,
                      );
                    }

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    await cargarSesiones();
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    tituloController.dispose();
    temaController.dispose();
  }

  Future<void> eliminarSesion(Sesion sesion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar sesión'),
          content: Text('¿Deseas eliminar "${sesion.titulo}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    await DatabaseHelper.instance.eliminarSesion(sesion.id);
    await cargarSesiones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sesiones académicas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => mostrarFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva sesión'),
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
                const Text(
                  'Grupo seleccionado',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.grupo.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.grupo.codigo,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : sesiones.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note,
                              size: 65,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text('Todavía no hay sesiones registradas'),
                            Text('Presiona "Nueva sesión" para comenzar'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sesiones.length,
                        itemBuilder: (context, index) {
                          final sesion = sesiones[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.menu_book,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              title: Text(
                                sesion.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tema: ${sesion.tema}'),
                                    Text('Fecha: ${formatoFecha(sesion.fecha)}'),
                                    Text('Estado: ${sesion.estado}'),
                                  ],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (valor) {
                                  if (valor == 'asistencia') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AsistenciaScreen(
                                          grupo: widget.grupo,
                                          sesion: sesion,
                                        ),
                                      ),
                                    );
                                  } else if (valor == 'participacion') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ParticipacionScreen(
                                          grupo: widget.grupo,
                                          sesion: sesion,
                                        ),
                                      ),
                                    );
                                  } else if (valor == 'editar') {
                                    mostrarFormulario(sesion: sesion);
                                  } else if (valor == 'eliminar') {
                                    eliminarSesion(sesion);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'asistencia',
                                    child: Text('Registrar asistencia'),
                                  ),
                                  PopupMenuItem(
                                    value: 'participacion',
                                    child: Text('Asignar puntos'),
                                  ),
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar'),
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
