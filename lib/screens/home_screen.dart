import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:prism/components/my_input_alert_box.dart';
import 'package:prism/components/my_post_tile.dart';
import 'package:prism/components/my_follow_button.dart';
import 'package:prism/helper/naviagte_pages.dart';
import 'package:prism/services/auth/auth_service.dart';
import 'package:shimmer/shimmer.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/database/database_provider.dart';

/*

HOME PAGE

This is the home page of the app. It displays list of all the posts

*/

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  //auth service
  final _auth = AuthService();

  //text controller
  final _messageController = TextEditingController();

  //on startup
  @override
  void initState() {
    super.initState();

    //get posts
    loadAllPosts();
  }

  //load all posts
  Future<void> loadAllPosts() async {
    final databaseProvider = Get.find<DatabaseProvider>();
    await databaseProvider.loadAllPosts();
  }

  //handle refresh
  Future<void> _handleRefresh() async {
    await loadAllPosts();
    return await Future.delayed(Duration(seconds: 1));
  }

  //show post message box
  void _openPostMessageBox() {
    final databaseProvider = Get.find<DatabaseProvider>();
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: _messageController,
        hintText: "What's on your mind?",
        onPressed: () async {
          //post in db
          await postMessage(_messageController.text);
        },
        onPressedText: "Post",
      ),
    );
  }

  //user wants to post a message
  Future<void> postMessage(String message) async {
    final databaseProvider = Get.find<DatabaseProvider>();
    await databaseProvider.postMessage(message);
  }

  //BUILD UI
  @override
  Widget build(BuildContext context) {
    final listeningProvider = Get.find<DatabaseProvider>();
    
    // TAB CONTROLLER
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,

        // Body
        body: LiquidPullToRefresh(
          onRefresh: _handleRefresh,
          color: Colors.deepPurple,
          height: 300,
          backgroundColor: Colors.deepPurple[200],
          animSpeedFactor: 2,
          child: Column(
            children: [
              // TabBar
              PreferredSize(
                preferredSize:
                    Size.fromHeight(50.0), // Adjust the height as needed
                child: TabBar(
                  dividerColor: Colors.transparent,
                  labelColor: Theme.of(context).colorScheme.inversePrimary,
                  unselectedLabelColor: Theme.of(context).colorScheme.primary,
                  indicatorColor: Colors.deepPurple,
                  tabs: const [
                    Tab(text: "For You"),
                    Tab(text: "Following"),
                  ],
                ),
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  children: [
                    // For You tab - all posts
                    _buildPostList(
                      listeningProvider.allPosts,
                      isFollowingTab: false,
                    ),
                    // Following tab - posts from followed users or suggestions
                    _buildFollowingTabContent(listeningProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //build list UI give a list of posts

  // Build Following tab content - shows posts or suggestions based on following count
  Widget _buildFollowingTabContent(DatabaseProvider databaseProvider) {
    final currentUserId = _auth.currentUser!.uid;
    final followingCount = databaseProvider.getFollowingCount(currentUserId);
    
    // If not following anyone, show suggestions
    if (followingCount == 0) {
      return _buildSuggestedUsersList();
    }
    
    // If following people, show their posts
    return _buildPostList(
      databaseProvider.followingPosts,
      isFollowingTab: true,
    );
  }

// Your build post list function
  Widget _buildPostList(List<Post> posts, {required bool isFollowingTab}) {
    if (posts.isEmpty) {
      // For "Following" tab when user follows people but posts haven't loaded yet
      if (isFollowingTab) {
        return ListView.builder(
          itemCount: 5,
          itemBuilder: (context, index) => _buildShimmerPlaceholder(),
        );
      }
      
      // For "For You" tab - check if user is new (not following anyone)
      final databaseProvider = Get.find<DatabaseProvider>();
      final currentUser = _auth.currentUser!.uid;
      
      return FutureBuilder<int>(
        future: Future.value(databaseProvider.getFollowingCount(currentUser)),
        builder: (context, snapshot) {
          // While loading following count, show shimmer
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 15,
              itemBuilder: (context, index) => _buildShimmerPlaceholder(),
            );
          }
          
          // If new user (following count = 0), show suggested users
          if (snapshot.hasData && snapshot.data == 0) {
            return _buildSuggestedUsersList();
          }
          
          // Otherwise show shimmer (loading posts)
          return ListView.builder(
            itemCount: 15,
            itemBuilder: (context, index) => _buildShimmerPlaceholder(),
          );
        },
      );
    }
    
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return MyPostTile(
          post: post,
          onUserTap: () => goUserPage(context, post.uid),
          onPostTap: () => goPostPage(context, post),
        );
      },
    );
  }

// Shimmer placeholder
  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.primary,
      highlightColor: Theme.of(context).colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular avatar
                Container(
                  width: 50.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10.0),
                // Name and time placeholder
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 10.0,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            // Post content placeholder
            Container(
              width: double.infinity,
              height: 100.0,
              color: Colors.white,
            ),
            const SizedBox(height: 10.0),
            // Like, comment, share placeholders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50.0,
                  height: 10.0,
                  color: Colors.white,
                ),
                Container(
                  width: 50.0,
                  height: 10.0,
                  color: Colors.white,
                ),
                Container(
                  width: 50.0,
                  height: 10.0,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build suggested users list for new users
  Widget _buildSuggestedUsersList() {
    final databaseProvider = Get.find<DatabaseProvider>();
    
    return FutureBuilder(
      future: databaseProvider.loadSuggestedUsers(),
      builder: (context, snapshot) {
        // Show loading while fetching
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final suggestedUsers = databaseProvider.suggestedUsers;
        
        if (suggestedUsers.isEmpty) {
          return const Center(
            child: Text("No suggested users available"),
          );
        }
        
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Header
            Text(
              "Suggested Users to Follow",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Start building your feed by following these users",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            
            // User cards
            ...suggestedUsers.map((user) => _buildSuggestedUserCard(user)),
          ],
        );
      },
    );
  }

  // Build individual user suggestion card
  Widget _buildSuggestedUserCard(UserProfile user) {
    final databaseProvider = Get.find<DatabaseProvider>();
    final isFollowing = databaseProvider.isFollowing(user.uid);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          child: Icon(Icons.person, size: 30),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("@${user.username}"),
            if (user.bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  user.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        trailing: MyFollowButton(
          onPressed: () async {
            if (isFollowing) {
              await databaseProvider.unfollowUser(user.uid);
            } else {
              await databaseProvider.followUser(user.uid);
            }
            // Force rebuild to update UI
            setState(() {});
          },
          isFollowing: isFollowing,
        ),
        onTap: () => goUserPage(context, user.uid),
      ),
    );
  }
}
