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

class MyCommentTile extends StatefulWidget {
  final Comment comment;
  final void Function()? onUserTap;
  final void Function()? onReplyTap;
  final List<Comment> replies;
  final bool isReply;
  final int depth;

  const MyCommentTile({
    Key? key,
    required this.comment,
    required this.onUserTap,
    required this.onReplyTap,
    this.replies = const [],
    this.isReply = false,
    this.depth = 0,
  }) : super(key: key);

  @override
  State<MyCommentTile> createState() => _MyCommentTileState();
}

class _MyCommentTileState extends State<MyCommentTile> {
  bool _isCollapsed = false;

  void _showOptions(BuildContext context) {
    //check if the comment is owned by the current user
    String currentUid = AuthService().getCurrentUid();
    final bool isOwnComment = widget.comment.uid == currentUid;

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
                      await Get.find<DatabaseProvider>().deleteComment(widget.comment.id, widget.comment.postId);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final indentWidth = widget.depth > 0 ? 12.0 : 0.0;
    final maxDepth = 5; // Maximum nesting level before flattening
    final effectiveDepth = widget.depth > maxDepth ? maxDepth : widget.depth;
    
    return Container(
      margin: EdgeInsets.only(
        left: effectiveDepth * indentWidth,
        top: widget.depth == 0 ? 8 : 0,
        bottom: widget.depth == 0 ? 8 : 0,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thread line indicator for replies
            if (widget.depth > 0)
              Container(
                width: 2,
                margin: EdgeInsets.only(left: 20, right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            
            // Comment content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: widget.onUserTap,
                        child: CircleAvatar(
                          radius: widget.depth == 0 ? 18 : 16,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            widget.comment.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.depth == 0 ? 16 : 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      
                      // Comment body
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username and timestamp row
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: widget.onUserTap,
                                  child: Text(
                                    widget.comment.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: widget.depth == 0 ? 15 : 14,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '• ${_getTimeAgo(widget.comment.timestamp)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            
                            // Comment text
                            Text(
                              widget.comment.message,
                              style: TextStyle(
                                fontSize: widget.depth == 0 ? 15 : 14,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: 6),
                            
                            // Action buttons row
                            Row(
                              children: [
                                // Reply button
                                if (widget.depth < maxDepth)
                                  InkWell(
                                    onTap: widget.onReplyTap,
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.reply_rounded,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Reply',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                
                                // Collapse/Expand button for threads with replies
                                if (widget.replies.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isCollapsed = !_isCollapsed;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _isCollapsed
                                                ? Icons.expand_more
                                                : Icons.expand_less,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            _isCollapsed
                                                ? 'Show ${widget.replies.length} ${widget.replies.length == 1 ? 'reply' : 'replies'}'
                                                : 'Hide',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                
                                Spacer(),
                                
                                // More options button
                                IconButton(
                                  icon: Icon(
                                    Icons.more_horiz,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                  onPressed: () => _showOptions(context),
                                  padding: EdgeInsets.all(4),
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Nested replies with animation
                  if (widget.replies.isNotEmpty && !_isCollapsed)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Column(
                        children: widget.replies.map((reply) {
                          return MyCommentTile(
                            comment: reply,
                            onUserTap: () => goUserPage(context, reply.uid),
                            onReplyTap: widget.onReplyTap,
                            isReply: true,
                            depth: widget.depth + 1,
                          );
                        }).toList(),
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

  String _getTimeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
