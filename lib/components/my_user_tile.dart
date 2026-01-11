/*

USER LIST TILE
================

*/

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/auth/auth_service.dart';
import 'package:prism/services/chat/chat_service.dart';
import 'package:prism/screens/chat_conversation_screen.dart';
import '../screens/profile_screen.dart';

class MyUserTile extends StatelessWidget {
  final UserProfile user;
  const MyUserTile({
    super.key,
    required this.user,
  });

  Future<void> _startChat(BuildContext context) async {
    final authService = AuthService();
    final chatService = ChatService();
    final currentUserId = authService.getCurrentUid();

    // Don't chat with yourself
    if (user.uid == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can't message yourself!")),
      );
      return;
    }

    try {
      // Create or get existing chat
      final chatId = await chatService.getOrCreateChat(user.uid);

      // Navigate to chat screen
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatConversationScreen(
              otherUser: user,
              chatId: chatId,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  //BUILD UI
  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final currentUserId = authService.getCurrentUid();
    final isCurrentUser = user.uid == currentUserId;

    //container
    return Container(
      //padding outside
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),

      //padding inside
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,

        //curve corner
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        //Name
        title: Text(user.name),
        titleTextStyle:
            TextStyle(color: Theme.of(context).colorScheme.inversePrimary),

        //username
        subtitle: Text('@${user.username}'),
        subtitleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),

        //profile pic
        leading: Icon(
          Icons.person,
          color: Theme.of(context).colorScheme.primary,
        ),

        //on tap
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(
              uid: user.uid,
            ),
          ),
        ),

        //trailing - message button or visit icon
        trailing: isCurrentUser
            ? Icon(CupertinoIcons.arrow_right,
                color: Theme.of(context).colorScheme.primary)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _startChat(context),
                  ),
                  Icon(CupertinoIcons.arrow_right,
                      color: Theme.of(context).colorScheme.primary),
                ],
              ),
      ),
    );
  }
}
