import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fix_mate/admin/SP_application.dart';
import 'package:fix_mate/admin/admin_footer.dart';
import 'package:fix_mate/admin/contact_developer.dart';
import 'package:fix_mate/home_page/home_page.dart';
import 'package:fix_mate/home_page/login_page.dart';
import 'package:fix_mate/home_page/register_option.dart';
import 'package:fix_mate/service_provider/p_profile.dart';
import 'package:fix_mate/service_provider/p_register.dart';
import 'package:fix_mate/service_seeker/s_profile.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/service_seeker/s_login.dart';
import 'package:fix_mate/service_provider/p_login.dart';
import 'package:fix_mate/home_page/reset_password.dart';
import 'package:fix_mate/home_page/login_option.dart';
import 'package:fix_mate/service_seeker/s_register.dart';
import 'package:fix_mate/routes.dart';
import 'package:fix_mate/admin/application_detail.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      routes: routes,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Poppins', // Set Poppins as the main font
      ),
      home:   SP_application(),
    );
  }
}
