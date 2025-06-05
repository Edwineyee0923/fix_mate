import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class terms_of_service extends StatelessWidget {
  const terms_of_service({Key? key}) : super(key: key);

  void _launchEmail() async {
    final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'fixmate1168@gmail.com',
        query: 'subject=FixMate Terms of Service Inquiry&body=Hello, I have a question regarding the Terms of Service of the FixMate app...'
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Terms of Service",
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
            const Center(child: Icon(Icons.description, size: 60, color: Color(0xFFFF9342))),
            const SizedBox(height: 16),
            const Text(
              "FixMate Terms of Service",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Effective Date: 2 June 2025",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            _buildSection("1. Acceptance of Terms", "By accessing or using the FixMate app, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree, please do not use our platform."),

            _buildSection("2. Description of Services", "FixMate is a platform that connects users (service seekers) with independent service providers. We facilitate booking, payment, and communication, but are not directly involved in the service transactions."),

            _buildSection("3. User Responsibilities", "- Provide accurate and updated information during registration.\n- Maintain the confidentiality of your login credentials.\n- Use the platform only for lawful purposes.\n- Treat service providers and other users respectfully."),

            _buildSection("4. Service Provider Responsibilities", "- Deliver services as advertised and agreed.\n- Maintain professional conduct and quality.\n- Comply with local laws and safety regulations."),

            _buildSection("5. Payments and Fees", "- All payments are processed via third-party gateways like ToyyibPay.\n- FixMate may apply service or transaction fees which will be disclosed upfront.\n- Refunds and cancellations are subject to our platform policies."),

            _buildSection("6. Dispute Resolution", "We encourage users and service providers to resolve disputes amicably. FixMate may mediate but is not legally responsible for service issues unless explicitly stated."),

            _buildSection("7. Account Termination", "We reserve the right to suspend or terminate accounts that violate our terms, abuse the platform, or engage in fraudulent behavior."),

            _buildSection("8. Limitation of Liability", "FixMate is not liable for damages arising from service issues, user behavior, or third-party integrations. We do our best to ensure safety and reliability but cannot guarantee uninterrupted service."),

            _buildSection("9. Changes to Terms", "FixMate may revise these Terms of Service at any time. Continued use of the platform after changes constitutes your acceptance of the updated terms."),

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
          style: const TextStyle(fontSize: 15, height: 1.5),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}
