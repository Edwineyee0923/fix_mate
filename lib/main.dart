// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fix_mate/admin/a_SP_application.dart';
// import 'package:fix_mate/admin/a_U_inquiries.dart';
// import 'package:fix_mate/admin/admin_footer.dart';
// import 'package:fix_mate/admin/a_contact_developer.dart';
// import 'package:fix_mate/home_page/HomePage.dart';
// import 'package:fix_mate/home_page/login_page.dart';
// import 'package:fix_mate/home_page/register_option.dart';
// import 'package:fix_mate/service_provider/p_AddInstantPost.dart';
// import 'package:fix_mate/service_provider/p_HomePage.dart';
// import 'package:fix_mate/service_provider/p_footer.dart';
// import 'package:fix_mate/service_provider/p_profile.dart';
// import 'package:fix_mate/service_provider/p_register.dart';
// import 'package:fix_mate/service_seeker/s_HomePage.dart';
// import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
// import 'package:fix_mate/service_seeker/s_profile.dart';
// import 'firebase_options.dart';
// import 'package:flutter/material.dart';
// import 'package:fix_mate/service_seeker/s_login.dart';
// import 'package:fix_mate/service_provider/p_login.dart';
// import 'package:fix_mate/home_page/reset_password.dart';
// import 'package:fix_mate/home_page/login_option.dart';
// import 'package:fix_mate/service_seeker/s_register.dart';
// import 'package:fix_mate/routes.dart';
// import 'package:fix_mate/admin/a_application_detail.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       debugShowCheckedModeBanner: false,
//       routes: routes,
//       theme: ThemeData(
//         primarySwatch: Colors.orange,
//         fontFamily: 'Poppins', // Set Poppins as the main font
//       ),
//       home: HomePage(),
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/routes.dart';
import 'package:fix_mate/home_page/HomePage.dart';
import 'package:fix_mate/service_seeker/s_BookingHistory.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  /// Handles deep links when the app is opened via a dynamic link
  void _handleDeepLinks() async {
    final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
    if (data != null) {
      _processDeepLink(data.link);
    }

    FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData dynamicLink) {
      _processDeepLink(dynamicLink.link);
    }).onError((error) {
      print("🔥 Error handling deep link: $error");
    });
  }

  /// Processes deep link and updates Firestore
  void _processDeepLink(Uri link) {
    if (link.queryParameters.containsKey('bookingId')) {
      String bookingId = link.queryParameters['bookingId']!;
      _updateBookingStatus(bookingId);
    }
  }

  /// Updates Firestore booking status to "Pending Confirmation" and navigates to history screen
  Future<void> _updateBookingStatus(String bookingId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Pending Confirmation',
    });

    Navigator.pushNamed(context, s_BookingHistory.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixMate',
      debugShowCheckedModeBanner: false,
      routes: routes,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Poppins',
      ),
      home: HomePage(),
    );
  }
}
