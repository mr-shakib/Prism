/*

COMMENT TILE

To use this widget, you need:

- comment
- a function ( e.g. PostMessages() )
- text for button ( e.g. "Save" )

*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helper/naviagte_pages.dart';
import '../models/comment.dart';
import '../services/auth/auth_service.dart';
import '../services/database/database_provider.dart';

class MyCommentTile extends StatelessWidget {
  final Comment comment;
  final void Function()? onUserTap;
  final void Function()? onReplyTap;
  final List<Comment> replies;
  final bool isReply;

  const MyCommentTile({
    Key? key,
    required this.comment,
    required this.onUserTap,
    required this.onReplyTap,
    this.replies = const [],
    this.isReply = false,
  }) : super(key: key);

  void _showOptions(BuildContext context) {
    //check if the comment is owned by the current user
    String currentUid = AuthService().getCurrentUid();
    final bool isOwnComment = comment.uid == currentUid;

    //show bottom options
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                //THIS COMMENT BELONGS TO THE CURRENT USER
                if (isOwnComment)
                  //delete comment button
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text("Delete"),
                    onTap: () async {
                      //pop the option box
                      Navigator.pop(context);

                      //handle delete action
                      await Get.find<DatabaseProvider>().deleteComment(comment.id, comment.postId);
                    },
                  )

                //THIS COMMENT DOES NOT BELONG TO THE CURRENT USER
                else ...[
                  //report Comment button
                  ListTile(
                    leading: const Icon(Icons.report),
                    title: const Text("Report"),
                    onTap: () {
                      //pop the option box
                      Navigator.pop(context);

                      //handle report action
                      //TODO: report message
                    },
                  ),

                  //block user button
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text("Block User"),
                    onTap: () {
                      //pop the option box
                      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: isReply ? 40 : 0,
        right: 0,
        top: 5,
        bottom: 5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              comment.name[0].toUpperCase(),
              style: TextStyle(color: Colors.white),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: onUserTap,
                        child: Text(
                          comment.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        comment.message,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getTimeAgo(comment.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReplyTap,
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (replies.isNotEmpty) ...[
                  SizedBox(height: 8),
                  ...replies.map((reply) => MyCommentTile(
                        comment: reply,
                        onUserTap: () => goUserPage(context, reply.uid),
                        onReplyTap: onReplyTap,
                        isReply: true,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }
}
