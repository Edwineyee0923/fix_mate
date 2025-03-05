import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:flutter/services.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> applicationData;
  final String docId;

  const ApplicationDetailsScreen({super.key,
    required this.applicationData,
    required this.docId,
  });

  @override
  _ApplicationDetailsScreenState createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {

  String? remark; // Store the remark

  @override
  void initState() {
    super.initState();
    _fetchApplicationDetails(); // Load the latest data
  }

  Future<void> _fetchApplicationDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.docId)
          .get();

      setState(() {
        remark = doc['remark']; // Get the remark from Firestore
      });
    } catch (e) {
      print("Error fetching application details: $e");
    }
  }
  bool isApproved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: Color(0xFFFF9342),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Application Details",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: widget.applicationData['profilePic'] != null
                  ? NetworkImage(widget.applicationData['profilePic'])
                  : const AssetImage("assets/default_profile.png") as ImageProvider,
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailsTable(),
                    _buildTagsRow("Expertise:", widget.applicationData['selectedExpertiseFields']),
                    _buildTagsRow("State:", widget.applicationData['selectedStates']),
                    _buildCredentialLink(widget.applicationData['certificateLink']),
                    _buildAddressRow(context, widget.applicationData['address']),
                  ],
                ),
              ),
            ),
            if (isApproved) _buildApprovalRemark(), // Show remark after approval
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton("Reject", Colors.red, () {}),
                _buildActionButton("Approve", Colors.orange, () async {
                  bool confirm = await _showConfirmationDialog(context); // Show confirmation
                  if (confirm) {
                    await _approveApplication(); // Update Firestore
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveApplication() async {
    try {
      await FirebaseFirestore.instance.collection('service_providers').doc(widget.docId).update({
        'status': 'Approved', // Change status
        'remark': 'This registration application has been successfully approved.',
      });

      setState(() {
        remark = 'This registration application has been successfully approved.'; // Update UI
        isApproved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Application Approved!")),
      );

      Navigator.pop(context, true); // Go back and refresh the list
    } catch (e) {
      print("Error updating status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update application status.")),
      );
    }
  }


  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Approval"),
          content: const Text("Are you sure you want to approve this application?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Approve"),
            ),
          ],
        );
      },
    ) ??
        false;
  }


  Widget _buildApprovalRemark() {
    if (remark == null || remark!.isEmpty) return const SizedBox(); // Hide if no remark

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Remark:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                remark!,
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.teal),
              ),
              const SizedBox(height: 8),
              const Text("The applicant meets all requirements, and the provided information is valid."),
            ],
          ),
        ),
      ),
    );
  }


  /// **Table layout for better alignment**
  Widget _buildDetailsTable() {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(140), // Fixed width for labels
        1: FlexColumnWidth(),
      },
      children: [
        _buildTableRow("Applicant Name:", widget.applicationData['name']),
        _buildTableRow("Bio:", widget.applicationData['bio']),
        _buildTableRow("Contact Number:", widget.applicationData['phone']),
        _buildTableRow("Email:", widget.applicationData['email']),
        _buildTableRow("Date of Birth:", widget.applicationData['dob']),
        _buildTableRow("Gender:", widget.applicationData['gender']),
      ],
    );
  }

  /// **Helper for building a table row**
  TableRow _buildTableRow(String title, dynamic value) {
    String formattedValue;

    if (title == "Date of Birth:" && value is String) {
      try {
        DateTime dob = DateTime.parse(value); // Convert string to DateTime
        formattedValue = DateFormat("d MMM yyyy").format(dob); // Format it as "26 Feb 1995"
      } catch (e) {
        formattedValue = value; // If parsing fails, show the original value
      }
    } else {
      formattedValue = value ?? "N/A";
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(formattedValue, textAlign: TextAlign.left),
        ),
      ],
    );
  }

  /// **Tags Row (for Expertise & State)**
  Widget _buildTagsRow(String title, dynamic values) {
    if (values == null || values is! List) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // Align titles properly
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: values
                  .map<Widget>((e) => Chip(
                label: Text(e, style: const TextStyle(color: Colors.white)),
                backgroundColor: Colors.orange,
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// **Certificate Link - Clickable URL**
  Widget _buildCredentialLink(String? url) {
    if (url == null || url.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          } else {
            debugPrint("Could not launch $url");
          }
        },
        child: Row(
          children: [
            const SizedBox(
              width: 140,
              child: Text("Credential Doc:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Text(
                "Open",
                style: const TextStyle(
                  color: Color(0xFFFF9342),
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **Address Row - With Copy Button**
  Widget _buildAddressRow(BuildContext context, String? address) {
    if (address == null || address.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns items to the top
        children: [
          SizedBox(
            width: 140, // Ensure alignment with other labels
            child: Text(
              "Address:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Row( // Wrap text and icon in a Row
              children: [
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 14),
                    softWrap: true, // Ensures text wraps properly
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Color(0xFFFF9342), size: 18), // Smaller icon
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    ReusableSnackBar(
                      context,
                      "Address copied to clipboard!",
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// **For the Approve & Reject buttons**
  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}



