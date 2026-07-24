import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_model.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String chatIdFor(String jobId, String workerId) =>
      '${jobId}_$workerId';

  static Future<String> getOrCreateChat({
    required String jobId,
    required String employerId,
    required String workerId,
  }) async {
    final chatId = chatIdFor(jobId, workerId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final existing = await chatRef.get();
    if (!existing.exists) {
      await chatRef.set({
        'jobId': jobId,
        'employerId': employerId,
        'workerId': workerId,
        'participantIds': [employerId, workerId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return chatId;
  }

  static Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty && (imageUrl == null || imageUrl.isEmpty)) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId != senderId) {
      throw StateError('You are not allowed to send this message.');
    }

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(messageRef, {
      'chatId': chatId,
      'senderId': senderId,
      'text': trimmedText,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    batch.update(chatRef, {
      'lastMessage': trimmedText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  static Future<void> markAsRead(String chatId, String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .limit(100)
        .get();

    final batch = _firestore.batch();
    var hasUpdates = false;
    for (final document in snapshot.docs) {
      if (document.data()['senderId'] != userId) {
        batch.update(document.reference, {'read': true});
        hasUpdates = true;
      }
    }
    if (hasUpdates) await batch.commit();
  }

  static Stream<List<ChatModel>> getChatList() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(const []);
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  static Future<MessageModel?> getLastMessage(String chatId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final document = snapshot.docs.first;
    return MessageModel.fromMap(document.data(), document.id);
  }

  static Future<int> getUnreadCount(String chatId, String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .get();
    return snapshot.docs
        .where((document) => document.data()['senderId'] != userId)
        .length;
  }
}
