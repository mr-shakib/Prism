/*

USER PROFILE

This is what each user will have in their profile

----------------------------------------------------------------------

- uid
- name
- email
- username
- bio
- profile photo
- cover photo

 */

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String username;
  final String bio;
  final String? profilePictureUrl;
  final String? coverPhotoUrl;
  final List<String> followers;
  final List<String> following;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.bio,
    this.profilePictureUrl,
    this.coverPhotoUrl,
    this.followers = const [],
    this.following = const [],
  });
  //firebase -> app
  //convert firestore document to user profile

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    // Check if document exists
    if (!doc.exists) {
      throw Exception('User document does not exist for uid: ${doc.id}');
    }
    
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('User document data is null for uid: ${doc.id}');
    }
    
    return UserProfile(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      bio: data['bio'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
      coverPhotoUrl: data['coverPhotoUrl'],
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
    );
  }

  //app -> firebase
  //convert a user profile to a map

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'username': username,
      'bio': bio,
      'followers': followers,
      'following': following,
    };
  }
}
