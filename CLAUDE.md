# MisFinanzas — contexto del proyecto

App Flutter (Android) de ingresos y gastos por **día** y por **mes**, con backend propio.
Proyecto Final del curso "Desarrolla Aplicaciones Móviles Robustas con Flutter e IA".

## Arquitectura (obligatoria)
`screens/` → `controllers/` (GetX) → `services/` (HTTP, caché local, almacenamiento seguro) → API REST (`backend/`).
- Ninguna pantalla hace HTTP; solo habla con controladores GetX (`Get.find<...>()`).
- Estado compartido entre pantallas = `GetxController` con `Rx`. `setState` solo para estado local de un formulario.
- Token JWT en `flutter_secure_storage` (`TokenStorage`). Nunca en `shared_preferences`.
- `shared_preferences` solo guarda la caché local de movimientos y el último correo.
- Backend en `backend/` (Dart + shelf). Datos en `backend/data/db.json` (ignorado por git).
- La clave del proveedor de IA vive SOLO en `backend/.env` (ignorado). La app llama a `POST /ia/resumen`.

## Reglas de datos
- Movimiento: `tipo` ingreso|gasto, `monto` INT en centavos (> 0), `modo` diario|mensual; si es mensual, `fecha` = día 1.
- El total mensual suma movimientos `diario` y `mensual`; la vista diaria solo los `diario`.
- Errores de la API: 400 petición mal formada, 401 no autenticado, 404, 409 duplicado, 422 datos inválidos, 5xx servidor.
  Cada uno muestra un mensaje distinto (`ApiException.paraUsuario`).

## Reglas de trabajo
- Textos de interfaz en español; comentarios en español donde aporten.
- Antes de dar algo por hecho: `flutter analyze`, `flutter test` y, en `backend/`, `dart analyze` y `dart test`.
- Nunca commitear `.env`, claves ni tokens. Commits pequeños y descriptivos.
- No agregar dependencias sin necesidad; explicar cada una.
