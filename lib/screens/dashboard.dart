
import 'grupos.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/grupo.dart';
import 'sesiones.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color fondo = Color(0xFF101827);
  static const Color tarjeta = Color(0xFF1E293B);
  static const Color azul = Color(0xFF38BDF8);
  static const Color verde = Color(0xFF34D399);
  static const Color texto = Colors.white;

  void _mostrarMensaje(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: tarjeta,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fondo,

      appBar: AppBar(
        backgroundColor: fondo,
        foregroundColor: texto,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: azul, size: 28),
            SizedBox(width: 10),
            Text(
              'Aula Puntos',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BIENVENIDA
              const Text(
                '¡Buenos días!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Instructor',
                style: TextStyle(
                  color: texto,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Aquí tienes el resumen de tu actividad académica.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              // ESTADO DE CONEXION
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: tarjeta,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white10,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      color: verde,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Conectado',
                        style: TextStyle(
                          color: texto,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Sincronizado',
                      style: TextStyle(
                        color: verde,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // RESUMEN
              const Text(
                'Resumen general',
                style: TextStyle(
                  color: texto,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: const [
                  _StatCard(
                    titulo: 'Mis grupos',
                    cantidad: '4',
                    icono: Icons.groups_rounded,
                    color: azul,
                  ),
                  _StatCard(
                    titulo: 'Estudiantes',
                    cantidad: '86',
                    icono: Icons.people_alt_rounded,
                    color: Color(0xFFA78BFA),
                  ),
                  _StatCard(
                    titulo: 'Sesiones',
                    cantidad: '12',
                    icono: Icons.calendar_month_rounded,
                    color: Color(0xFFFBBF24),
                  ),
                  _StatCard(
                    titulo: 'Participaciones',
                    cantidad: '148',
                    icono: Icons.stars_rounded,
                    color: verde,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ACCESOS RAPIDOS
              const Text(
                'Accesos rápidos',
                style: TextStyle(
                  color: texto,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _ActionCard(
  titulo: 'Mis grupos',
  descripcion: 'Administrar estudiantes',
  icono: Icons.groups_rounded,
  color: azul,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GruposScreen(),
      ),
    );
  },
),
                  _ActionCard(
  titulo: 'Asistencia',
  descripcion: 'Control de asistencia',
  icono: Icons.fact_check_rounded,
  color: verde,
  onTap: () async {
    final datos = await DatabaseHelper.instance.obtenerGrupos();

    if (!context.mounted) return;

    if (datos.isEmpty) {
      _mostrarMensaje(context, 'Primero debes registrar un grupo.');
      return;
    }

    final grupos = datos.map((fila) {
      return Grupo(
        id: fila['id'],
        codigo: fila['codigo'],
        nombre: fila['nombre'],
        periodo: fila['periodo'],
      );
    }).toList();

    final seleccion = await showDialog<Grupo>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Seleccionar grupo'),
        children: grupos.map((grupo) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, grupo),
            child: Text('${grupo.nombre} (${grupo.codigo})'),
          );
        }).toList(),
      ),
    );

    if (seleccion == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SesionesScreen(grupo: seleccion),
      ),
    );
  },
),
                  _ActionCard(
                    titulo: 'Puntuación',
                    descripcion: 'Asignar puntos',
                    icono: Icons.stars_rounded,
                    color: const Color(0xFFFBBF24),
                    onTap: () {
                      _mostrarMensaje(
                        context,
                        'Próximamente: Puntuación',
                      );
                    },
                  ),
                  _ActionCard(
                    titulo: 'Reportes',
                    descripcion: 'Consultar resultados',
                    icono: Icons.bar_chart_rounded,
                    color: const Color(0xFFA78BFA),
                    onTap: () {
                      _mostrarMensaje(
                        context,
                        'Próximamente: Reportes',
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // GRUPOS RECIENTES
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis grupos',
                    style: TextStyle(
                      color: texto,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _mostrarMensaje(
                        context,
                        'Próximamente: Todos los grupos',
                      );
                    },
                    child: const Text(
                      'Ver todos',
                      style: TextStyle(color: azul),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              const _GroupCard(
                nombre: 'Desarrollo de Aplicaciones',
                codigo: 'IDAW-401',
                estudiantes: '24 estudiantes',
                color: azul,
              ),

              const SizedBox(height: 12),

              const _GroupCard(
                nombre: 'Desarrollo Móvil',
                codigo: 'IDAW-402',
                estudiantes: '22 estudiantes',
                color: verde,
              ),

              const SizedBox(height: 12),

              const _GroupCard(
                nombre: 'Base de Datos',
                codigo: 'IDAW-403',
                estudiantes: '20 estudiantes',
                color: Color(0xFFA78BFA),
              ),

              const SizedBox(height: 28),

              // ACTIVIDAD RECIENTE
              const Text(
                'Actividad reciente',
                style: TextStyle(
                  color: texto,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              _ActivityItem(
                icono: Icons.fact_check_rounded,
                color: verde,
                titulo: 'Asistencia registrada',
                descripcion: 'Grupo IDAW-401',
                hora: 'Hoy',
              ),

              const Divider(color: Colors.white12, height: 25),

              _ActivityItem(
                icono: Icons.stars_rounded,
                color: const Color(0xFFFBBF24),
                titulo: 'Puntos asignados',
                descripcion: 'Participación en clase',
                hora: 'Hoy',
              ),

              const Divider(color: Colors.white12, height: 25),

              _ActivityItem(
                icono: Icons.calendar_month_rounded,
                color: azul,
                titulo: 'Sesión académica',
                descripcion: 'Grupo IDAW-402',
                hora: 'Ayer',
              ),

              const SizedBox(height: 25),

              const Center(
                child: Text(
                  'AULA PUNTOS - SENATI',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// TARJETA DE ESTADISTICAS

class _StatCard extends StatelessWidget {
  final String titulo;
  final String cantidad;
  final IconData icono;
  final Color color;

  const _StatCard({
    required this.titulo,
    required this.cantidad,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DashboardScreen.tarjeta,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icono, color: color, size: 25),
          Text(
            cantidad,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// TARJETAS DE ACCESO RAPIDO

class _ActionCard extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: DashboardScreen.tarjeta,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: color, size: 29),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              descripcion,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TARJETA DE GRUPOS

class _GroupCard extends StatelessWidget {
  final String nombre;
  final String codigo;
  final String estudiantes;
  final Color color;

  const _GroupCard({
    required this.nombre,
    required this.codigo,
    required this.estudiantes,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DashboardScreen.tarjeta,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.groups_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$codigo • $estudiantes',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white38,
            size: 16,
          ),
        ],
      ),
    );
  }
}

// ELEMENTOS DE ACTIVIDAD RECIENTE

class _ActivityItem extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String descripcion;
  final String hora;

  const _ActivityItem({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.descripcion,
    required this.hora,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(
            icono,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          hora,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
