import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String jobId;
  final String employerId;
  final String workerId;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.jobId,
    required this.employerId,
    required this.workerId,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      jobId: map['jobId'] as String? ?? '',
      employerId: map['employerId'] as String? ?? '',
      workerId: map['workerId'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'employerId': employerId,
      'workerId': workerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool read;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    required this.read,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      chatId: map['chatId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: map['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }
}
