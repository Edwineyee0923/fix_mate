import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static const String senderEmail = "enweiyee0923@gmail.com"; // 🔹 Your Gmail
  static const String senderPassword = "bcppfgdpnmgmuhfm"; // 🔹 Your App Password

  static Future<bool> sendEmail(String recipient, String subject, String body) async {
    final smtpServer = SmtpServer(
      'smtp.gmail.com',
      username: senderEmail,
      password: senderPassword,
      port: 587, // ✅ Use TLS (Most reliable)
      ssl: false,
      allowInsecure: true,
    );

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

void main() async {
  print("🚀 Sending test email...");

  bool emailSent = await EmailService.sendEmail(
    "enwei0923@gmail.com", // 🔹 Change to your test email
    "Test Email from FixMate",
    "Hello, this is a test email from FixMate App!",
  );

  if (emailSent) {
    print("✅ Email successfully sent!");
  } else {
    print("❌ Email failed to send.");
  }
}
