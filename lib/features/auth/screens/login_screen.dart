import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/app_strings.dart';
import '../../demo/demo_mode.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Notify the OS autofill service that sign-in succeeded so it can
      // offer to save these credentials.
      TextInput.finishAutofillContext();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _messageFor(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _messageFor(String code) {
    final s = context.s;
    return switch (code) {
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        s.errInvalidCredentials,
      'network-request-failed' => s.errNoInternet,
      _ => s.errGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: AutofillGroup(
              child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storefront, size: 72, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Latitude Tracker',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: s.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? s.email
                            : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                      labelText: s.password,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                      ),
                    ),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? s.password : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(s.signIn),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => DemoMode.enter(),
                    child: Text(s.tryDemo),
                  ),
                ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
