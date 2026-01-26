import 'package:flutter/material.dart';
import '../../app/controller_scope.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final controller = QrControllerScope.of(context);
    final result = controller.signIn(
      name: _nameController.text,
      email: _emailController.text,
    );
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Bilinmeyen hata.')),
      );
      return;
    }
    Navigator.of(context).pop();
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
                        key: const ValueKey('loginName'),
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad Soyad',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('loginEmail'),
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleSignIn(),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const ValueKey('loginButton'),
                        onPressed: _handleSignIn,
                        child: const Text('Giriş Yap'),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
