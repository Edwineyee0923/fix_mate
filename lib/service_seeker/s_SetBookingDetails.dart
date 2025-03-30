import 'package:fix_mate/service_seeker/s_IPPaymentSummary.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching payment URL
import 'dart:math';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class s_SetBookingDetails extends StatefulWidget {
  final String spId; // ID of the service provider
  final String IBpostId; // ID of the post being booked
  final int IBPrice;
  final String spName;
  final String spImageURL;
  final String IPTitle;
  final String serviceCategory;


  const s_SetBookingDetails({
    Key? key,
    required this.spId,
    required this.IBpostId,
    required this.IBPrice,
    required this.spImageURL,
    required this.spName,
    required this.IPTitle,
    required this.serviceCategory,
  }) : super(key: key);

  @override
  _s_SetBookingDetailsState createState() => _s_SetBookingDetailsState();
}

class _s_SetBookingDetailsState extends State<s_SetBookingDetails> {
  final TextEditingController _locationController = TextEditingController();
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  DateTime? _alternativeDate;
  TimeOfDay? _alternativeTime;


  /// 🗓 Formats the date to "29 Mac 2025"
  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat("d MMM yyyy", 'ms'); // 'ms' for Malay format
    return formatter.format(date);
  }

  // /// 🕒 Formats the time to 24-hour format "14:30"
  // String _formatTime(TimeOfDay time) {
  //   return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  // }

  String _formatTime(TimeOfDay time) {
    final int hour = time.hourOfPeriod; // Converts 24-hour to 12-hour format
    final String period = time.period == DayPeriod.am ? "AM" : "PM";
    return "${hour == 0 ? 12 : hour}:${time.minute.toString().padLeft(2, '0')} $period";
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
          _preferredDate = picked;
          _alternativeDate = picked.add(Duration(days: 1)); // Set default alternative date
          _alternativeTime = null; // Reset alternative time too
        } else {
          if (_preferredDate != null && !picked.isAfter(_preferredDate!)) {
            ReusableSnackBar(
                context, "Alternative date must be after the preferred date.",
                icon: Icons.warning, iconColor: Colors.orange);
            return;
          }
          _alternativeDate = picked;
        }
      });
    }
  }



  /// ⏰ Selects a time and ensures valid selections
  Future<void> _selectTime(BuildContext context, bool isPreferred) async {
    DateTime now = DateTime.now();
    TimeOfDay nowTime = TimeOfDay(hour: now.hour, minute: now.minute);
    TimeOfDay initialTime = TimeOfDay(hour: now.hour + 1, minute: now.minute); // Default 1 hour later

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
          if (_preferredDate != null &&
              _preferredDate!.year == now.year &&
              _preferredDate!.month == now.month &&
              _preferredDate!.day == now.day) {
            if (picked.hour < nowTime.hour || (picked.hour == nowTime.hour && picked.minute <= nowTime.minute)) {
              ReusableSnackBar(context, "Time must be in the future.",
                  icon: Icons.warning, iconColor: Colors.orange);
              return;
            }
          }
          _preferredTime = picked;
          _alternativeTime = null; // Reset alternative time if it was invalid
        } else {
          // 🚨 Ensure alternative time is after preferred time (if on the same date)
          if (_alternativeDate != null &&
              _alternativeDate!.year == _preferredDate!.year &&
              _alternativeDate!.month == _preferredDate!.month &&
              _alternativeDate!.day == _preferredDate!.day) {
            if (_preferredTime != null &&
                (picked.hour < _preferredTime!.hour ||
                    (picked.hour == _preferredTime!.hour && picked.minute <= _preferredTime!.minute))) {
              ReusableSnackBar(
                  context, "Alternative time must be after the preferred time.",
                  icon: Icons.warning, iconColor: Colors.orange);
              return;
            }
          }
          _alternativeTime = picked;
        }
      });
    }
  }





  String generateBookingId() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    Random random = Random();
    return "BKIB-${List.generate(5, (index) => chars[random.nextInt(chars.length)]).join()}";
  }

  Future<void> _confirmBooking() async {
    if (_locationController.text.isEmpty || _preferredDate == null || _preferredTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    try {
      // 🔹 Get the currently logged-in user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User not logged in.");
        return;
      }

      // 🔹 Fetch Service Seeker ID from Firestore
      String? seekerId;
      String? seekerEmail;
      String? seekerPhone;
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('service_seekers')
          .where('id', isEqualTo: user.uid) // Match by UID instead of email
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        seekerId = querySnapshot.docs.first['id'];
        seekerEmail = querySnapshot.docs.first['email']; // Fetch email
        seekerPhone = querySnapshot.docs.first['phone'];
      }

      if (seekerId == null) {
        print("Service seeker ID not found.");
        return;
      }

      // 🔹 Fetch service provider's ToyyibPay details
      DocumentSnapshot spDoc = await FirebaseFirestore.instance.collection('service_providers').doc(widget.spId).get();
      if (!spDoc.exists) {
        print("Service provider not found.");
        return;
      }

      Map<String, dynamic> spData = spDoc.data() as Map<String, dynamic>;
      String? toyyibSecretKey = spData['spUSecret'];
      String? toyyibCategory = spData['spCCode'];

      if (toyyibSecretKey == null || toyyibCategory == null) {
        print("ToyyibPay details missing for this service provider.");
        return;
      }

      // 🔹 Generate Shorter & Confidential Booking ID
      String bookingId = generateBookingId();

      // 🔹 Save booking with seekerId
      // await FirebaseFirestore.instance.collection('bookings').add({
      //   'bookingId': bookingId, // ✅ Save short Booking ID
      //   'serviceProviderId': widget.spId,
      //   'spName': widget.spName, // ✅ Added Service Provider Name
      //   'spImageURL': widget.spImageURL, // ✅ Added Service Provider Image URL
      //   'postId': widget.IBpostId,
      //   'IPTitle': widget.IPTitle, // ✅ Added Instant Booking Post Title
      //   'serviceCategory': widget.serviceCategory,
      //   'serviceSeekerId': user.uid, // ✅ Add the current user's UID
      //   'location': _locationController.text,
      //   'preferredDate': _preferredDate!.toIso8601String(),
      //   'preferredTime': "${_preferredTime!.hour}:${_preferredTime!.minute}",
      //   'alternativeDate': _alternativeDate?.toIso8601String(),
      //   'alternativeTime': _alternativeTime != null ? "${_alternativeTime!.hour}:${_alternativeTime!.minute}" : null,
      //   'status': 'pending', // Service provider will later confirm
      //   'bookedAt': FieldValue.serverTimestamp(),
      //   'price': widget.IBPrice,
      //   'spUSecret': toyyibSecretKey,
      //   'spCCode': toyyibCategory,
      // });

      // 🔹 Navigate to Payment Summary Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => s_IPPaymentSummary(
            bookingId: bookingId, // ✅ Pass the booking ID
            spName: widget.spName,
            spImageURL: widget.spImageURL,
            IPTitle: widget.IPTitle,
            location: _locationController.text,
            preferredDate: _preferredDate!,
            preferredTime: _preferredTime!,
            alternativeDate: _alternativeDate,
            alternativeTime: _alternativeTime,
            totalPrice: widget.IBPrice,
            toyyibSecretKey: toyyibSecretKey,
            toyyibCategory: toyyibCategory,
            userEmail: seekerEmail!, // ✅ Pass the seeker's email
            userPhone: seekerPhone!,
            serviceSeekerId: seekerId!,
            serviceCategory: widget.serviceCategory,
            postId: widget.IBpostId,
            spId: widget.spId,
          ),
        ),
      );


    } catch (e) {
      print("Error saving booking: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: Color(0xFFfb9798),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Set Booking Details",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 25,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Location Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 5),
            TextFormField(
              controller: _locationController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your location...",
                hintStyle: TextStyle(color: Colors.grey.shade600), // Match hint style
                filled: true,
                fillColor: Colors.white, // Ensuring consistency with pickers
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners like pickers
                  borderSide: BorderSide(color: Color(0xFFfb9798)), // Pinkish-red border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFFfb9798)), // Default border
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(width: 2, color: Color(0xFFfb9798)), // Thicker when focused
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Proper spacing
              ),
              style: TextStyle(color: Colors.black, fontSize: 16), // Consistent font style
              cursorColor: Color(0xFFfb9798), // Match cursor color to theme
            ),

            SizedBox(height: 30),

            Text("Pick your desired time slot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            // Preferred Date & Time
            Text("Preferred Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildDateTimePicker("Select a date", _preferredDate, () => _selectDate(context, true)),
            _buildDateTimePicker("Select a time", _preferredTime, () => _selectTime(context, true)),

            // Alternative Date & Time
            SizedBox(height: 20),
            Text("Alternative Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildDateTimePicker("Select a date", _alternativeDate, () => _selectDate(context, false)),
            _buildDateTimePicker("Select a time", _alternativeTime, () => _selectTime(context, false)),

            SizedBox(height: 30),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print("Confirm button pressed! Calling _confirmBooking()");
                  _confirmBooking();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFfb9798),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Confirm", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildDateTimePicker(String label, dynamic value, VoidCallback onTap) {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 10),
  //     child: InkWell(
  //       onTap: onTap,
  //       child: Container(
  //         padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.grey),
  //           borderRadius: BorderRadius.circular(10),
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(value != null ? value.toString() : label, style: TextStyle(color: Colors.black54)),
  //             Icon(Icons.calendar_today, color: Color(0xFFfb9798)),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  /// 🔹 Builds the aesthetic date/time picker UI
  Widget _buildDateTimePicker(String label, dynamic value, VoidCallback onTap) {
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
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
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
                (value is DateTime) ? Icons.calendar_today : Icons.access_time, // Ensure correct icon
                color: Color(0xFFfb9798),
              ),
            ],
          ),
        ),
      ),
    );
  }




}
