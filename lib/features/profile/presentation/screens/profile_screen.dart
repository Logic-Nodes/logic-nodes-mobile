import 'package:flutter/material.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/design_tokens.dart';
import '../../../auth/application/controllers/session_controller.dart';
import '../../application/controllers/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.controller,
    required this.sessionController,
    super.key,
  });

  final ProfileController controller;
  final SessionController sessionController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _syncFields() {
    final profile = widget.controller.profile;
    if (profile == null) {
      return;
    }

    if (_firstNameController.text.isEmpty) {
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _phoneController.text = profile.phoneNumber ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final controller = widget.controller;

          if (controller.isLoading && controller.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          _syncFields();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Edita tu perfil',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: controller.isSaving ? null : () => _save(context),
                icon: controller.isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Guardar cambios'),
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: widget.sessionController.isSigningOut
                    ? null
                    : () => _signOutAll(context),
                icon: const Icon(Icons.devices_other_outlined),
                label: const Text('Cerrar sesión en todos los dispositivos'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: widget.sessionController.isSigningOut
                    ? null
                    : () => _signOut(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final success = await widget.controller.save(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phoneNumber: _phoneController.text,
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Perfil actualizado.'
              : widget.controller.errorMessage ?? 'No se pudo actualizar el perfil.',
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await widget.sessionController.signOut();
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _signOutAll(BuildContext context) async {
    await widget.sessionController.signOutAll();
    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }
}
