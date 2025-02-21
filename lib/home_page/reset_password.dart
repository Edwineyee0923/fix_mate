import 'package:fix_mate/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class reset_password extends StatefulWidget {

  const reset_password({Key? key}) : super(key: key);

  _reset_passwordState createState() => _reset_passwordState();

}

class _reset_passwordState extends State<reset_password> {
  TextEditingController _emailTextController = TextEditingController();

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
                  .height * 0.1), // Add space from top
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'lib/assets/images/reset_password.png', // Updated image path
                      width: 300,
                      height: 300,
                    ),
                    SizedBox(height: 25),
                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center, // Center the text
                    ),
                    SizedBox(height: 35),
                    reusableTextField("Enter Email Address", Icons.email, false,
                        _emailTextController),
                    SizedBox(height: 20),
                a_button(
                  context,
                  "Reset Password",
                      () {
                    if (_emailTextController.text.isEmpty) {
                      // Show a validation message if the email is empty
                      showValidationMessage(context, 'Please enter your registered email.');
                      return;
                    }

                    FirebaseAuth.instance
                        .sendPasswordResetEmail(email: _emailTextController.text)
                        .then((value) {
                      // Show a dialog with a message
                      showSuccessMessage(
                        context,
                        'Please check your email to reset your password.',
                        onPressed: () {
                          // Navigate to the homepage after closing the dialog
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => home_page()),
                          );
                        },
                      );
                    }).catchError((error) {
                      // Show an error validation message
                      showValidationMessage(context, 'Failed to send reset email. Please try again.');
                    });
                  },
                ),
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
