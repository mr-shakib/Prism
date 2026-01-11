import 'package:flutter/material.dart';
import 'package:prism/pages/modern_profile_page.dart';

/* 

PROFILE SCREEN - Redirects to ModernProfilePage

*/

class ProfileScreen extends StatelessWidget {
  //user id
  final String uid;
  const ProfileScreen({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return ModernProfilePage(uid: uid);
  }
}
