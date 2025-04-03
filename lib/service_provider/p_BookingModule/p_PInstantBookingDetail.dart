import 'package:fix_mate/service_provider/p_BookingModule/p_BookingHistory.dart';
import 'package:fix_mate/service_provider/p_EditInstantPost.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class p_PInstantBookingDetail extends StatefulWidget {
  final String bookingId;
  final String postId;
  final String seekerId;

  const p_PInstantBookingDetail({
    Key? key,
    required this.bookingId,
    required this.postId,
    required this.seekerId,
  }) : super(key: key);

  @override
  State<p_PInstantBookingDetail> createState() => _p_PInstantBookingDetailState();
}

class _p_PInstantBookingDetailState extends State<p_PInstantBookingDetail> {
  Map<String, dynamic>? bookingData;
  Map<String, dynamic>? instantPostData;
  String? seekerPhone;
  String? selectedSchedule; // 'preferred' or 'alternative'
  bool isSubmitting = false;
  bool isRescheduling = false;
  DateTime? _rescheduleDate;
  TimeOfDay? _rescheduleTime;


  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _rescheduleDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 8))),
    );

    if (picked != null) {
      if (_rescheduleDate != null &&
          _rescheduleDate!.year == now.year &&
          _rescheduleDate!.month == now.month &&
          _rescheduleDate!.day == now.day) {
        final pickedDateTime = DateTime(
          _rescheduleDate!.year,
          _rescheduleDate!.month,
          _rescheduleDate!.day,
          picked.hour,
          picked.minute,
        );
        if (pickedDateTime.isBefore(now)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please choose a future time.")),
          );
          return;
        }
      }

      setState(() => _rescheduleTime = picked);
    }
  }


  Widget _buildDateTimePicker(String label, dynamic value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value != null
                    ? (value is DateTime
                    ? DateFormat("d MMM yyyy").format(value)
                    : "${value.hourOfPeriod}:${value.minute.toString().padLeft(2, '0')} ${value.period == DayPeriod.am ? 'AM' : 'PM'}")
                    : label,
                style: TextStyle(color: value != null ? Colors.black : Colors.black54),
              ),
              Icon((value is DateTime) ? Icons.calendar_today : Icons.access_time, color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReschedule() async {
    if (_rescheduleDate == null || _rescheduleTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select both reschedule date and time.")),
      );
      return;
    }

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _rescheduleDate!.year,
      _rescheduleDate!.month,
      _rescheduleDate!.day,
      _rescheduleTime!.hour,
      _rescheduleTime!.minute,
    );

    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Reschedule date and time must be in the future.")),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docRef = query.docs.first.reference;

        final formattedDate = DateFormat("d MMM yyyy").format(_rescheduleDate!); // Example: 25 Apr 2025

        final dt = DateTime(0, 1, 1, _rescheduleTime!.hour, _rescheduleTime!.minute);
        final formattedTime = DateFormat("h:mm a").format(dt); // Example: 4:05 PM


        await docRef.update({
          'finalDate': formattedDate,
          'finalTime': formattedTime,
        });

        await FirebaseFirestore.instance.collection('s_notifications').add({
          'seekerId': widget.seekerId,
          'providerId': bookingData?['serviceProviderId'],
          'bookingId': widget.bookingId,
          'postId': widget.postId,
          'title': 'Booking Rescheduled (#${widget.bookingId})',
          'message': 'Your provider has rescheduled a custom time for your service. Please review and confirm with the schedule.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reschedule confirmed.")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const p_BookingHistory(initialTabIndex: 1)),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to confirm.")));
    } finally {
      setState(() => isSubmitting = false);
    }
  }


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
      DocumentSnapshot seekerSnap = await FirebaseFirestore.instance.collection('service_seekers').doc(widget.seekerId).get();
      if (seekerSnap.exists) {
        seekerPhone = seekerSnap['phone'];
      }

      setState(() {});
    } catch (e) {
      print("❌ Error fetching details: $e");
    }
  }

  String _formatDate(String date) {
    try {
      DateTime dt = DateTime.parse(date);
      return "${dt.day} ${_monthName(dt.month)} ${dt.year}";
    } catch (_) {
      return date;
    }
  }

  String _formatTime(String time) {
    try {
      TimeOfDay t = TimeOfDay(
        hour: int.parse(time.split(":")[0]),
        minute: int.parse(time.split(":")[1]),
      );
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      return TimeOfDay.fromDateTime(dt).format(context);
    } catch (_) {
      return time;
    }
  }

  String _monthName(int month) {
    const months = ["Jan", "Feb", "Mac", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }


  Future<void> _confirmSchedule() async {
    if (selectedSchedule == null) return;

    setState(() => isSubmitting = true);

    try {
      String finalDate = selectedSchedule == 'preferred'
          ? bookingData!["preferredDate"]
          : bookingData!["alternativeDate"];
      String finalTime = selectedSchedule == 'preferred'
          ? bookingData!["preferredTime"]
          : bookingData!["alternativeTime"];

      final query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('bookingId', isEqualTo: widget.bookingId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final docRef = query.docs.first.reference;
        await docRef.update({
          'finalDate': finalDate,
          'finalTime': finalTime,
          'status': 'Active',
        });


        // 🔔 Add a notification to Firestore for the service seeker
        await FirebaseFirestore.instance.collection('s_notifications').add({
          'seekerId': widget.seekerId,
          'providerId': bookingData?['serviceProviderId'],
          'bookingId': widget.bookingId,
          'postId': widget.postId,
          'title': 'Service Confirmed (#${widget.bookingId})',
          'message': 'Your service booking has been confirmed by the provider.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Schedule confirmed successfully.")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const p_BookingHistory(initialTabIndex: 1),
        ),
      );
    } catch (e) {
      print("❌ Failed to confirm schedule: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to confirm schedule.")));
    } finally {
      setState(() => isSubmitting = false);
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
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor:  const Color(0xFF464E65),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Booking History", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        titleSpacing: 25,
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
                  MaterialPageRoute(builder: (_) => p_EditInstantPost(docId: widget.postId)),
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
          Text("Booking ID: ${bookingData!["bookingId"]}"),
          Text("Status: ${bookingData!["status"]}"),
          Text("Title: ${bookingData!["IPTitle"]}"),
          Text("Category: ${bookingData!["serviceCategory"]}"),
          Text("Preferred Date: ${_formatDate(bookingData!["preferredDate"])}"),
          Text("Preferred Time: ${_formatTime(bookingData!["preferredTime"])}"),
          if (bookingData!["alternativeDate"] != null)
            Text("Alternative Date: ${_formatDate(bookingData!["alternativeDate"])}"),
          if (bookingData!["alternativeTime"] != null)
            Text("Alternative Time: ${_formatTime(bookingData!["alternativeTime"])}"),
          Text("Location: ${bookingData!["location"]}"),
          Text("Price: RM ${bookingData!["price"]}"),
          const SizedBox(height: 12),
          if (seekerPhone != null)
            ElevatedButton.icon(
              onPressed: () async {
                final url = "https://wa.me/$seekerPhone";
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text("Contact Seeker via WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

          const SizedBox(height: 24),
          const SizedBox(height: 16),
          Opacity(
            opacity: isRescheduling ? 0.5 : 1.0, // 🔸 Fade out when rescheduling
            child: IgnorePointer(
              ignoring: isRescheduling, // 🔒 Prevent interaction
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Choose Schedule to Confirm", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  CheckboxListTile(
                    title: Text(
                      "Preferred Schedule: ${_formatDate(bookingData!["preferredDate"])} at ${_formatTime(bookingData!["preferredTime"])}",
                      style: TextStyle(color: isRescheduling ? Colors.grey : Colors.black),
                    ),
                    value: selectedSchedule == 'preferred',
                    activeColor: isRescheduling ? Colors.grey : Colors.green,
                    onChanged: isRescheduling
                        ? null
                        : (val) {
                      setState(() => selectedSchedule = 'preferred');
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      "Alternative Schedule: ${_formatDate(bookingData!["alternativeDate"])} at ${_formatTime(bookingData!["alternativeTime"])}",
                      style: TextStyle(color: isRescheduling ? Colors.grey : Colors.black),
                    ),
                    value: selectedSchedule == 'alternative',
                    activeColor: isRescheduling ? Colors.grey : Colors.green,
                    onChanged: isRescheduling
                        ? null
                        : (val) {
                      setState(() => selectedSchedule = 'alternative');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: isSubmitting ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.check),
            label: Text("Confirm Schedule"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: selectedSchedule == null || isSubmitting
                ? null
                : () async {
              await _confirmSchedule();
            },
          ),

          if (!isRescheduling) ...[
            const SizedBox(height: 16),
            Text(
              "⚠ Both booking schedules are unavailable.\nTry to contact seeker via WhatsApp and reschedule below.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.edit_calendar),
              label: Text("Edit Schedule"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                setState(() {
                  isRescheduling = true;
                });
              },
            ),
          ],

          if (isRescheduling) ...[
            const SizedBox(height: 20),
            Text("Custom Reschedule Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

            _buildDateTimePicker("Select new date", _rescheduleDate, () => _selectDate(context)),
            _buildDateTimePicker("Select new time", _rescheduleTime, () => _selectTime(context)),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      isRescheduling = false;
                      _rescheduleDate = null;
                      _rescheduleTime = null;
                    });
                  },
                  child: Text("Cancel Reschedule"),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : _confirmReschedule,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("Confirm Reschedule"),
                ),
              ],
            ),
          ],


          // Bottom Section: Edit & Cancel
          ElevatedButton(
            onPressed: () {},
            child: const Text("Edit Schedule"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Request Cancellation", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}