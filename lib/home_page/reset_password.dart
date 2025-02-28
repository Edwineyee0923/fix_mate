import 'package:fix_mate/home_page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
                    String email = _emailTextController.text.trim();
                    if (email.isEmpty) {
                      showValidationMessage(context, 'Please enter your registered email.');
                      return;
                    }

                    // Query both collections in parallel
                    Future.wait([
                      FirebaseFirestore.instance
                          .collection('service_seekers')
                          .where('email', isEqualTo: email)
                          .get(),
                      FirebaseFirestore.instance
                          .collection('service_providers')
                          .where('email', isEqualTo: email)
                          .get(),
                    ]).then((List<QuerySnapshot> snapshots) {
                      // Check if email exists in either collection
                      final seekers = snapshots[0];
                      final providers = snapshots[1];

                      if (seekers.docs.isEmpty && providers.docs.isEmpty) {
                        // Email not found in either collection
                        showValidationMessage(context,
                            'This email is not registered. Please sign up first.');
                      } else {
                        // Email exists in at least one collection, proceed with reset
                        FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email)
                            .then((value) {
                          showSuccessMessage(
                            context,
                            'Please check your email to reset your password.',
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => home_page()),
                              );
                            },
                          );
                        }).catchError((error) {
                          showValidationMessage(context,
                              'Failed to send reset email. Please try again.');
                        });
                      }
                    }).catchError((error) {
                      showValidationMessage(
                          context, 'An error occurred. Please try again later.');
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
