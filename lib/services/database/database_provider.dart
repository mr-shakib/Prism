/*

DATABASE PROVIDER

This provier is to separate the firestore data handling and the UI of our app.

---------------------------------------------------------------------

- The database service class handles data to and from firebase
- The database provider class handles the UI of our app

*/

import 'package:flutter/foundation.dart';
import 'package:prism/services/database/database_service.dart';
import 'package:prism/models/comment.dart';
import 'package:prism/models/post.dart';
import 'package:prism/models/user.dart';
import 'package:prism/services/auth/auth_service.dart';

class DatabaseProvider extends ChangeNotifier {
  /*
  
  SERVICES

  */

  //get db & auth
  final _db = DatabaseService();
  final _auth = AuthService();
  /* 
  
  USER PROFILE
  
  */

  //get user profile given uid
  Future<UserProfile?> userProfile(String uid) =>
      _db.getUserInfoFromFirestore(uid);

  //update the user bio
  Future<void> updateBio(String bio) => _db.updateUserBioInFirebase(bio);

  //Delete user info

  /* 
  
  POST
  
  */

  //loacl list of post
  List<Post> _allPosts = [];
  List<Post> _followingPosts = [];

  //get all posts
  List<Post> get allPosts => _allPosts;

  //get following posts
  List<Post> get followingPosts => _followingPosts;

  //post message
  Future<void> postMessage(String message) async {
    //post message in firebase
    await _db.postMessageInFirebase(message);

    //reload all posts
    await loadAllPosts();
  }

  //fetch all posts
  Future<void> loadAllPosts() async {
    //get all posts from firebase
    final allPost = await _db.getAllPostsFromFirebase();

    //get blocked user id
    final blockedUsers = await _db.getBlockedUsersFromFirebase();

    //filter out blocked users
    _allPosts =
        allPost.where((post) => !blockedUsers.contains(post.uid)).toList();

    //load following posts
    loadFollowingPosts();

    //initialize local like data
    initializeLikeMap();

    //update the UI
    notifyListeners();
  }

  //filter and return post given uid
  List<Post> filterUserPosts(String uid) {
    return _allPosts.where((post) => post.uid == uid).toList();
  }

  //load following posts
  Future<void> loadFollowingPosts() async {
    //get current uid
    String currentUid = _auth.getCurrentUid();

    //get list of uids that the current user is following
    final followingUids = await _db.getFollowingUidsFromFirebase(currentUid);

    //filter following posts
    _followingPosts =
        _allPosts.where((post) => followingUids.contains(post.uid)).toList();

    //update the UI
    notifyListeners();
  }

  //delete post
  Future<void> deletePost(String postId) async {
    //delete from firebase
    await _db.deletePostFromFirebase(postId);

    //referesh data from firebase
    await loadAllPosts();
  }

  /*
  
  LIKES
  
  */

  //local map to track like count for each post
  Map<String, int> _likeCounts = {
    //for each post id: like count
  };

  //local list to track post liked by current user
  List<String> _likedPosts = [];

  //does the current user like the post
  bool isPostLikedByCurrentUser(String postId) => _likedPosts.contains(postId);

  //get like count
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;

  //initialize like map locally
  void initializeLikeMap() {
    //get  current uid
    final currentUserID = _auth.getCurrentUid();

    //clear liked posts ( for when new users signs in, clear local data)
    _likedPosts.clear();

    //for each post get like data
    for (var post in _allPosts) {
      //update like count map
      _likeCounts[post.id] = post.likeCount;

      //if the post is liked by current user
      if (post.likedBy.contains(currentUserID)) {
        //add to liked post list
        _likedPosts.add(post.id);
      }
    }
  }

  //toggle like
  Future<void> toggleLike(String postId) async {
    /* 
     
     This first part will update the local values first so thwat the UI feels responsive.
     
     */

    //store the original like count
    final likedPostsOriginal = _likedPosts;
    final likeCountsOriginal = _likeCounts;

    //perform the like/unlike
    if (likedPostsOriginal.contains(postId)) {
      //remove from liked post list
      _likedPosts.remove(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) - 1;
    } else {
      //add to liked post list
      _likedPosts.add(postId);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
    }

    //update the UI
    notifyListeners();

    /*
    
    Now let's update in the database
    
    */

    //attempt the likes in database

    try {
      await _db.toggleLikeInFirebase(postId);
    } catch (e) {
      _likedPosts = likedPostsOriginal;
      _likeCounts = likeCountsOriginal;
      notifyListeners();
      print(e);
    }
  }

  /*
  COMMENTS
  */

  // local list of comments
  final Map<String, List<Comment>> _comments = {};

  //get comments locally
  List<Comment> getComments(String postId) => _comments[postId] ?? [];

  //fetch comments from database for a post
  Future<void> loadComments(String postId) async {
    //get comments from firebase
    final allComments = await _db.getCommentsFromFirebase(postId);

    //update local data
    _comments[postId] = allComments;

    //update UI
    notifyListeners();
  }

  // add a comment
  Future<void> addComment(String postId, String message) async {
    await _db.addCommentInFirebase(postId, message);
    await loadCommentsAndReplies(postId);
  }

  //delete a comment
  Future<void> deleteComment(String commentId, postId) async {
    //delete comment in firebase
    await _db.deleteCommentFromFirebase(commentId);

    //reload comments
    await loadComments(commentId);
  }

  // Update the _comments map to store all comments and replies

  // Get comments and replies for a post
  List<Comment> getCommentsAndReplies(String postId) => _comments[postId] ?? [];

  // Fetch comments and replies from database for a post
  Future<void> loadCommentsAndReplies(String postId) async {
    final allComments = await _db.getCommentsAndRepliesFromFirebase(postId);
    _comments[postId] = allComments;
    notifyListeners();
  }

  // Add a comment reply
  Future<void> addCommentReply(
      String postId, String parentCommentId, String message) async {
    await _db.addCommentReplyInFirebase(postId, parentCommentId, message);
    await loadCommentsAndReplies(postId);
  }

  /*
  
  ACCOUNTS Stuff
  
  */

  //local list of blocked users
  List<UserProfile> _blockedUsers = [];

  //get list of blocked users
  List<UserProfile> get blockedUsers => _blockedUsers;

  //fetch the blocked users
  Future<void> loadBlockedUsers() async {
    //get blocked users from firebase
    final blockedUserIds = await _db.getBlockedUsersFromFirebase();

    //get full user details using the blocked user id
    final blockedUsersData = await Future.wait(
        blockedUserIds.map((id) => _db.getUserInfoFromFirestore(id)));

    //return as a list
    _blockedUsers = blockedUsersData.whereType<UserProfile>().toList();

    //update UI
    notifyListeners();
  }

  //block a user
  Future<void> blockUser(String userId) async {
    //block user in firebase
    await _db.blockUserInFirebase(userId);

    //reload blocked users
    await loadBlockedUsers();

    //reload data
    await loadAllPosts();

    //update UI
    notifyListeners();
  }

  //unblock a user
  Future<void> unblockUser(String userId) async {
    //unblock user in firebase
    await _db.unblockUserInFirebase(userId);

    //reload blocked users
    await loadBlockedUsers();

    //reload data
    await loadAllPosts();

    //update UI
    notifyListeners();
  }

  //report user and post
  Future<void> reportUser(String postId, userId) async {
    //report user in firebase
    await _db.reportUserInFirebase(postId, userId);
  }

  /*
  
  Follow
  
  */

  //loacl map
  final Map<String, List<String>> _followers = {};
  final Map<String, List<String>> _following = {};
  final Map<String, int> _followersCount = {};
  final Map<String, int> _followingCount = {};

  //get counts for followers & following locally: given a uid
  int getFollowersCount(String uid) => _followersCount[uid] ?? 0;
  int getFollowingCount(String uid) => _followingCount[uid] ?? 0;

  //load followers
  Future<void> loadFollowers(String uid) async {
    //get followers from firebase
    final followers = await _db.getFollowersUidsFromFirebase(uid);
    _followers[uid] = followers;
    _followersCount[uid] = followers.length;
    notifyListeners();
  }

  //load following
  Future<void> loadFollowing(String uid) async {
    //get following from firebase
    final following = await _db.getFollowingUidsFromFirebase(uid);
    _following[uid] = following;
    _followingCount[uid] = following.length;
    notifyListeners();
  }

  //follow a user
  Future<void> followUser(String targetUserId) async {
    //get current user id
    final currentUserId = _auth.getCurrentUid();
    //initialize with empty list if null
    _following.putIfAbsent(currentUserId, () => []);
    _followers.putIfAbsent(targetUserId, () => []);

    //follow if current user is not one of the followers
    if (!_followers[targetUserId]!.contains(currentUserId)) {
      //add current user to target user's follower list
      _followers[targetUserId]?.add(currentUserId);
      //update follower count
      _followersCount[targetUserId] = (_followersCount[targetUserId] ?? 0) + 1;

      //add target user to current user's following list
      _following[currentUserId]!.add(targetUserId);
      //update following count
      _followingCount[currentUserId] =
          (_followingCount[currentUserId] ?? 0) + 1;

      //update the ui
      notifyListeners();

      try {
        //follow user in firebase
        await _db.followUserInFirebase(targetUserId);

        //reload current user's followers
        await loadFollowers(currentUserId);
        //reload target user's following
        await loadFollowing(targetUserId);
      } catch (e) {
        //if error, undo the changes
        _followers[targetUserId]?.remove(currentUserId);
        _followersCount[targetUserId] =
            (_followersCount[targetUserId] ?? 0) - 1;
        _following[currentUserId]!.remove(targetUserId);
        _followingCount[currentUserId] =
            (_followingCount[currentUserId] ?? 0) - 1;
        notifyListeners();
      }
    }
  }

  //unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    //get current user id
    final currentUserId = _auth.getCurrentUid();

    //initialize list if null
    _following.putIfAbsent(currentUserId, () => []);
    _followers.putIfAbsent(targetUserId, () => []);

    //unfollow if current user is one of the followers
    if (_followers[targetUserId]!.contains(currentUserId)) {
      //remove current user from target user's follower list
      _followers[targetUserId]?.remove(currentUserId);
      //update follower count
      _followersCount[targetUserId] = (_followersCount[targetUserId] ?? 1) - 1;

      //remove target user from current user's following list
      _following[currentUserId]!.remove(targetUserId);
      //update following count
      _followingCount[currentUserId] =
          (_followingCount[currentUserId] ?? 1) - 1;

      //update the ui
      notifyListeners();
    }

    try {
      //unfollow user in firebase
      await _db.unfollowUserInFirebase(targetUserId);

      //reload current user's followers
      await loadFollowers(currentUserId);
      //reload target user's following
      await loadFollowing(targetUserId);
    } catch (e) {
      //if error, undo the changes
      _followers[targetUserId]?.add(currentUserId);
      _followersCount[targetUserId] = (_followersCount[targetUserId] ?? 0) + 1;
      _following[currentUserId]!.add(targetUserId);
      _followingCount[currentUserId] =
          (_followingCount[currentUserId] ?? 0) + 1;
      notifyListeners();
    }
  }

  bool isFollowing(String uid) {
    final currentUserId = _auth.getCurrentUid();
    return _followers[uid]?.contains(currentUserId) ?? false;
  }

  /*

  FOLLOWERS/FOLLOWINg


  */

  final Map<String, List<UserProfile>> _followersProfile = {};
  final Map<String, List<UserProfile>> _followingProfile = {};

  //get list of follower profile
  List<UserProfile> getListOfFollowersProfile(String uid) =>
      _followersProfile[uid] ?? [];

  //get list of following profile
  List<UserProfile> getListOfFollowingProfile(String uid) =>
      _followingProfile[uid] ?? [];

  //load followers profile given uid
  Future<void> loadUserFollowersProfile(String uid) async {
    try {
      //get list of followers uid from firebase
      final followerIds = await _db.getFollowersUidsFromFirebase(uid);

      //create list of user profiles
      List<UserProfile> followerProfiles = [];

      //go thru each followers id
      for (String followerId in followerIds) {
        //get user profile from firebase
        UserProfile? followerProfile =
            await _db.getUserInfoFromFirestore(followerId);

        //add followers profile to list
        if (followerProfile != null) {
          followerProfiles.add(followerProfile);
        }
      }

      //update local data
      _followersProfile[uid] = followerProfiles;

      //update ui
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  //load following profile given uid
  //load followers profile given uid
  Future<void> loadUserFollowingProfile(String uid) async {
    try {
      //get list of following uid from firebase
      final followingIds = await _db.getFollowingUidsFromFirebase(uid);

      //create list of user profiles
      List<UserProfile> followingProfiles = [];

      //go thru each following id
      for (String followingId in followingIds) {
        //get user profile from firebase
        UserProfile? followingProfile =
            await _db.getUserInfoFromFirestore(followingId);

        //add followers profile to list
        if (followingProfile != null) {
          followingProfiles.add(followingProfile);
        }
      }

      //update local data
      _followingProfile[uid] = followingProfiles;

      //update ui
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

/*

SEARCH USERS

*/

//list of search resulkt
  List<UserProfile> _searchResults = [];

//get list of search result
  List<UserProfile> get searchResults => _searchResults;

//method to search for a user
  Future<void> searchUsers(String searchTerms) async {
    try {
      //get list of search result from firebase
      final results = await _db.searchUsersInFirebase(searchTerms);

      //update local data
      _searchResults = results;

      //update ui
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
