import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  UserRole _role = UserRole.customer;
  bool _loading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final firebaseUser = ref.read(authServiceProvider).currentUser;
    if (firebaseUser == null) {
      context.go('/login');
      return;
    }
    setState(() => _loading = true);
    try {
      final appUser = AppUser(
        uid: firebaseUser.uid,
        name: _nameController.text.trim(),
        phone: firebaseUser.phoneNumber ?? '',
        role: _role,
      );
      await ref.read(userRepositoryProvider).createUser(appUser);
      if (!mounted) return;
      context.go(UserRepository.homeRouteFor(appUser));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your profile. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text('Set up your account',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Tell us your name and how you will use ParcelGo.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Full name',
                  hint: 'e.g. Ali Khan',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 24),
                const Text('I want to',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Send parcels',
                  subtitle: 'I am a customer',
                  selected: _role == UserRole.customer,
                  onTap: () => setState(() => _role = UserRole.customer),
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  icon: Icons.two_wheeler_outlined,
                  title: 'Deliver parcels',
                  subtitle: 'I am a rider',
                  selected: _role == UserRole.rider,
                  onTap: () => setState(() => _role = UserRole.rider),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                    label: 'Continue', isLoading: _loading, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0x143F5B2E) : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: AppColors.green),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? AppColors.green : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}