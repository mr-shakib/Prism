import 'package:flutter/material.dart';
import 'package:prism/components/my_comment_tile.dart';
import 'package:prism/components/my_post_tile.dart';
import 'package:prism/helper/naviagte_pages.dart';
import 'package:get/get.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../services/database/database_provider.dart';

/*

POST PAGE

This page displays:

- individual post
- comments on this post

*/
class PostPage extends StatefulWidget {
  final Post post;
  const PostPage({Key? key, required this.post}) : super(key: key);

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _commentController = TextEditingController();
  String? _replyingToCommentId;

  @override
  void initState() {
    super.initState();
    Get.find<DatabaseProvider>()
        .loadCommentsAndReplies(widget.post.id);
  }

  void _showReplyInput(String parentCommentId) {
    setState(() {
      _replyingToCommentId = parentCommentId;
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isNotEmpty) {
      if (_replyingToCommentId != null) {
        await Get.find<DatabaseProvider>()
            .addCommentReply(
          widget.post.id,
          _replyingToCommentId!,
          _commentController.text,
        );
      } else {
        await Get.find<DatabaseProvider>()
            .addComment(widget.post.id, _commentController.text);
      }
      _commentController.clear();
      setState(() {
        _replyingToCommentId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allComments = Get.find<DatabaseProvider>()
        .getCommentsAndReplies(widget.post.id);

    Map<String, List<Comment>> groupedComments = {};
    for (var comment in allComments) {
      if (comment.parentCommentId == null) {
        groupedComments[comment.id] = [comment];
      } else {
        groupedComments[comment.parentCommentId]?.add(comment);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Post'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                MyPostTile(
                  post: widget.post,
                  onUserTap: () => goUserPage(context, widget.post.uid),
                  onPostTap: () {},
                ),
                Divider(),
                ...groupedComments.entries.map((entry) {
                  Comment parentComment = entry.value.first;
                  List<Comment> replies = entry.value.skip(1).toList();
                  return MyCommentTile(
                    comment: parentComment,
                    onUserTap: () => goUserPage(context, parentComment.uid),
                    onReplyTap: () => _showReplyInput(parentComment.id),
                    replies: replies,
                  );
                }).toList(),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _replyingToCommentId != null
                          ? 'Write a reply...'
                          : 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _submitComment,
                  color: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
