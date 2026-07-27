import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(authProvider.notifier).checkLoginStatus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  backgroundImage: user?.profilePic.isNotEmpty == true ? NetworkImage(user!.profilePic) : null,
                  child: user?.profilePic.isEmpty ?? true ? Text(user?.username[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 32, color: Colors.white)) : null,
                ),
                const SizedBox(height: 8),
                Text(user?.username ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.email ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
                if (user?.phone != null && user!.phone.isNotEmpty) Text(user.phone, style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: Text(user?.role.toUpperCase() ?? 'CUSTOMER', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            _menuItem(Icons.person, 'My Details', () => _showMyDetails(context, user)),
            _menuItem(Icons.location_on, 'My Addresses', () => context.go('/profile/addresses')),
            _menuItem(Icons.favorite, 'Wishlist', () => context.go('/wishlist')),
            _menuItem(Icons.receipt_long, 'My Orders', () => context.go('/orders')),
            _menuItem(Icons.book, 'Khata / Credit', () => context.go('/khata')),
            _menuItem(Icons.info_outline, 'About', () => showAboutDialog(context: context, applicationName: 'Gokulam Traders', applicationVersion: '1.0.0', children: [
              const Text('Hardware, Electrical & Plumbing Store Management App'),
            ])),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorColor),
              title: const Text('Logout', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Logout'), content: const Text('Are you sure?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  TextButton(onPressed: () async {
                    Navigator.pop(ctx);
                    await ref.read(authProvider.notifier).logout();
                    context.go('/auth/login');
                  }, child: const Text('Logout', style: TextStyle(color: AppTheme.errorColor))),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showMyDetails(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('My Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Username', user?.username ?? ''),
            _detailRow('Email', user?.email ?? ''),
            _detailRow('Phone', user?.phone ?? ''),
            _detailRow('Role', user?.role?.toUpperCase() ?? ''),
            _detailRow('Address', user?.address ?? ''),
            _detailRow('Joined', user?.dateJoined ?? ''),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary))),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}