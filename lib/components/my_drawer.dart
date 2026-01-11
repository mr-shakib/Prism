import 'package:flutter/material.dart';
import 'package:prism/components/my_drawer_tile.dart';
import 'package:prism/pages/modern_profile_page.dart';

import '../pages/settings_page.dart';
import '../services/auth/auth_service.dart';

/* 

Drawer

This is a menu drawer which is usually access on the lest side of the app

-------------------------------------------------------------------------

Contains 5 menu options:

- Home
- Profile
- Search
- Settings
- Logout

*/

class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});

  //access auth service
  final _auth = AuthService();

  //logout
  void _logout() async {
    _auth.logout();
  }

  //BUILD UI
  @override
  Widget build(BuildContext context) {
    // Drawer
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              // app logo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50.0),
                child: Icon(
                  Icons.person,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              // Divider Lane
              Divider(
                color: Theme.of(context).colorScheme.secondary,
              ),

              const SizedBox(height: 10),

              // home
              MyDrawerTile(
                title: "H O M E",
                icon: Icons.home,
                onTap: () {
                  // pop the menu drawer since we are already on the home
                  Navigator.pop(context);
                },
              ),

              // profile
              MyDrawerTile(
                title: "P R O F I L E",
                icon: Icons.person,
                onTap: () {
                  // pop the menu drawer since we are already on the home
                  Navigator.pop(context);

                  //go to profile
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModernProfilePage(
                        uid: _auth.getCurrentUid(),
                      ),
                    ),
                  );
                },
              ),

              // search
              MyDrawerTile(
                title: "S E A R C H",
                icon: Icons.search,
                onTap: () {
                  // pop the menu drawer since we are already on the home
                  Navigator.pop(context);
                },
              ),

              // settings
              MyDrawerTile(
                title: "S E T T I N G S",
                icon: Icons.settings,
                onTap: () {
                  //pop the menu
                  Navigator.pop(context);

                  //go to  setrtings page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // logout
              MyDrawerTile(
                title: "L O G O U T",
                icon: Icons.logout,
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
