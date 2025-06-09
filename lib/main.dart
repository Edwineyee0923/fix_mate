// import 'package:firebase_core/firebase_core.dart';
// import 'package:fix_mate/home_page/login_page.dart';
// import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
// import 'package:fix_mate/service_provider/p_BookingCalender.dart';
// import 'package:fix_mate/service_provider/p_HomePage.dart';
// import 'package:fix_mate/service_provider/p_Rating.dart';
// import 'package:fix_mate/service_provider/p_profile.dart';
// import 'package:fix_mate/service_seeker/s_HomePage.dart';
// import 'package:fix_mate/service_seeker/s_ReviewRating/s_RateService.dart';
// import 'package:fix_mate/service_seeker/s_SPList.dart';
// import 'package:fix_mate/service_seeker/s_ReviewRating/s_SPRating.dart';
// import 'package:fix_mate/service_seeker/s_profile.dart';
// import 'package:fix_mate/service_seeker/s_register.dart';
// import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:fix_mate/home_page/HomePage.dart';
// import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'firebase_options.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fix_mate/reusable_widget/reusable_widget.dart';
//
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter bindings are initialized
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   // 👉 Add this line here
//   FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
//
//   await initializeDateFormatting('en', null); // Ensures proper date formatting for locale
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     FlutterBranchSdk.validateSDKIntegration();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _listenBranchDeepLinks();
//     });
//   }
//
//   /// Listens to Branch deep links when the app is opened via link
//   /// Listens to Branch deep links when the app is opened via link
//   void _listenBranchDeepLinks() {
//     FlutterBranchSdk.initSession().listen((data) {
//       print("🔥 Branch Deep Link Data: $data");
//
//
//       if (data.containsKey("+clicked_branch_link") && data["+clicked_branch_link"] == true) {
//         String? bookingId = data["bookingId"];
//         String? spId = data["spId"];
//         String? postId = data["postId"];
//         String? serviceSeekerId = data["serviceSeekerId"];
//
//         print("📦 bookingId: $bookingId");
//         print("📦 spId: $spId");
//         print("📦 postId: $postId");
//
//         if (bookingId != null && spId != null && postId != null && serviceSeekerId != null) {
//           _updateBookingStatus(bookingId, spId, postId, serviceSeekerId);
//         } else {
//           print("❌ Deep link payload missing required keys.");
//           _handleMissingBookingId();
//         }
//       } else {
//         print("⚠️ Not a Branch deep link or not clicked.");
//       }
//     });
//   }
//
//   void _handleMissingBookingId() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomePage()),
//       );
//       Future.delayed(const Duration(milliseconds: 300), () {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("⚠️ Invalid or expired payment link."),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       });
//     });
//   }
//
//   Future<void> _updateBookingStatus(String bookingId, String spId, String postId, String serviceSeekerId) async {
//     try {
//       final context = navigatorKey.currentContext;
//       if (context == null) {
//         print("❌ navigatorKey context is null.");
//         return;
//       }
//
//       // Show full-screen loading spinner
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         },
//       );
//
//       // Fetch booking
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('bookings')
//           .where('bookingId', isEqualTo: bookingId)
//           .limit(1)
//           .get();
//
//
//
//       if (snapshot.docs.isNotEmpty) {
//         await snapshot.docs.first.reference.update({
//           'status': 'Pending Confirmation',
//           'providerHasSeen': false, // 🔔 Add this flag
//           'updatedAt': FieldValue.serverTimestamp(),
//         });
//
//
//         // 🔔 Add a notification to Firestore for service provider
//         await FirebaseFirestore.instance.collection('p_notifications').add({
//           'providerId': spId,
//           'bookingId': bookingId,
//           'postId': postId,
//           'seekerId': serviceSeekerId,
//           'title': 'New Order Assigned\n(#$bookingId)',
//           'message': 'Please review and confirm the booking schedule. If both schedule is unavailable, kindly coordinate with the service seeker via WhatsApp to reschedule.',
//           'isRead': false,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//
//         print("✅ Booking status updated & notification sent for $bookingId");
//
//
//         await Future.delayed(Duration(milliseconds: 200));
//
//         Navigator.pop(context); // Close loading dialog
//
//         // navigatorKey.currentState?.pushNamedAndRemoveUntil(
//         //   s_BookingHistory.routeName,
//         //       (route) => false,
//         // );
//
//         navigatorKey.currentState?.pushAndRemoveUntil(
//           MaterialPageRoute(
//             builder: (_) => const s_BookingHistory(initialTabIndex: 0),
//           ),
//               (route) => false,
//         );
//
//         await Future.delayed(Duration(milliseconds: 300));
//         final postNavContext = navigatorKey.currentContext;
//         if (postNavContext != null) {
//           ReusableSnackBar(
//             context,
//             "Payment successful! Your booking has been confirmed.!",
//             icon: Icons.check_circle,
//             iconColor: Colors.green,
//           );
//           // ScaffoldMessenger.of(postNavContext).showSnackBar(
//           //   SnackBar(
//           //     content: Text("🎉 Payment successful! Your booking has been confirmed."),
//           //     backgroundColor: Colors.green,
//           //     duration: Duration(seconds: 3),
//           //   ),
//           // );
//         }
//       } else {
//         print("❌ No matching booking found for bookingId: $bookingId");
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       print("❌ Error updating booking: $e");
//       final context = navigatorKey.currentContext;
//       if (context != null) Navigator.pop(context);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'FixMate',
//       debugShowCheckedModeBanner: false,
//       routes: {
//         s_BookingHistory.routeName: (context) => const s_BookingHistory(),
//       },
//       theme: ThemeData(
//         primarySwatch: Colors.orange,
//         fontFamily: 'Poppins',
//       ),
//       home: p_HomePage(),
//     );
//   }
// }


// import 'package:firebase_core/firebase_core.dart';
// import 'package:fix_mate/home_page/login_page.dart';
// import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
// import 'package:fix_mate/service_provider/p_BookingCalender.dart';
// import 'package:fix_mate/service_provider/p_HomePage.dart';
// import 'package:fix_mate/service_provider/p_Rating.dart';
// import 'package:fix_mate/service_provider/p_profile.dart';
// import 'package:fix_mate/service_seeker/s_HomePage.dart';
// import 'package:fix_mate/service_seeker/s_ReviewRating/s_RateService.dart';
// import 'package:fix_mate/service_seeker/s_SPList.dart';
// import 'package:fix_mate/service_seeker/s_ReviewRating/s_SPRating.dart';
// import 'package:fix_mate/service_seeker/s_profile.dart';
// import 'package:fix_mate/service_seeker/s_register.dart';
// import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:fix_mate/home_page/HomePage.dart';
// import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'firebase_options.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:fix_mate/reusable_widget/reusable_widget.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
//
//
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
// FlutterLocalNotificationsPlugin();
//
// Future<void> requestExactAlarmPermission() async {
//   final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   final bool granted = await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//       ?.requestPermission() ?? false;
//
//   print("🔐 Exact alarm permission granted: $granted");
// }
//
// Future<void> showTestNotification() async {
//   await flutterLocalNotificationsPlugin.zonedSchedule(
//     0, // ID
//     '🔔 Test Reminder',
//     'This is a test notification to verify it works.',
//     tz.TZDateTime.now(tz.local).add(Duration(seconds: 5)), // Trigger in 5 seconds
//     const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'test_channel_id',
//         'Test Channel',
//         importance: Importance.max,
//         priority: Priority.high,
//         playSound: true,
//       ),
//     ),
//     androidAllowWhileIdle: true,
//     uiLocalNotificationDateInterpretation:
//     UILocalNotificationDateInterpretation.absoluteTime,
//     matchDateTimeComponents: DateTimeComponents.time, // optional for daily
//   );
//   print("✅ Test notification scheduled (5 sec)");
// }
//
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
//
//   await initializeDateFormatting('en', null);
//
//   // 🕒 Timezone setup for scheduled notifications
//   tz.initializeTimeZones();
//   await requestExactAlarmPermission(); // 🔐 Request exact alarm permission
//   await showTestNotification();
//
//   // ✅ Local Notification Initialization
//   const AndroidInitializationSettings initializationSettingsAndroid =
//   AndroidInitializationSettings('@mipmap/ic_launcher');
//
//   final InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//   );
//
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) {
//       // Optional: handle navigation or actions when user taps the notification
//       print('🔔 Notification tapped: ${response.payload}');
//     },
//   );
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatefulWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();
//     FlutterBranchSdk.validateSDKIntegration();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _listenBranchDeepLinks();
//     });
//   }
//
//   /// Listens to Branch deep links when the app is opened via link
//   /// Listens to Branch deep links when the app is opened via link
//   void _listenBranchDeepLinks() {
//     FlutterBranchSdk.initSession().listen((data) {
//       print("🔥 Branch Deep Link Data: $data");
//
//
//       if (data.containsKey("+clicked_branch_link") && data["+clicked_branch_link"] == true) {
//         String? bookingId = data["bookingId"];
//         String? spId = data["spId"];
//         String? postId = data["postId"];
//         String? serviceSeekerId = data["serviceSeekerId"];
//
//         print("📦 bookingId: $bookingId");
//         print("📦 spId: $spId");
//         print("📦 postId: $postId");
//
//         if (bookingId != null && spId != null && postId != null && serviceSeekerId != null) {
//           _updateBookingStatus(bookingId, spId, postId, serviceSeekerId);
//         } else {
//           print("❌ Deep link payload missing required keys.");
//           _handleMissingBookingId();
//         }
//       } else {
//         print("⚠️ Not a Branch deep link or not clicked.");
//       }
//     });
//   }
//
//   void _handleMissingBookingId() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomePage()),
//       );
//       Future.delayed(const Duration(milliseconds: 300), () {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("⚠️ Invalid or expired payment link."),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       });
//     });
//   }
//
//   Future<void> _updateBookingStatus(String bookingId, String spId, String postId, String serviceSeekerId) async {
//     try {
//       final context = navigatorKey.currentContext;
//       if (context == null) {
//         print("❌ navigatorKey context is null.");
//         return;
//       }
//
//       // Show full-screen loading spinner
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         },
//       );
//
//       // Fetch booking
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('bookings')
//           .where('bookingId', isEqualTo: bookingId)
//           .limit(1)
//           .get();
//
//
//
//       if (snapshot.docs.isNotEmpty) {
//         await snapshot.docs.first.reference.update({
//           'status': 'Pending Confirmation',
//           'providerHasSeen': false, // 🔔 Add this flag
//           'updatedAt': FieldValue.serverTimestamp(),
//         });
//
//
//         // 🔔 Add a notification to Firestore for service provider
//         await FirebaseFirestore.instance.collection('p_notifications').add({
//           'providerId': spId,
//           'bookingId': bookingId,
//           'postId': postId,
//           'seekerId': serviceSeekerId,
//           'title': 'New Order Assigned\n(#$bookingId)',
//           'message': 'Please review and confirm the booking schedule. If both schedule is unavailable, kindly coordinate with the service seeker via WhatsApp to reschedule.',
//           'isRead': false,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//
//         print("✅ Booking status updated & notification sent for $bookingId");
//
//
//         await Future.delayed(Duration(milliseconds: 200));
//
//         Navigator.pop(context); // Close loading dialog
//
//         // navigatorKey.currentState?.pushNamedAndRemoveUntil(
//         //   s_BookingHistory.routeName,
//         //       (route) => false,
//         // );
//
//         navigatorKey.currentState?.pushAndRemoveUntil(
//           MaterialPageRoute(
//             builder: (_) => const s_BookingHistory(initialTabIndex: 0),
//           ),
//               (route) => false,
//         );
//
//         await Future.delayed(Duration(milliseconds: 300));
//         final postNavContext = navigatorKey.currentContext;
//         if (postNavContext != null) {
//           ReusableSnackBar(
//             context,
//             "Payment successful! Your booking has been confirmed.!",
//             icon: Icons.check_circle,
//             iconColor: Colors.green,
//           );
//           // ScaffoldMessenger.of(postNavContext).showSnackBar(
//           //   SnackBar(
//           //     content: Text("🎉 Payment successful! Your booking has been confirmed."),
//           //     backgroundColor: Colors.green,
//           //     duration: Duration(seconds: 3),
//           //   ),
//           // );
//         }
//       } else {
//         print("❌ No matching booking found for bookingId: $bookingId");
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       print("❌ Error updating booking: $e");
//       final context = navigatorKey.currentContext;
//       if (context != null) Navigator.pop(context);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       title: 'FixMate',
//       debugShowCheckedModeBanner: false,
//       routes: {
//         s_BookingHistory.routeName: (context) => const s_BookingHistory(),
//       },
//       theme: ThemeData(
//         primarySwatch: Colors.orange,
//         fontFamily: 'Poppins',
//       ),
//       home: HomePage(),
//     );
//   }
// }



import 'package:firebase_core/firebase_core.dart';
import 'package:fix_mate/home_page/login_page.dart';
import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
import 'package:fix_mate/service_provider/p_BookingCalender.dart';
import 'package:fix_mate/service_provider/p_Dashboard.dart';
import 'package:fix_mate/service_provider/p_HomePage.dart';
import 'package:fix_mate/service_provider/p_ReviewRating/p_Rating.dart';
import 'package:fix_mate/service_provider/p_profile.dart';
import 'package:fix_mate/service_seeker/s_BookingCalender.dart';
import 'package:fix_mate/service_seeker/s_Dashboard.dart';
import 'package:fix_mate/service_seeker/s_HomePage.dart';
import 'package:fix_mate/service_seeker/s_ReviewRating/s_MyReview.dart';
import 'package:fix_mate/service_seeker/s_ReviewRating/s_RateService.dart';
import 'package:fix_mate/service_seeker/s_SPList.dart';
import 'package:fix_mate/service_seeker/s_ReviewRating/s_SPRating.dart';
import 'package:fix_mate/service_seeker/s_profile.dart';
import 'package:fix_mate/service_seeker/s_register.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/home_page/HomePage.dart';
import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter bindings are initialized

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👉 Add this line here
  FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);

  await initializeDateFormatting('en', null); // Ensures proper date formatting for locale
  await initializeNotifications(); // Add this


  // 🟡 Ask for exact alarm permission (only needed once)
  // await requestExactAlarmPermission();

  runApp(const MyApp());
}


// Future<void> initializeNotifications() async {
//   const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('fixmate_icon');
//
//   final InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//   );
//
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (response) {
//       // Navigate on click
//       navigatorKey.currentState?.push(
//         MaterialPageRoute(builder: (_) => const p_BookingCalender()),
//       );
//     },
//   );
// }

// // Working version for the provider site
// Future<void> initializeNotifications() async {
//   const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('fixmate_icon');
//
//   final InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//   );
//
//   // 🔐 Request notification permission explicitly (required for Android 13+)
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//       AndroidFlutterLocalNotificationsPlugin>()
//       ?.requestPermission();
//
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (response) async {
//       final payload = response.payload ?? '';
//       final parts = payload.split('|');
//       if (parts.length >= 4) {
//         final bookingId = parts[0];
//         final postId = parts[1];
//         final seekerId = parts[2];
//         final providerId = parts[3];
//
//         // Save Firestore notification only when notification is triggered
//         await FirebaseFirestore.instance.collection('p_notifications').add({
//           'providerId': providerId,
//           'bookingId': bookingId,
//           'postId': postId,
//           'seekerId': seekerId,
//           'title': 'Booking Reminder\n(#$bookingId)',
//           'message': 'Your scheduled booking service is about to start, please double check your booking details',
//           'isRead': false,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//
//         navigatorKey.currentState?.push(
//           MaterialPageRoute(
//             builder: (_) => p_BookingCalender(
//               highlightedBookingId: bookingId,
//             ),
//           ),
//         );
//       }
//     },
//   );
// }




// Working version
// Future<void> initializeNotifications() async {
//   const AndroidInitializationSettings initializationSettingsAndroid =
//   AndroidInitializationSettings('fixmate_icon');
//
//   final InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//   );
//
//   // 🔐 Request notification permission explicitly (required for Android 13+)
//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<
//       AndroidFlutterLocalNotificationsPlugin>()
//       ?.requestPermission();
//
//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (response) async {
//       final payload = response.payload ?? '';
//       final parts = payload.split('|');
//       if (parts.length >= 4) {
//         final bookingId = parts[0];
//         final postId = parts[1];
//         final seekerId = parts[2];
//         final providerId = parts[3];
//
//         // ✅ Write to provider notifications
//         await FirebaseFirestore.instance.collection('p_notifications').add({
//           'providerId': providerId,
//           'bookingId': bookingId,
//           'postId': postId,
//           'seekerId': seekerId,
//           'title': 'Booking Reminder\n(#$bookingId)',
//           'message':
//           'Your scheduled booking service is about to start, please double check your booking details',
//           'isRead': false,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//
//         // ✅ Write to seeker notifications
//         await FirebaseFirestore.instance.collection('s_notifications').add({
//           'seekerId': seekerId,
//           'providerId': providerId,
//           'bookingId': bookingId,
//           'postId': postId,
//           'title': 'Booking Reminder\n(#$bookingId)',
//           'message':
//           'Your scheduled booking service is about to start. Please check your schedule.',
//           'isRead': false,
//           'createdAt': FieldValue.serverTimestamp(),
//         });
//
//         // ✅ Detect current user role
//         final currentUserId = FirebaseAuth.instance.currentUser?.uid;
//         String role = '';
//
//         // First check service_providers
//         final providerSnap = await FirebaseFirestore.instance
//             .collection('service_providers')
//             .doc(currentUserId)
//             .get();
//
//         if (providerSnap.exists) {
//           role = 'provider';
//         } else {
//           // Then check service_seekers
//           final seekerSnap = await FirebaseFirestore.instance
//               .collection('service_seekers')
//               .doc(currentUserId)
//               .get();
//           if (seekerSnap.exists) {
//             role = 'seeker';
//           }
//         }
//
//         // ✅ Navigate to the correct calendar screen
//         if (role == 'provider') {
//           navigatorKey.currentState?.push(
//             MaterialPageRoute(
//               builder: (_) => p_BookingCalender(
//                 highlightedBookingId: bookingId,
//               ),
//             ),
//           );
//         } else if (role == 'seeker') {
//           navigatorKey.currentState?.push(
//             MaterialPageRoute(
//               builder: (_) => s_BookingCalender(
//                 highlightedBookingId: bookingId,
//               ),
//             ),
//           );
//         } else {
//           print('⚠️ Unknown user role. Could not navigate to calendar.');
//         }
//       }
//     },
//   );
// }

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('fixmate_icon');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // 🔐 Request notification permission (for Android 13+)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) async {
      final payload = response.payload ?? '';
      final parts = payload.split('|');

      if (parts.length >= 5) {
        final bookingId = parts[0];
        final postId = parts[1];
        final seekerId = parts[2];
        final providerId = parts[3];
        final reminderMinutes = parts[4]; // 👈 Duration added

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        String role = '';

        // ✅ Firestore logging (optional, if not already done during schedule)
        await FirebaseFirestore.instance.collection('p_notifications').add({
          'providerId': providerId,
          'bookingId': bookingId,
          'postId': postId,
          'seekerId': seekerId,
          'title': 'Booking Reminder\n(#$bookingId)',
          'message': 'A $reminderMinutes-minute booking reminder. Please further check your schedule.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('s_notifications').add({
          'seekerId': seekerId,
          'providerId': providerId,
          'bookingId': bookingId,
          'postId': postId,
          'title': 'Booking Reminder\n(#$bookingId)',
          'message': 'A $reminderMinutes-minute booking reminder. Please further check your schedule.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ Role detection
        final providerSnap = await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(currentUserId)
            .get();

        if (providerSnap.exists) {
          role = 'provider';
        } else {
          final seekerSnap = await FirebaseFirestore.instance
              .collection('service_seekers')
              .doc(currentUserId)
              .get();
          if (seekerSnap.exists) {
            role = 'seeker';
          }
        }

        // ✅ Navigate to calendar with booking highlighted
        if (role == 'provider') {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => p_BookingCalender(highlightedBookingId: bookingId),
            ),
          );
        } else if (role == 'seeker') {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => s_BookingCalender(highlightedBookingId: bookingId),
            ),
          );
        } else {
          print('⚠️ Unknown user role. Could not navigate to calendar.');
        }
      }
    },
  );
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
          'updatedAt': FieldValue.serverTimestamp(),
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
          ReusableSnackBar(
            context,
            "Payment successful! Your booking has been confirmed!",
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
          // ScaffoldMessenger.of(postNavContext).showSnackBar(
          //   SnackBar(
          //     content: Text("🎉 Payment successful! Your booking has been confirmed."),
          //     backgroundColor: Colors.green,
          //     duration: Duration(seconds: 3),
          //   ),
          // );
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