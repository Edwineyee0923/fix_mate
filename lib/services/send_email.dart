import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // static const String senderEmail = "enweiyee0923@gmail.com"; // 🔹 Replace with your Gmail
  // static const String senderPassword = "bcppfgdpnmgmuhfm"; // 🔹 Use the App Password from Step 1

  static const String senderEmail = "fixmate1168@gmail.com"; // 🔹 Replace with your Gmail
  static const String senderPassword = "pqlatqkbzogxjuwi"; // 🔹 Use the App Password from Step 1

  static Future<bool> sendEmail(String recipient, String subject, String body) async {
    final smtpServer = gmail(senderEmail, senderPassword); // 🔹 Gmail SMTP server

    final message = Message()
      ..from = Address(senderEmail, "FixMate Support") // 🔹 Sender Name
      ..recipients.add(recipient) // 🔹 Recipient email
      ..subject = subject
      ..text = body;

    try {
      final sendReport = await send(message, smtpServer);
      print("✅ Email sent: ${sendReport.toString()}");
      return true;
    } catch (e) {
      print("❌ Failed to send email: $e");
      return false;
    }
  }
}
