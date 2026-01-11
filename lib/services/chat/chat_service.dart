/*

CHAT SERVICE

Handles all chat/messaging operations with Firestore

*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prism/models/chat.dart';
import 'package:prism/models/message.dart';
import 'package:prism/services/auth/auth_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // Get or create a chat between two users
  Future<String> getOrCreateChat(String otherUserId) async {
    final currentUserId = _auth.getCurrentUid();
    final chatId = Chat.getChatId(currentUserId, otherUserId);

    try {
      final chatDoc = await _db.collection('Chats').doc(chatId).get();

      if (!chatDoc.exists) {
        // Create new chat
        await _db.collection('Chats').doc(chatId).set({
          'participants': [currentUserId, otherUserId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'unreadCount': {
            currentUserId: 0,
            otherUserId: 0,
          },
        });
      }

      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String message,
    String? imageUrl,
  }) async {
    final currentUserId = _auth.getCurrentUid();

    try {
      // Add message to Messages subcollection
      await _db
          .collection('Chats')
          .doc(chatId)
          .collection('Messages')
          .add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });

      // Update chat's last message
      await _db.collection('Chats').doc(chatId).update({
        'lastMessage': message.isNotEmpty ? message : '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUserId,
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages stream for a chat
  Stream<List<Message>> getMessagesStream(String chatId) {
    return _db
        .collection('Chats')
        .doc(chatId)
        .collection('Messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromDocument(doc))
          .toList();
    });
  }

  // Get all chats for current user
  Stream<List<Chat>> getUserChatsStream() {
    final currentUserId = _auth.getCurrentUid();

    return _db
        .collection('Chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Chat.fromDocument(doc))
          .toList();
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _auth.getCurrentUid();

    try {
      // Get unread messages
      final unreadMessages = await _db
          .collection('Chats')
          .doc(chatId)
          .collection('Messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark each as read
      final batch = _db.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      // Reset unread count for current user
      await _db.collection('Chats').doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      // Delete all messages
      final messages = await _db
          .collection('Chats')
          .doc(chatId)
          .collection('Messages')
          .get();

      final batch = _db.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Delete chat document
      await _db.collection('Chats').doc(chatId).delete();
    } catch (e) {
      print('Error deleting chat: $e');
    }
  }
}
