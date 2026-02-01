import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/controller_scope.dart';
import '../../state/qr_app_controller.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  final ValueNotifier<bool> _isLoginMode = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isCopyingEmail = ValueNotifier<bool>(false);
  final ValueNotifier<int> _selectedAvatarIndex = ValueNotifier<int>(0);
  final ValueNotifier<String?> _customDisplayName =
      ValueNotifier<String?>(null);
  final ValueNotifier<bool> _isSavingProfile = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isDeletingAccount = ValueNotifier<bool>(false);
  bool _hasSeededProfile = false;
  final List<String> _avatarAssets = List<String>.generate(
    19,
    (index) => 'assets/avatars/avatar-${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _isLoginMode.dispose();
    _isLoading.dispose();
    _isCopyingEmail.dispose();
    _selectedAvatarIndex.dispose();
    _customDisplayName.dispose();
    _isSavingProfile.dispose();
    _isDeletingAccount.dispose();
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
      controller.setTabIndex(0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Kayıt başarılı.')),
      );
    }
  }

  Future<void> _copyEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kopyalanacak email bulunamadı.')),
      );
      return;
    }
    _isCopyingEmail.value = true;
    try {
      await Clipboard.setData(ClipboardData(text: email));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email kopyalandı.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email kopyalanamadı.')),
      );
    } finally {
      _isCopyingEmail.value = false;
    }
  }

  Future<void> _saveProfile() async {
    final controller = QrControllerScope.of(context);
    if (!controller.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil kaydetmek için giriş yap.')),
      );
      return;
    }
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad ve soyad gerekli.')),
      );
      return;
    }
    _isSavingProfile.value = true;
    final result = await controller.saveProfile(
      firstName: firstName,
      lastName: lastName,
      avatarIndex: _selectedAvatarIndex.value,
    );
    _isSavingProfile.value = false;
    if (!mounted) {
      return;
    }
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Profil kaydedilemedi.')),
      );
      return;
    }
    _customDisplayName.value = '$firstName $lastName';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil kaydedildi.')),
    );
  }

  Future<void> _showAvatarPicker() async {
    if (_avatarAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar bulunamadı.')),
      );
      return;
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final sheetHeight = MediaQuery.of(context).size.height * 0.6;
        return SafeArea(
          child: SizedBox(
            height: sheetHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avatar Seç',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _selectedAvatarIndex,
                      builder: (context, selectedIndex, _) {
                        return GridView.builder(
                          itemCount: _avatarAssets.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final isSelected = index == selectedIndex;
                            return InkWell(
                              key: ValueKey('avatarOption$index'),
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                _selectedAvatarIndex.value = index;
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                  color: colorScheme.primary.withOpacity(0.08),
                                ),
                                child: Center(
                                  child: _AvatarVisual(
                                    assetPath: _avatarAssets[index],
                                    size: 46,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDeleteAccount() async {
    if (_isDeletingAccount.value) {
      return;
    }
    _isDeletingAccount.value = true;
    try {
      debugPrint('hesabı sil');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap silme yakında eklenecek.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap silme başarısız oldu.')),
      );
    } finally {
      _isDeletingAccount.value = false;
    }
  }

  void _seedProfileIfNeeded(QrAppController controller) {
    final profile = controller.profile;
    if (profile == null || _hasSeededProfile) {
      return;
    }
    _hasSeededProfile = true;
    _firstNameController.text = profile.firstName;
    _lastNameController.text = profile.lastName;
    _selectedAvatarIndex.value = profile.avatarIndex.clamp(
      0,
      _avatarAssets.length - 1,
    );
    final fullName =
        '${profile.firstName.trim()} ${profile.lastName.trim()}'.trim();
    _customDisplayName.value = fullName.isEmpty ? null : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final controller = QrControllerScope.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appBarTitleStyle = theme.textTheme.titleLarge;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.isSignedIn) {
          _hasSeededProfile = false;
          _customDisplayName.value = null;
        } else if (!controller.isProfileLoading) {
          _seedProfileIfNeeded(controller);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Hesap'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: controller.isSignedIn
                ? ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            ValueListenableBuilder<int>(
                              valueListenable: _selectedAvatarIndex,
                              builder: (context, selectedIndex, _) {
                                return CircleAvatar(
                                  radius: 28,
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.2),
                                  child: _AvatarVisual(
                                    assetPath: _avatarAssets[selectedIndex],
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ValueListenableBuilder<String?>(
                                valueListenable: _customDisplayName,
                                builder: (context, displayName, _) {
                                  final resolvedName = displayName?.trim();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (resolvedName != null &&
                                                resolvedName.isNotEmpty)
                                            ? resolvedName
                                            : (controller.displayName ?? ''),
                                        style: appBarTitleStyle,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        controller.email ?? '',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: _isCopyingEmail,
                              builder: (context, isCopying, _) {
                                return IconButton(
                                  key: const ValueKey('profileCopyEmail'),
                                  tooltip: 'Email kopyala',
                                  onPressed: isCopying
                                      ? null
                                      : () => _copyEmail(controller.email),
                                  icon: isCopying
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.copy_rounded),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<int>(
                        valueListenable: _selectedAvatarIndex,
                        builder: (context, selectedIndex, _) {
                          final previewKey =
                              ValueKey('profileAvatarPreview_$selectedIndex');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: InkWell(
                                  key: const ValueKey('profileAvatarPicker'),
                                  borderRadius: BorderRadius.circular(36),
                                  onTap: _showAvatarPicker,
                                  child: AnimatedContainer(
                                    key: previewKey,
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(36),
                                      border: Border.all(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: colorScheme.primary
                                              .withOpacity(0.1),
                                          child: _AvatarVisual(
                                            assetPath:
                                                _avatarAssets[selectedIndex],
                                            size: 56,
                                          ),
                                        ),
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: colorScheme.primary,
                                          child: const Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Avatarı değiştirmek için dokun.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'İsim Bilgileri',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('profileFirstName'),
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ad',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const ValueKey('profileLastName'),
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Soyad',
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveProfile(),
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isSavingProfile,
                        builder: (context, isSaving, _) {
                          return SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              key: const ValueKey('profileSave'),
                              onPressed: isSaving ? null : _saveProfile,
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Kaydet'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _ProfileInfoCard(
                              title: 'Son Tarama',
                              value: controller.lastScan ?? 'Henüz yok',
                              icon: Icons.qr_code_scanner,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ProfileInfoCard(
                              title: 'Son Oluşturma',
                              value: controller.lastGenerated ?? 'Henüz yok',
                              icon: Icons.qr_code_2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (controller.isProfileLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (controller.profileError != null)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.error.withOpacity(0.4),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: colorScheme.error),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    controller.profileError!,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                TextButton(
                                  onPressed: controller.retryProfile,
                                  child: const Text('Tekrar Dene'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.security_rounded,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Hesabın güvende. QR geçmişin bulutta saklanır.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: controller.signOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Çıkış Yap'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isDeletingAccount,
                        builder: (context, isDeleting, _) {
                          return SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const ValueKey('profileDeleteAccount'),
                              onPressed:
                                  isDeleting ? null : _handleDeleteAccount,
                              icon: isDeleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline),
                              label: const Text('Hesabı Sil'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  )
                : ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  colorScheme.primary.withOpacity(0.2),
                              child: Icon(
                                Icons.lock_outline,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hesabını güvene al',
                                    style: appBarTitleStyle,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Geçmişini senkronla, cihazlar arasında devam et.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          return SizedBox(
                            width: double.infinity,
                            child: FilledButton(
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

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarVisual extends StatelessWidget {
  const _AvatarVisual({
    required this.assetPath,
    required this.size,
  });

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isTest = bool.fromEnvironment('FLUTTER_TEST');
    if (isTest) {
      return Icon(
        Icons.person,
        size: size * 0.6,
        color: Theme.of(context).colorScheme.primary,
      );
    }
    return ClipOval(
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, _, __) {
          return Icon(
            Icons.person,
            size: size * 0.6,
            color: Theme.of(context).colorScheme.primary,
          );
        },
      ),
    );
  }
}
