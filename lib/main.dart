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
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/home_page/HomePage.dart';
import 'package:fix_mate/service_seeker/s_BookingHistory.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    FlutterBranchSdk.validateSDKIntegration();
    // Wait for the first frame to be fully built before listening to deep links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenBranchDeepLinks();
    });
  }

  /// Listens to Branch deep links when the app is opened via link
  void _listenBranchDeepLinks() {
    FlutterBranchSdk.initSession().listen((data) {
      print("🔥 Branch Deep Link Data: $data");

      if (data.containsKey("+clicked_branch_link") && data["+clicked_branch_link"] == true) {
        String? bookingId = data["bookingId"]; // Deep link param must match key here
        if (bookingId != null) {
          _updateBookingStatus(bookingId);
        } else {
          _handleMissingBookingId();
        }
      } else {
        print("⚠️ Not a Branch deep link or not clicked.");
      }
    });
  }

  void _handleMissingBookingId() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⚠️ Invalid or expired payment link."),
            backgroundColor: Colors.orange,
          ),
        );
      });
    });
  }

  Future<void> _updateBookingStatus(String bookingId) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        print("❌ navigatorKey context is null.");
        return;
      }

      // Show full-screen loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Fetch booking
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'status': 'Pending Confirmation',
        });

        print("✅ Booking status updated for $bookingId");

        // Delay slightly before navigating
        await Future.delayed(Duration(milliseconds: 200));

        // Close the loading dialog
        Navigator.pop(context);

        // Navigate to Booking History
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          s_BookingHistory.routeName,
              (route) => false,
        );

        // Show success SnackBar
        await Future.delayed(Duration(milliseconds: 300));
        final postNavContext = navigatorKey.currentContext;
        if (postNavContext != null) {
          ScaffoldMessenger.of(postNavContext).showSnackBar(
            SnackBar(
              content: Text("🎉 Payment successful! Your booking has been confirmed."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print("❌ No matching booking found for bookingId: $bookingId");
        Navigator.pop(context); // Close the dialog
      }
    } catch (e) {
      print("❌ Error updating booking: $e");
      final context = navigatorKey.currentContext;
      if (context != null) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Add this line
      title: 'FixMate',
      debugShowCheckedModeBanner: false,
      routes: {
        s_BookingHistory.routeName: (context) => const s_BookingHistory(),
        // other routes...
      },
      // routes: routes,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Poppins',
      ),
      home: HomePage(),
    );
  }
}
