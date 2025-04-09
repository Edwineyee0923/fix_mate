import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:fix_mate/services/FullScreenImageViewer.dart';

class SPDetailScreen extends StatefulWidget {
  final String docId;

  const SPDetailScreen({super.key, required this.docId});

  @override
  _SPDetailScreenState createState() => _SPDetailScreenState();
}

class _SPDetailScreenState extends State<SPDetailScreen> {
  Map<String, dynamic>? spData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServiceProviderDetails();
  }

  Future<void> _fetchServiceProviderDetails() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.docId)
          .get();
      if (snapshot.exists) {
        setState(() {
          spData = snapshot.data() as Map<String, dynamic>?;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFF2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF9342),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Service Provider Details",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        titleSpacing: 2,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : spData == null
          ? const Center(child: Text("No data available"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                if (spData!["profilePic"] != null) {
                  showDialog(
                    context: context,
                    builder: (_) => FullScreenImageViewer(
                      imageUrls: [spData!["profilePic"]], // must be a List<String>
                      initialIndex: 0,
                    ),
                  );
                }
              },
              child: CircleAvatar(
                radius: 60,
                backgroundImage: spData!["profilePic"] != null
                    ? NetworkImage(spData!["profilePic"])
                    : const AssetImage("assets/default_profile.png") as ImageProvider,
              ),
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
                    _buildTagsRow("Expertise:", spData!["selectedExpertiseFields"]),
                    _buildTagsRow("State:", spData!["selectedStates"]),
                    _buildCredentialLink(spData!["certificateLink"]),
                    _buildAddressRow(context, spData!["address"]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTable() {
    return Table(
      columnWidths: const {0: FixedColumnWidth(140), 1: FlexColumnWidth()},
      children: [
        _buildTableRow("Applicant Name:", spData!["name"]),
        _buildTableRow("Bio:", spData!["bio"]),
        _buildTableRow("Contact Number:", spData!["phone"]),
        _buildTableRow("Email:", spData!["email"]),
        _buildTableRow("Date of Birth:", spData!["dob"]),
        _buildTableRow("Gender:", spData!["gender"]),
      ],
    );
  }

  TableRow _buildTableRow(String title, dynamic value) {
    String formattedValue = value ?? "N/A";
    if (title == "Date of Birth:" && value is String) {
      try {
        DateTime dob = DateTime.parse(value);
        formattedValue = DateFormat("d MMM yyyy").format(dob);
      } catch (_) {}
    }
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(formattedValue, textAlign: TextAlign.left)),
      ],
    );
  }

  Widget _buildTagsRow(String title, dynamic values) {
    if (values == null || values is! List) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: values.map<Widget>((e) => Chip(label: Text(e, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.orange)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialLink(String? url) {
    if (url == null || url.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          children: [
            const SizedBox(width: 140, child: Text("Credential Doc:", style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text("Open", style: const TextStyle(color: Color(0xFFFF9342), decoration: TextDecoration.underline, fontWeight: FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressRow(BuildContext context, String? address) {
    if (address == null || address.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text("Address:", style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(address)),
          IconButton(
            icon: const Icon(Icons.copy, color: Color(0xFFFF9342), size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: address));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address copied to clipboard!")));
            },
          ),
        ],
      ),
    );
  }
}