import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';


class s_PInstantBookingDetail extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String providerId;

  const s_PInstantBookingDetail({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.providerId,
  }) : super(key: key);

  @override
  State<s_PInstantBookingDetail> createState() => _s_PInstantBookingDetailState();
}

class _s_PInstantBookingDetailState extends State<s_PInstantBookingDetail> {
  Map<String, dynamic>? bookingData;
  Map<String, dynamic>? instantPostData;
  String? providerPhone;

  bool isEditingSchedule = false;

  DateTime? _newPreferredDate;
  TimeOfDay? _newPreferredTime;
  DateTime? _newAlternativeDate;
  TimeOfDay? _newAlternativeTime;


  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      // Fetch booking info
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        bookingData = snapshot.docs.first.data() as Map<String, dynamic>;
      }


      // Fetch IP post info
      DocumentSnapshot postSnap = await FirebaseFirestore.instance.collection('instant_booking').doc(widget.postId).get();
      if (postSnap.exists) {
        instantPostData = postSnap.data() as Map<String, dynamic>;
      }

      // Fetch provider phone
      DocumentSnapshot providerSnap = await FirebaseFirestore.instance.collection('service_providers').doc(widget.providerId).get();
      if (providerSnap.exists) {
        providerPhone = providerSnap['phone'];
      }

      setState(() {});
    } catch (e) {
      print("❌ Error fetching details: $e");
    }
  }

  /// 📅 Selects a date and formats it as "29 Mac 2025"
  Future<void> _selectDate(BuildContext context, bool isPreferred) async {
    DateTime now = DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(Duration(days: 365)), // Within 1 year
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFFfb9798),
            colorScheme: ColorScheme.light(primary: Color(0xFFfb9798)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPreferred) {
          _newPreferredDate = picked;
        } else {
          if (_newPreferredDate != null && !picked.isAfter(_newPreferredDate!)) {
            ReusableSnackBar(
                context, "Alternative date must be after the preferred date.",
                icon: Icons.warning, iconColor: Colors.orange);
            return;
          }
          _newAlternativeDate = picked;
        }
      });
    }
  }



  /// ⏰ Selects a time and ensures valid selections
  Future<void> _selectTime(BuildContext context, bool isPreferred) async {
    DateTime now = DateTime.now();
    TimeOfDay nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
    TimeOfDay initialTime = TimeOfDay(hour: now.hour + 1, minute: now.minute); // Default 1 hour later
    // TimeOfDay nowTime = TimeOfDay.fromDateTime(
    //   now.add(const Duration(hours: 8)),
    // );
    // TimeOfDay initialTime = TimeOfDay.fromDateTime(
    //   now.add(const Duration(hours: 9)),
    // );
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFFfb9798),
            colorScheme: ColorScheme.light(primary: Color(0xFFfb9798)),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPreferred) {
          // 🚨 If selecting for today, ensure selected time is in the future
          if (_newPreferredDate != null &&
              _newPreferredDate!.year == now.year &&
              _newPreferredDate!.month == now.month &&
              _newPreferredDate!.day == now.day) {
            if (picked.hour < nowTime.hour || (picked.hour == nowTime.hour && picked.minute <= nowTime.minute)) {
              ReusableSnackBar(context, "Time must be in the future.",
                  icon: Icons.warning, iconColor: Colors.orange);
              return;
            }
          }
          _newPreferredTime = picked;
          _newAlternativeTime = null; // Reset alternative time if it was invalid
        } else {
          // 🚨 Ensure alternative time is after preferred time (if on the same date)
          if (_newAlternativeDate != null &&
              _newAlternativeDate!.year == _newPreferredDate!.year &&
              _newAlternativeDate!.month == _newPreferredDate!.month &&
              _newAlternativeDate!.day == _newPreferredDate!.day) {
            if (_newPreferredTime != null &&
                (picked.hour < _newPreferredTime!.hour ||
                    (picked.hour == _newPreferredTime!.hour && picked.minute <= _newPreferredTime!.minute))) {
              ReusableSnackBar(
                  context, "Alternative time must be after the preferred time.",
                  icon: Icons.warning, iconColor: Colors.orange);
              return;
            }
          }
          _newAlternativeTime = picked;
        }
      });
    }
  }


  TimeOfDay parseTimeOfDay(String timeString) {
    timeString = timeString.replaceAll(RegExp(r'\s+'), ' ').trim(); // Normalize spacing
    final format = DateFormat("h:mm a");
    final DateTime dt = format.parse(timeString);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }





  DateTime parseCustomDate(String dateStr) {
    try {
      return DateFormat("d MMM yyyy", 'en').parse(dateStr);
    } catch (e) {
      print("❌ Date parsing failed: $e");
      return DateTime.now(); // fallback
    }
  }


  /// 🗓 Formats the date to "29 Mac 2025"
  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat("d MMM yyyy", 'ms'); // 'ms' for Malay format
    return formatter.format(date);
  }

  String _formatTime(TimeOfDay time) {
    final int hour = time.hourOfPeriod; // Converts 24-hour to 12-hour format
    final String period = time.period == DayPeriod.am ? "AM" : "PM";
    return "${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period";
  }


  Future<void> _saveUpdatedSchedule() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        final timeFormat12 = DateFormat("h:mm a"); // 12-hour format

        await doc.docs.first.reference.update({
          'preferredDate': _newPreferredDate != null ? _formatDate(_newPreferredDate!) : null,
          'preferredTime': _newPreferredTime != null
              ? timeFormat12.format(DateTime(0, 1, 1, _newPreferredTime!.hour, _newPreferredTime!.minute))
              : null,
          'alternativeDate': _newAlternativeDate != null ? _formatDate(_newAlternativeDate!) : null,
          'alternativeTime': _newAlternativeTime != null
              ? timeFormat12.format(DateTime(0, 1, 1, _newAlternativeTime!.hour, _newAlternativeTime!.minute))
              : null,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Schedule updated.")),
      );

      setState(() {
        isEditingSchedule = false;
      });

      _fetchBookingDetails(); // Refresh data
    } catch (e) {
      print("Error saving schedule: $e");
    }
  }




  @override
  Widget build(BuildContext context) {
    if (bookingData == null || instantPostData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ipImages = (instantPostData!["IPImage"] != null && instantPostData!["IPImage"] is List<dynamic>)
        ? List<String>.from(instantPostData!["IPImage"])
        : [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFfb9798),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Instant Booking Detail",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Top Section
          if (ipImages.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: widget.postId)),
                );
              },
              child: Column(
                children: [
                  Image.network(ipImages[0], height: 200, fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  Text(instantPostData!["IPTitle"],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Details Section
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: bookingData!["bookingId"]));
              ReusableSnackBar(
                context,
                "Booking ID copied to clipboard!",
                icon: Icons.check_circle,
                iconColor: Colors.green,
              );
            },
            child: Text(
              "Booking ID: ${bookingData!["bookingId"]}",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          Text("Status: ${bookingData!["status"]}"),
          Text("Title: ${bookingData!["IPTitle"]}"),
          Text("Category: ${bookingData!["serviceCategory"]}"),
          // 📌 Step 1: If rescheduling sent, show finalDate/finalTime with confirmation buttons
          if (bookingData!['isRescheduling'] == true && bookingData!['rescheduleSent'] == true) ...[
            const SizedBox(height: 10),
            Text(
              "📌 Booking schedule has been reset.\nWaiting for you to confirm the new schedule.",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 10),
            Text("Final Date: ${bookingData!["finalDate"]}"),
            Text("Final Time: ${bookingData!["finalTime"]}"),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                  onPressed: () async {
                    bool? shouldProceed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Reject Reschedule"),
                        content: const Text(
                            "We are sorry as you are unavailable for the rescheduled time.\n"
                                "Please contact the provider via WhatsApp so they can reschedule again."
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Okay"),
                          ),
                        ],
                      ),
                    );

                    if (shouldProceed == true) {
                      final doc = await FirebaseFirestore.instance
                          .collection('bookings')
                          .where('bookingId', isEqualTo: widget.bookingId)
                          .limit(1)
                          .get();

                      if (doc.docs.isNotEmpty) {
                        await doc.docs.first.reference.update({
                          'status': 'Pending Confirmation',
                          'isRescheduling': true,
                          'rescheduleSent': false,
                          'providerHasSeen': false,
                        });

                        // 🔔 Notify the service provider
                        await FirebaseFirestore.instance.collection('p_notifications').add({
                          'providerId': bookingData!["serviceProviderId"],
                          'bookingId': widget.bookingId,
                          'postId': widget.postId,
                          'seekerId': bookingData?['serviceSeekerId'],
                          'title': 'Reschedule Rejected (#${widget.bookingId})',
                          'message': 'Seeker rejected the new schedule. Please coordinate with them to reset.',
                          'isRead': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("You have rejected the reschedule.")),
                        );

                        // 🔁 Redirect back to Pending tab
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => s_BookingHistory(initialTabIndex: 0),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Confirm"),
                  onPressed: () async {
                    final doc = await FirebaseFirestore.instance
                        .collection('bookings')
                        .where('bookingId', isEqualTo: widget.bookingId)
                        .limit(1)
                        .get();
                    if (doc.docs.isNotEmpty) {
                      await doc.docs.first.reference.update({
                        'status': 'Active',
                        'isRescheduling': false,
                        'rescheduleSent': false,
                        'providerHasSeen': false,
                      });

                      await FirebaseFirestore.instance.collection('p_notifications').add({
                        'providerId': bookingData!["serviceProviderId"],
                        'bookingId': widget.bookingId,
                        'postId': widget.postId,
                        'seekerId': bookingData?['serviceSeekerId'],
                        'title': 'Reschedule Approved (#${widget.bookingId})',
                        'message': 'Seeker confirmed the new schedule.',
                        'isRead': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("You have confirmed the reschedule.")),
                      );

                      // ✅ Redirect to Booking History, Active Tab
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => s_BookingHistory(initialTabIndex: 1),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ]

          // ✅ Step 2: If reschedule is rejected (rescheduleSent == false but isRescheduling still true)
          else if (bookingData!['isRescheduling'] == true && bookingData!['rescheduleSent'] == false) ...[
            Text(
              "Final Schedule (Rescheduled): ${bookingData!['finalDate']}, ${bookingData!['finalTime']}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ]

            // 🔚 Default: show the preferred + alternative date/time
          else ...[
              Text("Preferred Date: ${_formatDate(parseCustomDate(bookingData!["preferredDate"]))}"),
              Text("Preferred Time: ${_formatTime(parseTimeOfDay(bookingData!["preferredTime"]))}"),
              if (bookingData!["alternativeDate"] != null)
                Text("Alternative Date: ${_formatDate(parseCustomDate(bookingData!["alternativeDate"]))}"),
              if (bookingData!["alternativeTime"] != null)
                Text("Alternative Time: ${_formatTime(parseTimeOfDay(bookingData!["alternativeTime"]))}"),
            ],

          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: bookingData!["location"]));
              ReusableSnackBar(
                context,
                "Location copied to clipboard!",
                icon: Icons.check_circle,
                iconColor: Colors.green,
              );
            },
            child: Text(
              "Location: ${bookingData!["location"]}",
              // style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          Text("Price: RM ${bookingData!["price"]}"),
          const SizedBox(height: 12),
          if (providerPhone != null)
            ElevatedButton.icon(
              onPressed: () async {
                final url = "https://wa.me/$providerPhone";
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Contact Seller via WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

          const SizedBox(height: 24),

          if ((bookingData?['isRescheduling'] ?? false) && !(bookingData?['rescheduleSent'] ?? false)) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                "📌 You have rejected the previous schedule suggested by the provider.\n"
                    "Please contact them via WhatsApp to arrange a new time, or wait for an updated schedule to be sent.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          // Only show the edit UI if reschedule == false and isRescheduling == false
          if (!(bookingData?['sCancelled'] ?? false) &&
              !(bookingData?['rescheduleSent'] ?? false) &&
              !(bookingData?['isRescheduling'] ?? false)) ...[
            const SizedBox(height: 10),

            if (isEditingSchedule) ...[
              Text("Pick your new desired time slot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              Text("New Preferred Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              _buildDateTimePicker("Select Preferred Date", _newPreferredDate, () => _selectDate(context, true), isDate: true),
              _buildDateTimePicker("Select Preferred Time", _newPreferredTime, () => _selectTime(context, true), isDate: false),

              const SizedBox(height: 20),

              Text("New Alternative Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              _buildDateTimePicker("Select Alternative Date", _newAlternativeDate, () => _selectDate(context, false), isDate: true),
              _buildDateTimePicker("Select Alternative Time", _newAlternativeTime, () => _selectTime(context, false), isDate: false),

              const SizedBox(height: 16),

              // Buttons: Cancel and Save Changes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isEditingSchedule = false;
                        _newPreferredDate = null;
                        _newPreferredTime = null;
                        _newAlternativeDate = null;
                        _newAlternativeTime = null;
                      });
                    },
                    child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed: _saveUpdatedSchedule,
                    child: const Text("Save Changes"),
                  ),
                ],
              ),
            ]
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "📌 You can edit and reschedule the booking before service provider confirming the service.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isEditingSchedule = true;

                    // Pre-fill from existing booking data
                    _newPreferredDate = parseCustomDate(bookingData!['preferredDate']);
                    _newPreferredTime = parseTimeOfDay(bookingData!['preferredTime']);

                    _newAlternativeDate = bookingData!['alternativeDate'] != null
                        ? parseCustomDate(bookingData!['alternativeDate'])
                        : null;

                    _newAlternativeTime = bookingData!['alternativeTime'] != null
                        ? parseTimeOfDay(bookingData!['alternativeTime'])
                        : null;
                  });
                },
                child: const Text("Edit Schedule"),
              ),
            ]
          ],


          if (!(bookingData?['isRescheduling'] ?? false) && !(bookingData?['sCancelled'] ?? false)) ...[
            pk_button(context, "Request Cancellation", () async {
              showDialog(
                context: context,
                builder: (_) => ConfirmationDialog(
                  title: "Cancel Service Booking?",
                  message:
                  "Are you sure you want to cancel this service booking?\n\n⚠️ The provider may reject your request and refunds are not guaranteed.\n\n💵 RM1 transaction fee is non-refundable.\n\n📲 Please contact the provider via WhatsApp before confirming.",
                  confirmText: "Confirm",
                  cancelText: "Cancel",
                  icon: Icons.cancel,
                  iconColor: Colors.redAccent,
                  confirmButtonColor: Colors.red,
                  cancelButtonColor: Colors.grey.shade300,
                  onConfirm: () async {
                    Navigator.pop(context); // Close dialog

                    final doc = await FirebaseFirestore.instance
                        .collection('bookings')
                        .where('bookingId', isEqualTo: widget.bookingId)
                        .limit(1)
                        .get();

                    if (doc.docs.isNotEmpty) {
                      final bookingRef = doc.docs.first.reference;

                      await bookingRef.update({
                        'sCancelled': true,
                      });

                      // Send notification to provider
                      await FirebaseFirestore.instance.collection('p_notifications').add({
                        'providerId': bookingData!["serviceProviderId"],
                        'bookingId': widget.bookingId,
                        'postId': widget.postId,
                        'seekerId': bookingData?['serviceSeekerId'],
                        'title': 'Cancellation Requested',
                        'message':
                        'The service seeker has requested to cancel the booking. Please approve or reject the request.',
                        'isRead': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      ReusableSnackBar(
                        context,
                        "Cancellation request sent to provider.",
                        icon: Icons.info_outline,
                        iconColor: Colors.orange,
                      );
                    } else {
                      ReusableSnackBar(
                        context,
                        "Booking not found.",
                        icon: Icons.error_outline,
                        iconColor: Colors.red,
                      );
                    }
                  },
                ),
              );
            }),
          ],

          if (bookingData?['sCancelled'] == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6), // soft orange background
                  borderRadius: BorderRadius.circular(20), // extra rounded corners
                  border: Border.all(color: const Color(0xFFFFCC99)), // light orange border
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFFFF9900), // soft orange icon
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cancellation request sent. Please wait for the provider's decision. Thank you.",
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFFF6600), // deeper orange text
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )










        ],
      ),
    );
  }

  /// 🔹 Builds the aesthetic date/time picker UI
  Widget _buildDateTimePicker(String label, dynamic value, VoidCallback onTap, {required bool isDate}) {
    print("Value Type: ${value.runtimeType} | Value: $value");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD19C86).withOpacity(1),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),

            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value != null
                    ? (value is DateTime
                    ? _formatDate(value) // Format the date
                    : _formatTime(value as TimeOfDay)) // Format the time
                    : label, // Show hint text if value is null
                style: TextStyle(
                  color: value != null ? Colors.black : Colors.black54, // Black for selected value, Black54 for hint
                  fontWeight: value != null ? FontWeight.bold : FontWeight.normal, // Bold for real input
                  fontSize: value != null ? 16 : 14, // Keep font size 14 for consistency
                ),
              ),
              Icon(
                  isDate ? Icons.calendar_month : Icons.access_time,
                  color: Color(0xFFB87F65), size: 26
              ),
            ],
          ),
        ),
      ),
    );
  }

}
