import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../utils/validators.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  bool _ocultar = true;
  final _auth = Get.find<AuthController>();

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    final ok = await _auth.registrar(_nombre.text, _correo.text, _password.text);
    // La sesión ya está iniciada: se vuelve a la raíz, que mostrará la pantalla principal.
    if (ok) Get.until((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Nombre', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Correo', border: OutlineInputBorder()),
                  validator: validarCorreo,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  obscureText: _ocultar,
                  decoration: InputDecoration(
                    labelText: 'Contraseña (mínimo 6 caracteres)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _ocultar = !_ocultar),
                    ),
                  ),
                  validator: validarPassword,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmar,
                  obscureText: _ocultar,
                  decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña', border: OutlineInputBorder()),
                  validator: (v) =>
                      v != _password.text ? 'Las contraseñas no coinciden' : null,
                ),
                Obx(() => _auth.error.value == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_auth.error.value!,
                            style: TextStyle(color: tema.colorScheme.error)),
                      )),
                const SizedBox(height: 24),
                Obx(() => FilledButton(
                      onPressed: _auth.enviando.value ? null : _registrar,
                      child: _auth.enviando.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Registrarme'),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
