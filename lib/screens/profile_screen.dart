import 'package:flutter/material.dart';
import 'package:prism/components/my_bio_box.dart';
import 'package:prism/components/my_input_alert_box.dart';
import 'package:prism/components/my_profile_stats.dart';
import 'package:prism/helper/naviagte_pages.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/auth/auth_service.dart';
import 'package:get/get.dart';
import '../components/my_follow_button.dart';
import '../components/my_post_tile.dart';
import '../pages/follow_list_page.dart';
import '../services/database/database_provider.dart';


/* 

PROFILE  PAGE

*/

class ProfileScreen extends StatefulWidget {
  //user id
  final String uid;
  const ProfileScreen({
    super.key,
    required this.uid,
  });

  @override
  State<ProfileScreen> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfileScreen> {
  //provider
  late final listeningProvider = Get.find<DatabaseProvider>();
  late final databaseProvider = Get.find<DatabaseProvider>();

  //user info
  UserProfile? user;
  String currentUserId = AuthService().getCurrentUid();

  //text controller for bio
  final bioTextController = TextEditingController();

  //loading..
  bool _isLoading = true;

  //is following
  bool _isFollowing = false;

  //on startup
  @override
  void initState() {
    super.initState();

    //get user info
    loadUser();
  }

  Future<void> loadUser() async {
    //get the user profile info
    user = await databaseProvider.userProfile(widget.uid);

    //load followers and following
    await databaseProvider.loadFollowers(widget.uid);
    await databaseProvider.loadFollowing(widget.uid);

    //update following state
    _isFollowing = databaseProvider.isFollowing(widget.uid);

    //finished loading
    setState(() {
      _isLoading = false;
    });
  }

  //show edit bio box
  void _showEditBioBox() {
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: bioTextController,
        hintText: "Edit bio...",
        onPressed: saveBio,
        onPressedText: "Save",
      ),
    );
  }

  //save the updated bio
  Future<void> saveBio() async {
    //start loading
    setState(() {
      _isLoading = true;
    });

    //update the boi
    await databaseProvider.updateBio(bioTextController.text);

    //reload user
    await loadUser();

    //finish loading

    setState(() {
      _isLoading = false;
    });
  }

  //toggle follow
  Future<void> toggleFollow() async {
    if (_isFollowing) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Unfollow"),
          content: const Text("Are you sure you want to unfollow?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await databaseProvider.unfollowUser(widget.uid);
                },
                child: const Text("Yes"))
          ],
        ),
      );
    } else {
      await databaseProvider.followUser(widget.uid);
    }

    //updat isFollowing state

    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  //BUILD UI
  @override
  Widget build(BuildContext context) {
    // if (_isLoading || user == null) {
    //   return Center(
    //     child: CircularProgressIndicator(),
    //   );
    // }
    //get user post
    final allUserPost = listeningProvider.filterUserPosts(widget.uid);
    bool isOwnProfile = widget.uid == currentUserId;

    //listen to is following status
    _isFollowing = listeningProvider.isFollowing(widget.uid);

    //listen to followers and and folloer count
    final followerCount = listeningProvider.getFollowersCount(widget.uid);
    final followingCount = listeningProvider.getFollowingCount(widget.uid);

    //SCAFOLD
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: isOwnProfile
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => goHomePage(context),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
            ),

      //body
      body: ListView(
        children: [
          const SizedBox(height: 25),

          //profile picture
          Stack(
            children: [
              CircleAvatar(
                radius: 70,
                backgroundImage: NetworkImage('https://static.vecteezy.com/system/resources/previews/036/594/092/non_2x/man-empty-avatar-photo-placeholder-for-social-networks-resumes-forums-and-dating-sites-male-and-female-no-photo-images-for-unfilled-user-profile-free-vector.jpg'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.add_a_photo),
                  onPressed: () {},
                ),

              )
            ],
          ),

          Center(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Colors.purple,
                  Colors.blue
                ], // Define your gradient colors
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                _isLoading ? '' : user!.name,
                style: const TextStyle(
                  color: Colors
                      .white, // The color won't matter as the shader will override it
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          //username handle
          Center(
            child: Text(
              _isLoading ? '' : '@${user!.username}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),

          const SizedBox(height: 25),

          //profile stats -> number of post/ followers/following
          MyProfileStats(
            postCount: allUserPost.length,
            followerCount: followerCount,
            followingCount: followingCount,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FollowListPage(
                  uid: widget.uid,
                ),
              ),
            ),
          ),

          //follow/unfollow button
          //only show if i visit someone else's profile
          if (user != null && user!.uid != currentUserId)
            MyFollowButton(
              onPressed: toggleFollow,
              isFollowing: _isFollowing,
            ),

          //edit bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Text
                Text(
                  "Bio",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                //Button
                if (user != null && user!.uid == currentUserId)
                  GestureDetector(
                    onTap: _showEditBioBox,
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          //bio box
          MyBioBox(text: _isLoading ? '...' : user!.bio),

          Padding(
            padding: const EdgeInsets.only(left: 25.03, top: 20),
            child: Text(
              "Posts",
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),

          //list of post from user
          allUserPost.isEmpty
              ?

              //user post is empty
              const Center(
                  child: Text("Nothing Here..."),
                )
              :

              //not empty
              ListView.builder(
                  itemCount: allUserPost.length,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    //get each post
                    final post = allUserPost[index];

                    //return post tile UI
                    return MyPostTile(
                      post: post,
                      onUserTap: () {},
                      onPostTap: () => goPostPage(context, post),
                    );
                  },
                )
        ],
      ),
    );
  }
}
