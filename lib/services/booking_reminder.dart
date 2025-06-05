// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:intl/intl.dart';
// import 'package:timezone/timezone.dart' as tz;
// import '../main.dart'; // for flutterLocalNotificationsPlugin
//
// Future<void> scheduleReminders(String providerId) async {
//   final bookings = await FirebaseFirestore.instance
//       .collection('bookings')
//       .where('serviceProviderId', isEqualTo: providerId)
//       .where('status', isEqualTo: 'Active')
//       .get();
//
//   for (final doc in bookings.docs) {
//     final data = doc.data();
//     final bookingId = doc.id;
//
//     try {
//       final String date = data['finalDate']; // e.g. "5 Jun 2025"
//       final String time = data['finalTime']; // e.g. "2:30 PM"
//       final cleanedTime = time.replaceAll(RegExp(r'\s+'), ' ').trim();
//       final cleanedDate = date.trim();
//       DateTime bookingDateTime = DateFormat("d MMM yyyy h:mm a").parse('$cleanedDate $cleanedTime');
//
//
//       // final DateTime reminderTime = bookingDateTime.subtract(Duration(minutes: 30));
//       final DateTime reminderTime = bookingDateTime.subtract(Duration(minutes: 1));
//
//       if (reminderTime.isAfter(DateTime.now())) {
//         await flutterLocalNotificationsPlugin.zonedSchedule(
//           bookingId.hashCode,
//           'Upcoming Booking',
//           'Service at $time today. Get ready!',
//           tz.TZDateTime.from(reminderTime, tz.local),
//           const NotificationDetails(
//             android: AndroidNotificationDetails(
//               'booking_channel_id',
//               'Booking Reminders',
//               importance: Importance.max,
//               priority: Priority.high,
//               sound: RawResourceAndroidNotificationSound('reminder_sound'),
//             ),
//           ),
//           androidAllowWhileIdle: true,
//           uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
//           matchDateTimeComponents: DateTimeComponents.time, // optional
//         );
//         print('✅ Reminder scheduled for $bookingId');
//       }
//     } catch (e) {
//       print('❌ Error scheduling $bookingId: $e');
//     }
//   }
// }
