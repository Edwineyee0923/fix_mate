import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fix_mate/reusable_widget/reusable_widget.dart';

class p_SchedulePage extends StatefulWidget {
  const p_SchedulePage({super.key});

  @override
  State<p_SchedulePage> createState() => _p_SchedulePageState();
}

class _p_SchedulePageState extends State<p_SchedulePage> {
  final List<String> daysOfWeek = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  final defaultStart = const TimeOfDay(hour: 8, minute: 0);
  final defaultEnd = const TimeOfDay(hour: 20, minute: 30);
  Map<String, bool> activeDays = {};
  Map<String, TimeOfDay> startTimes = {};
  Map<String, TimeOfDay> endTimes = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSchedule();
  }


  Future<void> _initializeSchedule() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(uid)
        .get();

    // Clear previous values
    activeDays.clear();
    startTimes.clear();
    endTimes.clear();

    if (doc.exists && doc.data()!.containsKey('availability')) {
      final data = doc.data()!['availability'] as Map<String, dynamic>;
      for (var day in daysOfWeek) {
        if (data.containsKey(day)) {
          activeDays[day] = true;
          startTimes[day] = _parseTime(data[day]['start']) ?? defaultStart;
          endTimes[day] = _parseTime(data[day]['end']) ?? defaultEnd;
        } else {
          activeDays[day] = false;
          startTimes[day] = defaultStart;
          endTimes[day] = defaultEnd;
        }
      }
    } else {
      // If no availability data exists, fallback to default
      for (var day in daysOfWeek) {
        activeDays[day] = true;
        startTimes[day] = defaultStart;
        endTimes[day] = defaultEnd;
      }
    }

    setState(() {});
  }


  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})\s?(AM|PM)$', caseSensitive: false)
        .firstMatch(timeStr.trim());

    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!.toUpperCase();

    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<TimeOfDay?> _showSlotPicker(
      BuildContext context,
      TimeOfDay initialTime,
      {required String title}
      ) async {
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
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TimeSlotSelector(
                selectedTime: null,
                onSelected: (selected) {
                  selectedTimeStr = selected;
                  Navigator.pop(context);
                },
                disabledSlots: const [], // ✅ New required param – currently empty
              ),
            ],
          ),
        );
      },
    );

    if (selectedTimeStr == null) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})\s?(AM|PM)$').firstMatch(selectedTimeStr!.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    int minute = int.parse(match.group(2)!);
    String period = match.group(3)!;

    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }


  Future<void> _editTime(String day) async {
    final newStart = await _showSlotPicker(
      context,
      startTimes[day]!,
      title: "Select Start Time for $day",
    );
    if (newStart == null) return;

    final newEnd = await _showSlotPicker(
      context,
      endTimes[day]!,
      title: "Select End Time for $day",
    );
    if (newEnd == null) return;

    setState(() {
      startTimes[day] = newStart;
      endTimes[day] = newEnd;
    });
  }


  Future<void> _saveSchedule() async {
    setState(() => isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final providerRef = FirebaseFirestore.instance.collection('service_providers').doc(uid);
    Map<String, dynamic> availability = {};

    for (var day in daysOfWeek) {
      if (activeDays[day] == true) {
        availability[day] = {
          'start': startTimes[day]!.format(context),
          'end': endTimes[day]!.format(context),
        };
      }
    }

    await providerRef.update({
      'availability': availability,
      'availabilityUpdatedAt': FieldValue.serverTimestamp(),
    });

    await _initializeSchedule(); // optional, in case you navigate back to same page again
    setState(() => isLoading = false);

    ReusableSnackBar(
      context,
      "Schedule updated successfully!",
      icon: Icons.check_circle,
      iconColor: Colors.green,
    );

    // ✅ Navigate back
    Navigator.pop(context);
  }



  Widget _buildScheduleCard(String day) {
    final isActive = activeDays[day] ?? true;
    final start = startTimes[day]?.format(context) ?? '--';
    final end = endTimes[day]?.format(context) ?? '--';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$start - $end"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: isActive,
              onChanged: (val) => setState(() => activeDays[day] = val),
              activeColor: const Color(0xFF464E65), // Thumb when ON
              activeTrackColor: const Color(0xFFB0B4C2), // Track when ON (optional, complementary shade)
              inactiveThumbColor: Colors.grey.shade400, // Thumb when OFF
              inactiveTrackColor: Colors.grey.shade300, // Track when OFF
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF464E65)),
              onPressed: isActive ? () => _editTime(day) : null,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: Color(0xFF464E65),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Manage Schedule",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Weekly Operation Availability",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: daysOfWeek.length,
                  itemBuilder: (context, index) =>
                      _buildScheduleCard(daysOfWeek[index]),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        color:  Color(0xFFFFFFF2),
        child: SizedBox(
          height: 60,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSchedule,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF464E65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Save Schedule",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

