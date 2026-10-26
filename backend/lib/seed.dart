import 'auth.dart';
import 'store.dart';

/// Crea el usuario demo con ~26 movimientos si la base está vacía.
/// Demo: demo@misfinanzas.app / demo1234
void sembrarSiVacio(Store s) {
  if (s.usuarios.isNotEmpty) return;
  final sal = generarSal();
  final uid = s.nuevoIdUsuario();
  s.usuarios.add({
    'id': uid,
    'nombre': 'Usuario Demo',
    'correo': 'demo@misfinanzas.app',
    'salt': sal,
    'passwordHash': hashPassword('demo1234', sal),
    'creadoEn': DateTime.now().toIso8601String(),
  });
  final hoy = DateTime.now();
  String f(int mesesAtras, int dia) {
    final d = DateTime(hoy.year, hoy.month - mesesAtras, dia);
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void add(String tipo, int dolares, String cat, String desc, String fecha, String modo) =>
      s.movimientos.add({
        'id': s.nuevoIdMovimiento(),
        'usuarioId': uid,
        'tipo': tipo,
        'monto': dolares * 100,
        'categoria': cat,
        'descripcion': desc,
        'fecha': fecha,
        'modo': modo,
        'creadoEn': DateTime.now().toIso8601String(),
      });

  for (var m = 0; m < 2; m++) {
    add('ingreso', 900, 'Sueldo', 'Sueldo mensual', f(m, 1), 'mensual');
    add('gasto', 250, 'Servicios', 'Arriendo y servicios básicos', f(m, 1), 'mensual');
    add('ingreso', 120, 'Ventas', 'Venta de artículos', f(m, 8), 'diario');
    add('gasto', 45, 'Alimentación', 'Supermercado', f(m, 3), 'diario');
    add('gasto', 18, 'Transporte', 'Pasajes de bus', f(m, 4), 'diario');
    add('gasto', 60, 'Alimentación', 'Compras de la semana', f(m, 10), 'diario');
    add('gasto', 35, 'Salud', 'Farmacia', f(m, 12), 'diario');
    add('gasto', 80, 'Educación', 'Libros y materiales', f(m, 15), 'diario');
    add('gasto', 22, 'Transporte', 'Taxi', f(m, 17), 'diario');
    add('gasto', 30, 'Otros', 'Salida con amigos', f(m, 20), 'diario');
    add('ingreso', 50, 'Otros', 'Reembolso', f(m, 22), 'diario');
    add('gasto', 40, 'Alimentación', 'Restaurante', f(m, 24), 'diario');
  }
  s.guardar();
}
