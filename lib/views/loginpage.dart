import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homepage.dart';
import 'adminhomepage.dart';
import 'signuppage.dart';
import 'uihelper.dart';
import 'background_container.dart';

// class BackgroundContainer extends StatelessWidget {
//   final Widget child;
//   final Color backgroundColor;
//   final String backgroundImage;
//
//   const BackgroundContainer({
//     Key? key,
//     required this.child,
//     this.backgroundColor = Colors.white,
//     this.backgroundImage = 'assets/bg1'
//         ''
//         '.png',
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage(backgroundImage),
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: Container(
//         color: backgroundColor.withOpacity(0.4),
//         child: child,
//       ),
//     );
//   }
// }

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FirebaseAuth _auth = FirebaseAuth.instance;
  String errorMessage = '';

  Future<void> _login() async {
    try {
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      print("Login Error: $e");
      setState(() {
        errorMessage = 'Incorrect email or password. Please try again.';
      });
    }
  }

  Future<void> _adminLogin() async {
    try {
      List<String> adminEmails = [
        'samyukta12@gmail.com',
        'htalwar18@gmail.com',
        'mandvishukla20@gmail.com'
      ];
      if (adminEmails.contains(emailController.text.trim())) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomePage()),
        );
      } else {
        setState(() {
          errorMessage = 'You are not authorized as an admin.';
        });
      }
    } catch (e) {
      print("Admin Login Error: $e");
      setState(() {
        errorMessage = 'An error occurred during admin login.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundContainer(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Login Page"),
          centerTitle: true,
        ),
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UiHelper.CustomTextField(
                  emailController, "Email", Icons.mail, false),
              UiHelper.CustomTextField(
                  passwordController, "Password", Icons.lock, true),
              SizedBox(height: 10),
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 20),
              UiHelper.CustomButton(_login, "Login"),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't Have an Account?",
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpPage()));
                    },
                    child: Text(
                      "Sign up",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _adminLogin,
                child: Text('Admin Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
