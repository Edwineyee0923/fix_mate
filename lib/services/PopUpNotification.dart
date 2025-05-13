import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

void PopUpNotification({
  required BuildContext context,
  required String title,
  required String message,
  IconData icon = Icons.campaign_rounded, // Default icon
  Color iconColor = Colors.orangeAccent, // Default icon color
}) {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    margin: const EdgeInsets.all(12),
    borderRadius: BorderRadius.circular(12),
    backgroundColor: Colors.white,
    boxShadows: [
      BoxShadow(
        color: Colors.black12,
        offset: Offset(0, 2),
        blurRadius: 6,
      ),
    ],
    icon: Icon(
      icon,
      color: iconColor,
      size: 28,
    ),
    titleText: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: 16,
      ),
    ),
    messageText: Text(
      message,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 14,
      ),
    ),
    duration: const Duration(seconds: 4),
    onTap: (_) {
      print("Notification tapped");
    },
  )..show(context);
}
