Eres mi asistente de desarrollo Flutter. Vamos a construir "MisFinanzas", una app
Android para registrar ingresos y gastos por mes y por día. Respeta SIEMPRE este contexto.

OBJETIVO
App móvil (Flutter, Dart, Android) para que un usuario registre ingresos y gastos,
tanto por DÍA (con fecha exacta) como por MES (monto mensual consolidado), y consulte
resúmenes y balance.

ENTIDADES (3 tablas en SQLite)
1. usuarios(id, nombre, correo UNIQUE, passwordHash, salt, creadoEn)
2. ingresos(id, usuarioId FK, monto INTEGER en centavos, categoria, descripcion, fecha, modo, creadoEn)
3. gastos(id, usuarioId FK, monto INTEGER en centavos, categoria, descripcion, fecha, modo, creadoEn)
- modo: 'diario' o 'mensual'. Si es 'mensual', fecha = día 1 del mes.
- ON DELETE CASCADE de usuarios hacia ingresos y gastos.

STACK Y REGLAS
- Flutter estable, Dart null-safety, Material 3.
- Persistencia: sqflite + path. Estado: provider. Formato de fechas/moneda: intl. Hash: crypto.
- Arquitectura por carpetas dentro de lib/: models/, data/ (base de datos y repositorios),
  providers/, screens/, widgets/, utils/.
- Nunca guardar contraseñas en texto plano (SHA-256 con sal aleatoria).
- Montos como int en centavos; mostrar con formato de moneda en la interfaz.
- Validar formularios (monto > 0, categoría obligatoria, fecha válida, correo válido).
- Textos de la interfaz en español.
- Una pantalla o funcionalidad por vez. No agregues pantallas ni dependencias que yo no pida.
- Código limpio, comentado en español donde sea útil. Después de cada cambio, indica qué
  archivos creaste o modificaste y cómo probarlo.

CÓMO TRABAJAMOS
Voy a darte instrucciones por pasos. En cada paso, haz solo lo que pido, verifica con
`flutter analyze` y dime qué debo probar en el emulador.
