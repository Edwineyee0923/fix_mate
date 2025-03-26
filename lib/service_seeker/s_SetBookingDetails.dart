import 'package:fix_mate/service_seeker/s_IPPaymentSummary.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // For launching payment URL
import 'dart:math';

class s_SetBookingDetails extends StatefulWidget {
  final String spId; // ID of the service provider
  final String IBpostId; // ID of the post being booked
  final int IBPrice;
  final String spName;
  final String spImageURL;
  final String IPTitle;

  const s_SetBookingDetails({
    Key? key,
    required this.spId,
    required this.IBpostId,
    required this.IBPrice,
    required this.spImageURL,
    required this.spName,
    required this.IPTitle,
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

  Future<void> _selectDate(BuildContext context, bool isPreferred) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)), // Within 1 year
    );

    if (picked != null) {
      setState(() {
        if (isPreferred) {
          _preferredDate = picked;
        } else {
          _alternativeDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isPreferred) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isPreferred) {
          _preferredTime = picked;
        } else {
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
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('service_seekers')
          .where('id', isEqualTo: user.uid) // Match by UID instead of email
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        seekerId = querySnapshot.docs.first['id'];
        seekerEmail = querySnapshot.docs.first['email']; // Fetch email
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
      await FirebaseFirestore.instance.collection('bookings').add({
        'bookingId': bookingId, // ✅ Save short Booking ID
        'serviceProviderId': widget.spId,
        'spName': widget.spName, // ✅ Added Service Provider Name
        'spImageURL': widget.spImageURL, // ✅ Added Service Provider Image URL
        'postId': widget.IBpostId,
        'IPTitle': widget.IPTitle, // ✅ Added Instant Booking Post Title
        'serviceSeekerId': user.uid, // ✅ Add the current user's UID
        'location': _locationController.text,
        'preferredDate': _preferredDate!.toIso8601String(),
        'preferredTime': "${_preferredTime!.hour}:${_preferredTime!.minute}",
        'alternativeDate': _alternativeDate?.toIso8601String(),
        'alternativeTime': _alternativeTime != null ? "${_alternativeTime!.hour}:${_alternativeTime!.minute}" : null,
        'status': 'pending', // Service provider will later confirm
        'bookedAt': FieldValue.serverTimestamp(),
        'price': widget.IBPrice,
        'spUSecret': toyyibSecretKey,
        'spCCode': toyyibCategory,
      });

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
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking request submitted! Pending service provider to confirm with the service booked.")),
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
            Text("Location Details *", style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _locationController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Enter your location...",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            Text("Pick your desired time slot", style: TextStyle(fontWeight: FontWeight.bold)),

            // Preferred Date & Time
            Text("Preferred Date & Time *", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildDateTimePicker("Select a date", _preferredDate, () => _selectDate(context, true)),
            _buildDateTimePicker("Select a time", _preferredTime, () => _selectTime(context, true)),

            // Alternative Date & Time
            SizedBox(height: 20),
            Text("Alternative Date & Time", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildDateTimePicker(String label, dynamic value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value != null ? value.toString() : label, style: TextStyle(color: Colors.black54)),
              Icon(Icons.calendar_today, color: Color(0xFFfb9798)),
            ],
          ),
        ),
      ),
    );
  }
}
