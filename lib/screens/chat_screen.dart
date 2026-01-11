import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:prism/models/chat.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/auth/auth_service.dart';
import 'package:prism/services/chat/chat_service.dart';
import 'package:prism/services/database/database_provider.dart';
import 'package:prism/themes/app_colors.dart';
import 'package:prism/helper/time_formatter.dart';
import 'package:prism/screens/chat_conversation_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = _authService.getCurrentUid();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: StreamBuilder<List<Chat>>(
        stream: _chatService.getUserChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: (isDark ? AppColors.darkText : AppColors.lightText)
                          .withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting with your friends!',
                    style: TextStyle(
                      fontSize: 14,
                      color: (isDark ? AppColors.darkText : AppColors.lightText)
                          .withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.participants
                  .firstWhere((id) => id != currentUserId);

              return FutureBuilder<UserProfile?>(
                future: Get.find<DatabaseProvider>().userProfile(otherUserId),
                builder: (context, userSnapshot) {
                  final otherUser = userSnapshot.data;
                  final unreadCount = chat.unreadCount[currentUserId] ?? 0;
                  final isUnread = unreadCount > 0;

                  return _buildChatTile(
                    context,
                    chat,
                    otherUser,
                    currentUserId,
                    isUnread,
                    unreadCount,
                    isDark,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    Chat chat,
    UserProfile? otherUser,
    String currentUserId,
    bool isUnread,
    int unreadCount,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatConversationScreen(
                otherUser: otherUser!,
                chatId: chat.id,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Profile picture
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade300, Colors.blue.shade300],
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                    backgroundImage: otherUser?.profilePictureUrl != null
                        ? NetworkImage(otherUser!.profilePictureUrl!)
                        : null,
                    child: otherUser?.profilePictureUrl == null
                        ? Icon(
                            Icons.person,
                            size: 28,
                            color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser?.name ?? 'User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                        color: (isDark ? AppColors.darkText : AppColors.lightText)
                            .withOpacity(isUnread ? 0.8 : 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Timestamp and unread badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatTimestamp(chat.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnread
                          ? Colors.blue
                          : (isDark ? AppColors.darkText : AppColors.lightText)
                              .withOpacity(0.5),
                      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (isUnread) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
