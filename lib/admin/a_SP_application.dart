import 'package:fix_mate/admin/admin_layout.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fix_mate/admin/a_application_detail.dart';
import 'package:flutter/material.dart';


class SP_application extends StatefulWidget {
  static String routeName = "/admin/SP_application";

  const SP_application({Key? key}) : super(key: key);

  @override
  _SP_applicationState createState() => _SP_applicationState();
}

class _SP_applicationState extends State<SP_application> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedStatus = "All Status";
  List<ApplicationCard> allApplications = [];

  @override
  void initState() {
    super.initState();
    _loadApplications(); // Load applications from Firestore
  }


  Future<void> _loadApplications() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('service_providers')
          .orderBy('createdAt', descending: false) // Sort by earliest first
          .get();

      List<ApplicationCard> applications = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        return ApplicationCard(
          name: data['name'] ?? "Unknown",
          location: (data['selectedStates'] as List<dynamic>?)?.join(", ") ?? "Unknown",
          services: (data['selectedExpertiseFields'] as List<dynamic>?)?.join(", ") ?? "No services listed",
          status: data['status'] ?? "Pending",
          imageUrl: data['profilePic'] ?? "", // Default image if null
          appliedAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          onReview: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ApplicationDetailsScreen(
                  applicationData: data,
                  docId: doc.id,
                ),
              ),
            );

            // Check if the application was updated
            if (result == true) {
              _loadApplications(); // Refresh applications
            }
          },
        );
      }).toList();

      setState(() {
        allApplications = applications;
      });
    } catch (e) {
      print("Error loading applications: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // **Filter applications based on the selected status**
    List<ApplicationCard> filteredApplications = allApplications.where((app) {
      if (selectedStatus == "All Status") return true;
      return app.status == selectedStatus;
    }).toList();

    final PageController _pageController = PageController(initialPage: 2); // Starts at "Applications Not Reviewed"
    // **Counts for Summary Cards**
    int totalApplications = allApplications.length;
    int reviewedApplications =
        allApplications.where((app) => app.status == "Rejected" || app.status == "Approved").length;
    int notReviewedApplications = allApplications.where((app) => app.status == "Pending" ).length;


    return AdminLayout(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF9342),
          title: const Text(
            "Manage Application",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,),
          ),
          titleSpacing: 25,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------- Summary Cards with PageView --------------------
              SizedBox(
                height: 80, // Adjust based on SummaryCard height
                child: PageView(
                  controller: _pageController,
                  clipBehavior: Clip.none, // Prevents cutting off elements
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SummaryCard(
                        count: "$totalApplications",
                        label: "Total Applications",
                        countColor: const Color(0xFFFF9342),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SummaryCard(
                        count: "$reviewedApplications",
                        label: "Applications Reviewed",
                        countColor: const Color(0xFFFF9342),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: SummaryCard(
                        count: "$notReviewedApplications",
                        label: "Applications Not Reviewed",
                        countColor: const Color(0xFFFF9342),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
// -------------------- Page Indicator (Three Dots) --------------------
              Center(
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: 3, // Number of summary cards
                  effect: ExpandingDotsEffect(
                    activeDotColor: Colors.orange,
                    dotColor: Colors.grey.shade400,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                  onDotClicked: (index) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ),
              // -------------------- Status Dropdown --------------------
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusDropdown(
                      selectedStatus: selectedStatus,
                      onChanged: (String status) {
                        setState(() {
                          selectedStatus = status;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // -------------------- List of Filtered Applications --------------------
              Expanded(
                child: ListView.separated(
                  itemCount: filteredApplications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  // clipBehavior: Clip.none,
                  itemBuilder: (context, index) => filteredApplications[index],
                ),
              ),
            ],
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
      width: MediaQuery.of(context).size.width * 0.85, // Make cards responsive
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Text(
            count,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: countColor,
            ),
          ),
          const SizedBox(width: 17),
          Container(
            width: 2.5,
            height: 38,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 45,
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
          items: ["All Status", "Pending", "Approved", "Rejected"].map((String status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Text(
                status,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ApplicationCard extends StatelessWidget {
  final String name;
  final String location;
  final String services;
  final String status;
  final String imageUrl;
  final DateTime appliedAt;
  final VoidCallback onReview;

  const ApplicationCard({
    Key? key,
    required this.name,
    required this.location,
    required this.services,
    required this.status,
    required this.imageUrl,
    required this.appliedAt,
    required this.onReview,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    if (status == "Approved") {
      statusColor = Colors.green;
    } else if (status == "Rejected") {
      statusColor = Colors.red;
    } else {
      statusColor = Color(0xFFFF9342);
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(appliedAt), // Display actual applied time
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: statusColor, width: 1.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 1, // Underline
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: imageUrl.isNotEmpty
                      ? NetworkImage(imageUrl)
                      : AssetImage("assets/default_profile.png") as ImageProvider,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180, // Restrict width to prevent overflow
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        softWrap: true, // Allows text to wrap to the next line
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        SizedBox(
                          width: 180, // Ensure consistent width
                          child: Text(
                            location,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.build, size: 14, color: Colors.grey),
                        SizedBox(
                          width: 180,
                          child: Text(
                            services,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],



            ),
            const SizedBox(height: 10),
            Center(
              child: (status == "Approved" || status == "Rejected")
                  ? TextButton(
                onPressed: onReview,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF9442),
                ),
                child: const Text(
                  "View Details",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              )
                  : ElevatedButton(
                onPressed: onReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9442),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  "Review",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


