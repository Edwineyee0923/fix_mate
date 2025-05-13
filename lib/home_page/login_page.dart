import 'package:fix_mate/admin/a_SP_application.dart';
import 'package:fix_mate/home_page/HomePage.dart';
import 'package:fix_mate/home_page/register_option.dart';
import 'package:fix_mate/service_provider/p_HomePage.dart';
import 'package:fix_mate/service_provider/p_ResubmitApplication.dart';
import 'package:fix_mate/service_provider/p_login.dart';
import 'package:fix_mate/service_provider/p_profile.dart';
import 'package:fix_mate/service_seeker/s_HomePage.dart';
import 'package:fix_mate/service_seeker/s_login.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/service_seeker/s_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class login_page extends StatefulWidget {
  const login_page({Key? key}) : super(key: key);

  _login_pageState createState() => _login_pageState();
}

class _login_pageState extends State<login_page> {
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();
  bool _isAdminRedirected = false;

  @override
  void initState() {
    super.initState();
    // _emailTextController.addListener(_checkForAdmin);
    // _passwordTextController.addListener(_checkForAdmin);
  }

  @override
  void dispose() {
    _emailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }

  // void _checkForAdmin() {
  //   if (_emailTextController.text == "admin123@gmail.com" &&
  //       _passwordTextController.text == "fixmate123456") {
  //     if (!_isAdminRedirected) {
  //       _isAdminRedirected = true;
  //       // Delay a tick to ensure the context is stable
  //       Future.delayed(Duration.zero, () {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => SP_application()),
  //         );
  //       });
  //     }
  //   }
  // }



  // void _checkForAdmin() async {
  //   if (_emailTextController.text == "admin123@gmail.com" &&
  //       _passwordTextController.text == "fixmate123456") {
  //     if (!_isAdminRedirected) {
  //       _isAdminRedirected = true;
  //
  //       try {
  //         UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  //           email: _emailTextController.text,
  //           password: _passwordTextController.text,
  //         );
  //
  //         // 🔁 Force token refresh to get the latest admin claim
  //         await userCredential.user?.getIdToken(true);
  //
  //         final idTokenResult = await userCredential.user?.getIdTokenResult();
  //         final isAdmin = idTokenResult?.claims?['admin'] == true;
  //
  //         if (isAdmin) {
  //           print("✅ Admin authenticated, redirecting...");
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(builder: (context) => SP_application()),
  //           );
  //         } else {
  //           print("❌ Logged in, but not an admin.");
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text("You are not authorized as admin.")),
  //           );
  //         }
  //       } catch (e) {
  //         print("❌ Admin login failed: $e");
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text("Admin login failed. Please try again.")),
  //         );
  //         _isAdminRedirected = false; // Allow retry
  //       }
  //     }
  //   }
  // }

  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height, // Ensures full height
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'lib/assets/images/LoginImage.png',
                      width: 280,
                      height: 280,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 32, // Slightly larger for emphasis
                        fontWeight: FontWeight.w800, // More impactful
                        color: Colors.black87, // Slightly softer black
                        height: 1.3, // Better spacing
                        letterSpacing: 0.5, // Slightly spaced letters for readability
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 3), // Adds better separation
                    Text(
                      'Log in to continue.',
                      style: TextStyle(
                        fontSize: 22, // Slightly smaller for a balanced hierarchy
                        fontWeight: FontWeight.w500, // A bit lighter than the header
                        color: Colors.grey[800], // Softer text color
                        height: 1.2, // Optimal spacing
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 22),
                    reusableTextField(
                        "Enter Email Address", Icons.email, false, _emailTextController),
                    SizedBox(height: 10),
                    reusableTextField(
                        "Enter Password", Icons.lock_outline, true, _passwordTextController),
                    forgetPassword(context, Colors.grey,),
                    SizedBox(height: 20),
                  // pk_button(context, "Login As Service Seeker", () async {
                  //   // Basic validation of email and password
                  //   if (_emailTextController.text.isEmpty || _passwordTextController.text.isEmpty) {
                  //     showValidationMessage(context, 'Please fill in both email and password.');
                  //     return;
                  //   }
                  //
                  //   // Proceed with Firebase Authentication for a normal user
                  //   try {
                  //     UserCredential userCredential = await FirebaseAuth.instance
                  //         .signInWithEmailAndPassword(
                  //       email: _emailTextController.text,
                  //       password: _passwordTextController.text,
                  //     );
                  //
                  //     // Try to retrieve the document from the service_seekers collection
                  //     DocumentSnapshot seekerDoc = await FirebaseFirestore.instance
                  //         .collection('service_seekers')
                  //         .doc(userCredential.user!.uid)
                  //         .get();
                  //
                  //     if (seekerDoc.exists) {
                  //       String role = seekerDoc['role']; // Should be "Service Seeker"
                  //       if (role == "Service Seeker") {
                  //         // Navigate to Service Seeker dashboard
                  //         Navigator.push(
                  //           context,
                  //           MaterialPageRoute(builder: (context) => s_HomePage()),
                  //         );
                  //       } else {
                  //         showValidationMessage(
                  //             context, 'This account is not registered as a Service Seeker.');
                  //       }
                  //     } else {
                  //       // If not found in service_seekers, check the service_providers collection
                  //       DocumentSnapshot providerDoc = await FirebaseFirestore.instance
                  //           .collection('service_providers')
                  //           .doc(userCredential.user!.uid)
                  //           .get();
                  //
                  //       if (providerDoc.exists) {
                  //         // The account exists in the providers collection
                  //         showValidationMessage(
                  //             context,
                  //             'This account is registered as a Service Provider. Please use the Service Provider login.');
                  //       } else {
                  //         // Account is not found in either collection
                  //         showValidationMessage(
                  //             context,
                  //             'This account is not registered as a Service Seeker. If you don\'t have an account, please sign up.');
                  //       }
                  //     }
                  //   } catch (error) {
                  //     print("Error: ${error.toString()}");
                  //     if (error is FirebaseAuthException) {
                  //       if (error.code == 'user-not-found') {
                  //         showValidationMessage(
                  //           context,
                  //           'Email not found. If you don\'t have an account, please register.',
                  //         );
                  //       } else if (error.code == 'wrong-password') {
                  //         showValidationMessage(
                  //           context,
                  //           'The password is incorrect. Please try again.',
                  //         );
                  //       } else {
                  //         showValidationMessage(
                  //           context,
                  //             'Sign-in failed. Please check your email and password. If you don’t have an account, click Sign Up.',
                  //         );
                  //       }
                  //     }
                  //   }
                  // }),
                  // dk_button(context, "Login As Service Provider", () async {
                  //   // Basic validation of email and password
                  //   if (_emailTextController.text.isEmpty || _passwordTextController.text.isEmpty) {
                  //     showValidationMessage(context, 'Please fill in both email and password.');
                  //     return;
                  //   }
                  //
                  //   try {
                  //     UserCredential userCredential = await FirebaseAuth.instance
                  //         .signInWithEmailAndPassword(
                  //       email: _emailTextController.text,
                  //       password: _passwordTextController.text,
                  //     );
                  //
                  //     // Retrieve service provider details
                  //     DocumentSnapshot providerDoc = await FirebaseFirestore.instance
                  //         .collection('service_providers')
                  //         .doc(userCredential.user!.uid)
                  //         .get();
                  //
                  //     if (providerDoc.exists) {
                  //       String role = providerDoc['role'];
                  //       String status = providerDoc['status'];
                  //       int resubmissionCount = providerDoc['resubmissionCount'] ?? 0;
                  //
                  //       if (role == "Service Provider") {
                  //         if (status == "Approved") {
                  //           // Navigate to Service Provider dashboard
                  //           Navigator.push(
                  //             context,
                  //             MaterialPageRoute(builder: (context) => p_HomePage()),
                  //           );
                  //         } else if (status == "Rejected") {
                  //           if (resubmissionCount < 3) {
                  //             // Show confirmation dialog for resubmission
                  //             showDialog(
                  //               context: context,
                  //               builder: (context) => ConfirmationDialog(
                  //                 title: "Resubmit Application?",
                  //                 message:
                  //                 "Your application was rejected. Do you want to resubmit it based on the reason stated in your email? (Attempts left: ${3 - resubmissionCount})",
                  //                 confirmText: "Resubmit",
                  //                 cancelText: "Cancel",
                  //                 icon: Icons.warning_amber_rounded,
                  //                 iconColor: Color(0xFFFF9342),
                  //                 confirmButtonColor: Color(0xFFFF9342),
                  //                 cancelButtonColor: Colors.grey.shade300,
                  //                 onConfirm: () {
                  //                   Navigator.pop(context); // Close dialog
                  //                   Navigator.push(
                  //                     context,
                  //                     MaterialPageRoute(builder: (context) => p_ResubmitApplication()),
                  //                   );
                  //                 },
                  //               ),
                  //             );
                  //           } else {
                  //             showValidationMessage(
                  //               context,
                  //               "You have reached the maximum resubmission attempts (3). Please back to the homepage and contact the customer service.",
                  //             );
                  //           }
                  //         } else {
                  //           showValidationMessage(
                  //             context,
                  //             'Your account is not approved yet. Please wait for approval.',
                  //           );
                  //         }
                  //       } else {
                  //         showValidationMessage(
                  //           context,
                  //           'This account is not registered as a Service Provider.',
                  //         );
                  //       }
                  //     } else {
                  //       // Check if user is a service seeker
                  //       DocumentSnapshot seekerDoc = await FirebaseFirestore.instance
                  //           .collection('service_seekers')
                  //           .doc(userCredential.user!.uid)
                  //           .get();
                  //
                  //       if (seekerDoc.exists) {
                  //         showValidationMessage(
                  //           context,
                  //           'This account is registered as a Service Seeker. Please use the Service Seeker login.',
                  //         );
                  //       } else {
                  //         showValidationMessage(
                  //           context,
                  //           'This account is not registered as a Service Provider.',
                  //         );
                  //       }
                  //     }
                  //   } catch (error) {
                  //     print("Error: ${error.toString()}");
                  //     if (error is FirebaseAuthException) {
                  //       if (error.code == 'user-not-found') {
                  //         showValidationMessage(
                  //           context,
                  //           'Email not found. If you don\'t have an account, please register.',
                  //         );
                  //       } else if (error.code == 'wrong-password') {
                  //         showValidationMessage(
                  //           context,
                  //           'The password is incorrect. Please try again.',
                  //         );
                  //       } else {
                  //         showValidationMessage(
                  //           context,
                  //           'Sign-in failed. Please check your email and password. If you don’t have an account, click Sign Up.',
                  //         );
                  //       }
                  //     }                  //   }
                  // }),
                    pk_button(context, "Login", () async {
                      if (_emailTextController.text.isEmpty || _passwordTextController.text.isEmpty) {
                        showValidationMessage(context, 'Please fill in both email and password.');
                        return;
                      }

                      try {
                        UserCredential userCredential = await FirebaseAuth.instance
                            .signInWithEmailAndPassword(
                          email: _emailTextController.text,
                          password: _passwordTextController.text,
                        );

                        final uid = userCredential.user!.uid;

                        // // Check admin shortcut (or custom claim logic)
                        // if (_emailTextController.text == "admin123@gmail.com" &&
                        //     _passwordTextController.text == "fixmate123456") {
                        //   final idTokenResult = await userCredential.user?.getIdTokenResult(true);
                        //   final isAdmin = idTokenResult?.claims?['admin'] == true;
                        //   if (isAdmin) {
                        //     Navigator.pushReplacement(
                        //       context,
                        //       MaterialPageRoute(builder: (_) => SP_application()),
                        //     );
                        //     return;
                        //   }
                        // }

                        final idTokenResult = await userCredential.user?.getIdTokenResult(true);
                        final isAdmin = idTokenResult?.claims?['admin'] == true;

                        if (isAdmin) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => SP_application()),
                          );
                          return;
                        }


                        // Check service seeker
                        final seekerDoc = await FirebaseFirestore.instance.collection('service_seekers').doc(uid).get();
                        if (seekerDoc.exists) {
                          final role = seekerDoc['role'];
                          if (role == "Service Seeker") {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => s_HomePage()));
                            return;
                          }
                        }

                        // Check service provider
                        final providerDoc = await FirebaseFirestore.instance.collection('service_providers').doc(uid).get();
                        if (providerDoc.exists) {
                          final role = providerDoc['role'];
                          final status = providerDoc['status'];
                          final resubmissionCount = providerDoc['resubmissionCount'] ?? 0;

                          if (role == "Service Provider") {
                            if (status == "Approved") {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => p_HomePage()));
                            } else if (status == "Rejected") {
                              if (resubmissionCount < 3) {
                                showDialog(
                                  context: context,
                                  builder: (_) => ConfirmationDialog(
                                    title: "Resubmit Application?",
                                    message:
                                    "Your application was rejected. Do you want to resubmit it based on the reason stated in your email? "
                                        "(Attempts left: ${3 - resubmissionCount})",
                                    confirmText: "Resubmit",
                                    cancelText: "Cancel",
                                    icon: Icons.warning_amber_rounded,
                                    iconColor: Color(0xFFFF9342),
                                    confirmButtonColor: Color(0xFFFF9342),
                                    cancelButtonColor: Colors.grey.shade300,
                                    onConfirm: () {
                                      Navigator.pop(context);
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => p_ResubmitApplication()));
                                    },
                                  ),
                                );
                              } else {
                                showValidationMessage(
                                  context,
                                  "You have reached the maximum resubmission attempts (3). Please contact customer service.",
                                );
                              }
                            } else {
                              showValidationMessage(
                                context,
                                "Your account is not approved yet. Please wait for approval.",
                              );
                            }
                            return;
                          }
                        }

                        // If no valid role is found
                        showValidationMessage(
                          context,
                          'This account is not registered. Please check your login credentials or contact support.',
                        );
                      } catch (e) {
                        if (e is FirebaseAuthException) {
                          print('FirebaseAuthException code: ${e.code}'); // 🔥 Add this line

                          if (e.code == 'invalid-email') {
                            showValidationMessage(context, 'Invalid email format. Please check and try again.');
                          } else if (e.code == 'user-not-found') {
                            showValidationMessage(context, 'Email not found. Please register.');
                          } else if (e.code == 'wrong-password') {
                            showValidationMessage(context, 'Incorrect password. Please try again.');
                          } else {
                            showValidationMessage(context, 'Login failed. Please try again.');
                          }
                        }
                      }
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
        "Don't have an account? ",
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => register_option()),
          );
        },
        child: const Text(
          "Sign Up",
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w800,
            fontSize: 17,
            decoration: TextDecoration.underline,
            decorationThickness: 1.5,
          ),
        ),
      ),
    ],
  );
}
