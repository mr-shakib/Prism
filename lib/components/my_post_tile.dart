import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:prism/components/my_input_alert_box.dart';
import 'package:prism/helper/time_formatter.dart';
import 'package:prism/themes/app_colors.dart';
import 'package:prism/services/cloudinary/cloudinary_service.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../models/user.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
      onLongPress: _showOptions,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Profile info and options
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile picture
                  FutureBuilder<UserProfile?>(
                    future: databaseProvider.userProfile(widget.post.uid),
                    builder: (context, snapshot) {
                      final userProfile = snapshot.data;
                      final cloudinaryService = CloudinaryService();
                      
                      return GestureDetector(
                        onTap: widget.onUserTap,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.purple.shade300, Colors.purple.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                              backgroundImage: userProfile?.profilePictureUrl != null
                                  ? NetworkImage(
                                      cloudinaryService.getOptimizedImageUrl(
                                        userProfile!.profilePictureUrl!,
                                        width: 100,
                                        height: 100,
                                      ),
                                    )
                                  : null,
                              child: userProfile?.profilePictureUrl == null
                                  ? Icon(
                                      Icons.person,
                                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.6),
                                      size: 24,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 12),

                  // Name and username
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onUserTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.name,
                            style: TextStyle(
                              color: isDark ? AppColors.darkText : AppColors.lightText,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${widget.post.username}',
                            style: TextStyle(
                              color: (isDark ? AppColors.darkText : AppColors.lightText)
                                  .withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Timestamp
                  Text(
                    formatTimestamp(widget.post.timestamp),
                    style: TextStyle(
                      color: (isDark ? AppColors.darkText : AppColors.lightText)
                          .withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // More options button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showOptions,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.more_horiz,
                          color: (isDark ? AppColors.darkText : AppColors.lightText)
                              .withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Message/Caption
            if (widget.post.message.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.post.message,
                  style: TextStyle(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),

            if (widget.post.message.trim().isNotEmpty)
              const SizedBox(height: 12),

            // Image if available
            if (widget.post.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      child: Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Video placeholder if available
            if (widget.post.videoUrl != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 64,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam,
                              size: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Like button
                  LikeButton(
                    size: 28,
                    isLiked: likedByCurrentUser,
                    circleColor: const CircleColor(
                      start: Color(0xFFFF6868),
                      end: Color(0xFFFF4D4D),
                    ),
                    bubblesColor: const BubblesColor(
                      dotPrimaryColor: Color(0xFFFF6868),
                      dotSecondaryColor: Color(0xFFFF4D4D),
                    ),
                    likeBuilder: (bool isLiked) {
                      return Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked
                            ? Colors.red
                            : (isDark ? AppColors.darkText : AppColors.lightText)
                                .withOpacity(0.6),
                        size: 28,
                      );
                    },
                    onTap: (bool isLiked) async {
                      _toggleLikedPost();
                      return !isLiked;
                    },
                  ),

                  if (likeCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      likeCount.toString(),
                      style: TextStyle(
                        color: (isDark ? AppColors.darkText : AppColors.lightText)
                            .withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(width: 20),

                  // Comment button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openNewCommentBox,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.mode_comment_outlined,
                          color: (isDark ? AppColors.darkText : AppColors.lightText)
                              .withOpacity(0.6),
                          size: 26,
                        ),
                      ),
                    ),
                  ),

                  if (commentCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      commentCount.toString(),
                      style: TextStyle(
                        color: (isDark ? AppColors.darkText : AppColors.lightText)
                            .withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Share button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share feature coming soon!')),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.share_outlined,
                          color: (isDark ? AppColors.darkText : AppColors.lightText)
                              .withOpacity(0.6),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
