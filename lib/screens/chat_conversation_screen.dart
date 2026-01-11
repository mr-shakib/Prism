import 'package:flutter/material.dart';
import 'package:prism/models/message.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/auth/auth_service.dart';
import 'package:prism/services/chat/chat_service.dart';
import 'package:prism/services/cloudinary/cloudinary_service.dart';
import 'package:prism/themes/app_colors.dart';
import 'package:intl/intl.dart';

class ChatConversationScreen extends StatefulWidget {
  final UserProfile otherUser;
  final String chatId;

  const ChatConversationScreen({
    super.key,
    required this.otherUser,
    required this.chatId,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final message = _messageController.text.trim();
    if (message.isEmpty && imageUrl == null) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        receiverId: widget.otherUser.uid,
        message: message.isEmpty ? '📷 Photo' : message,
        imageUrl: imageUrl,
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final imageFile = await _cloudinaryService.pickImageFromGallery();
      if (imageFile == null) return;

      setState(() => _isSending = true);

      final chatImageId = 'chat_${widget.chatId}_${DateTime.now().millisecondsSinceEpoch}';
      final imageUrl = await _cloudinaryService.uploadPostImage(
        imageFile,
        chatImageId,
      );
      await _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = _authService.getCurrentUid();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purple.shade300, Colors.purple.shade400],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  backgroundImage: widget.otherUser.profilePictureUrl != null
                      ? NetworkImage(widget.otherUser.profilePictureUrl!)
                      : null,
                  child: widget.otherUser.profilePictureUrl == null
                      ? Icon(
                          Icons.person,
                          size: 18,
                          color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  Text(
                    '@${widget.otherUser.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: (isDark ? AppColors.darkText : AppColors.lightText)
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _chatService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.waving_hand,
                          size: 60,
                          color: (isDark ? Colors.white : Colors.black)
                              .withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Say Hi! 👋',
                          style: TextStyle(
                            fontSize: 18,
                            color: (isDark ? AppColors.darkText : AppColors.lightText)
                                .withOpacity(0.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message.senderId == currentUserId;
                    final showDateHeader = _shouldShowDateHeader(messages, index);

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(
                          DateTime.fromMillisecondsSinceEpoch(
                            message.timestamp.millisecondsSinceEpoch,
                          ),
                          isDark,
                        ),
                        _buildMessageBubble(message, isSender, isDark),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  bool _shouldShowDateHeader(List<Message> messages, int index) {
    if (index == messages.length - 1) return true;

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    final currentDate = DateTime.fromMillisecondsSinceEpoch(
      currentMessage.timestamp.millisecondsSinceEpoch,
    );
    final nextDate = DateTime.fromMillisecondsSinceEpoch(
      nextMessage.timestamp.millisecondsSinceEpoch,
    );

    return currentDate.day != nextDate.day ||
        currentDate.month != nextDate.month ||
        currentDate.year != nextDate.year;
  }

  Widget _buildDateHeader(DateTime timestamp, bool isDark) {
    final now = DateTime.now();
    final messageDate = DateTime.fromMillisecondsSinceEpoch(
      timestamp.millisecondsSinceEpoch,
    );

    String dateText;
    if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day) {
      dateText = 'Today';
    } else if (messageDate.year == now.year &&
        messageDate.month == now.month &&
        messageDate.day == now.day - 1) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM d, yyyy').format(messageDate);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        dateText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: (isDark ? AppColors.darkText : AppColors.lightText).withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isSender, bool isDark) {
    final time = DateFormat('h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(
        message.timestamp.millisecondsSinceEpoch,
      ),
    );

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: 200,
                      color: (isDark ? Colors.white : Colors.black)
                          .withOpacity(0.05),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            if (message.imageUrl != null && message.message != '📷 Photo')
              const SizedBox(height: 4),
            if (message.message != '📷 Photo')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSender
                      ? LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.purple.shade500,
                          ],
                        )
                      : null,
                  color: !isSender
                      ? (isDark ? AppColors.darkCard : Colors.grey.shade200)
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSender ? 16 : 4),
                    bottomRight: Radius.circular(isSender ? 4 : 16),
                  ),
                ),
                child: Text(
                  message.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSender
                        ? Colors.white
                        : (isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: (isDark ? AppColors.darkText : AppColors.lightText)
                        .withOpacity(0.4),
                  ),
                ),
                if (isSender) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? Colors.purple
                        : (isDark ? AppColors.darkText : AppColors.lightText)
                            .withOpacity(0.4),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            IconButton(
              onPressed: _isSending ? null : _pickAndSendImage,
              icon: Icon(
                Icons.image_outlined,
                color: _isSending
                    ? (isDark ? Colors.white : Colors.black).withOpacity(0.3)
                    : Colors.purple,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  enabled: !_isSending,
                  style: TextStyle(
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(
                      color: (isDark ? AppColors.darkText : AppColors.lightText)
                          .withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(
                      Icons.send,
                      color: _messageController.text.trim().isEmpty
                          ? (isDark ? Colors.white : Colors.black).withOpacity(0.3)
                          : Colors.purple,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
