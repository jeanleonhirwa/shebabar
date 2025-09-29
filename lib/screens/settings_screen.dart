import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme_config.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.settingsTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            _buildUserInfoSection(context),
            const SizedBox(height: 20),
            
            // Settings Options
            _buildSettingsOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        if (user == null) return const SizedBox.shrink();

        return CustomCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: ThemeConfig.primaryColor,
                child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.role.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeConfig.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Username: ${user.username}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeConfig.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsOptions(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Employees (Owner only)
            if (authProvider.canManageUsers)
              _buildSettingsItem(
                context,
                title: AppConstants.employees,
                subtitle: 'Gucunga abakozi',
                icon: Icons.people,
                onTap: () {
                  // TODO: Navigate to employees screen
                  Helpers.showSuccessMessage(context, 'Coming soon...');
                },
              ),
            
            // Products Management (Owner only)
            if (authProvider.canManageProducts)
              _buildSettingsItem(
                context,
                title: AppConstants.products,
                subtitle: 'Gucunga ibicuruzwa',
                icon: Icons.inventory,
                onTap: () {
                  // TODO: Navigate to product management screen
                  Helpers.showSuccessMessage(context, 'Coming soon...');
                },
              ),
            
            // Backup
            _buildSettingsItem(
              context,
              title: AppConstants.backup,
              subtitle: 'Kubika no gusubiza amakuru',
              icon: Icons.backup,
              onTap: () {
                // TODO: Implement backup functionality
                Helpers.showSuccessMessage(context, 'Coming soon...');
              },
            ),
            
            // User Info
            _buildSettingsItem(
              context,
              title: AppConstants.userInfo,
              subtitle: 'Hindura amakuru yawe',
              icon: Icons.person,
              onTap: () {
                // TODO: Navigate to user profile screen
                Helpers.showSuccessMessage(context, 'Coming soon...');
              },
            ),
            
            const SizedBox(height: 20),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _handleLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  AppConstants.logout,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeConfig.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: ThemeConfig.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeConfig.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ThemeConfig.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      'Gusohoka',
      'Niwemeza ko ushaka gusohoka?',
    );

    if (confirmed && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (context.mounted) {
        Helpers.showSuccessMessage(context, 'Wasohokye neza!');
      }
    }
  }
}
