/*

POST MODEL

*/

import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String uid;
  final String name;
  final String username;
  final String message;
  final Timestamp timestamp;
  final int likeCount;
  final List<String> likedBy;
  final String? imageUrl;
  final String? videoUrl;

  Post({
    required this.id,
    required this.uid,
    required this.name,
    required this.username,
    required this.message,
    required this.timestamp,
    required this.likeCount,
    required this.likedBy,
    this.imageUrl,
    this.videoUrl,
  });

  //convert a Firestore document to a post
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      id: doc.id,
      uid: doc['uid'],
      name: doc['name'],
      username: doc['username'],
      message: doc['message'],
      timestamp: doc['timestamp'],
      likeCount: doc['likeCount'],
      likedBy: List<String>.from(doc['likedBy'] ?? []),
      imageUrl: doc.data().toString().contains('imageUrl') ? doc['imageUrl'] : null,
      videoUrl: doc.data().toString().contains('videoUrl') ? doc['videoUrl'] : null,
    );
  }

  //convert a post object to a map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'username': username,
      'message': message,
      'timestamp': timestamp,
      'likeCount': likeCount,
      'likedBy': likedBy,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
    };
  }
}
