import 'package:fix_mate/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      body: SingleChildScrollView( // Prevent overflow
        child: Container(
          width: MediaQuery
              .of(context)
              .size
              .width,
          height: MediaQuery
              .of(context)
              .size
              .height,
          color: Color(0xFFFFFFF2), // Background color
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start, // Align to top
            children: <Widget>[
              SizedBox(height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.11), // Add space from top
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'lib/assets/images/ss_register.png', // Updated image path
                      width: 290,
                      height: 290,
                    ),
                    SizedBox(height: 25),
                    Text(
                      'Login \nService Seeker Account',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2, // Controls line spacing (default is 1.0)
                      ),
                      textAlign: TextAlign.center, // Center the text
                    ),
                    SizedBox(height: 35),
                    reusableTextField("Enter Email Address", Icons.email, false,
                        _emailTextController),
                    SizedBox(height: 10),
                    reusableTextField(
                        "Enter Password", Icons.lock_outline, true,
                        _passwordTextController),
                  forgetPassword(context, Color(0xFFfb9798)),
                    SizedBox(height: 10),
                    pk_button(
                      context,
                      "Login",
                          () {
                            // Validate email and password
                            if (_emailTextController.text.isEmpty || _passwordTextController.text.isEmpty) {
                              // Show a validation message inside the UI
                              showValidationMessage(context, 'Please fill in both email and password.');
                              return; // Stop further execution if email or password is empty
                            } // Your login logic

                            // Perform Firebase authentication
                            FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                                email: _emailTextController.text, password: _passwordTextController.text)
                                .then((value) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => home_page()),
                              );
                            }).onError((error, stackTrace) {
                              print("Error ${error.toString()}");

                              // Check for specific error codes
                              if (error is FirebaseAuthException) {
                                if (error.code == 'user-not-found' || error.code == 'wrong-password') {
                                  // Handle specific error codes for incorrect email/password
                                  showValidationMessage(context, 'Invalid email or password. Please try again.');
                                } else {
                                  // Other errors, show a generic validation message
                                  showValidationMessage(context, 'Sign-in failed. Please check and re-enter your email and password.');
                                }
                              }
                            });
                      },
                    ),
                    signUpOption(context),
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
Row signUpOption(BuildContext context) { // ✅ Accept context as a parameter
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