import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/glass_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final isGuest = ref.watch(isGuestProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: authState.when(
          data: (user) {
            if (user == null) {
              return _buildSignInPrompt(context, colorScheme, theme);
            }

            return profileAsync.when(
              data: (profile) => _buildProfileContent(
                context,
                theme,
                colorScheme,
                user,
                profile,
                isGuest,
                ref,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                // If profile doesn't exist yet (new anonymous user), still show UI
                return _buildProfileContent(
                  context,
                  theme,
                  colorScheme,
                  user,
                  null, // null profile is okay
                  isGuest,
                  ref,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text('Error: $error'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic user,
    dynamic profile,
    bool isGuest,
    WidgetRef ref,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // User Header with Avatar
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: Text(
                profile?.initials ?? 'G',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.displayNameOrEmail ?? 'Guest',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (user.email != null)
                    Text(
                      user.email!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  if (isGuest)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Guest Mode',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        if (isGuest) ...[
          const SizedBox(height: 18),

          // Sign In / Sign Up Row for Guest Users
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 18),

        // Learning Plan Card
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learning plan',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '3 lessons completed this week — keep the streak!',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () {},
                child: const Text('View curriculum'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Settings Card
        GlassCard(
          child: Column(
            children: const [
              _SettingTile(
                title: 'Notifications',
                subtitle: 'Price alerts, lesson reminders, news digests',
                icon: Icons.notifications_active_outlined,
              ),
              Divider(height: 1),
              _SettingTile(
                title: 'Linked broker',
                subtitle: 'Not connected',
                icon: Icons.link,
              ),
              Divider(height: 1),
              _SettingTile(
                title: 'Privacy & security',
                subtitle: '2FA, devices, data controls',
                icon: Icons.lock_outline,
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Support Card
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Need help or want to suggest a feature? We read every note.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contact support'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Sign Out Button (only for non-guest)
        if (!isGuest)
          OutlinedButton.icon(
            onPressed: () => _handleSignOut(context, ref),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSignInPrompt(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_circle,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Sign in to save your progress',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.signOut();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed out successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to sign out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}
