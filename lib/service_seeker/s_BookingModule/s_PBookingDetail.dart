import 'package:fix_mate/service_seeker/s_BookingModule/s_BookingHistory.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class s_PBookingDetail extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String providerId;

  const s_PBookingDetail({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.providerId,
  }) : super(key: key);

  @override
  State<s_PBookingDetail> createState() => _s_PBookingDetailState();
}

class _s_PBookingDetailState extends State<s_PBookingDetail> {
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

  String _slotFromIndex(int index) {
    int hour = index ~/ 2;
    int minute = (index % 2) * 30;
    final period = hour < 12 ? 'AM' : 'PM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr $period';
  }

  bool _isTimeBefore(String slot, String reference) {
    final slotTime = _parseToTimeOfDay(slot);
    final refTime = _parseToTimeOfDay(reference);
    if (slotTime == null || refTime == null) return false;
    return slotTime.hour < refTime.hour ||
        (slotTime.hour == refTime.hour && slotTime.minute < refTime.minute);
  }

  bool _isTimeAfter(String slot, String reference) {
    final slotTime = _parseToTimeOfDay(slot);
    final refTime = _parseToTimeOfDay(reference);
    if (slotTime == null || refTime == null) return false;
    return slotTime.hour > refTime.hour ||
        (slotTime.hour == refTime.hour && slotTime.minute > refTime.minute);
  }

  TimeOfDay? _parseToTimeOfDay(String? timeStr) {
    if (timeStr == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s?(AM|PM)$', caseSensitive: false).firstMatch(timeStr.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  int? _indexFromSlot(String slot) {
    final time = _parseToTimeOfDay(slot);
    if (time == null) return null;
    return time.hour * 2 + (time.minute >= 30 ? 1 : 0);
  }

  Future<List<String>> getDisabledSlots(String providerId, DateTime selectedDate) async {
    final slots = <String>[];

    // 🔹 1. Get all active bookings on selected date
    final bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: providerId)
        .where('status', isEqualTo: 'Active')
        .where('finalDate', isEqualTo: DateFormat("d MMM yyyy").format(selectedDate))
        .get();

    for (var doc in bookings.docs) {
      String bookedTime = doc['finalTime'];
      slots.add(bookedTime); // main slot

      final index = _indexFromSlot(bookedTime);
      if (index != null && index < 47) {
        slots.add(_slotFromIndex(index + 1)); // buffer slot after
      }
    }

    // 🔹 2. Fetch service provider availability
    final spDoc = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(providerId)
        .get();

    final day = DateFormat('EEEE').format(selectedDate); // e.g., Monday
    final data = spDoc.data() as Map<String, dynamic>;
    final availability = data['availability'] as Map<String, dynamic>?;

    // ✅ If availability config not present at all → assume all time allowed
    if (availability == null) {
      print("✅ No availability config found — assuming fully available.");
      return slots;
    }

    // ❌ If day not configured → block all slots
    if (!availability.containsKey(day)) {
      print("⛔ No availability set for $day — disabling full day.");
      return List.generate(48, (i) => _slotFromIndex(i));
    }

    final availableStart = availability[day]['start'];
    final availableEnd = availability[day]['end'];

    // ❌ If start/end missing → block entire day
    if (availableStart == null || availableEnd == null) {
      print("⛔ Incomplete availability for $day — disabling full day.");
      return List.generate(48, (i) => _slotFromIndex(i));
    }

    // 🔸 3. Disable time slots outside availability window
    final allSlots = List.generate(48, (i) => _slotFromIndex(i));
    final outsideSlots = allSlots.where((slot) {
      return _isTimeBefore(slot, availableStart) || _isTimeAfter(slot, availableEnd);
    });

    slots.addAll(outsideSlots);
    return slots;
  }



  Future<void> _showTimeSlotSelector({
    required bool isPreferred,
    required DateTime? selectedDate,
  }) async {
    print("🟢 _showTimeSlotSelector triggered | isPreferred: $isPreferred | selectedDate: $selectedDate");

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a date first.")),
      );
      return;
    }

    // 🟨 Get the service provider ID
    final spId = widget.providerId; // ✅ correct
    if (spId == null) return;

    // 🟨 Fetch disabled slots
    final disabledSlots = await getDisabledSlots(spId, selectedDate);
    print("⏰ Time slot tapped | disabledSlots count: ${disabledSlots.length}");

    String? selectedTimeStr;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select a time slot",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TimeSlotSelector(
                selectedTime: null,
                disabledSlots: disabledSlots,
                onSelected: (selected) {
                  selectedTimeStr = selected;
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );

    if (selectedTimeStr != null) {
      setState(() {
        if (isPreferred) {
          _newPreferredTime = _parseToTimeOfDay(selectedTimeStr!);
        } else {
          _newAlternativeTime = _parseToTimeOfDay(selectedTimeStr!);
        }
      });
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
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      ReusableSnackBar(
        context,
        "Schedule updated!",
        icon: Icons.check_circle,
        iconColor: Colors.green,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      // ✅ Reroute to s_BookingHistory, tab 0 (Pending Confirmation)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => s_BookingHistory(
            key: UniqueKey(),
            initialTabIndex: 0,
          ),
        ),
      );

      setState(() {
        isEditingSchedule = false;
      });

      _fetchBookingDetails(); // Refresh data
    } catch (e) {
      print("Error saving schedule: $e");
    }
  }




  // @override
  // Widget build(BuildContext context) {
  //   if (bookingData == null || instantPostData == null) {
  //     return const Scaffold(
  //       body: Center(child: CircularProgressIndicator()),
  //     );
  //   }
  //
  //   final ipImages = (instantPostData!["IPImage"] != null && instantPostData!["IPImage"] is List<dynamic>)
  //       ? List<String>.from(instantPostData!["IPImage"])
  //       : [];
  //
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFFFF8F2),
  //     appBar: AppBar(
  //       backgroundColor: const Color(0xFFfb9798),
  //       leading: IconButton(
  //         icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
  //         onPressed: () => Navigator.pop(context),
  //       ),
  //       title: Text(
  //         "Booking Summary Detail",
  //         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
  //       ),
  //       titleSpacing: 5,
  //     ),
  //     body: ListView(
  //       padding: const EdgeInsets.all(16),
  //       children: [
  //         // Top Section
  //         if (ipImages.isNotEmpty)
  //           GestureDetector(
  //             onTap: () {
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: widget.postId)),
  //               );
  //             },
  //             child: Column(
  //               children: [
  //                 Image.network(ipImages[0], height: 200, fit: BoxFit.cover),
  //                 const SizedBox(height: 10),
  //                 Text(instantPostData!["IPTitle"],
  //                     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
  //               ],
  //             ),
  //           ),
  //
  //         const SizedBox(height: 24),
  //
  //         // Details Section
  //         GestureDetector(
  //           onLongPress: () {
  //             Clipboard.setData(ClipboardData(text: bookingData!["bookingId"]));
  //             ReusableSnackBar(
  //               context,
  //               "Booking ID copied to clipboard!",
  //               icon: Icons.check_circle,
  //               iconColor: Colors.green,
  //             );
  //           },
  //           child: Text(
  //             "Booking ID: ${bookingData!["bookingId"]}",
  //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //           ),
  //         ),
  //
  //         Text("Status: ${bookingData!["status"]}"),
  //         Text("Title: ${bookingData!["IPTitle"]}"),
  //         Text("Category: ${bookingData!["serviceCategory"]}"),
  //
  //         if (bookingData!['isRescheduling'] == true && bookingData!['rescheduleSent'] == true) ...[
  //           const SizedBox(height: 10),
  //           Container(
  //             margin: const EdgeInsets.symmetric(horizontal: 0),
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(16),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.05),
  //                   blurRadius: 6,
  //                   offset: const Offset(0, 3),
  //                 ),
  //               ],
  //             ),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // 🟧 Orange Info Box
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Container(
  //                       width: MediaQuery.of(context).size.width * 0.82, // Adjust as needed
  //                       padding: const EdgeInsets.all(14),
  //                       decoration: BoxDecoration(
  //                         color: Colors.orange.withOpacity(0.08),
  //                         border: Border.all(color: Colors.orange),
  //                         borderRadius: BorderRadius.circular(12),
  //                       ),
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           const Text(
  //                             "📌 Booking schedule has been reset.\nWaiting for you to confirm the new schedule.",
  //                             style: TextStyle(
  //                               fontSize: 14,
  //                               fontWeight: FontWeight.w600,
  //                               color: Colors.orange,
  //                             ),
  //                           ),
  //                           const SizedBox(height: 12),
  //                           Text(
  //                             "📅 Final Date: ${bookingData!["finalDate"]}",
  //                             style: const TextStyle(fontSize: 14),
  //                           ),
  //                           Text(
  //                             "⏰ Final Time: ${bookingData!["finalTime"]}",
  //                             style: const TextStyle(fontSize: 14),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 15),
  //                 🔘 Action Buttons
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     // Reject Button
  //                     OutlinedButton(
  //                       onPressed: () async {
  //                         bool? shouldProceed = await showDialog<bool>(
  //                           context: context,
  //                           builder: (_) => Dialog(
  //                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //                             backgroundColor: Colors.white,
  //                             child: Padding(
  //                               padding: const EdgeInsets.all(20.0),
  //                               child: Column(
  //                                 mainAxisSize: MainAxisSize.min,
  //                                 children: [
  //                                   Icon(Icons.schedule_outlined, color: Color(0xFFfb9798), size: 60),
  //                                   const SizedBox(height: 15),
  //                                   const Text(
  //                                     "Reject Reschedule",
  //                                     style: TextStyle(
  //                                       fontSize: 22,
  //                                       fontWeight: FontWeight.bold,
  //                                       color: Colors.black87,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(height: 10),
  //                                   const Text(
  //                                     "You’re unavailable at the new time. Please message the provider on WhatsApp to suggest another slot.",
  //                                     textAlign: TextAlign.center,
  //                                     style: TextStyle(fontSize: 16, color: Colors.black54),
  //                                   ),
  //                                   const SizedBox(height: 20),
  //                                   Row(
  //                                     children: [
  //                                       Expanded(
  //                                         child: OutlinedButton(
  //                                           onPressed: () => Navigator.pop(context, false),
  //                                           style: OutlinedButton.styleFrom(
  //                                             backgroundColor: Colors.grey.shade100,
  //                                             shape: RoundedRectangleBorder(
  //                                               borderRadius: BorderRadius.circular(30),
  //                                             ),
  //                                             side: const BorderSide(color: Colors.grey),
  //                                             padding: const EdgeInsets.symmetric(vertical: 12),
  //                                           ),
  //                                           child: const Text(
  //                                             "Cancel",
  //                                             style: TextStyle(
  //                                               fontSize: 16,
  //                                               fontWeight: FontWeight.bold,
  //                                               color: Colors.black87,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       const SizedBox(width: 10),
  //                                       Expanded(
  //                                         child: ElevatedButton(
  //                                           onPressed: () => Navigator.pop(context, true), // Returns true
  //                                           style: ElevatedButton.styleFrom(
  //                                             backgroundColor: Color(0xFFfb9798),
  //                                             shape: RoundedRectangleBorder(
  //                                               borderRadius: BorderRadius.circular(30),
  //                                             ),
  //                                             padding: const EdgeInsets.symmetric(vertical: 12),
  //                                           ),
  //                                           child: const Text(
  //                                             "Okay",
  //                                             style: TextStyle(
  //                                               fontSize: 16,
  //                                               fontWeight: FontWeight.bold,
  //                                               color: Colors.white,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   )
  //                                 ],
  //                               ),
  //                             ),
  //                           )
  //                         );
  //
  //                         if (shouldProceed == true) {
  //                           final doc = await FirebaseFirestore.instance
  //                               .collection('bookings')
  //                               .where('bookingId', isEqualTo: widget.bookingId)
  //                               .limit(1)
  //                               .get();
  //
  //                           if (doc.docs.isNotEmpty) {
  //                             await doc.docs.first.reference.update({
  //                               'status': 'Pending Confirmation',
  //                               'isRescheduling': true,
  //                               'rescheduleSent': false,
  //                               'providerHasSeen': false,
  //                               'updatedAt': FieldValue.serverTimestamp(),
  //                             });
  //
  //                             await FirebaseFirestore.instance.collection('p_notifications').add({
  //                               'providerId': bookingData!["serviceProviderId"],
  //                               'bookingId': widget.bookingId,
  //                               'postId': widget.postId,
  //                               'seekerId': bookingData?['serviceSeekerId'],
  //                               'title': 'Reschedule Rejected\n(#${widget.bookingId})',
  //                               'message': 'Seeker rejected the new schedule. Please coordinate with them to reset.',
  //                               'isRead': false,
  //                               'createdAt': FieldValue.serverTimestamp(),
  //                             });
  //
  //                             ReusableSnackBar(
  //                               context,
  //                               "You have rejected the reschedule!",
  //                               icon: Icons.check_circle,
  //                               iconColor: Colors.green,
  //                             );
  //
  //                             Navigator.pushReplacement(
  //                               context,
  //                               MaterialPageRoute(builder: (_) => s_BookingHistory(initialTabIndex: 0)),
  //                             );
  //                           }
  //                         }
  //                       },
  //                       style: OutlinedButton.styleFrom(
  //                         side: const BorderSide(color: Color(0xFFfb9798), width: 2),
  //                         foregroundColor: Color(0xFFfb9798),
  //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  //                         padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
  //                       ),
  //                       child: const Text(
  //                         "Reject",
  //                         style: TextStyle(
  //                           fontSize: 16, // or 18 if you want it to match the Confirm button
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 14),
  //                     // Confirm Button
  //                     ElevatedButton(
  //                       onPressed: () async {
  //                         final doc = await FirebaseFirestore.instance
  //                             .collection('bookings')
  //                             .where('bookingId', isEqualTo: widget.bookingId)
  //                             .limit(1)
  //                             .get();
  //
  //                         if (doc.docs.isNotEmpty) {
  //                           await doc.docs.first.reference.update({
  //                             'status': 'Active',
  //                             'isRescheduling': false,
  //                             'rescheduleSent': false,
  //                             'providerHasSeen': false,
  //                             'updatedAt': FieldValue.serverTimestamp(),
  //                           });
  //
  //                           await FirebaseFirestore.instance.collection('p_notifications').add({
  //                             'providerId': bookingData!["serviceProviderId"],
  //                             'bookingId': widget.bookingId,
  //                             'postId': widget.postId,
  //                             'seekerId': bookingData?['serviceSeekerId'],
  //                             'title': 'Reschedule Approved\n(#${widget.bookingId})',
  //                             'message': 'Seeker confirmed the new schedule.',
  //                             'isRead': false,
  //                             'createdAt': FieldValue.serverTimestamp(),
  //                           });
  //
  //                           ReusableSnackBar(
  //                             context,
  //                             "Reschedule confirmed sucessfully!",
  //                             icon: Icons.check_circle,
  //                             iconColor: Colors.green,
  //                           );
  //
  //
  //                           Navigator.pushReplacement(
  //                             context,
  //                             MaterialPageRoute(builder: (_) => s_BookingHistory(initialTabIndex: 1)),
  //                           );
  //                         }
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Color(0xFFfb9798),
  //                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  //                         padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 12),
  //                       ),
  //                       child: const Text(
  //                         "Confirm",
  //                         style: TextStyle(
  //                           fontSize: 16, // ⬅️ Adjust this value as needed (e.g., 16–18 for buttons)
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.white,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //           const SizedBox(height: 10),
  //         ]
  //
  //
  //         // ✅ Step 2: If reschedule is rejected (rescheduleSent == false but isRescheduling still true)
  //         else if (bookingData!['isRescheduling'] == true && bookingData!['rescheduleSent'] == false) ...[
  //           Text(
  //             "Final Schedule (Rescheduled): ${bookingData!['finalDate']}, ${bookingData!['finalTime']}",
  //             style: TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //         ]
  //
  //           // 🔚 Default: show the preferred + alternative date/time
  //         else ...[
  //             Text(
  //               "Preferred Schedule: ${_formatDate(parseCustomDate(bookingData!["preferredDate"]))}, ${_formatTime(parseTimeOfDay(bookingData!["preferredTime"]))}",
  //             ),
  //             if (bookingData!["alternativeDate"] != null && bookingData!["alternativeTime"] != null)
  //               Text(
  //                 "Alternative Schedule: ${_formatDate(parseCustomDate(bookingData!["alternativeDate"]))}, ${_formatTime(parseTimeOfDay(bookingData!["alternativeTime"]))}",
  //               ),
  //           ],
  //
  //         GestureDetector(
  //           onLongPress: () {
  //             Clipboard.setData(ClipboardData(text: bookingData!["location"]));
  //             ReusableSnackBar(
  //               context,
  //               "Location copied to clipboard!",
  //               icon: Icons.check_circle,
  //               iconColor: Colors.green,
  //             );
  //           },
  //           child: Text(
  //             "Location: ${bookingData!["location"]}",
  //             // style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //           ),
  //         ),
  //
  //         Text("Price: RM ${bookingData!["price"]}"),
  //         const SizedBox(height: 12),
  //         if (providerPhone != null)
  //           ElevatedButton.icon(
  //             onPressed: () async {
  //               final url = "https://wa.me/$providerPhone";
  //               if (await canLaunch(url)) {
  //                 await launch(url);
  //               }
  //             },
  //             icon: const Icon(Icons.chat_bubble_outline),
  //             label: const Text("Contact Seller via WhatsApp"),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green,
  //               foregroundColor: Colors.white,
  //             ),
  //           ),
  //
  //         const SizedBox(height: 24),
  //
  //         if ((bookingData?['isRescheduling'] ?? false) && !(bookingData?['rescheduleSent'] ?? false)) ...[
  //           Padding(
  //             padding: const EdgeInsets.only(bottom: 10),
  //             child: Text(
  //               "📌 You have rejected the previous schedule suggested by the provider.\n"
  //                   "Please contact them via WhatsApp to arrange a new time, or wait for an updated schedule to be sent.",
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 color: Colors.orange.shade700,
  //                 fontStyle: FontStyle.italic,
  //               ),
  //             ),
  //           ),
  //         ],
  //
  //
  //         if (!(bookingData?['sCancelled'] ?? false) &&
  //             !(bookingData?['rescheduleSent'] ?? false) &&
  //             !(bookingData?['isRescheduling'] ?? false)) ...[
  //           const SizedBox(height: 10),
  //
  //           if (isEditingSchedule) ...[
  //             Card(
  //               elevation: 2,
  //               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //               margin: const EdgeInsets.only(bottom: 16),
  //               child: Padding(
  //                 padding: const EdgeInsets.all(16),
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text("Pick your new desired time slot",
  //                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
  //                     const SizedBox(height: 16),
  //
  //                     /// Preferred Section
  //                     Row(
  //                       children: [
  //                         Icon(Icons.calendar_today, size: 18, color: Colors.blue),
  //                         const SizedBox(width: 6),
  //                         Text("New Preferred Date & Time",
  //                             style:
  //                             TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 10),
  //                     _buildDateTimePicker("Select Preferred Date", _newPreferredDate,
  //                             () => _selectDate(context, true),
  //                         isDate: true),
  //                     _buildDateTimePicker(
  //                       "Select Preferred Time",
  //                       _newPreferredTime,
  //                           () => _showTimeSlotSelector(
  //                         isPreferred: true,
  //                         selectedDate: _newPreferredDate,
  //                       ),
  //                       isDate: false,
  //                     ),
  //
  //                     const SizedBox(height: 20),
  //                     Divider(
  //                       color: Colors.grey.shade400,
  //                       thickness: 1.5, // or try 2.0 for more thickness
  //                     ),
  //                     const SizedBox(height: 16),
  //
  //                     /// Alternative Section
  //                     Row(
  //                       children: [
  //                         Icon(Icons.schedule, size: 18, color: Colors.teal),
  //                         const SizedBox(width: 6),
  //                         Text("New Alternative Date & Time",
  //                             style:
  //                             TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 10),
  //                     _buildDateTimePicker("Select Alternative Date", _newAlternativeDate,
  //                             () => _selectDate(context, false),
  //                         isDate: true),
  //                     _buildDateTimePicker(
  //                       "Select Alternative Time",
  //                       _newAlternativeTime,
  //                           () => _showTimeSlotSelector(
  //                         isPreferred: false,
  //                         selectedDate: _newAlternativeDate,
  //                       ),
  //                       isDate: false,
  //                     ),
  //
  //                     const SizedBox(height: 20),
  //
  //                     //Action Button
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.center,
  //                       children: [
  //                         SizedBox(
  //                           width: 150,
  //                           child: OutlinedButton(
  //                             onPressed: () {
  //                               setState(() {
  //                                 isEditingSchedule = false;
  //                                 _newPreferredDate = null;
  //                                 _newPreferredTime = null;
  //                                 _newAlternativeDate = null;
  //                                 _newAlternativeTime = null;
  //                               });
  //                             },
  //                             style: OutlinedButton.styleFrom(
  //                               foregroundColor: Color(0xFFfb9798),
  //                               side: BorderSide(color: Color(0xFFfb9798)),
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(30),
  //                               ),
  //                               padding: const EdgeInsets.symmetric(vertical: 14),
  //                             ),
  //                             child: const Text(
  //                               "Cancel",
  //                               style: TextStyle(
  //                                 fontSize: 16,
  //                                 fontWeight: FontWeight.bold,
  //                               ),
  //                             ),
  //
  //                           ),
  //                         ),
  //                         const SizedBox(width: 16),
  //                         SizedBox(
  //                           width: 150,
  //                           child: ElevatedButton(
  //                             onPressed: _saveUpdatedSchedule,
  //                             style: ElevatedButton.styleFrom(
  //                               backgroundColor: Color(0xFFfb9798),
  //                               foregroundColor: Colors.white,
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(30),
  //                               ),
  //                               padding: const EdgeInsets.symmetric(vertical: 12),
  //                             ),
  //                             child: const Text(
  //                               "Save Changes",
  //                               style: TextStyle(
  //                                 fontSize: 16,            // Increased font size
  //                                 fontWeight: FontWeight.bold, // Make it bold
  //                               ),
  //                             ),
  //
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //
  //
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ] else ...[
  //             /// Reschedule Notice + Button
  //             Container(
  //               padding: const EdgeInsets.all(12),
  //               margin: const EdgeInsets.only(bottom: 10),
  //               decoration: BoxDecoration(
  //                 color: Colors.orange.shade50,
  //                 border: Border.all(color: Colors.orange.shade200),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Row(
  //                 children: [
  //                   Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       "You can edit and reschedule the booking before the service provider confirms.",
  //                       style: TextStyle(
  //                           fontSize: 14,
  //                           color: Colors.orange.shade800,
  //                           fontStyle: FontStyle.italic),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             pk_button(context, "Edit Schedule", () {
  //               setState(() {
  //                 isEditingSchedule = true;
  //
  //                 // Pre-fill from existing booking data
  //                 _newPreferredDate = parseCustomDate(bookingData!['preferredDate']);
  //                 _newPreferredTime = parseTimeOfDay(bookingData!['preferredTime']);
  //
  //                 _newAlternativeDate = bookingData!['alternativeDate'] != null
  //                     ? parseCustomDate(bookingData!['alternativeDate'])
  //                     : null;
  //
  //                 _newAlternativeTime = bookingData!['alternativeTime'] != null
  //                     ? parseTimeOfDay(bookingData!['alternativeTime'])
  //                     : null;
  //               });
  //             }),
  //
  //           ]
  //         ],
  //
  //
  //         if (!(bookingData?['isRescheduling'] ?? false) && !(bookingData?['sCancelled'] ?? false)) ...[
  //           pk_button(context, "Request Cancellation", () async {
  //             final result = await showModalBottomSheet(
  //               context: context,
  //               isScrollControlled: true,
  //               shape: const RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //               ),
  //               builder: (_) => CancelReasonBottomSheet(
  //                 bookingId: widget.bookingId,
  //                 postId: widget.postId,
  //                 seekerId: bookingData!['serviceSeekerId'],
  //                 providerId: bookingData!['serviceProviderId'],
  //               ),
  //             );
  //
  //             // ✅ Now that the sheet is closed and returned result
  //             if (result == true) {
  //               Navigator.pushReplacement(
  //                 context,
  //                 MaterialPageRoute(
  //                   builder: (_) => s_BookingHistory(
  //                     key: UniqueKey(),
  //                     initialTabIndex: 0, // Go to Pending tab
  //                   ),
  //                 ),
  //               );
  //             }
  //           }),
  //         ],
  //
  //         if (bookingData?['sCancelled'] == true)
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
  //             child: Container(
  //               width: double.infinity,
  //               padding: const EdgeInsets.all(14),
  //               decoration: BoxDecoration(
  //                 color: const Color(0xFFFFF7E6), // soft orange background
  //                 borderRadius: BorderRadius.circular(20), // extra rounded corners
  //                 border: Border.all(color: const Color(0xFFFFCC99)), // light orange border
  //               ),
  //               child: Row(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Icon(
  //                     Icons.info_outline,
  //                     color: const Color(0xFFFF9900), // soft orange icon
  //                     size: 18,
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       "Cancellation request sent. Please wait for the provider's decision. Thank you.",
  //                       style: const TextStyle(
  //                         fontSize: 14,
  //                         fontStyle: FontStyle.italic,
  //                         color: Color(0xFFFF6600), // deeper orange text
  //                         height: 1.4,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           )
  //       ],
  //     ),
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    if (bookingData == null || instantPostData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ipImages = (instantPostData!["IPImage"] != null && instantPostData!["IPImage"] is List)
        ? (instantPostData!["IPImage"] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfb9798),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pending Booking Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildServiceHeaderCard(ipImages),
            const SizedBox(height: 16),
            _buildBookingInfoCard(),
            const SizedBox(height: 16),
            _buildScheduleSection(),
            if (bookingData?['isRescheduling'] == true) ...[
              const SizedBox(height: 16),
            ],
            if (providerPhone != null) _buildContactSection(),
            const SizedBox(height: 16),
            _buildEditSection(),
            const SizedBox(height: 5),
           _buildCancellationSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHeaderCard(List<String> ipImages) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          if (ipImages.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: widget.postId)),
                );
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(ipImages[0]),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instantPostData!["IPTitle"] ?? "Service Title",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfb9798).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          bookingData!["serviceCategory"] ?? "Category",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFfb9798),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBookingInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.receipt_long, color: Color(0xFFfb9798), size: 24),
                SizedBox(width: 12),
                Text(
                  "Booking Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFfb9798),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Booking ID
            _buildInfoRow(
              "Booking ID",
              bookingData!["bookingId"],
              icon: Icons.confirmation_number,
              copyable: true,
              copyMessage: "Booking ID copied to clipboard!",
            ),

            // Status
            _buildInfoRow(
              "Status",
              bookingData!["status"],
              icon: Icons.info_outline,
              statusBadge: true,
            ),

            // Schedule Information
            _buildScheduleInfo(),

            // Location
            _buildInfoRow(
              "Location",
              bookingData!["location"],
              icon: Icons.location_on,
              copyable: true,
              copyMessage: "Location copied to clipboard!",
            ),

            // Price
            _buildInfoRow(
              "Total Price",
              "RM ${bookingData!["price"]}",
              icon: Icons.payments,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow(
      String label,
      String value, {
        IconData? icon,
        bool copyable = false,
        String? copyMessage,
        bool statusBadge = false,
        bool highlight = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: const Color(0xFFfb9798)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                const SizedBox(height: 4),
                statusBadge
                    ? _buildStatusBadge(value)
                    : Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                    color: highlight ? const Color(0xFFfb9798) : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ReusableSnackBar(
                  context,
                  copyMessage ?? "Copied to clipboard!",
                  icon: Icons.check_circle,
                  iconColor: Colors.green,
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8.0, top: 2),
                child: Icon(Icons.copy, size: 16, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildScheduleInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, color: Color(0xFFfb9798), size: 20),
              SizedBox(width: 8),
              Text(
                "Schedule Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFfb9798),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (bookingData?['isRescheduling'] == true) ...[
            _buildScheduleItem(
              "Final Schedule (Rescheduled)",
              "${_formatDate(parseCustomDate(bookingData!["finalDate"]))
    }, ${_formatTime(parseTimeOfDay(bookingData!["finalTime"]))}",
              isConfirmed: true,
            ),
          ] else ...[
            _buildScheduleItem(
              "Preferred Schedule",
              "${_formatDate(parseCustomDate(bookingData!["preferredDate"]))}, ${ _formatTime(parseTimeOfDay(bookingData!["preferredTime"]))}",
              isPrimary: true,
            ),
            if (bookingData!["alternativeDate"] != null && bookingData!["alternativeTime"] != null)
              _buildScheduleItem(
                "Alternative Schedule",
                "${_formatDate(parseCustomDate(bookingData!["alternativeDate"]))
                }, ${_formatTime(parseTimeOfDay(bookingData!["alternativeTime"]))
                }",
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String label, String dateTime, {bool isPrimary = false, bool isConfirmed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConfirmed ? const Color(0xFFfb9798) :
              isPrimary ? const Color(0xFFfb9798) : const Color(0xFF95A5A6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
                Text(
                  dateTime,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isConfirmed ? const Color(0xFF27AE60) : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = const Color(0xFF10B981); // Modern emerald green
        textColor = Colors.white;
        break;
      case 'active':
        backgroundColor = const Color(0xFF3B82F6); // Bright blue
        textColor = Colors.white;
        break;
      case 'pending confirmation':
        backgroundColor = const Color(0xFFF39C12);
        textColor = Colors.white;
        break;
      case 'cancelled':
        backgroundColor = const Color(0xFFE74C3C);
        textColor = Colors.white;
        break;
      default:
        backgroundColor = const Color(0xFF95A5A6);
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }


  Widget _buildScheduleSection() {
    final bool isRescheduling = bookingData?['isRescheduling'] == true;
    final bool rescheduleSent = bookingData?['rescheduleSent'] == true;

    // 🔕 Return nothing if no rescheduling involved
    if (!isRescheduling) return const SizedBox.shrink();

    // 🟧 Case 1: New schedule proposed – Confirm/Reject
    if (rescheduleSent) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  "📌 New Schedule Proposed by Provider",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Please review the updated schedule and confirm or reject it below.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "📅 Final Date: ${_formatDate(parseCustomDate(bookingData!["finalDate"]))}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      "⏰ Final Time: ${_formatTime(parseTimeOfDay(bookingData!["finalTime"]))}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ❌ Reject
                  OutlinedButton(
                    onPressed: () async {
                      final shouldProceed = await showDialog<bool>(
                        context: context,
                        builder: (_) => Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_outlined, color: Color(0xFFfb9798), size: 60),
                                const SizedBox(height: 15),
                                const Text(
                                  "Reject Reschedule",
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "You’re unavailable at the new time. Please message the provider on WhatsApp to suggest another slot.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16, color: Colors.black54),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.grey),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          backgroundColor: Colors.grey.shade100,
                                        ),
                                        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFfb9798),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text("Okay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
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
                            'updatedAt': FieldValue.serverTimestamp(),
                          });

                          await FirebaseFirestore.instance.collection('p_notifications').add({
                            'providerId': bookingData!["serviceProviderId"],
                            'bookingId': widget.bookingId,
                            'postId': widget.postId,
                            'seekerId': bookingData?['serviceSeekerId'],
                            'title': 'Reschedule Rejected\n(#${widget.bookingId})',
                            'message': 'Seeker rejected the new schedule. Please coordinate with them to reset.',
                            'isRead': false,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          ReusableSnackBar(
                            context,
                            "You have rejected the reschedule!",
                            icon: Icons.check_circle,
                            iconColor: Colors.green,
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => s_BookingHistory(initialTabIndex: 0)),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFfb9798), width: 2),
                      foregroundColor: const Color(0xFFfb9798),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 14),
                  // ✅ Confirm
                  ElevatedButton(
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
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        await FirebaseFirestore.instance.collection('p_notifications').add({
                          'providerId': bookingData!["serviceProviderId"],
                          'bookingId': widget.bookingId,
                          'postId': widget.postId,
                          'seekerId': bookingData?['serviceSeekerId'],
                          'title': 'Reschedule Approved\n(#${widget.bookingId})',
                          'message': 'Seeker confirmed the new schedule.',
                          'isRead': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        ReusableSnackBar(
                          context,
                          "Reschedule confirmed successfully!",
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => s_BookingHistory(initialTabIndex: 1)),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfb9798),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: const Text("Confirm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 🔁 Case 2: Rejected schedule – informative message
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: const [
                Icon(Icons.schedule_outlined, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Text(
                  "Schedule Rejected",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "⏳ You have rejected the schedule suggested by the provider.",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please contact the provider to arrange a new booking or wait for a new schedule suggestion.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }



  Widget _buildScheduleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFfb9798),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    if (!(bookingData?['sCancelled'] ?? false) &&
        !(bookingData?['rescheduleSent'] ?? false) &&
        !(bookingData?['isRescheduling'] ?? false)) {
      if (isEditingSchedule) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pick your new desired time slot",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Preferred Date & Time
                Row(
                  children: const [
                    Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                    SizedBox(width: 6),
                    Text("New Preferred Date & Time",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDateTimePicker(
                  "Select Preferred Date",
                  _newPreferredDate,
                      () => _selectDate(context, true),
                  isDate: true,
                ),
                _buildDateTimePicker(
                  "Select Preferred Time",
                  _newPreferredTime,
                      () => _showTimeSlotSelector(
                    isPreferred: true,
                    selectedDate: _newPreferredDate,
                  ),
                  isDate: false,
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade400, thickness: 1.5),
                const SizedBox(height: 16),

                // Alternative Date & Time
                Row(
                  children: const [
                    Icon(Icons.schedule, size: 18, color: Colors.teal),
                    SizedBox(width: 6),
                    Text("New Alternative Date & Time",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildDateTimePicker(
                  "Select Alternative Date",
                  _newAlternativeDate,
                      () => _selectDate(context, false),
                  isDate: true,
                ),
                _buildDateTimePicker(
                  "Select Alternative Time",
                  _newAlternativeTime,
                      () => _showTimeSlotSelector(
                    isPreferred: false,
                    selectedDate: _newAlternativeDate,
                  ),
                  isDate: false,
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            isEditingSchedule = false;
                            _newPreferredDate = null;
                            _newPreferredTime = null;
                            _newAlternativeDate = null;
                            _newAlternativeTime = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFfb9798),
                          side: const BorderSide(color: Color(0xFFfb9798)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 150,
                      child: ElevatedButton(
                        onPressed: _saveUpdatedSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFfb9798),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else {
        // Edit Schedule Container with Title
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: const [
                    Icon(Icons.edit_calendar, color: Color(0xFFfb9798), size: 24),
                    SizedBox(width: 12),
                    Text(
                      "Edit Schedule",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        // color: Color(0xFFfb9798),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reschedule notice
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFfb9798).withOpacity(0.08),
                    border: Border.all(color: const Color(0xFFfb9798)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.info_outline, size: 20, color: Color(0xFFfb9798)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "You can edit and reschedule the booking before the service provider confirms.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFfb9798),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Schedule Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
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
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text("Edit Schedule"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFfb9798),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      return const SizedBox.shrink();
    }
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
  Widget _buildContactSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.chat, color: Color(0xFF25D366), size: 24),
                SizedBox(width: 12),
                Text(
                  "Contact Provider",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = "https://wa.me/$providerPhone";
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text("Message via WhatsApp"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancellationSection() {
    if (!(bookingData?['isRescheduling'] ?? false) && !(bookingData?['sCancelled'] ?? false)) {
      // Show cancellation request option
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: const [
                  Icon(Icons.cancel_outlined, color: Color(0xFFfb9798), size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Request Cancellation",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      // color: Color(0xFFfb9798),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cancellation notice
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFfb9798).withOpacity(0.08),
                  border: Border.all(color: const Color(0xFFfb9798)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, size: 20, color: Color(0xFFfb9798)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Please contact with the provider before you request to cancel this booking as the provider will decide on the refund cancellation decision",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFfb9798),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Request Cancellation Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => CancelReasonBottomSheet(
                        bookingId: widget.bookingId,
                        postId: widget.postId,
                        seekerId: bookingData!['serviceSeekerId'],
                        providerId: bookingData!['serviceProviderId'],
                      ),
                    );

                    // ✅ Now that the sheet is closed and returned result
                    if (result == true) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => s_BookingHistory(
                            key: UniqueKey(),
                            initialTabIndex: 0, // Go to Pending tab
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text("Request Cancellation"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFfb9798),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (bookingData?['sCancelled'] == true) {
      // Show cancellation request sent status
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: const [
                  Icon(Icons.pending_actions, color: Color(0xFFFF9900), size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Cancellation Requested",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      // color: Color(0xFFFF9900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  border: Border.all(color: const Color(0xFFFFCC99)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, size: 20, color: Color(0xFFFF9900)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Cancellation request sent. Please wait for the provider's decision. Thank you.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFF6600),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }


}


class CancelReasonBottomSheet extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String seekerId;
  final String providerId;

  const CancelReasonBottomSheet({
    required this.bookingId,
    required this.postId,
    required this.seekerId,
    required this.providerId,
  });

  @override
  State<CancelReasonBottomSheet> createState() => _CancelReasonBottomSheetState();
}

class _CancelReasonBottomSheetState extends State<CancelReasonBottomSheet> {
  String? _selectedReason;
  bool _agreedToTerms = false;

  final List<String> cancellationReasons = [
    "Need to change delivery address",
    "Booked the wrong service or package",
    "No longer need the service",
    "Found a more suitable service provider",
    "Found cheaper elsewhere",
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 50, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                const Text("Select Cancellation Reason", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.announcement_outlined, color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            "Terms & Conditions",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ExpandableTermsText(),
                    ],
                  ),
                ),


                const SizedBox(height: 20),
                ...cancellationReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: _selectedReason,
                    onChanged: (value) => setState(() => _selectedReason = value),
                    activeColor: Colors.redAccent,
                  );
                }).toList(),


                RadioListTile<String>(
                  value: "Others",
                  groupValue: _selectedReason,
                  onChanged: (value) => setState(() => _selectedReason = value),
                  activeColor: Colors.redAccent,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Others"),
                      if (_selectedReason == "Others") ...[
                        const SizedBox(height: 8),
                        TextField(
                          onChanged: (value) => _selectedReason = value,
                          decoration: InputDecoration(
                            hintText: "Please specify your reason",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                CheckboxListTile(
                  value: _agreedToTerms,
                  onChanged: (val) => setState(() => _agreedToTerms = val!),
                  title: const Text(
                    "I agree to the cancellation terms and conditions as above stated.",
                    style: TextStyle(fontSize: 13),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedReason != null && _agreedToTerms)
                        ? () async {
                      // Firestore: update cancellation reason + flag
                      final doc = await FirebaseFirestore.instance
                          .collection('bookings')
                          .where('bookingId', isEqualTo: widget.bookingId)
                          .limit(1)
                          .get();

                      if (doc.docs.isNotEmpty) {
                        final bookingRef = doc.docs.first.reference;
                        await bookingRef.update({
                          'sCancelled': true,
                          'cancellationReason': _selectedReason,
                          'status': 'Pending Confirmation',
                          'cancelledRequestedAt': FieldValue.serverTimestamp(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        await FirebaseFirestore.instance.collection('p_notifications').add({
                          'providerId': widget.providerId,
                          'bookingId': widget.bookingId,
                          'postId': widget.postId,
                          'seekerId': widget.seekerId,
                          'title': 'Cancellation Requested\n(#${widget.bookingId})',
                          'message': 'The service seeker has requested to cancel the booking. Please approve or reject the request.',
                          'isRead': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        Navigator.pop(context, true); // ✅ return success to caller
                      }
                    }
                        : null,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Confirm Cancellation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}

class ExpandableTermsText extends StatefulWidget {
  const ExpandableTermsText({Key? key}) : super(key: key);

  @override
  State<ExpandableTermsText> createState() => _ExpandableTermsTextState();
}

class _ExpandableTermsTextState extends State<ExpandableTermsText> {
  bool _isExpanded = false;

  final String shortText =
      "⚠️ Cancellations are subject to provider approval and refunds are not guaranteed.\n"
      "💬 Contact your provider via WhatsApp before confirming.\n"
      "💵 RM1 transaction fee is non-refundable.";

  final String fullText =
      "⚠️ Cancellation Approval Is Subject to Provider’s Discretion\n\n"
      "Submitting a cancellation request does not guarantee approval or refund. "
      "The provider reserves full rights to approve or reject your request. "
      "If rejected, the original booking will proceed as scheduled.\n\n"
      "💬 Communication Is Recommended\n\n"
      "Contact the provider via WhatsApp before submitting a cancellation request. "
      "This ensures clarity on whether they will approve and whether a refund (partial/full) applies.\n\n"
      "💵 Transaction Fee Notice\n\n"
      "The RM1 platform transaction fee is strictly non-refundable.\n\n"
      "📌 Summary:\n"
      "• Provider have the right to approve and reject the booking service cancellation request.\n"
      "• If they approve the cancellation, refunds are not guaranteed.\n"
      "• If rejected, the booking will continues.\n"
      "•Contact provider before submitting the cancellation request is highly recommended.\n"
      "• RM1 fee is not refundable.\n\n"
      "By submitting the cancellation request, you confirm that you understand and agree to these terms and conditions.";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedCrossFade(
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          firstChild: Text(
            shortText,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.orange.shade800,
              height: 1.5,
            ),
          ),
          secondChild: Text(
            fullText,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.orange.shade800,
              height: 1.5,
            ),
          ),
        ),
        Center(
          child: IconButton(
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            icon: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.orange.shade800,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

