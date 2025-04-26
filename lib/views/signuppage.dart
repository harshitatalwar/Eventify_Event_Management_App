import 'package:aivent/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aivent/views/uihelper.dart';
import 'package:flutter/cupertino.dart';
import 'package:aivent/views/loginpage.dart';
import 'background_container.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPage();
}

class _SignUpPage extends State<SignUpPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  signUp(String email, String password) async {
    if (email == "" || password == "") {
      UiHelper.CustomAlertBox(context, "Enter Required Fields");
    } else {
      UserCredential? userCredential;
      try {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Send email verification
        await sendEmailVerification(context);

        // Display success message or navigate to the next screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sign up successful. Check your email for verification."),
            duration: Duration(seconds: 3),
          ),
        );

        // Optional: Navigate to login page after successful sign-up
        Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
      } on FirebaseAuthException catch (ex) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${ex.code}"),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> sendEmailVerification(BuildContext context) async {
    try {
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email verification sent!'),
          duration: Duration(seconds: 3),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message!),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up Page"),
        centerTitle: true,
      ),
      body: BackgroundContainer(
          child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.CustomTextField(emailController, "Email", Icons.mail, false),
            UiHelper.CustomTextField(passwordController, "Password", Icons.password, true),
            SizedBox(height: 30),
            UiHelper.CustomButton(() {
              signUp(emailController.text.toString(), passwordController.text.toString());
            }, "Sign Up")
          ],
        ),
      ),
    );
  }
}
