import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:prism/components/my_input_alert_box.dart';
import 'package:prism/components/my_post_tile.dart';
import 'package:prism/helper/naviagte_pages.dart';
import 'package:prism/screens/profile_screen.dart';
import 'package:prism/screens/search_screen.dart';
import 'package:prism/screens/settings_screen.dart';
import '../models/post.dart';
import 'package:prism/screens/home_screen.dart';
import '../services/auth/auth_service.dart';
import '../services/database/database_provider.dart';

/*

HOME PAGE

This is the home page of the app. It displays list of all the posts

*/

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    final controller = Get.put(NavigationController());
    //access auth service
    

    //SCAFOLD
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // drawer: MyDrawer(),

      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) =>
              controller.selectedIndex.value = index,
          destinations: [
            Container(
              child: const NavigationDestination(
                  icon: Icon(Icons.home), label: 'Home'),
            ),
            Container(
              child: const NavigationDestination(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
            ),
            Container(
              child: const NavigationDestination(
                icon: const Icon(Icons.settings),
                label: 'Settings',
              ),
            ),
            Container(
              child: const NavigationDestination(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ),
          ],
        ),
      ),

      //App Bar
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Colors.purple,
              Colors.blue
            ], // Define your gradient colors here
            tileMode: TileMode.mirror,
          ).createShader(bounds),
          child: const Text(
            "P R I S M",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors
                  .white, // The text color will be replaced by the gradient
            ),
          ),
        ),
        backgroundColor: Colors
            .transparent, // Set transparent background to see the gradient effect
        elevation: 0, // Optional: remove shadow
        centerTitle: true,
      ),

      //Floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: _openPostMessageBox,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),

      //body
      // body: _buildPostList(listeningProvider.allPosts),

      body: Obx(() {
        final screens = controller.getScreens(context);
        return screens[controller.selectedIndex.value];
      }),
    );
  }

  //build list UI give a list of posts
  Widget _buildPostList(List<Post> posts) {
    return posts.isEmpty
        ?
        //if post list is empty
        const Center(child: Text("Nothing Here..."))
        :
        //if post ;ist is not empty
        ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              //get each post
              final post = posts[index];

              //return post tile UI
              return MyPostTile(
                post: post,
                onUserTap: () => goUserPage(context, post.uid),
                onPostTap: () => goPostPage(context, post),
              );
            });
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;
  final AuthService _auth = AuthService();

  // Create screens getter instead of constructor initialization
  List<Widget> getScreens(BuildContext context) {
    return [
      const HomeScreen(),
      const SearchScreen(),
      SettingsScreen(),
      ProfileScreen(
        uid: _auth.getCurrentUid(),
      ),
    ];
  }
}
