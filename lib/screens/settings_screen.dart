import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prism/components/my_settings_tile.dart';
import 'package:prism/themes/theme_provider.dart';
import 'package:provider/provider.dart';

import '../helper/naviagte_pages.dart';
import '../services/auth/auth_service.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  //access auth service
  final _auth = AuthService();

  //logout
  void _logout(BuildContext context) async {
    await _auth.logout();
    // Navigate back to auth gate (login screen)
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dark Mode

            MySettingsTile(
            title: "Dark Mode",
            action: CupertinoSwitch(
              onChanged: (value) => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
              value: Provider.of<ThemeProvider>(context).isDarkMode,
            ),
          ),


          // Blocked Users
          MySettingsTile(
            title: "Blocked Users",
            action: IconButton(
              onPressed: () => goBlockedUsersPage(context),
              icon: Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          
          // Account Settings
          MySettingsTile(
            title: "Account Settings",
            action: IconButton(
              onPressed: () => goAccountSettingsPage(context),
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          //logout
          MySettingsTile(
            title: "L O G O U T",
            icon: Icons.logout,
            onTap: () => _logout(context),
          ),
          ],
        ),
      ),
    );
  }
}
