import '../database/database_helper.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../models/grupo.dart';

class ExportadorReportes {
  static String _fecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }
static Future<void> exportarAsistencias(Grupo grupo, Sesion sesion) async {
  final db = DatabaseHelper.instance;

  final estudiantes = await db.obtenerEstudiantes(grupo.id);
  final asistencias = await db.obtenerAsistencias(sesion.id);

  final excel = Excel.createExcel();
  final sheet = excel['Asistencias'];

  sheet.appendRow([
    TextCellValue('Código'),
    TextCellValue('Nombres'),
    TextCellValue('Apellidos'),
    TextCellValue('Estado'),
  ]);

  for (final estudiante in estudiantes) {
    final registro = asistencias.where(
      (a) => a['estudiante_id'] == estudiante['id'],
    );

    final estado = registro.isNotEmpty
        ? registro.first['estado'].toString()
        : 'Sin registrar';

    sheet.appendRow([
      TextCellValue(estudiante['codigo'].toString()),
      TextCellValue(estudiante['nombres'].toString()),
      TextCellValue(estudiante['apellidos'].toString()),
      TextCellValue(estado),
    ]);
  }

  final bytes = excel.save();

  if (bytes == null) return;

  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(bytes),
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      fileNameOverrides: ['asistencias_${grupo.codigo}.xlsx'],
    ),
  );
}
  static int _puntosEstudiante(Grupo grupo, int estudianteId) {
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

  static int _contarAsistencia(Grupo grupo, String estado) {
    int total = 0;

    for (var sesion in grupo.sesiones) {
      total += sesion.asistencias
          .where((registro) => registro.estado == estado)
          .length;
    }

    return total;
  }

  static Future<void> exportarPDF(Grupo grupo) async {
    final documento = pw.Document();

    final estudiantes = grupo.estudiantes
        .where((estudiante) => estudiante.estado == 'Activo')
        .toList();

    documento.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'AULA PUNTOS - SENATI',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('REPORTE ACADEMICO'),
          pw.SizedBox(height: 12),
          pw.Text('Grupo: ${grupo.nombre}'),
          pw.Text('Codigo: ${grupo.codigo}'),
          pw.Text('Periodo: ${grupo.periodo}'),
          pw.SizedBox(height: 18),

          pw.Text(
            'RESUMEN DE ASISTENCIA',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Estado', 'Cantidad'],
            data: [
              ['Presentes', '${_contarAsistencia(grupo, 'Presente')}'],
              ['Tardanzas', '${_contarAsistencia(grupo, 'Tardanza')}'],
              ['Faltas', '${_contarAsistencia(grupo, 'Falta')}'],
              ['Justificados', '${_contarAsistencia(grupo, 'Justificado')}'],
            ],
          ),

          pw.SizedBox(height: 18),
          pw.Text(
            'RENDIMIENTO POR ESTUDIANTE',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Codigo', 'Estudiante', 'Puntos'],
            data: estudiantes.map((estudiante) {
              return [
                estudiante.codigo,
                estudiante.nombreCompleto,
                '${_puntosEstudiante(grupo, estudiante.id)}',
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 18),
          pw.Text(
            'SESIONES REGISTRADAS',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Sesion', 'Fecha', 'Estado'],
            data: grupo.sesiones.map((sesion) {
              return [
                sesion.titulo,
                _fecha(sesion.fecha),
                sesion.estado,
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),
          pw.Text(
            'Reporte generado por Aula Puntos - SENATI',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await documento.save(),
      filename: 'reporte_${grupo.codigo}.pdf',
    );
  }

  static Future<void> exportarExcel(Grupo grupo) async {
    final excel = Excel.createExcel();
    final sheet = excel['Reporte'];

    sheet.appendRow([
      TextCellValue('AULA PUNTOS - SENATI'),
    ]);

    sheet.appendRow([
      TextCellValue('REPORTE ACADEMICO'),
    ]);

    sheet.appendRow([
      TextCellValue('Grupo'),
      TextCellValue(grupo.nombre),
    ]);

    sheet.appendRow([
      TextCellValue('Codigo'),
      TextCellValue(grupo.codigo),
    ]);

    sheet.appendRow([
      TextCellValue('Periodo'),
      TextCellValue(grupo.periodo),
    ]);

    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('RESUMEN DE ASISTENCIA'),
    ]);

    sheet.appendRow([
      TextCellValue('Estado'),
      TextCellValue('Cantidad'),
    ]);

    sheet.appendRow([
      TextCellValue('Presentes'),
      IntCellValue(_contarAsistencia(grupo, 'Presente')),
    ]);

    sheet.appendRow([
      TextCellValue('Tardanzas'),
      IntCellValue(_contarAsistencia(grupo, 'Tardanza')),
    ]);

    sheet.appendRow([
      TextCellValue('Faltas'),
      IntCellValue(_contarAsistencia(grupo, 'Falta')),
    ]);

    sheet.appendRow([
      TextCellValue('Justificados'),
      IntCellValue(_contarAsistencia(grupo, 'Justificado')),
    ]);

    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('RENDIMIENTO POR ESTUDIANTE'),
    ]);

    sheet.appendRow([
      TextCellValue('Codigo'),
      TextCellValue('Estudiante'),
      TextCellValue('Puntos acumulados'),
    ]);

    final estudiantes = grupo.estudiantes
        .where((estudiante) => estudiante.estado == 'Activo')
        .toList();

    for (var estudiante in estudiantes) {
      sheet.appendRow([
        TextCellValue(estudiante.codigo),
        TextCellValue(estudiante.nombreCompleto),
        IntCellValue(
          _puntosEstudiante(grupo, estudiante.id),
        ),
      ]);
    }

    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('SESIONES REGISTRADAS'),
    ]);

    sheet.appendRow([
      TextCellValue('Sesion'),
      TextCellValue('Tema'),
      TextCellValue('Fecha'),
      TextCellValue('Estado'),
      TextCellValue('Asistencias'),
      TextCellValue('Participaciones'),
    ]);

    for (var sesion in grupo.sesiones) {
      sheet.appendRow([
        TextCellValue(sesion.titulo),
        TextCellValue(sesion.tema),
        TextCellValue(_fecha(sesion.fecha)),
        TextCellValue(sesion.estado),
        IntCellValue(sesion.asistencias.length),
        IntCellValue(sesion.participaciones.length),
      ]);
    }

    final bytes = excel.save();

    if (bytes == null) {
      throw Exception('No se pudo generar el archivo Excel.');
    }

    await SharePlus.instance.share(
      ShareParams(
        title: 'Reporte de ${grupo.nombre}',
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: [
          'reporte_${grupo.codigo}.xlsx',
        ],
      ),
    );
  }
}
