import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class privacy_policy extends StatelessWidget {
  const privacy_policy({Key? key}) : super(key: key);

  void _launchEmail() async {
    final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'fixmate1168@gmail.com',
        query: 'subject=FixMate Inquiry&body=Hello, I have a question regarding the FixMate app...'
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9342),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        titleSpacing: 5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Icon(Icons.privacy_tip, size: 60, color: Color(0xFFFF9342))),
            const SizedBox(height: 16),
            const Text(
              "FixMate Privacy Policy",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Last updated: 2 June 2025",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            _buildSection("1. Overview", "FixMate is a local service marketplace that connects users with reliable service providers. This policy outlines how we collect, use, and safeguard your data in line with Malaysian data protection laws and global best practices."),
            // Location: For nearby service suggestions and real-time updates (with permission).
            _buildSection("2. Information We Collect", "- Personal Details: Name, email, phone number, address.\n- Authentication Data: Login credentials (email/password, or social login).\n- Booking & Transaction Data: Booking history, service details, payment method.\n- Multimedia: Photos, videos, and documents uploaded with reviews or bookings.\n- Device Data: Device type, app version, crash logs, and diagnostics."),

            _buildSection("3. How We Use Your Data", "- Match you with suitable service providers.\n- Manage orders, reviews, payments, and in-app messages.\n- Enhance safety, detect fraud, and verify user legitimacy.\n- Analyze app usage to improve features and performance.\n- Notify you of bookings, promotions, or important updates."),

            _buildSection("4. Data Sharing & Third Parties", "We only share your data with trusted parties when necessary:\n- Service providers for confirmed bookings.\n- Firebase for authentication, database, push notifications.\n- ToyyibPay or other payment gateways for transactions.\n\nWe never sell or trade your personal information."),

            _buildSection("5. Your Control & Choices", "- Edit your personal information anytime from your profile.\n- View and delete your booking or review history.\n- Opt out of marketing notifications in your settings.\n- Request access or deletion of your data via email."),

            _buildSection("6. Data Security", "We use modern encryption, access controls, and monitoring to protect your data. Access to sensitive info is restricted and stored in secure cloud infrastructure."),

            _buildSection("7. Data Retention", "We retain your data only as long as your account is active or required by law. Reviews and bookings may be anonymized for analytics after account deletion."),

            _buildSection("8. Children's Privacy", "FixMate is not intended for use by individuals under the age of 13. We do not knowingly collect personal data from children."),

            _buildSection("9. Updates to this Policy", "We may occasionally update this Privacy Policy. You will be notified through the app or email for significant changes."),

            const SizedBox(height: 16),
            const Text(
              "10. Contact Us",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFFF9342)),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _launchEmail,
              child: const Text(
                "📧 fixmate1168@gmail.com",
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF9342),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}