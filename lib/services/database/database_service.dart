/*

DATABASE SERVICE

This handles everything to do with the firebase

---------------------------------------------------------------------

- User Profile
- Posts
- Messages
- Likes
- Comments
- Account Settings( Report / Block / Delete Account)
- Follow / Unfollow
- Search Users


*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/auth/auth_service.dart';

import '../../models/comment.dart';
import '../../models/post.dart';

class DatabaseService {
  // get instance of firestore db and auth
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /* 
  
  USER PROFILE
  
  */
  //save user info
  Future<void> saveUserInfoInFirebase(
      {required String name, required String email}) async {
    //get current uid
    String uid = _auth.currentUser!.uid;

    // extract username from email
    String username = email.split('@')[0];

    //create a user profile
    UserProfile user = UserProfile(
      uid: uid,
      name: name,
      email: email,
      username: username,
      bio: '',
    );

    //convert user into a map so that we can store in firebase
    final userMap = user.toMap();

    //save user in firebase
    await _db.collection("Users").doc(uid).set(userMap);
  }

  //get user info
  Future<UserProfile?> getUserInfoFromFirestore(String uid) async {
    try {
      // retrive user info from firebase
      DocumentSnapshot userDoc = await _db.collection("Users").doc(uid).get();

      //convert to doc to user profile
      return UserProfile.fromDocument(userDoc);
    } catch (e) {
      print(e);
      return null;
    }
  }

  //update user bio
  Future<void> updateUserBioInFirebase(String bio) async {
    //get current uid
    String uid = AuthService().getCurrentUid();

    //update user bio in firebase
    try {
      await _db.collection("Users").doc(uid).update({"bio": bio});
    } catch (e) {
      print(e);
    }
  }

  //update profile picture
  Future<void> updateProfilePicture(String imageUrl) async {
    String uid = AuthService().getCurrentUid();
    try {
      await _db.collection("Users").doc(uid).update({
        "profilePictureUrl": imageUrl,
      });
    } catch (e) {
      print(e);
    }
  }

  //update cover photo
  Future<void> updateCoverPhoto(String imageUrl) async {
    String uid = AuthService().getCurrentUid();
    try {
      await _db.collection("Users").doc(uid).update({
        "coverPhotoUrl": imageUrl,
      });
    } catch (e) {
      print(e);
    }
  }

  //Get random users for suggestions
  Future<List<UserProfile>> getRandomUsersFromFirebase(
      {int limit = 5}) async {
    try {
      String currentUid = _auth.currentUser!.uid;

      // Get all users except current user
      QuerySnapshot snapshot = await _db
          .collection("Users")
          .where(FieldPath.documentId, isNotEqualTo: currentUid)
          .limit(limit * 2) // Get more to filter
          .get();

      // Convert to list and shuffle
      List<UserProfile> users = snapshot.docs
          .map((doc) => UserProfile.fromDocument(doc))
          .toList()
        ..shuffle();

      // Return limited number
      return users.take(limit).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  //Delete user info

  Future<void> deleteUserInfoFromFirebase(String uid) async {
    WriteBatch batch = _db.batch();

    //delete user doc
    DocumentReference userDoc = _db.collection("Users").doc(uid);
    batch.delete(userDoc);

    //delete user posts
    QuerySnapshot userPosts =
        await _db.collection("Posts").where('uid', isEqualTo: uid).get();

    for (var post in userPosts.docs) {
      batch.delete(post.reference);
    }

    //delete user comments

    QuerySnapshot userComments =
        await _db.collection("Comments").where('uid', isEqualTo: uid).get();

    for (var comment in userComments.docs) {
      batch.delete(comment.reference);
    }

    //delete likes by this user

    QuerySnapshot allPosts = await _db.collection("Posts").get();

    for (QueryDocumentSnapshot post in allPosts.docs) {
      Map<String, dynamic> postData = post.data() as Map<String, dynamic>;
      var likedBy = postData['likedBy'] as List<dynamic>? ?? [];

      if (likedBy.contains(uid)) {
        batch.update(post.reference, {
          'likedBy': FieldValue.arrayRemove([uid]),
          'likes': FieldValue.increment(-1),
        });
      }
    }

    //upadate follower & following records accordingly

    //commit the batch
    await batch.commit();
  }

  /* 
  
  POST MESSAGE
  
  */

  //post a message
  Future<void> postMessageInFirebase(String message, {String? imageUrl, String? videoUrl}) async {
    try {
      String uid = _auth.currentUser!.uid;

      //use this to get the current user

      UserProfile? user = await getUserInfoFromFirestore(uid);

      //create a post
      Post newPost = Post(
        id: '',
        uid: uid,
        name: user!.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
        likeCount: 0,
        likedBy: [],
        imageUrl: imageUrl,
        videoUrl: videoUrl,
      );

      //convert post into a map so that we can store in firebase
      Map<String, dynamic> newPostMap = newPost.toMap();

      //add to firebase
      await _db.collection("Posts").add(newPostMap);
    } catch (e) {
      print(e);
    }
  }

  //delete a message

  Future<void> deletePostFromFirebase(String postId) async {
    try {
      await _db.collection("Posts").doc(postId).delete();
    } catch (e) {
      print(e);
    }
  }

  //get  all posts from firebase

  Future<List<Post>> getAllPostsFromFirebase() async {
    try {
      QuerySnapshot snapshot = await _db
          //go to collection -> posts
          .collection("Posts")

          //order by timestamp
          .orderBy('timestamp', descending: true)

          //get this data
          .get();

      //return list of posts
      return snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  //get single post from firebase

  /* 
  
  LIKES
  
  */

  //like a post
  Future<void> toggleLikeInFirebase(String postId) async {
    try {
      //get current user
      String uid = _auth.currentUser!.uid;

      //go to doc for the post
      DocumentReference postDoc = _db.collection("Posts").doc(postId);

      //execute the likes
      await _db.runTransaction((transaction) async {
        //get post data
        DocumentSnapshot postSnapshot = await transaction.get(postDoc);

        //get like of users who like this post
        List<String> likedBy = List<String>.from(postSnapshot['likedBy'] ?? []);

        //get like count
        int currentLikeCount = postSnapshot['likeCount'];

        //if user has not liked the post -> like
        if (!likedBy.contains(uid)) {
          //add user to like list
          likedBy.add(uid);

          //increment like count
          currentLikeCount++;
        }

        //if user has liked the post -> unlike

        else {
          //remove user from like list
          likedBy.remove(uid);

          //decrement like count
          currentLikeCount--;
        }

        //update in firebase
        transaction.update(postDoc, {
          'likedBy': likedBy,
          'likeCount': currentLikeCount,
        });
      });
    } catch (e) {
      print(e);
    }
  }

  /* 
  
  COMMENTS
  
  */

  // Add a comment to a post
  Future<void> addCommentInFirebase(String postId, message) async {
    try {
      //get current user
      String uid = _auth.currentUser!.uid;
      UserProfile? user = await getUserInfoFromFirestore(uid);

      //create a comment
      Comment newComment = Comment(
        id: '',
        postId: postId,
        uid: uid,
        name: user!.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
      );

      //convert comment into a map so that we can store in firebase

      Map<String, dynamic> newCommentMap = newComment.toMap();

      //store in firebase
      await _db.collection("Comments").add(newCommentMap);
    } catch (e) {
      print(e);
    }
  }

  // Delete a comment from a post
  Future<void> deleteCommentFromFirebase(String commentId) async {
    try {
      await _db.collection("Comments").doc(commentId).delete();
    } catch (e) {
      print(e);
    }
  }

  //Fetch all comments from firebase
  Future<List<Comment>> getCommentsFromFirebase(String postId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Comments")
          .where('postId', isEqualTo: postId)
          .get();
      return snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // Add a comment reply
  Future<void> addCommentReplyInFirebase(
      String postId, String parentCommentId, String message) async {
    try {
      String uid = _auth.currentUser!.uid;
      UserProfile? user = await getUserInfoFromFirestore(uid);

      Comment newReply = Comment(
        id: '',
        postId: postId,
        parentCommentId: parentCommentId,
        uid: uid,
        name: user!.name,
        username: user.username,
        message: message,
        timestamp: Timestamp.now(),
      );

      Map<String, dynamic> newReplyMap = newReply.toMap();

      // Add the reply to the Comments collection
      DocumentReference replyRef =
          await _db.collection("Comments").add(newReplyMap);

      // Update the parent comment's replyIds
      await _db.collection("Comments").doc(parentCommentId).update({
        'replyIds': FieldValue.arrayUnion([replyRef.id])
      });
    } catch (e) {
      print(e);
    }
  }

  // Fetch comments and replies for a post
  Future<List<Comment>> getCommentsAndRepliesFromFirebase(String postId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Comments")
          .where('postId', isEqualTo: postId)
          .get();

      List<Comment> comments =
          snapshot.docs.map((doc) => Comment.fromDocument(doc)).toList();

      // Sort comments: top-level comments first, then replies
      comments.sort((a, b) {
        if (a.parentCommentId == null && b.parentCommentId == null) {
          return b.timestamp.compareTo(a.timestamp);
        } else if (a.parentCommentId == null) {
          return -1;
        } else if (b.parentCommentId == null) {
          return 1;
        } else {
          return a.timestamp.compareTo(b.timestamp);
        }
      });

      return comments;
    } catch (e) {
      return [];
    }
  }
  /* 
  
  ACCOUNT SETTINGS
  
  */

  // Report a post
  Future<void> reportUserInFirebase(String postId, userId) async {
    //get current user
    final currentUserId = _auth.currentUser!.uid;

    //create a report map
    final report = {
      'reportedBy': currentUserId,
      'messageId': postId,
      'messageownerId': userId,
      'timestamp': Timestamp.now(),
    };

    //update in firestore
    await _db.collection("Reports").add(report);
  }

  //block user
  Future<void> blockUserInFirebase(String userId) async {
    //get current user
    final currentUserId = _auth.currentUser!.uid;

    //add this user to block list
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(userId)
        .set({});
    ;
  }

  //unblock user
  Future<void> unblockUserInFirebase(String blockedUserId) async {
    //get current user
    final currentUserId = _auth.currentUser!.uid;

    //unblock user in firebase
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .doc(blockedUserId)
        .delete();
  }

  //get list of blocked users
  Future<List<String>> getBlockedUsersFromFirebase() async {
    //get current user
    final currentUserId = _auth.currentUser!.uid;

    //get data of blocked users

    final snapshot = await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("BlockedUsers")
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /* 
  
  FOLLOW / UNFOLLOW
  
  */
  //folow user
  Future<void> followUserInFirebase(String uid) async {
    //get current user
    final currentUserId = _auth.currentUser!.uid;

    //add this user to follow list
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("Following")
        .doc(uid)
        .set({});

    //add this user to follower list
    await _db
        .collection("Users")
        .doc(uid)
        .collection("Followers")
        .doc(currentUserId)
        .set({});
  }

  //unfollow user
  Future<void> unfollowUserInFirebase(String uid) async {
    //get current user
    final currentUserId = _auth.currentUser!.uid;

    //remove target user from current user's following list
    await _db
        .collection("Users")
        .doc(currentUserId)
        .collection("Following")
        .doc(uid)
        .delete();

    //remove current user from target user's follower list
    await _db
        .collection("Users")
        .doc(uid)
        .collection("Followers")
        .doc(currentUserId)
        .delete();
  }

  //Get a user's followers list of uids
  Future<List<String>> getFollowersUidsFromFirebase(String uid) async {
    //get user's followers list
    final snapshot =
        await _db.collection("Users").doc(uid).collection("Followers").get();

    //return as a list of uids
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  //Get a user's following list of uids
  Future<List<String>> getFollowingUidsFromFirebase(String uid) async {
    //get user's following list
    final snapshot =
        await _db.collection("Users").doc(uid).collection("Following").get();

    //return as a list of uids
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /* 
  
  SEARCH
  
  */

  //search users
  Future<List<UserProfile>> searchUsersInFirebase(String searchTerms) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection("Users")
          .where('username', isGreaterThanOrEqualTo: searchTerms)
          .where('username', isLessThanOrEqualTo: '${searchTerms}\uf8ff')
          .get();

      return snapshot.docs.map((doc) => UserProfile.fromDocument(doc)).toList();
    } catch (e) {
      return [];
    }
  }
}
