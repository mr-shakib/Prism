import 'package:flutter/material.dart';
import 'package:prism/components/my_bio_box.dart';
import 'package:prism/components/my_input_alert_box.dart';
import 'package:prism/helper/naviagte_pages.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/auth/auth_service.dart';
import 'package:get/get.dart';

import '../components/my_post_tile.dart';
import '../services/database/database_provider.dart';

/* 

PROFILE  PAGE

*/

class ProfilePage extends StatefulWidget {
  //user id
  final String uid;
  const ProfilePage({
    super.key,
    required this.uid,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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

  //BUILD UI
  @override
  Widget build(BuildContext context) {
    //get user post
    final allUserPost = listeningProvider.filterUserPosts(widget.uid);

    //SCAFOLD
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      //App BAr
      appBar: AppBar(
        title: Text(_isLoading ? '' : user!.name),
        centerTitle: true,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),

      //body
      body: ListView(
        children: [
          //username handle
          Center(
            child: Text(
              _isLoading ? '' : '@${user!.username}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),

          SizedBox(height: 25),

          //profile picture
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: EdgeInsets.all(25),
              child: Icon(
                Icons.person,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          SizedBox(height: 25),

          //profile stats -> number of post/ folloers/following

          //follow/unfollow button

          //edit bio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Bio",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
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
