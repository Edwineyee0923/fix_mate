import 'package:fix_mate/admin/admin_layout.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SP_application extends StatefulWidget {
  static String routeName = "/admin/SP_application";

  const SP_application({Key? key}) : super(key: key);

  @override
  _SP_applicationState createState() => _SP_applicationState();
}

class _SP_applicationState extends State<SP_application> {

  String selectedStatus = "All status";

  @override
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: Color(0xFFFFF8F2),
        appBar: AppBar(
          backgroundColor: Color(0xFFFF9342),
          // leading: IconButton(
          //   icon: Icon(Icons.arrow_back_ios_new_rounded),
          //   onPressed: () {
          //     Navigator.pop(context);
          //   },
          // ),
          title: Text(
            "Manage Application",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          titleSpacing: 20,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------- Summary Cards --------------------
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Allow horizontal scrolling if needed
                  child: Row(
                    children: [
                      SummaryCard(count: "4", label: "Total Applications", countColor: Colors.red),
                      const SizedBox(width: 10),
                      SummaryCard(count: "3", label: "Applications Reviewed", countColor: Colors.orange),
                      const SizedBox(width: 10),
                      SummaryCard(count: "1", label: "Applications Not Reviewed", countColor: Colors.brown),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // -------------------- Status Dropdown --------------------
                Align(
                  alignment: Alignment.centerRight,
                  child: StatusDropdown(
                    selectedStatus: selectedStatus,
                    onChanged: (String status) {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // -------------------- List of Pending Applications --------------------
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6, // Adjust height dynamically
                  child: ListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(), // Prevent double scrolling
                    children: [
                      ApplicationCard(
                        name: "Steven Yap",
                        location: "Perak",
                        services: "Plumbing, electrical repair...",
                        status: "Done",
                        imageUrl: "https://example.com/steven.jpg",
                        isDone: true,
                      ),
                      const SizedBox(height: 10),
                      ApplicationCard(
                        name: "Vivian",
                        location: "Kedah",
                        services: "Cleaning, painting...",
                        status: "Not Done",
                        imageUrl: "https://example.com/vivian.jpg",
                        isDone: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------ Summary Card Widget ------------------
class SummaryCard extends StatelessWidget {
  final String count;
  final String label;
  final Color countColor;

  const SummaryCard({
    Key? key,
    required this.count,
    required this.label,
    required this.countColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.3, // Make cards responsive
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: countColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1.5,
            height: 25,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ Status Dropdown ------------------
class StatusDropdown extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onChanged;

  const StatusDropdown({
    Key? key,
    required this.selectedStatus,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          icon: const Icon(Icons.arrow_drop_down),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: ["All status", "Done", "Not Done"].map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                status,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ------------------ Application Card ------------------
class ApplicationCard extends StatelessWidget {
  final String name;
  final String location;
  final String services;
  final String status;
  final String imageUrl;
  final bool isDone;

  const ApplicationCard({
    Key? key,
    required this.name,
    required this.location,
    required this.services,
    required this.status,
    required this.imageUrl,
    required this.isDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "10 Dec 2024, 10 a.m.",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDone ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDone ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(imageUrl),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        Text(
                          location,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.build, size: 14, color: Colors.grey),
                        Text(
                          services,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Handle review button press
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone ? Colors.grey : Colors.pinkAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: Text(
                  "Review",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
