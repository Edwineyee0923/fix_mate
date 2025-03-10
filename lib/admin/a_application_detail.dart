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
  String? rejectionReason;
  List<Map<String, dynamic>>? rejectionHistory = []; // Store rejection history as a list


  @override
  void initState() {
    super.initState();
    remark = widget.applicationData['remark']; // Initialize from passed data
    rejectionReason = widget.applicationData['rejectionReason'];
    var historyData = widget.applicationData['rejectionHistory'];
    if (historyData is List) {
      rejectionHistory = historyData.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      rejectionHistory = [];
    }
    _fetchApplicationDetails(); // Fetch latest data
  }


  Future<void> _fetchApplicationDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.docId)
          .get();

      setState(() {
        remark = doc['remark']; // Get the remark
        rejectionReason = doc['rejectionReason'] ?? ''; // Get the rejection reason separately
        rejectionHistory = List<Map<String, dynamic>>.from(doc['rejectionHistory'] ?? []);
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
        titleSpacing: 2,
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
            _buildRemarkCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: widget.applicationData['status'] == "Approved" || widget.applicationData['status'] == "Rejected"
                  ? [] // Hide buttons if approved or rejected
                  : [
                _buildActionButton("Reject", Color(0xFFFF9342), false, () async {
                  String? rejectionReason = await _showRejectionReasonDialog(context);
                  if (rejectionReason != null && rejectionReason.isNotEmpty) {
                    bool confirmReject = await _showConfirmationDialog(
                      context,
                      "Confirm Rejection",
                      "Are you sure you want to reject this application with the following reason?\n\n $rejectionReason",
                    );

                    if (confirmReject) {
                      _rejectApplication(rejectionReason);
                    }
                  }
                }),
          _buildActionButton("Approve", Color(0xFFFF9342), true, () async {
            bool confirm = await _showConfirmationDialog(
              context,
              "Confirm Approval", // Title
              "Are you sure you want to approve this application?", // Message
            );

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


  Future<String?> _showRejectionReasonDialog(BuildContext context) async {
    TextEditingController reasonController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9342), // Solid Orange Color
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Text(
                  "Rejection Reason",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // Input Field Section using LongInputContainer
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Please provide a reason for rejecting this application:",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),

                    // Reusing LongInputContainer
                    LongInputContainer(
                      controller: reasonController,
                      placeholder: "Enter reason...",
                      isRequired: true,
                      requiredMessage: "Reason is required.",
                      width: double.infinity,
                      height: 120,
                    ),
                  ],
                ),
              ),

              // Buttons Section
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Centers the buttons
                  children: [
                    // Cancel Button
                    SizedBox(
                      width: 100, // Compact width
                      height: 40, // Small height
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, null),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Color(0xFFFF9342), width: 1.5), // Thin border
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Smooth rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8), // Compact padding
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 16, // Set to 16
                            color: Color(0xFFFF9342), // Text color
                            fontWeight: FontWeight.w500, // Medium bold
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10), // Space between buttons
                    // Confirm Button
                    SizedBox(
                      width: 100, // Compact width
                      height: 40, // Small height
                      child: TextButton(
                        onPressed: () {
                          String enteredReason = reasonController.text.trim();
                          Navigator.pop(context, enteredReason.isNotEmpty ? enteredReason : null);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9342), // Orange background
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Smooth rounded corners
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8), // Compact padding
                        ),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(
                            fontSize: 16, // Set to 16
                            color: Colors.white, // Text color
                            fontWeight: FontWeight.w500, // Medium bold
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),


            ],
          ),
        );
      },
    );
  }


//   Future<void> _rejectApplication(String rejectionReason) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );
//
//     try {
//       String rejectionMessage = "This registration application has been sucessfully rejected.";
//
//       // Update Firestore
//       await FirebaseFirestore.instance.collection('service_providers').doc(widget.docId).update({
//         'status': 'Rejected',
//         'remark': rejectionMessage,  // Keep rejection message in remark
//         'rejectionReason': rejectionReason, // Store the rejection reason separately
//         'rejectedAt': FieldValue.serverTimestamp(), // Store rejection timestamp
//       });
//
//       setState(() {
//         remark = rejectionMessage;
//       });
//
//       // Send rejection email
//       String recipientEmail = widget.applicationData['email'];
//       String subject = "FixMate - Application Rejected";
//       String emailBody = """
// Dear ${widget.applicationData['name']},
//
// We regret to inform you that your application has been rejected.
//
// **Reason:**
// $rejectionReason
//
// For further inquiries, please contact us through this email.
//
// Best regards,
// FixMate Team
// """;
//
//       bool emailSent = await EmailService.sendEmail(recipientEmail, subject, emailBody);
//
//       if (emailSent) {
//         print("✅ Rejection email sent successfully.");
//       } else {
//         print("❌ Failed to send rejection email.");
//       }
//
//       ReusableSnackBar(
//         context,
//         "Application Rejected! Email notification sent.",
//         icon: Icons.check_circle,
//         iconColor: Colors.red,
//       );
//
//       // Delay before closing the dialog and navigating back
//       await Future.delayed(Duration(milliseconds: 200));
//
//       Navigator.pop(context); // Close loading indicator
//       Navigator.pop(context, true); // Go back and refresh the list
//
//     } catch (e) {
//       print("Error rejecting application or sending email: $e");
//       ReusableSnackBar(
//         context,
//         "Failed to update status or send notification.",
//         icon: Icons.error,
//         iconColor: Colors.red,
//       );
//     }
//   }

  Future<void> _rejectApplication(String rejectionReason) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String rejectionMessage = "This registration application has been successfully rejected.";
      Timestamp rejectionTimestamp = Timestamp.now();

      // Fetch existing rejection history safely
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.docId)
          .get();

      List<dynamic> rejectionHistory = [];

      // Check if 'rejectionHistory' exists before accessing it
      if (doc.exists && doc.data() is Map<String, dynamic>) {
        Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
        if (docData.containsKey('rejectionHistory') && docData['rejectionHistory'] is List) {
          rejectionHistory = List.from(docData['rejectionHistory']);
        }
      }

      // Append new rejection reason to history
      rejectionHistory.add({
        'reason': rejectionReason,
        'rejectedAt': rejectionTimestamp,
      });

      // Update Firestore with new rejection details
      await FirebaseFirestore.instance.collection('service_providers').doc(widget.docId).update({
        'status': 'Rejected',
        'remark': rejectionMessage,
        'rejectionHistory': rejectionHistory, // Store updated history
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        remark = rejectionMessage;
      });

      // Send rejection email
      String recipientEmail = widget.applicationData['email'];
      String subject = "FixMate - Application Rejected";
      String emailBody = """
Dear ${widget.applicationData['name']},

We regret to inform you that your application has been rejected.

**Reason:**
$rejectionReason

For further inquiries, please contact us through this email.

Best regards,  
FixMate Team
""";

      bool emailSent = await EmailService.sendEmail(recipientEmail, subject, emailBody);

      if (emailSent) {
        print("✅ Rejection email sent successfully.");
      } else {
        print("❌ Failed to send rejection email.");
      }

      ReusableSnackBar(
        context,
        "Application Rejected! Email notification sent.",
        icon: Icons.check_circle,
        iconColor: Colors.red,
      );

      // Delay before closing the dialog and navigating back
      await Future.delayed(Duration(milliseconds: 200));

      Navigator.pop(context); // Close loading indicator
      Navigator.pop(context, true); // Go back and refresh the list

    } catch (e) {
      print("Error rejecting application or sending email: $e");
      ReusableSnackBar(
        context,
        "Failed to update status or send notification.",
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }




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
        'approvedAt': FieldValue.serverTimestamp(),
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


  Future<bool> _showConfirmationDialog(
      BuildContext context,
      String title,
      String message,
      ) async {
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
                  title == "Confirm Rejection" ? Icons.cancel : Icons.how_to_reg, // Different icon for rejection
                  color: title == "Confirm Rejection" ? Colors.red : Colors.green, // Different color for rejection
                  size: 60,
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
                          backgroundColor: title == "Confirm Rejection" ? Colors.red : Colors.green, // Red for reject
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded button
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          title == "Confirm Rejection" ? "Confirm" : "Approve", // Dynamic button text
                          style: const TextStyle(
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
    ) ??
        false; // Default to false if dismissed
  }

  // Widget _buildRemarkCard() {
  //   String? displayRemark = remark ?? widget.applicationData['remark'];
  //   String? rejectionMsg = rejectionReason ?? widget.applicationData['rejectionReason'];
  //   Timestamp? rejectedAt = widget.applicationData['rejectedAt'];
  //   Timestamp? approvedAt = widget.applicationData['approvedAt'];
  //   String status = widget.applicationData['status'] ?? '';
  //
  //   // Hide the remark if the status is "Pending"
  //   if (status == "Pending" ||
  //       ((displayRemark == null || displayRemark.isEmpty) &&
  //           (status == "Rejected" && (rejectionMsg == null || rejectionMsg.isEmpty)))) {
  //     return const SizedBox(); // No remark to display
  //   }
  //
  //   // Determine title and colors based on status
  //   String title = status == "Rejected" ? "Rejection Remark:" : "Approval Remark:";
  //   Color textColor = status == "Rejected" ? Colors.red : Colors.teal;
  //   Color borderColor = status == "Rejected" ? Colors.red : Colors.teal;
  //   Color bgColor = status == "Rejected" ? Colors.red.shade50 : Colors.teal.shade50;
  //
  //   // Splitting remark into two parts
  //   List<String> remarkParts = displayRemark?.split("\n\n") ?? [];
  //   String firstPart = remarkParts.isNotEmpty ? remarkParts[0] : "";
  //   String secondPart = remarkParts.length > 1 ? remarkParts[1] : "";
  //
  //   // Format timestamps into readable date-time
  //
  //   String formatTimestamp(Timestamp? timestamp) {
  //     if (timestamp == null) return "N/A";
  //
  //     // Convert Firebase Timestamp to DateTime & adjust to local time
  //     DateTime dateTime = timestamp.toDate().toLocal();
  //
  //     // Malay month names
  //     List<String> monthNames = [
  //       "Jan", "Feb", "Mac", "Apr", "Mei", "Jun",
  //       "Jul", "Ogo", "Sep", "Okt", "Nov", "Dis"
  //     ];
  //
  //     // Format: "07 Mac 2025, 2300"
  //     String formattedDate =
  //         "${dateTime.day.toString().padLeft(2, '0')} ${monthNames[dateTime.month - 1]} ${dateTime.year}, "
  //         "${dateTime.hour.toString().padLeft(2, '0')}${dateTime.minute.toString().padLeft(2, '0')}";
  //
  //     return formattedDate;
  //   }
  //
  //
  //
  //   String timestampText = status == "Rejected"
  //       ? "Rejected At: ${formatTimestamp(rejectedAt)}"
  //       : "Approved At: ${formatTimestamp(approvedAt)}";
  //
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 16),
  //     child: Card(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         side: BorderSide(color: borderColor, width: 1.5), // Colored border
  //       ),
  //       color: bgColor, // Light background color based on status
  //       elevation: 3,
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
  //             const SizedBox(height: 4),
  //
  //             // First part with italic style
  //             Text(
  //               firstPart,
  //               style: TextStyle(
  //                 fontStyle: FontStyle.italic,
  //                 color: textColor,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //
  //             if (secondPart.isNotEmpty) const SizedBox(height: 8),
  //
  //             // Second part with normal style
  //             if (secondPart.isNotEmpty) Text(secondPart),
  //
  //             // If rejected, show the rejection reason
  //             if (status == "Rejected" && rejectionMsg != null && rejectionMsg.isNotEmpty) ...[
  //               const SizedBox(height: 10),
  //               const Text("Reason:", style: TextStyle(fontWeight: FontWeight.bold)),
  //               const SizedBox(height: 4),
  //               Text(
  //                 rejectionMsg,
  //                 style: const TextStyle(fontWeight: FontWeight.bold),
  //               ),
  //             ],
  //
  //             const SizedBox(height: 12),
  //
  //             // Timestamp Display
  //             Text(
  //               timestampText,
  //               style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildRemarkCard() {
  //   List<dynamic> rejectionHistory = [];
  //   if (widget.applicationData['rejectionHistory'] is List) {
  //     rejectionHistory = widget.applicationData['rejectionHistory'];
  //   }
  //   String? displayRemark = remark ?? widget.applicationData['remark'];
  //   String? rejectionMsg = rejectionReason ?? widget.applicationData['rejectionReason'];
  //   Timestamp? rejectedAt = widget.applicationData['rejectedAt'];
  //   Timestamp? approvedAt = widget.applicationData['approvedAt'];
  //   String status = widget.applicationData['status'] ?? '';
  //
  //   // Determine if there's a rejection history
  //   bool hasRejectionHistory = rejectionHistory.isNotEmpty;
  //
  //   // Hide the remark card if no remarks and no rejection history
  //   if (!hasRejectionHistory &&
  //       (displayRemark == null || displayRemark.isEmpty) &&
  //       (status == "Rejected" && (rejectionMsg == null || rejectionMsg.isEmpty))) {
  //     return const SizedBox();
  //   }
  //
  //   // Determine border, text, and background colors based on status
  //   Color borderColor = status == "Rejected" || hasRejectionHistory ? Colors.red : Colors.teal;
  //   Color textColor = status == "Rejected" || hasRejectionHistory ? Colors.red : Colors.teal;
  //   Color bgColor = status == "Rejected" || hasRejectionHistory ? Colors.red.shade50 : Colors.teal.shade50;
  //
  //   // Function to format timestamps
  //   String formatTimestamp(Timestamp? timestamp) {
  //     if (timestamp == null) return "N/A";
  //
  //     DateTime dateTime = timestamp.toDate().toLocal();
  //     List<String> monthNames = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ogo", "Sep", "Okt", "Nov", "Dis"];
  //
  //     return "${dateTime.day.toString().padLeft(2, '0')} ${monthNames[dateTime.month - 1]} ${dateTime.year}, "
  //         "${dateTime.hour.toString().padLeft(2, '0')}${dateTime.minute.toString().padLeft(2, '0')}";
  //   }
  //
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 16),
  //     child: Card(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //         side: BorderSide(color: borderColor, width: 1.5),
  //       ),
  //       color: bgColor,
  //       elevation: 3,
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             // Show Approval Remark if approved
  //             if (status == "Approved") ...[
  //               Text("Approval Remark:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
  //               const SizedBox(height: 4),
  //               Text(displayRemark ?? "N/A", style: const TextStyle(fontWeight: FontWeight.w500)),
  //               const SizedBox(height: 8),
  //               Text(
  //                 "Approved At: ${formatTimestamp(approvedAt)}",
  //                 style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
  //               ),
  //             ],
  //
  //             // Show Rejection History if exists
  //             if (hasRejectionHistory) ...[
  //               const SizedBox(height: 16),
  //               Text("Rejection History:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
  //               const SizedBox(height: 8),
  //               ...rejectionHistory.asMap().entries.map((entry) {
  //                 int index = entry.key + 1;
  //                 var rejection = entry.value;
  //                 return Padding(
  //                   padding: const EdgeInsets.only(bottom: 10),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text("Rejection $index:", style: const TextStyle(fontWeight: FontWeight.bold)),
  //                       const SizedBox(height: 4),
  //
  //                       // Ensure rejection is a Map before accessing its values
  //                       rejection is Map<String, dynamic>
  //                           ? Text(rejection['reason'] ?? "No reason provided",
  //                           style: const TextStyle(fontWeight: FontWeight.w500))
  //                           : const Text("No reason provided",
  //                           style: TextStyle(fontWeight: FontWeight.w500)),
  //
  //
  //                       const SizedBox(height: 4),
  //                       Text(
  //                         "Rejected At: ${formatTimestamp(rejection['rejectedAt'])}",
  //                         style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
  //                       ),
  //                       if (index < rejectionHistory.length) const Divider(),
  //                     ],
  //                   ),
  //                 );
  //               }).toList(),
  //             ],
  //
  //             // Show Current Rejection Remark if rejected
  //             if (status == "Rejected" && rejectionMsg != null && rejectionMsg.isNotEmpty) ...[
  //               const SizedBox(height: 16),
  //               Text("Rejection Remark:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
  //               const SizedBox(height: 4),
  //               Text(rejectionMsg, style: const TextStyle(fontWeight: FontWeight.w500)),
  //               const SizedBox(height: 8),
  //               Text(
  //                 "Rejected At: ${formatTimestamp(rejectedAt)}",
  //                 style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

/*  Widget _buildRemarkCard() {
    List<dynamic> rejectionHistory = [];
    if (widget.applicationData['rejectionHistory'] is List) {
      rejectionHistory = widget.applicationData['rejectionHistory'];
    }

    String? displayRemark = remark ?? widget.applicationData['remark'];
    String? rejectionMsg = rejectionReason ?? widget.applicationData['rejectionReason'];
    Timestamp? rejectedAt = widget.applicationData['rejectedAt'];
    Timestamp? approvedAt = widget.applicationData['approvedAt'];
    String status = widget.applicationData['status'] ?? '';

    bool hasRejectionHistory = rejectionHistory.isNotEmpty;
    bool hasApprovalRemark = displayRemark != null && displayRemark.isNotEmpty;
    bool hasRejectionRemark = rejectionMsg != null && rejectionMsg.isNotEmpty;

    // If no remarks or history exist, return an empty widget
    if (!hasRejectionHistory && !hasApprovalRemark && !hasRejectionRemark) {
      return const SizedBox();
    }

    Color borderColor = status == "Rejected" || hasRejectionHistory ? Colors.red : Colors.teal;
    Color textColor = status == "Rejected" || hasRejectionHistory ? Colors.red : Colors.teal;
    Color bgColor = status == "Rejected" || hasRejectionHistory ? Colors.red.shade50 : Colors.teal.shade50;

    // Function to format timestamps
    String formatTimestamp(Timestamp? timestamp) {
      if (timestamp == null) return "N/A";

      DateTime dateTime = timestamp.toDate().toLocal();
      List<String> monthNames = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ogo", "Sep", "Okt", "Nov", "Dis"];

      return "${dateTime.day.toString().padLeft(2, '0')} ${monthNames[dateTime.month - 1]} ${dateTime.year}, "
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }

    // Split the approval remark into two parts (if applicable)
    String firstPart = "";
    String secondPart = "";

    if (displayRemark != null) {
      List<String> remarkParts = displayRemark.split("\n\n");
      firstPart = remarkParts.isNotEmpty ? remarkParts[0] : "";
      secondPart = remarkParts.length > 1 ? remarkParts.sublist(1).join("\n\n") : "";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        color: bgColor,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 Show Approval Remark (if approved)
              if (status == "Approved" && hasApprovalRemark) ...[
                Text("Approval Remark:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),

                // Italic and bold first part
                Text(
                  firstPart,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (secondPart.isNotEmpty) const SizedBox(height: 8),
                if (secondPart.isNotEmpty) Text(secondPart),

                const SizedBox(height: 8),
                Text(
                  "Approved At: ${formatTimestamp(approvedAt)}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ],

              // 📌 Show Rejection Remark (if rejected)
              if (status == "Rejected") ...[
                const SizedBox(height: 16),
                Text("Rejection Remark:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 4),

                // Ensure rejection message is displayed even if it's empty
                Text(
                  rejectionMsg?.isNotEmpty == true ? rejectionMsg! : "No specific reason provided.",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),
                Text(
                  "Rejected At: ${formatTimestamp(rejectedAt)}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ],

              // 📌 Show Rejection History (if exists)
              if (hasRejectionHistory) ...[
                const SizedBox(height: 16),
                Text("Rejection History:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),

                ...rejectionHistory.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  var rejection = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rejection $index Reason:",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          rejection is Map<String, dynamic>
                              ? (rejection['reason'] ?? "No reason provided")
                              : "No reason provided",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 4),
                        Text(
                          "Rejected At: ${formatTimestamp(rejection['rejectedAt'])}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                        ),

                        if (index < rejectionHistory.length) const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }*/

/*  Widget _buildRemarkCard() {
    // Fetch values from Firebase
    List<dynamic> rejectionHistory = widget.applicationData['rejectionHistory'] ?? [];
    String? remark = widget.applicationData['remark']; // Can be either approval or rejection remark
    Timestamp? actionTimestamp = widget.applicationData['rejectedAt'] ?? widget.applicationData['approvedAt'];
    String status = widget.applicationData['status'] ?? '';

    bool hasRemark = remark != null && remark.isNotEmpty;
    bool hasRejectionHistory = rejectionHistory.isNotEmpty;

    // If no remarks or history exist, return an empty widget
    if (!hasRemark && !hasRejectionHistory) {
      return const SizedBox();
    }

    // Dynamic title based on status
    String title = status == "Rejected" ? "Rejection Remark:" : "Approval Remark:";
    Color borderColor = status == "Rejected" || hasRejectionHistory ? Colors.red : Colors.teal;
    Color textColor = status == "Rejected" || hasRejectionHistory ? Colors.red : Colors.teal;
    Color bgColor = status == "Rejected" || hasRejectionHistory ? Colors.red.shade50 : Colors.teal.shade50;

    // Function to format timestamps
    String formatTimestamp(Timestamp? timestamp) {
      if (timestamp == null) return "N/A";
      DateTime dateTime = timestamp.toDate().toLocal();
      List<String> monthNames = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ogo", "Sep", "Okt", "Nov", "Dis"];
      return "${dateTime.day.toString().padLeft(2, '0')} ${monthNames[dateTime.month - 1]} ${dateTime.year}, "
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor, width: 1.5),
        ),
        color: bgColor,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 Display Approval or Rejection Remark
              if (hasRemark) ...[
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(remark!, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  "${status == 'Rejected' ? 'Rejected' : 'Approved'} At: ${formatTimestamp(actionTimestamp)}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ],

              // 📌 Rejection History (if exists)
              if (hasRejectionHistory) ...[
                const SizedBox(height: 16),
                Text("Rejection History:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),

                ...rejectionHistory.asMap().entries.map((entry) {
                  int index = entry.key + 1;
                  var rejection = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rejection $index Reason:",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rejection is Map<String, dynamic>
                              ? (rejection['reason'] ?? "No reason provided")
                              : "No reason provided",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rejected At: ${formatTimestamp(rejection['rejectedAt'])}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                        ),
                        if (index < rejectionHistory.length) const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }*/

  Widget _buildRemarkCard() {
    // Fetch values from Firebase
    List<dynamic> rejectionHistory = widget.applicationData['rejectionHistory'] ?? [];
    String? remark = widget.applicationData['remark'];
    Timestamp? rejectedAt = widget.applicationData['rejectedAt'];
    Timestamp? approvedAt = widget.applicationData['approvedAt'];
    String status = widget.applicationData['status'] ?? '';

    bool hasRemark = remark != null && remark.isNotEmpty;
    bool hasRejectionHistory = rejectionHistory.isNotEmpty;

    // If no remarks or history exist, return an empty widget
    if (!hasRemark && !hasRejectionHistory) {
      return const SizedBox();
    }

    // Function to format timestamps
    String formatTimestamp(Timestamp? timestamp) {
      if (timestamp == null) return "N/A";
      DateTime dateTime = timestamp.toDate().toLocal();
      List<String> monthNames = ["Jan", "Feb", "Mac", "Apr", "Mei", "Jun", "Jul", "Ogo", "Sep", "Okt", "Nov", "Dis"];
      return "${dateTime.day.toString().padLeft(2, '0')} ${monthNames[dateTime.month - 1]} ${dateTime.year}, "
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    }

    if (status == "Rejected" || hasRejectionHistory) {
      // 🔴 **REJECTION UI**
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.red, width: 1.5),
          ),
          color: Colors.red.shade50,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasRemark) ...[
                  Text("Rejection Remark:", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(remark!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                ],

                // 🔥 **Rejection History**
                if (hasRejectionHistory) ...[
                  const SizedBox(height: 16),
                  const Text("Rejection History:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...rejectionHistory.asMap().entries.map((entry) {
                    int index = entry.key + 1;
                    var rejection = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Rejection $index Reason:", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            rejection is Map<String, dynamic>
                                ? (rejection['reason'] ?? "No reason provided")
                                : "No reason provided",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Rejected At: ${formatTimestamp(rejection['rejectedAt'])}",
                            style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                          ),
                          if (index < rejectionHistory.length) const Divider(color: Colors.black26, thickness: 1),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      );
    } else if (status == "Approved") {
      // 🟢 **APPROVAL UI**
      // Splitting the remark into two parts (if necessary)
      List<String> remarkParts = remark!.split("\n\n");
      String firstPart = remarkParts.isNotEmpty ? remarkParts.first : remark!;
      String secondPart = remarkParts.length > 1 ? remarkParts.sublist(1).join('. ') : '';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.teal, width: 1.5),
          ),
          color: Colors.teal.shade50,
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Approval Remark:", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),

                // 🔥 Italic & Bold first part
                Text(
                  firstPart,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                if (secondPart.isNotEmpty) const SizedBox(height: 8),
                if (secondPart.isNotEmpty)
                  Text(
                    secondPart,
                  ),

                const SizedBox(height: 8),
                Text(
                  "Approved At: ${formatTimestamp(approvedAt)}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SizedBox();
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
          backgroundColor: isFilled ? color : Colors.white,
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



