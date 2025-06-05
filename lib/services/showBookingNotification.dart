// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter/material.dart';
//
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//
// Future<void> showBookingNotification({
//   required String title,
//   required String message,
//   required String bookingId,
//   required String postId,
//   required String seekerId,
// }) async {
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'booking_channel',
//     'Booking Updates',
//     channelDescription: 'Notifications for booking updates',
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//     icon: '@mipmap/ic_launcher',
//     sound: RawResourceAndroidNotificationSound('notification_sound'),
//   );
//
//   const NotificationDetails notificationDetails = NotificationDetails(
//     android: androidDetails,
//   );
//
//   final payload = "$bookingId|$postId|$seekerId";
//
//   await flutterLocalNotificationsPlugin.show(
//     DateTime.now().millisecondsSinceEpoch ~/ 1000,
//     title,
//     message,
//     notificationDetails,
//     payload: payload,
//   );
// }


import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> scheduleBookingReminders({
  required String bookingId,
  required String postId,
  required String seekerId,
  required String providerId,
  required DateTime finalDateTime,
}) async {
  tz.initializeTimeZones();
  final tz.TZDateTime bookingTime = tz.TZDateTime.from(finalDateTime, tz.local);

  // List<Duration> reminderOffsets = [
  //   Duration(days: 1),
  //   Duration(hours: 2),
  //   Duration(hours: 1),
  //   Duration(minutes: 30),
  // ];

  // List<Duration> reminderOffsets = [
  //   // Duration(minutes: 30),
  //   Duration(minutes: 15),
  //   Duration(minutes: 10),
  //   Duration(minutes: 5),
  // ];

  List<Duration> reminderOffsets = [
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(minutes: 1),
  ];


  for (var offset in reminderOffsets) {
    final reminderTime = bookingTime.subtract(offset);
    if (reminderTime.isAfter(DateTime.now())) {
      final notificationId = Random().nextInt(100000);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'Booking Reminder\n(#$bookingId)',
        'Your scheduled booking service is about to start, please check your booking schedule',
        tz.TZDateTime.from(reminderTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'booking_reminder_channel',
            'Booking Reminder',
            channelDescription: 'Reminders for upcoming bookings',
            sound: RawResourceAndroidNotificationSound('reminder_sound'),
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Firestore notification
      await FirebaseFirestore.instance.collection('p_notifications').add({
        'providerId': providerId,
        'bookingId': bookingId,
        'postId': postId,
        'seekerId': seekerId,
        'title': 'Booking Reminder\n(#$bookingId)',
        'message': 'Your scheduled booking service is about to start, please check your booking schedule',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("⏰ Scheduled reminder at $reminderTime for booking $bookingId");

    }
  }
}
