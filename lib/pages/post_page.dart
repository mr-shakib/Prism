import 'package:flutter/material.dart';
import 'package:prism/components/my_comment_tile.dart';
import 'package:prism/components/my_post_tile.dart';
import 'package:prism/helper/naviagte_pages.dart';
import 'package:prism/themes/app_colors.dart';
import 'package:get/get.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../services/auth/auth_service.dart';
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

class _PostPageState extends State<PostPage> with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToCommentId;
  String? _replyingToUsername;
  bool _isSubmitting = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Get.find<DatabaseProvider>()
        .loadCommentsAndReplies(widget.post.id);
    
    // Listen to text changes to update UI
    _commentController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showReplyInput(String parentCommentId, String username) {
    setState(() {
      _replyingToCommentId = parentCommentId;
      _replyingToUsername = username;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
    _commentController.clear();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.isEmpty || _isSubmitting) return;
    
    final commentText = _commentController.text.trim();
    
    // Clear input and state immediately for responsive feel
    _commentController.clear();
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isSubmitting = true;
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
    
    try {
      if (_replyingToCommentId != null) {
        await Get.find<DatabaseProvider>().addCommentReply(
          widget.post.id,
          _replyingToCommentId!,
          commentText,
        );
      } else {
        await Get.find<DatabaseProvider>().addComment(
          widget.post.id,
          commentText,
        );
      }
      
      // Scroll to top to show new comment
      if (_scrollController.hasClients) {
        await Future.delayed(const Duration(milliseconds: 100));
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      
      // Play success animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildCommentInput(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply indicator
            if (_replyingToCommentId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replying to @$_replyingToUsername',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: (isDark ? AppColors.darkText : AppColors.lightText)
                            .withOpacity(0.6),
                      ),
                      onPressed: _cancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            
            // Input field
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _commentController,
                        focusNode: _focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? 'Write a reply...'
                              : 'Add a comment...',
                          hintStyle: TextStyle(
                            color: (isDark ? AppColors.darkText : AppColors.lightText)
                                .withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSubmitting
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.purple),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: _commentController.text.trim().isEmpty
                                ? (isDark ? Colors.white : Colors.black).withOpacity(0.3)
                                : Colors.purple,
                          ),
                          onPressed: _commentController.text.trim().isEmpty
                              ? null
                              : _submitComment,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Comments',
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Scrollable content (post + comments)
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: Get.find<DatabaseProvider>().getCommentsStream(widget.post.id),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.purple,
                    ),
                  );
                }

                // Error state
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load comments',
                          style: TextStyle(
                            fontSize: 16,
                            color: (isDark ? AppColors.darkText : AppColors.lightText)
                                .withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allComments = snapshot.data ?? [];

                // Group comments by parent
                Map<String, List<Comment>> groupedComments = {};
                for (var comment in allComments) {
                  if (comment.parentCommentId == null) {
                    groupedComments[comment.id] = [comment];
                  } else {
                    groupedComments[comment.parentCommentId]?.add(comment);
                  }
                }

                // Get only parent comments
                final parentComments = allComments
                    .where((c) => c.parentCommentId == null)
                    .toList()
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return RefreshIndicator(
                  onRefresh: () async {
                    // Stream automatically refreshes, but we can manually trigger
                    await Future.delayed(const Duration(milliseconds: 300));
                  },
                  color: Colors.purple,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      // Post at the top
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            MyPostTile(
                              post: widget.post,
                              onUserTap: () => goUserPage(context, widget.post.uid),
                              onPostTap: () {},
                            ),
                            Container(
                              height: 8,
                              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                            ),
                          ],
                        ),
                      ),

                      // Comments header
                      if (parentComments.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Text(
                                  '${parentComments.length} ${parentComments.length == 1 ? 'Comment' : 'Comments'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkText : AppColors.lightText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Comments list or empty state
                      if (parentComments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 60,
                                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: (isDark ? AppColors.darkText : AppColors.lightText)
                                        .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Be the first to comment!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: (isDark ? AppColors.darkText : AppColors.lightText)
                                        .withOpacity(0.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              Comment parentComment = parentComments[index];
                              List<Comment> replies = groupedComments[parentComment.id]
                                      ?.skip(1)
                                      .toList() ??
                                  [];
                              
                              return AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: MyCommentTile(
                                  comment: parentComment,
                                  onUserTap: () => goUserPage(context, parentComment.uid),
                                  onReplyTap: () => _showReplyInput(
                                    parentComment.id,
                                    parentComment.username,
                                  ),
                                  replies: replies,
                                ),
                              );
                            },
                            childCount: parentComments.length,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Comment input (fixed at bottom)
          _buildCommentInput(isDark),
        ],
      ),
    );
  }
}
