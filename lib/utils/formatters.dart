import 'package:intl/intl.dart';

/// Formatea centavos como moneda, ej. 125050 -> $1,250.50
String formatearMoneda(int centavos) {
  final f = NumberFormat.currency(locale: 'en_US', symbol: r'$', decimalDigits: 2);
  return f.format(centavos / 100);
}

/// Formatea una fecha como dd/MM/yyyy.
String formatearFecha(DateTime fecha) => DateFormat('dd/MM/yyyy').format(fecha);

/// Formatea un mes en español, ej. 'octubre 2026'.
/// Requiere haber llamado a initializeDateFormatting('es').
String formatearMes(DateTime fecha) => DateFormat('MMMM yyyy', 'es').format(fecha);

/// Fecha larga en español, ej. 'domingo 25 de octubre'.
String formatearDiaLargo(DateTime fecha) =>
    DateFormat("EEEE d 'de' MMMM", 'es').format(fecha);

/// Convierte un texto en dólares (acepta coma o punto decimal) a centavos.
/// Devuelve null si no es un número válido.
int? montoACentavos(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) return null;
  final valor = double.tryParse(limpio);
  if (valor == null || valor.isNaN || valor.isInfinite) return null;
  return (valor * 100).round();
}
