import 'package:fix_mate/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/service_seeker/s_profile.dart';

class s_login extends StatefulWidget {
  const s_login({Key? key}) : super(key: key);

  _s_loginState createState() => _s_loginState();
}

class _s_loginState extends State<s_login> {
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height, // Ensures full height
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'lib/assets/images/ss_login.png',
                      width: 300,
                      height: 300,
                    ),
                    SizedBox(height: 25),
                    Text(
                      'Login \nService Seeker Account',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 35),
                    reusableTextField(
                        "Enter Email Address", Icons.email, false, _emailTextController),
                    SizedBox(height: 10),
                    reusableTextField(
                        "Enter Password", Icons.lock_outline, true, _passwordTextController),
                    forgetPassword(context, Color(0xFFfb9798)),
                    SizedBox(height: 10),
                    pk_button(context, "Login", () {
                      if (_emailTextController.text.isEmpty || _passwordTextController.text.isEmpty) {
                        showValidationMessage(context, 'Please fill in both email and password.');
                        return;
                      }

                      FirebaseAuth.instance
                          .signInWithEmailAndPassword(
                          email: _emailTextController.text, password: _passwordTextController.text)
                          .then((value) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => s_profile()),
                        );
                      }).onError((error, stackTrace) {
                        print("Error ${error.toString()}");

                        if (error is FirebaseAuthException) {
                          if (error.code == 'user-not-found' || error.code == 'wrong-password') {
                            showValidationMessage(context, 'Invalid email or password. Please try again.');
                          } else {
                            showValidationMessage(context, 'Sign-in failed. Please check and re-enter your email and password.');
                          }
                        }
                      });
                    }),
                    signUpOption(context),
                    SizedBox(height: 20), // Extra spacing to prevent bottom cut-off
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Sign Up Option
Row signUpOption(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text(
        "Don't have an account?",
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => home_page()),
          );
        },
        child: const Text(
          " Sign Up",
          style: TextStyle(
            color: Color(0xFFfb9798),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ],
  );
}
