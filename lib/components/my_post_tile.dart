import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:prism/components/my_input_alert_box.dart';
import 'package:prism/helper/time_formatter.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../services/auth/auth_service.dart';
import '../services/database/database_provider.dart';

/*

POST TILE


All post will be displayed using this post tile widget

--------------------------------------------------------
To use this widget , you need:

- the post
- a function for onPostTap ( so to individual post )
- a function for onUserTap( go to user's profile page )
*/

class MyPostTile extends StatefulWidget {
  final Post post;
  final void Function()? onUserTap;
  final void Function()? onPostTap;

  const MyPostTile({
    super.key,
    required this.post,
    required this.onUserTap,
    required this.onPostTap,
  });

  @override
  State<MyPostTile> createState() => _MyPostTileState();
}

class _MyPostTileState extends State<MyPostTile> {
  //providers
  late final listeningProvider =
      Get.find<DatabaseProvider>();
  late final databaseProvider =
      Get.find<DatabaseProvider>();

  //on startup

  @override
  void initState() {
    super.initState();

    //loas=d comments for this post
    _loadComments();
  }

  /*
      
      LIKES
      
  */

  //user tapped liked or unlike
  void _toggleLikedPost() async {
    try {
      await databaseProvider.toggleLike(widget.post.id);
    } catch (e) {
      print(e);
    }
  }

  /*
  
  COMMENTS
  
  */

  //comment text controler
  final _commentController = TextEditingController();

  //open comments box

  void _openNewCommentBox() {
    showDialog(
      context: context,
      builder: (context) => MyInputAlertBox(
        textController: _commentController,
        hintText: "Type a comment...",
        onPressed: () async {
          //post in db
          await _addComment();
        },
        onPressedText: "Comment",
      ),
    );
  }

  //user tapped a post to add a comment
  Future<void> _addComment() async {
    // does nothing if the comment is empty
    if (_commentController.text.trim().isEmpty) return;

    try {
      //add comment in db
      await databaseProvider.addComment(
          widget.post.id, _commentController.text.trim());
    } catch (e) {
      print(e);
    }
  }

  //load comments
  Future<void> _loadComments() async {
    await databaseProvider.loadComments(widget.post.id);
  }

  //show option for the post
  void _showOptions() {
    //check if the post is owned by the current user
    String currentUid = AuthService().getCurrentUid();
    final bool isOwnPost = widget.post.uid == currentUid;

    //show bottom options
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                //THIS POST BELONGS TO THE CURRENT USER
                if (isOwnPost)
                  //delete message button
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text("Delete"),
                    onTap: () async {
                      //pop the option box
                      Navigator.pop(context);

                      //handle delete action
                      await databaseProvider.deletePost(widget.post.id);
                    },
                  )

                //THIS POST DOES NOT BELONG TO THE CURRENT USER
                else ...[
                  //report post button
                  ListTile(
                    leading: const Icon(Icons.report),
                    title: const Text("Report"),
                    onTap: () {
                      //pop the option box
                      Navigator.pop(context);

                      //handle report action
                      _reportPostConfirmationBox();
                    },
                  ),

                  //block user button
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text("Block User"),
                    onTap: () {
                      //pop the option box
                      Navigator.pop(context);

                      //handle block action
                      _blockUserConfirmationBox();
                    },
                  ),
                ],

                //cancel button
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text("Cancel"),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  //report post confirmation box
  void _reportPostConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Report Post"),
        content: Text("Are you sure you want to report this post?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await databaseProvider.reportUser(
                  widget.post.id, widget.post.uid);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Post Reported"),
                ),
              );
            },
            child: const Text("Report"),
          ),
        ],
      ),
    );
  }

  //block user confirmation box
  void _blockUserConfirmationBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Block User"),
        content: Text("Are you sure you want to block this user?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await databaseProvider.blockUser(widget.post.uid);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("User Blocked!"),
                ),
              );
            },
            child: const Text("Block"),
          ),
        ],
      ),
    );
  }

  //BUILD UI
  @override
  Widget build(BuildContext context) {
    //does the current user liked the post
    bool likedByCurrentUser =
        listeningProvider.isPostLikedByCurrentUser(widget.post.id);

    //listen to like count
    int likeCount = listeningProvider.getLikeCount(widget.post.id);

    //listen to comment count
    int commentCount = listeningProvider.getComments(widget.post.id).length;

    //container
    return GestureDetector(
      onTap: widget.onPostTap,
      onDoubleTap: _toggleLikedPost,
      onLongPress: () {
        _showOptions();
      },
      child: Container(
        //padding outside
        margin: const EdgeInsets.symmetric(vertical: 5),

        //padding inside
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          //color of the post tile
          color: Theme.of(context).colorScheme.secondary,

          //curve corner
          borderRadius: BorderRadius.circular(12),

          // Add border
          // border: Border.all(
          //   color: Theme.of(context)
          //       .colorScheme
          //       .secondary
          //       .withOpacity(0.5), // Adjust color as needed
          //   width: 1.0, // Adjust width as needed
          // ),
        ),

        //column
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Top section : profile picture, name, username
            GestureDetector(
              onTap: widget.onUserTap,
              child: Row(
                children: [
                  //profile picture
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),

                  const SizedBox(width: 20),

                  //name
                  Text(
                    widget.post.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 5),

                  //username handle
                  Text(
                    '@${widget.post.username}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  const Spacer(),

                  //button -> more options: delete

                  GestureDetector(
                    onTap: _showOptions,
                    child: Icon(
                      Icons.more_horiz,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            //message
            Text(
              widget.post.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),

            const SizedBox(height: 20),

            //buttons -> like, comment, share
            Row(
              children: [
                //LIKE SECTION

                Row(
                  children: [
                    //like button
                    LikeButton(
                      size: 40.0,
                      isLiked: likedByCurrentUser,
                      likeBuilder: (bool isLiked) {
                        return Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? Colors.red
                              : Theme.of(context).colorScheme.primary,
                          size: 30.0,
                        );
                      },
                      onTap: (bool isLiked) async {
                        _toggleLikedPost(); 
                        return !isLiked;
                      },
                    ),

                    //like count
                    const SizedBox(width: 10),
                    Text(
                      likeCount != 0 ? likeCount.toString() : '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 60),

                //COMMENT SECTION
                Row(
                  children: [
                    //comment button
                    GestureDetector(
                      onTap: _openNewCommentBox,
                      child: Icon(
                        Icons.comment,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),

                    const SizedBox(width: 10),

                    //comment count
                    Text(
                      commentCount != 0 ? commentCount.toString() : '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                //timestamp
                Text(
                  formatTimestamp(widget.post.timestamp),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
