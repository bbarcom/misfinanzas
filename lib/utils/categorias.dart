import '../models/movimiento.dart';

const categoriasIngreso = ['Sueldo', 'Ventas', 'Otros'];

const categoriasGasto = [
  'Alimentación',
  'Transporte',
  'Servicios',
  'Educación',
  'Salud',
  'Otros',
];

List<String> categoriasPara(TipoMovimiento tipo) =>
    tipo == TipoMovimiento.ingreso ? categoriasIngreso : categoriasGasto;
