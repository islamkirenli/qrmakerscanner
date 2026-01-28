import 'package:flutter/material.dart';
import '../../app/controller_scope.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final ValueNotifier<bool> _isLoginMode = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isLoginMode.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final controller = QrControllerScope.of(context);
    _isLoading.value = true;
    final isLoginMode = _isLoginMode.value;
    final result = isLoginMode
        ? await controller.signInWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await controller.signUpWithEmailPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
    _isLoading.value = false;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Bilinmeyen hata.')),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    if (isLoginMode) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Kayıt başarılı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = QrControllerScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Hesap'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: controller.isSignedIn
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.displayName ?? '',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(controller.email ?? ''),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: controller.signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Çıkış Yap'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        key: const ValueKey('authEmail'),
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleAuth(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('authPassword'),
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleAuth(),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isLoading,
                        builder: (context, isLoading, _) {
                          return FilledButton(
                            key: const ValueKey('authSubmit'),
                            onPressed: isLoading ? null : _handleAuth,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : ValueListenableBuilder<bool>(
                                    valueListenable: _isLoginMode,
                                    builder: (context, isLoginMode, _) {
                                      return Text(
                                        isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                      );
                                    },
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isLoginMode,
                        builder: (context, isLoginMode, _) {
                          return TextButton(
                            key: const ValueKey('authToggle'),
                            onPressed: _isLoading.value
                                ? null
                                : () => _isLoginMode.value = !isLoginMode,
                            child: Text(
                              isLoginMode
                                  ? 'Hesabın yok mu? Kayıt Ol'
                                  : 'Zaten hesabın var mı? Giriş Yap',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
