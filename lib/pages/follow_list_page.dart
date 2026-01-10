/*

FOLLOWLIST

*/

import 'package:flutter/material.dart';
import 'package:prism/components/my_user_tile.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/database/database_provider.dart';
import 'package:get/get.dart';

class FollowListPage extends StatefulWidget {
  final String uid;
  const FollowListPage({
    super.key,
    required this.uid,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  late DatabaseProvider databaseProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize provider here
    databaseProvider = Get.find<DatabaseProvider>();

    // Load followers and following after dependencies are ready
    loadFollowerList();
    loadFollowingList();
  }

  Future<void> loadFollowerList() async {
    await databaseProvider.loadUserFollowersProfile(widget.uid);
  }

  Future<void> loadFollowingList() async {
    await databaseProvider.loadUserFollowingProfile(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    final followers = databaseProvider.getListOfFollowersProfile(widget.uid);
    final following = databaseProvider.getListOfFollowingProfile(widget.uid);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          foregroundColor: Theme.of(context).colorScheme.primary,
          bottom: TabBar(
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.inversePrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: "Followers"),
              Tab(text: "Following"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(followers, "No followers yet!"),
            _buildUserList(following, "You haven't followed anyone yet!"),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserProfile> userList, String emptyMessage) {
    return userList.isEmpty
        ? Center(child: Text(emptyMessage))
        : ListView.builder(
            itemCount: userList.length,
            itemBuilder: (context, index) {
              final user = userList[index];
              return MyUserTile(user: user);
            },
          );
  }
}
