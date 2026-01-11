import 'package:flutter/material.dart';
import 'package:prism/pages/modern_profile_page.dart';

/* 

PROFILE PAGE - Redirects to ModernProfilePage

*/

class ProfilePage extends StatelessWidget {
  //user id
  final String uid;
  const ProfilePage({
    super.key,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return ModernProfilePage(uid: uid);
  }
}
