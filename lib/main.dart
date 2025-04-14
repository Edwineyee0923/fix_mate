import 'package:firebase_core/firebase_core.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
import 'package:fix_mate/service_provider/p_HomePage.dart';
import 'package:fix_mate/service_seeker/s_HomePage.dart';
import 'package:fix_mate/service_seeker/s_profile.dart';
import 'package:fix_mate/service_seeker/s_register.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/home_page/HomePage.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter bindings are initialized

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('en', null); // Ensures proper date formatting for locale

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenBranchDeepLinks();
    });
  }

  /// Listens to Branch deep links when the app is opened via link
  void _listenBranchDeepLinks() {
    FlutterBranchSdk.initSession().listen((data) {
      print("🔥 Branch Deep Link Data: $data");


      if (data.containsKey("+clicked_branch_link") && data["+clicked_branch_link"] == true) {
        String? bookingId = data["bookingId"];
        String? spId = data["spId"];
        String? postId = data["postId"];
        String? serviceSeekerId = data["serviceSeekerId"];

        print("📦 bookingId: $bookingId");
        print("📦 spId: $spId");
        print("📦 postId: $postId");

        if (bookingId != null && spId != null && postId != null && serviceSeekerId != null) {
          _updateBookingStatus(bookingId, spId, postId, serviceSeekerId);
        } else {
          print("❌ Deep link payload missing required keys.");
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

  Future<void> _updateBookingStatus(String bookingId, String spId, String postId, String serviceSeekerId) async {
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
          'providerHasSeen': false, // 🔔 Add this flag
        });


        // 🔔 Add a notification to Firestore for service provider
        await FirebaseFirestore.instance.collection('p_notifications').add({
          'providerId': spId,
          'bookingId': bookingId,
          'postId': postId,
          'seekerId': serviceSeekerId,
          'title': 'New Order Assigned\n(#$bookingId)',
          'message': 'Please review and confirm the booking schedule. If both schedule is unavailable, kindly coordinate with the service seeker via WhatsApp to reschedule.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("✅ Booking status updated & notification sent for $bookingId");


        await Future.delayed(Duration(milliseconds: 200));

        Navigator.pop(context); // Close loading dialog

        // navigatorKey.currentState?.pushNamedAndRemoveUntil(
        //   s_BookingHistory.routeName,
        //       (route) => false,
        // );

        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const s_BookingHistory(initialTabIndex: 0),
          ),
              (route) => false,
        );

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
        Navigator.pop(context);
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
      navigatorKey: navigatorKey,
      title: 'FixMate',
      debugShowCheckedModeBanner: false,
      routes: {
        s_BookingHistory.routeName: (context) => const s_BookingHistory(),
      },
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Poppins',
      ),
      home: s_HomePage(),
    );
  }
}
