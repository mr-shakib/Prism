import 'package:firebase_auth/firebase_auth.dart';
import 'package:prism/services/database/database_service.dart';

/*
 
AUTH SERVICE


This handles everything to do with the firebase

---------------------------------------------------------------------

- Login
- Register
- Logout
- Delete Account ( requiured if we wanna publish it)

*/

class AuthService {
  //get instance of the auth service

  final _auth = FirebaseAuth.instance;

  //get curent user and id
  User? get currentUser => _auth.currentUser;
  String getCurrentUid() => _auth.currentUser!.uid;
  String? getCurrentUserEmail() => _auth.currentUser?.email;

  //login email & pw
  Future<UserCredential> loginEmailPassword(String email, String pw) async {
    //attempt login
    try {
      final UserCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: pw);
      return UserCredential;
    }

    // catch any errors
    on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //register email & pw
  Future<UserCredential> registerEmailPassword(
      String email, String password) async {
    // attempt to register a new user

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  //logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  //delete account
  Future<void> deleteAccount() async {
    //get current user
    User? user = _auth.currentUser;

    if (user != null) {
      //delete user's data from firestore
      await DatabaseService().deleteUserInfoFromFirebase(user.uid);

      //delete user's auth record
      await user.delete();
    }
  }
}
