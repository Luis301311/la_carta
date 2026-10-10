import 'package:flutter/material.dart';
import 'package:lacarta/core/constant/app_colors.dart';
import 'package:get/get.dart';
import 'package:lacarta/core/constant/custom_colors.dart';
import 'package:lacarta/core/controller/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final AuthController _auth = AuthController.to;

  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Si ya hay sesión, directo al panel
    if (_auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _auth.goHome());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_auth.isLoading.value) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final error = await _auth.login(_email.text, _password.text);
    if (error != null && mounted) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.restaurant_menu,
                          size: 48, color: CustomColorBasic.yellow),
                      const SizedBox(height: 12),
                      const Text(
                        'Panel La Carta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ingresa con tu cuenta de administrador',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CustomColorBasic.grey1),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.mail_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return 'Escribe tu correo';
                          if (!value.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Escribe tu contraseña'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Obx(() {
                        final loading = _auth.isLoading.value;
                        return SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.carbon,
                              foregroundColor: CustomColorBasic.white1,
                            ),
                            onPressed: loading ? null : _submit,
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: CustomColorBasic.white1),
                                  )
                                : const Text('Ingresar',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
