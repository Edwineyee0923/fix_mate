import 'package:fix_mate/service_seeker/s_BookingModule/s_IPPaymentSummary.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchAndSetUserAddress();
  }

  Future<void> _fetchAndSetUserAddress() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('service_seekers')
        .where('id', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      final address = data['address'] as String?;

      if (address != null && address.isNotEmpty) {
        setState(() {
          _locationController.text = address;
        });
      } else {
        print("⚠️ Address field is missing or empty.");
      }
    } else {
      print("⚠️ No service seeker document found for this user.");
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


  // Future<List<String>> getDisabledSlots(String providerId, DateTime selectedDate) async {
  //   final slots = <String>[];
  //
  //   final bookings = await FirebaseFirestore.instance
  //       .collection('bookings')
  //       .where('serviceProviderId', isEqualTo: providerId)
  //       .where('status', isEqualTo: 'Active')
  //       .where('finalDate', isEqualTo: DateFormat("d MMM yyyy").format(selectedDate))
  //       .get();
  //
  //   // for (var doc in bookings.docs) {
  //   //   slots.add(doc['finalTime']); // Format must match TimeSlotSelector
  //   // }
  //
  //   // for (var doc in bookings.docs) {
  //   //   String bookedTime = doc['finalTime'];
  //   //   slots.add(bookedTime);
  //   //
  //   //   // Block 30 mins before and after
  //   //   final index = _indexFromSlot(bookedTime);
  //   //   if (index != null) {
  //   //     if (index > 0) slots.add(_slotFromIndex(index - 1)); // Before
  //   //     if (index < 47) slots.add(_slotFromIndex(index + 1)); // After
  //   //   }
  //   // }
  //
  //   for (var doc in bookings.docs) {
  //     String bookedTime = doc['finalTime'];
  //     slots.add(bookedTime); // current slot
  //
  //     final index = _indexFromSlot(bookedTime);
  //     if (index != null && index < 47) {
  //       slots.add(_slotFromIndex(index + 1)); // buffer slot after
  //     }
  //   }
  //
  //
  //   // 🔍 Get unavailable times outside of provider's available hours
  //   final spDoc = await FirebaseFirestore.instance
  //       .collection('service_providers')
  //       .doc(providerId)
  //       .get();
  //
  //   final day = DateFormat('EEEE').format(selectedDate); // e.g., Monday
  //   // final availableStart = spDoc['availability'][day]?['start'];
  //   // final availableEnd = spDoc['availability'][day]?['end'];
  //   final data = spDoc.data() as Map<String, dynamic>;
  //   final availability = data['availability'] as Map<String, dynamic>?;
  //
  //   if (availability == null || availability[day] == null) {
  //     print("⚠️ No availability set for $day — assuming fully available.");
  //     return slots; // only booked times will be disabled
  //   }
  //
  //   final availableStart = availability[day]['start'];
  //   final availableEnd = availability[day]['end'];
  //
  //   if (availableStart == null || availableEnd == null) {
  //     print("⚠️ Incomplete availability config — assuming fully available.");
  //     return slots;
  //   }
  //
  //
  //
  //   if (availableStart == null || availableEnd == null) {
  //     // whole day unavailable
  //     return List.generate(48, (i) => _slotFromIndex(i)); // disable all
  //   }
  //
  //   final allSlots = List.generate(48, (i) => _slotFromIndex(i));
  //   final filtered = allSlots.where((slot) {
  //     return _isTimeBefore(slot, availableStart) || _isTimeAfter(slot, availableEnd);
  //   });
  //
  //   slots.addAll(filtered);
  //   return slots;
  // }


  Future<List<String>> getDisabledSlots(String providerId, DateTime selectedDate) async {
    final slots = <String>[];

    // 🔹 Fetch active bookings for the day
    final bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('serviceProviderId', isEqualTo: providerId)
        .where('status', isEqualTo: 'Active')
        .where('finalDate', isEqualTo: DateFormat("d MMM yyyy").format(selectedDate))
        .get();

    // 🔹 Add current and buffer slots from bookings
    for (var doc in bookings.docs) {
      String bookedTime = doc['finalTime'];
      slots.add(bookedTime); // current slot

      final index = _indexFromSlot(bookedTime);
      if (index != null && index < 47) {
        slots.add(_slotFromIndex(index + 1)); // buffer slot after
      }
    }

    // 🔹 Check service provider availability config
    final spDoc = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(providerId)
        .get();

    final day = DateFormat('EEEE').format(selectedDate); // e.g., Monday
    final data = spDoc.data() as Map<String, dynamic>;
    final availability = data['availability'] as Map<String, dynamic>?;

    // ✅ No availability field at all → assume fully available
    if (availability == null) {
      print("✅ No availability config found — assuming fully available.");
      return slots; // only booked slots will be disabled
    }

    // ❌ Day not configured → disable full day
    if (!availability.containsKey(day)) {
      print("⛔ No availability set for $day — disabling full day.");
      return List.generate(48, (i) => _slotFromIndex(i));
    }

    final availableStart = availability[day]['start'];
    final availableEnd = availability[day]['end'];

    // ❌ Day is configured but incomplete → disable full day
    if (availableStart == null || availableEnd == null) {
      print("⛔ Incomplete availability for $day — disabling full day.");
      return List.generate(48, (i) => _slotFromIndex(i));
    }

    // 🔸 Disable slots before or after availability range
    final allSlots = List.generate(48, (i) => _slotFromIndex(i));
    final filtered = allSlots.where((slot) {
      return _isTimeBefore(slot, availableStart) || _isTimeAfter(slot, availableEnd);
    });

    slots.addAll(filtered);
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
    final spId = widget.spId;
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
          _preferredTime = _parseToTimeOfDay(selectedTimeStr!);
        } else {
          _alternativeTime = _parseToTimeOfDay(selectedTimeStr!);
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


  // String generateBookingId() {
  //   const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  //   Random random = Random();
  //   return "BKIB-${List.generate(5, (index) => chars[random.nextInt(chars.length)]).join()}";
  // }

  // Generate for the bookingId counter
  Future<String> generateBookingId() async {
    final counterRef = FirebaseFirestore.instance.collection('counters').doc('bookingId');
    final snapshot = await counterRef.get();

    String prefix = "A";
    int number = 1;

    if (snapshot.exists) {
      final data = snapshot.data()!;
      prefix = data["prefix"] ?? "A";
      number = data["number"] ?? 1;
    }

    // Format the bookingId
    String paddedNumber = number.toString().padLeft(6, '0');
    String bookingId = "BKIB-$prefix$paddedNumber";

    // Update for next booking
    int nextNumber = number + 1;
    String nextPrefix = prefix;

    if (nextNumber > 999999) {
      // Move to next alphabet
      nextPrefix = String.fromCharCode(prefix.codeUnitAt(0) + 1);
      nextNumber = 1;

      // Optional: prevent going beyond Z
      if (nextPrefix.codeUnitAt(0) > 'Z'.codeUnitAt(0)) {
        throw Exception("Booking ID prefix limit exceeded.");
      }
    }

    // Save the updated prefix and number
    await counterRef.set({
      "prefix": nextPrefix,
      "number": nextNumber,
    });

    return bookingId;
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
      String? seekerAddress;
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('service_seekers')
          .where('id', isEqualTo: user.uid) // Match by UID instead of email
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        seekerId = querySnapshot.docs.first['id'];
        seekerEmail = querySnapshot.docs.first['email']; // Fetch email
        seekerPhone = querySnapshot.docs.first['phone'];
        seekerAddress = querySnapshot.docs.first['address'];
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
      String bookingId = await generateBookingId();





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
        titleSpacing: 5,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Location Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 5),
            LongInputContainer(
              controller: _locationController,
              placeholder: "Enter your location...",
              isRequired: true,
              requiredMessage: "Location is required.",
              width: double.infinity,
            ),
            SizedBox(height: 30),

            Text("Pick your desired time slot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 10),
            // Preferred Date & Time
            Text("Preferred Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            // _buildDateTimePicker("Select a date", _preferredDate, () => _selectDate(context, true), isDate: true),
            // _buildDateTimePicker("Select a time", _preferredTime, () => _selectTime(context, true), isDate: false),

            // Preferred Date & Time
            _buildDateTimePicker(
              "Select a date",
              _preferredDate,
                  () => _selectDate(context, true),
              isDate: true,
            ),
            _buildDateTimePicker(
              "Select a time",
              _preferredTime,
                  () => _showTimeSlotSelector(
                isPreferred: true,
                selectedDate: _preferredDate,
              ),
              isDate: false,
            ),
            // Alternative Date & Time
            SizedBox(height: 20),
            Text("Alternative Date & Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            // _buildDateTimePicker("Select a date", _alternativeDate, () => _selectDate(context, false), isDate: true),
            // _buildDateTimePicker("Select a time", _alternativeTime, () => _selectTime(context, false), isDate: false),
            // Alternative Date & Time
            _buildDateTimePicker(
              "Select a date",
              _alternativeDate,
                  () => _selectDate(context, false),
              isDate: true,
            ),
            _buildDateTimePicker(
              "Select a time",
              _alternativeTime,
                  () => _showTimeSlotSelector(
                isPreferred: false,
                selectedDate: _alternativeDate,
              ),
              isDate: false,
            ),



            SizedBox(height: 20),

            // Confirm Button
            Center(
              child: pk_button(context, "Confirm", () {
                print("Confirm button pressed! Calling _confirmBooking()");
                _confirmBooking();
              }),
            ),
          ],
        ),
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
