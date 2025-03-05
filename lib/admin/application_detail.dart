import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:flutter/services.dart';
import 'package:fix_mate/services/send_email.dart';

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
    remark = widget.applicationData['remark']; // Initialize from passed data
    _fetchApplicationDetails(); // Fetch latest data
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
  bool isLoading = true;

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
            _buildApprovalRemark(), // Show remark after approval
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.applicationData['status'] == "Approved" || widget.applicationData['status'] == "Rejected"
                  ? [] // Hide buttons if approved or rejected
                  : [
                _buildActionButton("Reject", Colors.orange, false, () {}),
                _buildActionButton("Approve", Colors.orange, true, () async {
                  bool confirm = await _showConfirmationDialog(context); // Show confirmation
                  if (confirm) {
                    await _approveApplication(); // Update Firestore
                    setState(() {}); // Refresh UI to hide buttons
                  }
                }),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Future<void> _approveApplication() async {
  //   try {
  //     String approvalRemark = "This registration application has been successfully approved.";
  //     String additionalRemark = "The applicant meets all requirements, and the provided information is valid.";
  //     String combinedRemark = "$approvalRemark\n\n$additionalRemark";
  //
  //     await FirebaseFirestore.instance.collection('service_providers').doc(widget.docId).update({
  //       'status': 'Approved', // Change status
  //       'remark': combinedRemark, // Store combined remark
  //     });
  //
  //     setState(() {
  //       remark = combinedRemark; // Update UI
  //       isApproved = true;
  //     });
  //
  //
  //     ReusableSnackBar(
  //       context,
  //       "Application Approved!",
  //       icon: Icons.check_circle,
  //       iconColor: Colors.green,
  //     );
  //     Navigator.pop(context, true); // Go back and refresh the list
  //   } catch (e) {
  //     print("Error updating status: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Failed to update application status.")),
  //     );
  //   }
  // }


  Future<void> _approveApplication() async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(), // Full-screen loading indicator
        );
      },
    );

    try {
      String approvalRemark = "This registration application has been successfully approved.";
      String additionalRemark = "The applicant meets all requirements, and the provided information is valid.";
      String combinedRemark = "$approvalRemark\n\n$additionalRemark";

      // Update Firestore
      await FirebaseFirestore.instance.collection('service_providers').doc(widget.docId).update({
        'status': 'Approved',
        'remark': combinedRemark,
      });

      setState(() {
        remark = combinedRemark;
        isApproved = true;
      });

      // Send approval email
      String recipientEmail = widget.applicationData['email']; // Get provider's email
      String subject = "FixMate - Application Approved!";
      String emailBody =
          "Dear ${widget.applicationData['name']},\n\n"
          "Congratulations! Your registration application has been approved. "
          "You can now access the FixMate platform as a verified service provider.\n\n"
          "Best regards,\nFixMate Team";

      bool emailSent = await EmailService.sendEmail(recipientEmail, subject, emailBody);

      if (emailSent) {
        print("✅ Approval email sent successfully.");
      } else {
        print("❌ Failed to send approval email.");
      }

      ReusableSnackBar(
        context,
        "Application Approved! Email notification sent.",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );

      // Add a slight delay before navigating back
      await Future.delayed(Duration(milliseconds: 200));

      Navigator.pop(context); // Close the loading screen
      Navigator.pop(context, true); // Go back and refresh the list

    } catch (e) {
      print("Error updating status or sending email: $e");
      ReusableSnackBar(
          context,
          "Failed to update status or send notification.",
          icon: Icons.error,
          iconColor: Colors.red // Red icon for error
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }




  // Future<bool> _showConfirmationDialog(BuildContext context) async {
  //   return await showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text("Confirm Approval"),
  //         content: const Text("Are you sure you want to approve this application?"),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, false),
  //             child: const Text("Cancel"),
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.pop(context, true),
  //             child: const Text("Approve"),
  //           ),
  //         ],
  //       );
  //     },
  //   ) ??
  //       false;
  // }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          elevation: 10, // Subtle shadow
          backgroundColor: Colors.white, // Background color
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.how_to_reg, // Approval icon
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 15),
                const Text(
                  "Confirm Approval",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Are you sure you want to approve this application?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false); // Return false if canceled
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300, // Light grey button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded button
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.grey), // Outlined border
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true); // Return true if confirmed
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Green approve button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded button
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Approve",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false; // Default to false if dismissed
  }

  Widget _buildApprovalRemark() {
    String? displayRemark = remark ?? widget.applicationData['remark'];
    if (displayRemark == null || displayRemark.isEmpty) return const SizedBox();

    // Splitting remark into two parts
    List<String> remarkParts = displayRemark.split("\n\n");
    String firstPart = remarkParts.isNotEmpty ? remarkParts[0] : "";
    String secondPart = remarkParts.length > 1 ? remarkParts[1] : "";

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

              // First part with italic teal style
              Text(
                firstPart,
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.teal),
              ),

              const SizedBox(height: 8),

              // Second part with normal style
              Text(secondPart),
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
  Widget _buildActionButton(String text, Color color, bool isFilled, VoidCallback onPressed) {
    return SizedBox(
      width: 150, // Ensures both buttons have the same width
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isFilled ? color : Colors.transparent,
          side: BorderSide(color: color, width: 2), // Border for outlined button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // More rounded corners
          ),
          padding: const EdgeInsets.symmetric(vertical: 14), // Keep vertical padding consistent
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            color: isFilled ? Colors.white : color, // Text color based on fill type
            fontWeight: FontWeight.w600, // Slightly bold text
          ),
        ),
      ),
    );
  }
}



