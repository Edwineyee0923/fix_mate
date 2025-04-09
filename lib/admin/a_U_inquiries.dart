import 'package:fix_mate/admin/admin_layout.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class U_inquiries extends StatefulWidget {
  static String routeName = "/admin/U_inquiries";

  const U_inquiries({Key? key}) : super(key: key);

  @override
  _U_inquiriesState createState() => _U_inquiriesState();
}

class _U_inquiriesState extends State<U_inquiries> {

  // Function to open email
  // void _openGmail() async {
  //   final Uri gmailIntentUri = Uri.parse("intent://gmail/#Intent;scheme=android-app;package=com.google.android.gm;end;");
  //
  //   if (await canLaunchUrl(gmailIntentUri)) {
  //     await launchUrl(gmailIntentUri);
  //   } else {
  //     // Fallback to web
  //     final Uri gmailWebUri = Uri.parse("https://mail.google.com/mail/u/0/#inbox");
  //     if (await canLaunchUrl(gmailWebUri)) {
  //       await launchUrl(gmailWebUri, mode: LaunchMode.externalApplication);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Could not open Gmail.")),
  //       );
  //     }
  //   }
  // }

  void _openGmail(BuildContext context) async {
    const gmailPackageUrl = "mailto:"; // Opens available email apps (Gmail is likely default)
    final Uri gmailWebUri = Uri.parse("https://mail.google.com/mail/u/0/#inbox");

    try {
      // Try opening email apps (Gmail included if installed)
      if (await canLaunchUrl(Uri.parse(gmailPackageUrl))) {
        await launchUrl(Uri.parse(gmailPackageUrl), mode: LaunchMode.externalApplication);
      }
      // Fallback to Gmail web
      else if (await canLaunchUrl(gmailWebUri)) {
        await launchUrl(gmailWebUri, mode: LaunchMode.externalApplication);
      }
      // If everything fails
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Could not open Gmail.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to open Gmail: $e")),
      );
    }
  }





  @override
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF9342),
          title: const Text(
            "Contact Users",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          titleSpacing: 25,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 📧 Top Image Section with Shadow
              // 📧 Top Image Section with Rounded Shadow
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(80),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 310,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("lib/assets/images/email_profile.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),


              const SizedBox(height: 20),

              // 📩 Email Container with Image on Top
              GestureDetector(
                // onTap: _openGmail,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return ConfirmationDialog(
                        title: "Redirect to Gmail",
                        message: "You’ll be redirected to the FixMate Gmail inbox to view user inquiries.\n\nIf the email app opens a new message screen, simply close it to access the inbox.\n\n Please ensure also you're signed in to the official FixMate Gmail account.",
                        confirmText: "Open",
                        cancelText: "Cancel",
                        onConfirm: () {
                          _openGmail(context); // <-- Your existing email launcher
                        },
                        icon: Icons.email_outlined,
                        iconColor: Color(0xFFFF9342),
                        confirmButtonColor: Color(0xFFFF9342),
                        cancelButtonColor: Colors.grey.shade300,
                      );
                    },
                  );
                },

                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 35), // Reduced margin
                  padding: const EdgeInsets.all(12), // Reduced padding
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10), // Slightly smaller radius
                    border: Border.all(color: const Color(0xFFFF9342), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9342).withOpacity(0.3), // Lighter shadow
                        blurRadius: 6, // Reduced blur
                        spreadRadius: 3, // Reduced spread
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 📷 Image at the top
                      Image.asset(
                        "lib/assets/images/email_bottom.png",
                        width: 280, // Smaller Image
                        height: 280,
                      ),
                      const SizedBox(height: 10), // Reduced spacing

                      // 📌 Email Description
                      const Text(
                        "User Inquiries",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Smaller font
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Tap to check all user inquiries emails in Gmail (click 'OPEN' on top)",
                        style: TextStyle(fontSize: 14, color: Colors.black54), // Smaller text
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
