import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:prism/services/auth/auth_service.dart';

import '../components/my_button.dart';
import '../components/my_loading_circle.dart';
import '../components/my_text-field.dart';
import '../services/database/database_service.dart';

/* 

REGISTER PAGE

  --------------------------------------

  On this page, a new user can register with their:

  - name
  - email
  - password
  - confirm password

*/

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;

  const RegisterPage({super.key, this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  //access to auth & db service
  final _auth = AuthService();
  final _db = DatabaseService();

  //text controller
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pwController = TextEditingController();
  final TextEditingController confirmPwController = TextEditingController();

  //registered button tapped
  void register() async {
    if (pwController.text == confirmPwController.text) {
      showLoadingCircle(context);

      try {
        // Register user with Firebase Auth
        await _auth.registerEmailPassword(
          emailController.text,
          pwController.text,
        );

        // Save user profile in database (BEFORE hiding loading)
        await _db.saveUserInfoInFirebase(
          name: nameController.text,
          email: emailController.text,
        );

        // Success - hide loading circle after everything is done
        if (mounted) {
          hideLoadingCircle(context);
        }
      }

      //catch any errors
      catch (e) {
        // Handle the error, e.g., show an error message
        if (mounted) {
          hideLoadingCircle(context);
        }

        //let user know the error

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                e.toString(),
              ),
            ),
          );
        }
      }
    }

    //password mismatch
    else {
      // Handle password mismatch
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text(
            "Passwords don't match",
          ),
        ),
      );
    }
  }

  //BUILD UI
  @override
  Widget build(BuildContext context) {
    //SCAFFOLD
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      //body
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 10,
                  ),

                  // app logo
                  Lottie.network(
                    'https://lottie.host/5210bf1c-0430-4515-84f5-c2f4ca1626e9/CxRFgEflWA.json',
                    height: 200,
                  ),

                  const SizedBox(height: 10),

                  //Create an account message
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.purple, Colors.deepPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      "Let's create an account",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  //name field
                  MyTextField(
                      icon: Icons.person,
                      controller: nameController,
                      hintText: "Name",
                      obscureText: false),

                  const SizedBox(height: 15),

                  //email field
                  MyTextField(
                      icon: Icons.email,
                      controller: emailController,
                      hintText: "Email",
                      obscureText: false),

                  const SizedBox(height: 15),

                  //password field
                  MyTextField(
                      icon: Icons.password,
                      controller: pwController,
                      hintText: "Password",
                      obscureText: true),

                  const SizedBox(height: 15),

                  //confirm password field
                  MyTextField(
                      icon: Icons.password,
                      controller: confirmPwController,
                      hintText: "Confirm Password",
                      obscureText: true),

                  const SizedBox(height: 25),

                  //register button
                  MyButton(
                    text: "Register",
                    onTap: register,
                  ),

                  const SizedBox(height: 50),

                  //login button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Alreadey a prismer?",
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(width: 5),

                      //user can tap here to go to register page
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          "Login Now",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
