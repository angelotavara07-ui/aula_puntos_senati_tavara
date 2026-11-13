
import 'package:flutter/material.dart';
import '../models/grupo.dart';
import '../database/database_helper.dart';

class AsistenciaScreen extends StatefulWidget {
  final Grupo grupo;
  final Sesion sesion;

  const AsistenciaScreen({
    super.key,
    required this.grupo,
    required this.sesion,
  });

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  final List<String> estados = [
    'Presente',
    'Tardanza',
    'Falta',
    'Justificado',
  ];

  Map<int, String> asistencias = {};
  List<Estudiante> estudiantes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarAsistencias();
  }

  Future<void> cargarAsistencias() async {
    final estudiantesDB = await DatabaseHelper.instance.obtenerEstudiantes(
      widget.grupo.id,
    );

    final registros = await DatabaseHelper.instance.obtenerAsistencias(
      widget.sesion.id,
    );

    final mapa = <int, String>{};

    for (final registro in registros) {
      mapa[registro['estudiante_id'] as int] =
          registro['estado'] as String;
    }

    if (!mounted) return;

    setState(() {
      estudiantes = estudiantesDB
          .where((fila) => fila['estado'] == 'Activo')
          .map(
            (fila) => Estudiante(
              id: fila['id'],
              codigo: fila['codigo'],
              nombres: fila['nombres'],
              apellidos: fila['apellidos'],
              estado: fila['estado'],
            ),
          )
          .toList();

      asistencias = mapa;
      cargando = false;
    });

    widget.sesion.asistencias
      ..clear()
      ..addAll(
        mapa.entries.map(
          (entrada) => RegistroAsistencia(
            estudianteId: entrada.key,
            estado: entrada.value,
          ),
        ),
      );
  }

  Future<void> cambiarAsistencia(
    int estudianteId,
    String nuevoEstado,
  ) async {
    await DatabaseHelper.instance.registrarAsistencia(
      widget.sesion.id,
      estudianteId,
      nuevoEstado,
    );

    if (!mounted) return;

    setState(() {
      asistencias[estudianteId] = nuevoEstado;

      final indice = widget.sesion.asistencias.indexWhere(
        (registro) => registro.estudianteId == estudianteId,
      );

      if (indice >= 0) {
        widget.sesion.asistencias[indice].estado = nuevoEstado;
      } else {
        widget.sesion.asistencias.add(
          RegistroAsistencia(
            estudianteId: estudianteId,
            estado: nuevoEstado,
          ),
        );
      }
    });
  }

  int contarEstado(String estado) {
    return asistencias.values.where((valor) => valor == estado).length;
  }

  @override
  Widget build(BuildContext context) {
    final registrados = asistencias.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de asistencia'),
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
                const SizedBox(height: 6),
                Text(
                  'Sesión: ${widget.sesion.titulo}',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Tema: ${widget.sesion.tema}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _ResumenAsistencia(
                  titulo: 'Presentes',
                  cantidad: contarEstado('Presente'),
                ),
                _ResumenAsistencia(
                  titulo: 'Tardanzas',
                  cantidad: contarEstado('Tardanza'),
                ),
                _ResumenAsistencia(
                  titulo: 'Faltas',
                  cantidad: contarEstado('Falta'),
                ),
                _ResumenAsistencia(
                  titulo: 'Justificados',
                  cantidad: contarEstado('Justificado'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lista de estudiantes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('$registrados / ${estudiantes.length} registrados'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : estudiantes.isEmpty
                    ? const Center(
                        child: Text(
                          'Este grupo todavía no tiene estudiantes activos.',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                        itemCount: estudiantes.length,
                        itemBuilder: (context, index) {
                          final estudiante = estudiantes[index];
                          final estadoActual = asistencias[estudiante.id];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    estudiante.nombreCompleto,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Código: ${estudiante.codigo}'),
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    initialValue: estadoActual,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Estado de asistencia',
                                      border: OutlineInputBorder(),
                                    ),
                                    hint: const Text('Seleccionar estado'),
                                    items: estados.map((estado) {
                                      return DropdownMenuItem(
                                        value: estado,
                                        child: Text(estado),
                                      );
                                    }).toList(),
                                    onChanged: (valor) {
                                      if (valor != null) {
                                        cambiarAsistencia(
                                          estudiante.id,
                                          valor,
                                        );
                                      }
                                    },
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

class _ResumenAsistencia extends StatelessWidget {
  final String titulo;
  final int cantidad;

  const _ResumenAsistencia({
    required this.titulo,
    required this.cantidad,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$cantidad',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
