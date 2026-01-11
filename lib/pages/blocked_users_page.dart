/*

Blocked Users Page

*/

import 'package:flutter/material.dart';
import 'package:prism/services/database/database_provider.dart';
import 'package:get/get.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  //providers
  late final listeningProvider = Get.find<DatabaseProvider>();
  late final databaseProvider =
      Get.find<DatabaseProvider>();

  //on startup
  @override
  void initState() {
    super.initState();
    loadBlockedUsers();
  }

  //load blocked users
  Future<void> loadBlockedUsers() async {
    await databaseProvider.loadBlockedUsers();
  }

  //show unblock box
  void _showUnblockConfirmationBox(String userId) {
    //show dialog
    showDialog(
      context: context,
      builder: (context) {
        //return unblock box
        return AlertDialog(
          title: const Text("Unblock User"),
          content: const Text("Are you sure you want to unblock this user?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            //unblock button
            TextButton(
              onPressed: () async {
                //unblock user
                await databaseProvider.unblockUser(userId);

                //close box
                Navigator.pop(context);
                //let the user know
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("User Unblocked!"),
                  ),
                );
              },
              child: const Text("Unblock"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //listen to this blocked users

    final blockedUsers = listeningProvider.blockedUsers;
    return Scaffold(
      //appbar
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Blocked Users"),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),

      //body
      body: blockedUsers.isEmpty
          ? const Center(
              child: Text("You haven't blocked any users yet"),
            )
          : ListView.builder(
              itemCount: blockedUsers.length,
              itemBuilder: (context, index) {
                //get each blocked user
                final blockedUser = blockedUsers[index];

                //return as a ListTile UI
                return ListTile(
                  title: Text(blockedUser.name),
                  subtitle: Text("@${blockedUser.username}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.block_rounded),
                    onPressed: () =>
                        _showUnblockConfirmationBox(blockedUser.uid),
                  ),
                );
              },
            ),
    );
  }
}
