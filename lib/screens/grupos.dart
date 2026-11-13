
import 'package:flutter/material.dart';

import '../models/grupo.dart';
import '../database/database_helper.dart';
import 'sesiones.dart';
import 'reportes.dart';

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final Color fondo = const Color(0xFF101827);
  final Color tarjeta = const Color(0xFF1E293B);
  final Color azul = const Color(0xFF38BDF8);

  final TextEditingController _buscarController = TextEditingController();

  List<Grupo> grupos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  // CARGAR GRUPOS DESDE SQLITE

  Future<void> _cargarGrupos() async {
    final db = DatabaseHelper.instance;

    try {
      List<Map<String, dynamic>> datos = await db.obtenerGrupos();

      // Registrar ejemplos solamente si la base está vacía.
      if (datos.isEmpty) {
        await _registrarEjemplos();
        datos = await db.obtenerGrupos();
      }

      List<Grupo> lista = [];

      for (var dato in datos) {
        final grupo = Grupo(
          id: dato['id'],
          codigo: dato['codigo'],
          nombre: dato['nombre'],
          periodo: dato['periodo'],
        );

        final estudiantes = await db.obtenerEstudiantes(grupo.id);

        grupo.estudiantes = estudiantes.map((e) {
          return Estudiante(
            id: e['id'],
            codigo: e['codigo'],
            nombres: e['nombres'],
            apellidos: e['apellidos'],
            estado: e['estado'],
          );
        }).toList();

        lista.add(grupo);
      }

      if (!mounted) return;

      setState(() {
        grupos = lista;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar grupos: $e')),
      );
    }
  }

  // DATOS DE EJEMPLO INICIALES

  Future<void> _registrarEjemplos() async {
    final db = DatabaseHelper.instance;

    final ejemplos = [
      {
        'codigo': 'IDAW-401',
        'nombre': 'Desarrollo de Aplicaciones',
        'periodo': '2026-II',
        'estudiantes': [
          ['2026001', 'Carlos', 'Ramírez'],
          ['2026002', 'María', 'García'],
          ['2026003', 'José', 'Torres'],
        ],
      },
      {
        'codigo': 'IDAW-402',
        'nombre': 'Desarrollo Móvil',
        'periodo': '2026-II',
        'estudiantes': [
          ['2026004', 'Lucía', 'Flores'],
          ['2026005', 'Pedro', 'Castillo'],
        ],
      },
      {
        'codigo': 'IDAW-403',
        'nombre': 'Base de Datos',
        'periodo': '2026-II',
        'estudiantes': [
          ['2026006', 'Ana', 'Mendoza'],
        ],
      },
    ];

    for (var ejemplo in ejemplos) {
      final grupoId = await db.insertarGrupo({
        'codigo': ejemplo['codigo'],
        'nombre': ejemplo['nombre'],
        'periodo': ejemplo['periodo'],
      });

      final estudiantes =
          ejemplo['estudiantes'] as List<List<String>>;

      for (var estudiante in estudiantes) {
        await db.insertarEstudiante({
          'grupo_id': grupoId,
          'codigo': estudiante[0],
          'nombres': estudiante[1],
          'apellidos': estudiante[2],
          'estado': 'Activo',
        });
      }
    }
  }

  List<Grupo> get gruposFiltrados {
    String busqueda = _buscarController.text.toLowerCase();

    return grupos.where((grupo) {
      return grupo.nombre.toLowerCase().contains(busqueda) ||
          grupo.codigo.toLowerCase().contains(busqueda);
    }).toList();
  }

  // FORMULARIO DE GRUPOS

  void _formularioGrupo({Grupo? grupo}) {
    final codigoController = TextEditingController(
      text: grupo?.codigo ?? '',
    );

    final nombreController = TextEditingController(
      text: grupo?.nombre ?? '',
    );

    final periodoController = TextEditingController(
      text: grupo?.periodo ?? '2026-II',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: tarjeta,
          title: Text(
            grupo == null ? 'Nuevo grupo' : 'Editar grupo',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(codigoController, 'Código del grupo'),
                const SizedBox(height: 12),
                _campo(nombreController, 'Nombre del grupo'),
                const SizedBox(height: 12),
                _campo(periodoController, 'Periodo académico'),
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
                String codigo = codigoController.text.trim();
                String nombre = nombreController.text.trim();
                String periodo = periodoController.text.trim();

                if (codigo.isEmpty || nombre.isEmpty || periodo.isEmpty) {
                  return;
                }

                try {
                  final db = DatabaseHelper.instance;

                  if (grupo == null) {
                    await db.insertarGrupo({
                      'codigo': codigo,
                      'nombre': nombre,
                      'periodo': periodo,
                    });
                  } else {
                    await db.actualizarGrupo(grupo.id, {
                      'codigo': codigo,
                      'nombre': nombre,
                      'periodo': periodo,
                    });
                  }

                  if (!mounted || !dialogContext.mounted) return;

                    Navigator.pop(dialogContext);
                    await _cargarGrupos();

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Grupo guardado correctamente'),
                    ),
                  );
                } catch (e) {
                    if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No se pudo guardar. Verifica que el código no esté repetido.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _campo(TextEditingController controller, String etiqueta) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: fondo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ELIMINAR GRUPO

  void _eliminarGrupo(Grupo grupo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tarjeta,
        title: const Text(
          'Eliminar grupo',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Deseas eliminar ${grupo.nombre}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.eliminarGrupo(grupo.id);

                if (!mounted || !dialogContext.mounted) return;

                Navigator.pop(dialogContext);
                await _cargarGrupos();

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Grupo eliminado correctamente'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        title: const Text('Gestión de grupos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formularioGrupo(),
        backgroundColor: azul,
        foregroundColor: fondo,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo grupo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              controller: _buscarController,
              onChanged: (value) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar grupo...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white54,
                ),
                filled: true,
                fillColor: tarjeta,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text(
                  'Grupos registrados',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${grupos.length} grupos',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : gruposFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron grupos',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: gruposFiltrados.length,
                          itemBuilder: (context, index) {
                            final grupo = gruposFiltrados[index];

                            return Card(
                              color: tarjeta,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      azul.withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.groups,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                                title: Text(
                                  grupo.nombre,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Text(
                                    '${grupo.codigo}\n${grupo.periodo} • ${grupo.estudiantes.length} estudiantes',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      height: 1.6,
                                    ),
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'editar') {
                                      _formularioGrupo(grupo: grupo);
                                    } else if (value == 'eliminar') {
                                      _eliminarGrupo(grupo);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Text('Editar'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'eliminar',
                                      child: Text('Eliminar'),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EstudiantesScreen(grupo: grupo),
                                    ),
                                  ).then((value) => _cargarGrupos());
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// PANTALLA DE ESTUDIANTES

class EstudiantesScreen extends StatefulWidget {
  final Grupo grupo;

  const EstudiantesScreen({
    super.key,
    required this.grupo,
  });

  @override
  State<EstudiantesScreen> createState() => _EstudiantesScreenState();
}

class _EstudiantesScreenState extends State<EstudiantesScreen> {
  final Color fondo = const Color(0xFF101827);
  final Color tarjeta = const Color(0xFF1E293B);
  final Color azul = const Color(0xFF38BDF8);

  final TextEditingController _buscarController = TextEditingController();

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
  }

  // CARGAR ESTUDIANTES DESDE SQLITE

  Future<void> _cargarEstudiantes() async {
    try {
      final datos = await DatabaseHelper.instance.obtenerEstudiantes(
        widget.grupo.id,
      );

      final lista = datos.map((e) {
        return Estudiante(
          id: e['id'],
          codigo: e['codigo'],
          nombres: e['nombres'],
          apellidos: e['apellidos'],
          estado: e['estado'],
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        widget.grupo.estudiantes = lista;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar estudiantes: $e')),
      );
    }
  }

  List<Estudiante> get estudiantesFiltrados {
    String busqueda = _buscarController.text.toLowerCase();

    return widget.grupo.estudiantes.where((estudiante) {
      return estudiante.nombreCompleto.toLowerCase().contains(busqueda) ||
          estudiante.codigo.toLowerCase().contains(busqueda);
    }).toList();
  }

  // FORMULARIO DE ESTUDIANTES

  void _formularioEstudiante({Estudiante? estudiante}) {
    final codigoController = TextEditingController(
      text: estudiante?.codigo ?? '',
    );

    final nombresController = TextEditingController(
      text: estudiante?.nombres ?? '',
    );

    final apellidosController = TextEditingController(
      text: estudiante?.apellidos ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tarjeta,
        title: Text(
          estudiante == null ? 'Nuevo estudiante' : 'Editar estudiante',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(codigoController, 'Código institucional'),
              const SizedBox(height: 12),
              _campo(nombresController, 'Nombres'),
              const SizedBox(height: 12),
              _campo(apellidosController, 'Apellidos'),
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
              String codigo = codigoController.text.trim();
              String nombres = nombresController.text.trim();
              String apellidos = apellidosController.text.trim();

              if (codigo.isEmpty || nombres.isEmpty || apellidos.isEmpty) {
                return;
              }

              bool codigoDuplicado = widget.grupo.estudiantes.any(
                (e) =>
                    e.codigo.toLowerCase() == codigo.toLowerCase() &&
                    e.id != estudiante?.id,
              );

              if (codigoDuplicado) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('El código ya está registrado'),
                  ),
                );
                return;
              }

              try {
                final db = DatabaseHelper.instance;

                if (estudiante == null) {
                  await db.insertarEstudiante({
                    'grupo_id': widget.grupo.id,
                    'codigo': codigo,
                    'nombres': nombres,
                    'apellidos': apellidos,
                    'estado': 'Activo',
                  });
                } else {
                  await db.actualizarEstudiante(estudiante.id, {
                    'codigo': codigo,
                    'nombres': nombres,
                    'apellidos': apellidos,
                  });
                }

                if (!mounted || !dialogContext.mounted) return;

Navigator.pop(dialogContext);
await _cargarEstudiantes();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Estudiante guardado correctamente'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No se pudo guardar. Verifica el código del estudiante.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController controller, String etiqueta) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: fondo,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ELIMINAR ESTUDIANTE

  void _eliminarEstudiante(Estudiante estudiante) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tarjeta,
        title: const Text(
          'Eliminar estudiante',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Deseas eliminar a ${estudiante.nombreCompleto}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await DatabaseHelper.instance.eliminarEstudiante(
                  estudiante.id,
                );

                if (!mounted || !dialogContext.mounted) return;

Navigator.pop(dialogContext);
await _cargarEstudiantes();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Estudiante eliminado correctamente'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,
      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: Colors.white,
        title: Text(widget.grupo.codigo),
        actions: [
          IconButton(
            tooltip: 'Ver reportes',
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportesScreen(
                    grupo: widget.grupo,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Ver sesiones',
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SesionesScreen(
                    grupo: widget.grupo,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formularioEstudiante(),
        backgroundColor: azul,
        foregroundColor: fondo,
        icon: const Icon(Icons.person_add),
        label: const Text('Agregar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.grupo.nombre,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${widget.grupo.periodo} • ${widget.grupo.estudiantes.length} estudiantes',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _buscarController,
              onChanged: (value) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar estudiante...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white54,
                ),
                filled: true,
                fillColor: tarjeta,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : estudiantesFiltrados.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay estudiantes registrados',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: estudiantesFiltrados.length,
                          itemBuilder: (context, index) {
                            final estudiante = estudiantesFiltrados[index];

                            return Card(
                              color: tarjeta,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      azul.withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                                title: Text(
                                  estudiante.nombreCompleto,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  '${estudiante.codigo} • ${estudiante.estado}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                  ),
                                  onSelected: (value) {
                                    if (value == 'editar') {
                                      _formularioEstudiante(
                                        estudiante: estudiante,
                                      );
                                    } else if (value == 'eliminar') {
                                      _eliminarEstudiante(estudiante);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Text('Editar'),
                                    ),
                                    const PopupMenuItem(
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
      ),
    );
  }
}
