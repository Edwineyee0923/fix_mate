import 'package:fix_mate/home_page/login_option.dart';
import 'package:fix_mate/home_page/register_option.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> sendEmail() async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: 'enweiyee0923@gmail.com',
    query: {
      'subject': Uri.encodeComponent('Issue in regard to login'),
  'body': Uri.encodeComponent(
      'Dear FixMate Admin,\n\n'
          'I hope you are doing well, but I am facing an issue when I log in to the FixMate application.\n\n'
          'Below is my email:\n'
          'Role: Service seeker/ Service Provider\n\n'
          'I would appreciate your help with this issue. Thank you.\n\n'
          'Best regards,\n'
          '[Your Name]\n'
          'User of FixMate'
      ),
    }.entries.map((e) => '${e.key}=${e.value}').join('&'),
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    print('No email app found. Opening Gmail in browser...');
    final Uri gmailUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=enweiyee0923@gmail.com'
            '&su=Issue%20in%20regard%20to%20login'
            '&body=${Uri.encodeComponent('''Dear FixMate Admin,

I hope you are doing well, but I am facing an issue when I log in to the FixMate application.

Below is my email:
Role: Service seeker/ Service Provider

I would appreciate your help with this issue. Thank you.

Best regards,
[Your Name]
User of FixMate''')}'
    );

    await launchUrl(
      gmailUri,
      mode: LaunchMode.externalApplication, // Opens in browser
    );
  }
}


class home_page extends StatefulWidget {

  const home_page({Key? key}) : super(key: key);

  _home_pageState createState() => _home_pageState();

}

class _home_pageState extends State<home_page> {
  void navigateNextPage(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) {
      return login_option();
    }));
  }

  void navigateNextPage2(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(builder: (_) {
      return register_option();
    }));
  }



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
            crossAxisAlignment: CrossAxisAlignment.center, // Centers horizontally
            children: <Widget>[
              SizedBox(height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.1), // Add space from top
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'lib/assets/images/fix_mate_logo.png', // Updated image path
                      width: 350,
                      height: 350,
                    ),
                    SizedBox(height: 20),
                  pk_button(
                    context,
                    "Login",
                        () {
                      navigateNextPage(context); // Navigate to s_login page when pressed
                    },
                  ),
                    dk_button(
                      context,
                      "Register",
                          () {
                        navigateNextPage2(context); // Navigate to s_login page when pressed
                      },
                    ),
                    SizedBox(
                      child: Center( // Ensures text is centered inside
                        child: Text(
                          'Having Trouble logging in?',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            height: 1.50,
                          ),
                        ),
                      ),
                    ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Contact ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 1.50,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => sendEmail(),
                      child: Text(
                        'Customer Service',
                        style: TextStyle(
                          color: Color(0xFF4C3532),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          decorationThickness: 2.5,
                          height: 1.50,
                        ),
                      ),
                    ),
                  ],
                ),
                    SizedBox(height: 60),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login means you agree to ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.50,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => sendEmail(),
                          child: Text(
                            'Terms of Service',
                            style: TextStyle(
                              color: Color(0xFF4C3532),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              height: 1.50,
                              decorationThickness: 2.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'and ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.50,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => sendEmail(),
                          child: Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: Color(0xFF4C3532),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              height: 1.50,
                              decorationThickness: 2.5,
                            ),
                          ),
                        ),
                      ],
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
            color: Color(0xFF464E65),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ],
  );

}