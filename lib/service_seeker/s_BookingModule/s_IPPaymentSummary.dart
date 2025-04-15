// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
// import 'package:intl/intl.dart'; // At the top
//
// class s_IPPaymentSummary extends StatelessWidget {
//   final String spName;
//   final String spImageURL;
//   final String IPTitle;
//   final String location;
//   final DateTime preferredDate;
//   final TimeOfDay preferredTime;
//   final DateTime? alternativeDate;
//   final TimeOfDay? alternativeTime;
//   final int totalPrice;
//   final String toyyibSecretKey;
//   final String toyyibCategory;
//   final String bookingId;
//   final String userEmail;
//   final String userPhone;
//   final String serviceSeekerId;
//   final String serviceCategory;
//   final String postId;
//   final String spId;
//
//   const s_IPPaymentSummary({
//     Key? key,
//     required this.spName,
//     required this.spImageURL,
//     required this.IPTitle,
//     required this.location,
//     required this.preferredDate,
//     required this.preferredTime,
//     this.alternativeDate,
//     this.alternativeTime,
//     required this.totalPrice,
//     required this.toyyibSecretKey,
//     required this.toyyibCategory,
//     required this.bookingId,
//     required this.userEmail,
//     required this.userPhone,
//     required this.serviceSeekerId,
//     required this.serviceCategory,
//     required this.postId,
//     required this.spId,
//   }) : super(key: key);
//
//
//   String formatDate(DateTime date) => DateFormat("d MMM yyyy", "ms_MY").format(date);
//   String formatTime(TimeOfDay time) {
//     final now = DateTime.now();
//     final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
//     return DateFormat.jm().format(dt); // e.g., 12:30 PM
//   }
//
//
//   Future<void> _saveBookingToFirestore() async {
//     await FirebaseFirestore.instance.collection('bookings').add({
//       'bookingId': bookingId,
//       'serviceProviderId': spId,
//       'spName': spName,
//       'spImageURL': spImageURL,
//       'postId': postId,
//       'IPTitle': IPTitle,
//       'serviceCategory': serviceCategory,
//       'serviceSeekerId': serviceSeekerId,
//       'location': location,
//       'preferredDate': formatDate(preferredDate),
//       'preferredTime': formatTime(preferredTime),
//       'alternativeDate': alternativeDate != null ? formatDate(alternativeDate!) : null,
//       'alternativeTime': alternativeTime != null ? formatTime(alternativeTime!) : null,
//       'status': 'pending',
//       'bookedAt': FieldValue.serverTimestamp(),
//       'price': totalPrice,
//       'spUSecret': toyyibSecretKey,
//       'spCCode': toyyibCategory,
//       "providerHasSeen": false,
//     });
//   }
//
//   Future<String> _generateBranchLink(String bookingId) async {
//     BranchUniversalObject buo = BranchUniversalObject(
//       canonicalIdentifier: 'booking/$bookingId',
//       title: 'Your Booking ID',
//       contentDescription: 'Tap to view your booking details',
//       contentMetadata: BranchContentMetaData()
//         ..addCustomMetadata('bookingId', bookingId),
//     );
//
//     BranchLinkProperties lp = BranchLinkProperties(
//       channel: 'fixmate',
//       feature: 'booking',
//     );
//
//     BranchResponse response = await FlutterBranchSdk.getShortUrl(
//       buo: buo,
//       linkProperties: lp,
//     );
//
//     if (response.success) {
//       print('✅ Branch deep link sent to ToyyibPay: ${response.result}');
//       return response.result;
//     } else {
//       print('❌ Branch link error: ${response.errorMessage}');
//       return 'https://fixmate.com/deeplink-fallback';
//     }
//   }
//
//   // Future<String> _createToyyibPayBill() async {
//   //   try {
//   //     Uri apiUrl = Uri.parse('https://toyyibpay.com/index.php/api/createBill');
//   //
//   //     Map<String, String> bodyData = {
//   //       'userSecretKey': toyyibSecretKey,
//   //       'categoryCode': toyyibCategory,
//   //       'billName': 'Service Booking',
//   //       'billDescription': 'Payment for booking ID: $bookingId',
//   //       'billPriceSetting': '1',
//   //       'billPayorInfo': '1',
//   //       'billAmount': (totalPrice * 100).toString(),
//   //       // 'billReturnUrl': 'https://yourapp.com/payment-success?bookingId=$bookingId',
//   //       'billReturnUrl': await _generateBranchLink(bookingId),
//   //       'billCallbackUrl': 'https://your-server.com/toyyibpay-callback',
//   //       'billExternalReferenceNo': bookingId,
//   //       'billTo': userEmail,
//   //       'billEmail': userEmail,
//   //       'billPhone': userPhone,
//   //     };
//   //
//   //     print("🔹 Sending Request to ToyyibPay...");
//   //     print("📝 Request Data: $bodyData");
//   //
//   //     var response = await http.post(apiUrl, body: bodyData);
//   //
//   //     print("🔹 Response Status Code: ${response.statusCode}");
//   //     print("🔹 Response Body: ${response.body}");
//   //
//   //     if (response.statusCode == 200) {
//   //       List<dynamic> responseData = jsonDecode(response.body); // ✅ FIX: Expecting a list
//   //
//   //       if (responseData.isNotEmpty && responseData[0].containsKey('BillCode')) {
//   //         String billCode = responseData[0]['BillCode'];
//   //         String paymentUrl = "https://toyyibpay.com/$billCode";
//   //         print("✅ Payment URL: $paymentUrl");
//   //         return paymentUrl;
//   //       } else {
//   //         print("⚠️ Unexpected response format from ToyyibPay.");
//   //         return "";
//   //       }
//   //     } else {
//   //       print("❌ Failed to create bill: ${response.body}");
//   //       return "";
//   //     }
//   //   } catch (e) {
//   //     print("❌ Error creating ToyyibPay bill: $e");
//   //     return "";
//   //   }
//   // }
//
//   Future<String> _createToyyibPayBill() async {
//
//     try {
//       // 🔹 STEP 1: Generate Branch Deep Link FIRST
//       String? deepLink;
//       BranchUniversalObject buo = BranchUniversalObject(
//         canonicalIdentifier: 'booking/$bookingId',
//         title: 'Booking Confirmed',
//         contentDescription: 'Tap to confirm your booking in FixMate',
//         contentMetadata: BranchContentMetaData()
//           ..addCustomMetadata('bookingId', bookingId)
//           ..addCustomMetadata('spId', spId)
//           ..addCustomMetadata('serviceSeekerId', serviceSeekerId)
//           ..addCustomMetadata('postId', postId),
//       );
//
//       BranchLinkProperties lp = BranchLinkProperties(
//         channel: 'toyyibpay',
//         feature: 'payment',
//       );
//
//       BranchResponse response = await FlutterBranchSdk.getShortUrl(
//         buo: buo,
//         linkProperties: lp,
//       );
//
//       if (response.success) {
//         deepLink = response.result;
//         print("✅ Generated Branch Deep Link: $deepLink");
//       } else {
//         print("❌ Failed to generate Branch deep link: ${response.errorMessage}");
//         deepLink = 'https://fixmate.com/deeplink-fallback'; // Fallback link
//       }
//
//       // 🔹 STEP 2: Prepare ToyyibPay Bill Request
//       Uri apiUrl = Uri.parse('https://toyyibpay.com/index.php/api/createBill');
//
//       Map<String, String> bodyData = {
//         'userSecretKey': toyyibSecretKey,
//         'categoryCode': toyyibCategory,
//         'billName': 'Service Booking',
//         'billDescription': 'Payment for booking ID: $bookingId',
//         'billPriceSetting': '1',
//         'billPayorInfo': '1',
//         'billAmount': (totalPrice * 100).toString(),
//         'billReturnUrl': deepLink!,
//         'billCallbackUrl': 'https://your-server.com/toyyibpay-callback',
//         'billExternalReferenceNo': bookingId,
//         'billTo': userEmail,
//         'billEmail': userEmail,
//         'billPhone': userPhone,
//       };
//
//       print("🔹 Sending Request to ToyyibPay...");
//       print("📝 Request Data: $bodyData");
//
//       var responseToyyib = await http.post(apiUrl, body: bodyData);
//
//       print("🔹 Response Status Code: ${responseToyyib.statusCode}");
//       print("🔹 Response Body: ${responseToyyib.body}");
//
//       if (responseToyyib.statusCode == 200) {
//         List<dynamic> responseData = jsonDecode(responseToyyib.body);
//
//         if (responseData.isNotEmpty && responseData[0].containsKey('BillCode')) {
//           String billCode = responseData[0]['BillCode'];
//           String paymentUrl = "https://toyyibpay.com/$billCode";
//           print("✅ Payment URL: $paymentUrl");
//           return paymentUrl;
//         } else {
//           print("⚠️ Unexpected response format from ToyyibPay.");
//           return "";
//         }
//       } else {
//         print("❌ Failed to create bill: ${responseToyyib.body}");
//         return "";
//       }
//     } catch (e) {
//       print("❌ Error creating ToyyibPay bill: $e");
//       return "";
//     }
//   }
//
//
//   /// 🚀 Launch Payment in Browser
//   Future<void> _initiatePayment() async {
//     await _saveBookingToFirestore();
//
//     String paymentUrl = await _createToyyibPayBill();
//     if (paymentUrl.isNotEmpty) {
//
//       Uri uri = Uri.parse(paymentUrl);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       } else {
//         print("❌ Could not launch payment URL: $paymentUrl");
//       }
//     } else {
//       print("⚠️ Payment URL is empty. Check API response.");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Payment Summary")),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.network(spImageURL, height: 100, fit: BoxFit.cover),
//             SizedBox(height: 10),
//             Text(spName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             Text(IPTitle, style: TextStyle(fontSize: 16, color: Colors.grey)),
//             Divider(),
//             Text("Location: $location"),
//             Text("Preferred Date: ${preferredDate.toLocal()}"),
//             Text("Preferred Time: ${preferredTime.format(context)}"),
//             if (alternativeDate != null) Text("Alternative Date: ${alternativeDate!.toLocal()}"),
//             if (alternativeTime != null) Text("Alternative Time: ${alternativeTime!.format(context)}"),
//             SizedBox(height: 20),
//             Text("Total Price: RM$totalPrice", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             // Spacer(),
//             ElevatedButton(
//               onPressed: _initiatePayment,
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(vertical: 15),
//                 textStyle: TextStyle(fontSize: 18),
//               ),
//               child: Text("Buy Now"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
// import 'package:intl/intl.dart';
//
// class s_IPPaymentSummary extends StatelessWidget {
//   final String spName;
//   final String spImageURL;
//   final String IPTitle;
//   final String location;
//   final DateTime preferredDate;
//   final TimeOfDay preferredTime;
//   final DateTime? alternativeDate;
//   final TimeOfDay? alternativeTime;
//   final int totalPrice;
//   final String toyyibSecretKey;
//   final String toyyibCategory;
//   final String bookingId;
//   final String userEmail;
//   final String userPhone;
//   final String serviceSeekerId;
//   final String serviceCategory;
//   final String postId;
//   final String spId;
//
//   const s_IPPaymentSummary({
//     super.key,
//     required this.spName,
//     required this.spImageURL,
//     required this.IPTitle,
//     required this.location,
//     required this.preferredDate,
//     required this.preferredTime,
//     this.alternativeDate,
//     this.alternativeTime,
//     required this.totalPrice,
//     required this.toyyibSecretKey,
//     required this.toyyibCategory,
//     required this.bookingId,
//     required this.userEmail,
//     required this.userPhone,
//     required this.serviceSeekerId,
//     required this.serviceCategory,
//     required this.postId,
//     required this.spId,
//   });
//
//   String formatDate(DateTime date) => DateFormat("d MMM yyyy").format(date);
//   String formatTime(TimeOfDay time) {
//     final now = DateTime.now();
//     final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
//     return DateFormat.jm().format(dt);
//   }
//
//   Future<void> _saveBookingToFirestore() async {
//     await FirebaseFirestore.instance.collection('bookings').add({
//       'bookingId': bookingId,
//       'serviceProviderId': spId,
//       'spName': spName,
//       'spImageURL': spImageURL,
//       'postId': postId,
//       'IPTitle': IPTitle,
//       'serviceCategory': serviceCategory,
//       'serviceSeekerId': serviceSeekerId,
//       'location': location,
//       'preferredDate': formatDate(preferredDate),
//       'preferredTime': formatTime(preferredTime),
//       'alternativeDate': alternativeDate != null ? formatDate(alternativeDate!) : null,
//       'alternativeTime': alternativeTime != null ? formatTime(alternativeTime!) : null,
//       'status': 'pending',
//       'bookedAt': FieldValue.serverTimestamp(),
//       'price': totalPrice,
//       'spUSecret': toyyibSecretKey,
//       'spCCode': toyyibCategory,
//       "providerHasSeen": false,
//       'createdAt': FieldValue.serverTimestamp(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }
//
//   Future<String> _createToyyibPayBill() async {
//     try {
//       final buo = BranchUniversalObject(
//         canonicalIdentifier: 'booking/$bookingId',
//         title: 'Booking Confirmed',
//         contentDescription: 'Tap to confirm your booking in FixMate',
//         contentMetadata: BranchContentMetaData()
//           ..addCustomMetadata('bookingId', bookingId)
//           ..addCustomMetadata('spId', spId)
//           ..addCustomMetadata('serviceSeekerId', serviceSeekerId)
//           ..addCustomMetadata('postId', postId),
//       );
//
//       final lp = BranchLinkProperties(channel: 'toyyibpay', feature: 'payment');
//       final response = await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
//       final deepLink = response.success ? response.result : 'https://fixmate.com/deeplink-fallback';
//
//       final bodyData = {
//         'userSecretKey': toyyibSecretKey,
//         'categoryCode': toyyibCategory,
//         'billName': 'Service Booking',
//         'billDescription': 'Payment for booking ID: $bookingId',
//         'billPriceSetting': '1',
//         'billPayorInfo': '1',
//         'billAmount': (totalPrice * 100).toString(),
//         'billReturnUrl': deepLink,
//         'billCallbackUrl': 'https://your-server.com/toyyibpay-callback',
//         'billExternalReferenceNo': bookingId,
//         'billTo': userEmail,
//         'billEmail': userEmail,
//         'billPhone': userPhone,
//       };
//
//       final apiUrl = Uri.parse('https://toyyibpay.com/index.php/api/createBill');
//       final responseToyyib = await http.post(apiUrl, body: bodyData);
//       final responseData = jsonDecode(responseToyyib.body);
//
//       if (responseToyyib.statusCode == 200 && responseData.isNotEmpty && responseData[0]['BillCode'] != null) {
//         return "https://toyyibpay.com/${responseData[0]['BillCode']}";
//       }
//       return "";
//     } catch (e) {
//       print("❌ Error during payment bill creation: $e");
//       return "";
//     }
//   }
//
//   Future<void> _initiatePayment(BuildContext context) async {
//     await _saveBookingToFirestore();
//     final url = await _createToyyibPayBill();
//     if (url.isNotEmpty) {
//       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to initiate payment. Please try again.")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F7FB),
//       appBar: AppBar(
//         backgroundColor: Colors.teal,
//         title: const Text("Payment Summary", style: TextStyle(fontWeight: FontWeight.bold)),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Card(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             elevation: 4,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//                   child: Image.network(spImageURL, height: 200, width: double.infinity, fit: BoxFit.cover),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(spName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 6),
//                       Text(IPTitle, style: TextStyle(color: Colors.grey[700])),
//                       const Divider(height: 24),
//                       Row(children: [const Icon(Icons.location_on, color: Colors.teal), const SizedBox(width: 8), Expanded(child: Text(location))]),
//                       const SizedBox(height: 10),
//                       Row(children: [const Icon(Icons.calendar_month, color: Colors.teal), const SizedBox(width: 8), Text("Preferred: ${formatDate(preferredDate)} at ${formatTime(preferredTime)}")]),
//                       if (alternativeDate != null && alternativeTime != null)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 6.0),
//                           child: Row(children: [const Icon(Icons.calendar_today_outlined, color: Colors.grey), const SizedBox(width: 8), Text("Alternative: ${formatDate(alternativeDate!)} at ${formatTime(alternativeTime!)}")]),
//                         ),
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.teal[50],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text("Total Price", style: TextStyle(fontSize: 16)),
//                 Text("RM$totalPrice", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.payment),
//             label: const Text("Proceed to Payment"),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//               backgroundColor: Colors.teal[700],
//             ),
//             onPressed: () => _initiatePayment(context),
//           )
//         ],
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
// import 'package:intl/intl.dart';
// import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';
//
// class s_IPPaymentSummary extends StatefulWidget {
//   final String spName;
//   final String spImageURL;
//   final String IPTitle;
//   final String location;
//   final DateTime preferredDate;
//   final TimeOfDay preferredTime;
//   final DateTime? alternativeDate;
//   final TimeOfDay? alternativeTime;
//   final int totalPrice;
//   final String toyyibSecretKey;
//   final String toyyibCategory;
//   final String bookingId;
//   final String userEmail;
//   final String userPhone;
//   final String serviceSeekerId;
//   final String serviceCategory;
//   final String postId;
//   final String spId;
//
//   const s_IPPaymentSummary({
//     super.key,
//     required this.spName,
//     required this.spImageURL,
//     required this.IPTitle,
//     required this.location,
//     required this.preferredDate,
//     required this.preferredTime,
//     this.alternativeDate,
//     this.alternativeTime,
//     required this.totalPrice,
//     required this.toyyibSecretKey,
//     required this.toyyibCategory,
//     required this.bookingId,
//     required this.userEmail,
//     required this.userPhone,
//     required this.serviceSeekerId,
//     required this.serviceCategory,
//     required this.postId,
//     required this.spId,
//   });
//
//   @override
//   State<s_IPPaymentSummary> createState() => _s_IPPaymentSummaryState();
// }
//
// class _s_IPPaymentSummaryState extends State<s_IPPaymentSummary> {
//   List<String> ipImages = [];
//
//   @override
//   void initState() {
//     super.initState();
//     fetchPostImage();
//   }
//
//   Future<void> fetchPostImage() async {
//     final doc = await FirebaseFirestore.instance
//         .collection('instant_booking')
//         .doc(widget.postId)
//         .get();
//
//     if (doc.exists) {
//       final data = doc.data();
//       if (data != null && data['IPImage'] is List) {
//         setState(() {
//           ipImages = List<String>.from(data['IPImage']);
//         });
//       }
//     }
//   }
//
//   String formatDate(DateTime date) => DateFormat("d MMM yyyy").format(date);
//   String formatTime(TimeOfDay time) {
//     final now = DateTime.now();
//     final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
//     return DateFormat.jm().format(dt);
//   }
//
//   Future<void> _saveBookingToFirestore() async {
//     await FirebaseFirestore.instance.collection('bookings').add({
//       'bookingId': widget.bookingId,
//       'serviceProviderId': widget.spId,
//       'spName': widget.spName,
//       'spImageURL': widget.spImageURL,
//       'postId': widget.postId,
//       'IPTitle': widget.IPTitle,
//       'serviceCategory': widget.serviceCategory,
//       'serviceSeekerId': widget.serviceSeekerId,
//       'location': widget.location,
//       'preferredDate': formatDate(widget.preferredDate),
//       'preferredTime': formatTime(widget.preferredTime),
//       'alternativeDate': widget.alternativeDate != null ? formatDate(widget.alternativeDate!) : null,
//       'alternativeTime': widget.alternativeTime != null ? formatTime(widget.alternativeTime!) : null,
//       'status': 'pending',
//       'bookedAt': FieldValue.serverTimestamp(),
//       'price': widget.totalPrice,
//       'spUSecret': widget.toyyibSecretKey,
//       'spCCode': widget.toyyibCategory,
//       "providerHasSeen": false,
//       'createdAt': FieldValue.serverTimestamp(),
//       'updatedAt': FieldValue.serverTimestamp(),
//     });
//   }
//
//   Future<String> _createToyyibPayBill() async {
//     try {
//       final buo = BranchUniversalObject(
//         canonicalIdentifier: 'booking/${widget.bookingId}',
//         title: 'Booking Confirmed',
//         contentDescription: 'Tap to confirm your booking in FixMate',
//         contentMetadata: BranchContentMetaData()
//           ..addCustomMetadata('bookingId', widget.bookingId)
//           ..addCustomMetadata('spId', widget.spId)
//           ..addCustomMetadata('serviceSeekerId', widget.serviceSeekerId)
//           ..addCustomMetadata('postId', widget.postId),
//       );
//
//       final lp = BranchLinkProperties(channel: 'toyyibpay', feature: 'payment');
//       final response = await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
//       final deepLink = response.success ? response.result : 'https://fixmate.com/deeplink-fallback';
//
//       final bodyData = {
//         'userSecretKey': widget.toyyibSecretKey,
//         'categoryCode': widget.toyyibCategory,
//         'billName': 'Service Booking',
//         'billDescription': 'Payment for booking ID: ${widget.bookingId}',
//         'billPriceSetting': '1',
//         'billPayorInfo': '1',
//         'billAmount': (widget.totalPrice * 100).toString(),
//         'billReturnUrl': deepLink,
//         'billCallbackUrl': 'https://your-server.com/toyyibpay-callback',
//         'billExternalReferenceNo': widget.bookingId,
//         'billTo': widget.userEmail,
//         'billEmail': widget.userEmail,
//         'billPhone': widget.userPhone,
//       };
//
//       final apiUrl = Uri.parse('https://toyyibpay.com/index.php/api/createBill');
//       final responseToyyib = await http.post(apiUrl, body: bodyData);
//       final responseData = jsonDecode(responseToyyib.body);
//
//       if (responseToyyib.statusCode == 200 && responseData.isNotEmpty && responseData[0]['BillCode'] != null) {
//         return "https://toyyibpay.com/${responseData[0]['BillCode']}";
//       }
//       return "";
//     } catch (e) {
//       print("❌ Error during payment bill creation: $e");
//       return "";
//     }
//   }
//
//   Future<void> _initiatePayment(BuildContext context) async {
//     await _saveBookingToFirestore();
//     final url = await _createToyyibPayBill();
//     if (url.isNotEmpty) {
//       await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to initiate payment. Please try again.")),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F7FB),
//       appBar: AppBar(
//         backgroundColor: Colors.teal,
//         title: const Text("Payment Summary", style: TextStyle(fontWeight: FontWeight.bold)),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           ipImages.isNotEmpty
//               ? GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: widget.postId)),
//               );
//             },
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(16),
//               child: Image.network(ipImages[0], height: 200, width: double.infinity, fit: BoxFit.cover),
//             ),
//           )
//               : Container(
//             height: 200,
//             decoration: BoxDecoration(
//               color: Colors.grey[200],
//               borderRadius: BorderRadius.circular(16),
//             ),
//             alignment: Alignment.center,
//             child: const CircularProgressIndicator(),
//           ),
//           const SizedBox(height: 20),
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.teal[50],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text("Total Price", style: TextStyle(fontSize: 16)),
//                 Text("RM$totalPrice", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//               ],
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.payment),
//             label: const Text("Proceed to Payment"),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//               backgroundColor: Colors.teal[700],
//             ),
//             onPressed: () => _initiatePayment(context),
//           )
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:intl/intl.dart';
import 'package:fix_mate/service_seeker/s_InstantPostInfo.dart';

class s_IPPaymentSummary extends StatefulWidget {
  final String spName;
  final String spImageURL;
  final String IPTitle;
  final String location;
  final DateTime preferredDate;
  final TimeOfDay preferredTime;
  final DateTime? alternativeDate;
  final TimeOfDay? alternativeTime;
  final int totalPrice;
  final String toyyibSecretKey;
  final String toyyibCategory;
  final String bookingId;
  final String userEmail;
  final String userPhone;
  final String serviceSeekerId;
  final String serviceCategory;
  final String postId;
  final String spId;

  const s_IPPaymentSummary({
    super.key,
    required this.spName,
    required this.spImageURL,
    required this.IPTitle,
    required this.location,
    required this.preferredDate,
    required this.preferredTime,
    this.alternativeDate,
    this.alternativeTime,
    required this.totalPrice,
    required this.toyyibSecretKey,
    required this.toyyibCategory,
    required this.bookingId,
    required this.userEmail,
    required this.userPhone,
    required this.serviceSeekerId,
    required this.serviceCategory,
    required this.postId,
    required this.spId,
  });

  @override
  State<s_IPPaymentSummary> createState() => _s_IPPaymentSummaryState();
}

class _s_IPPaymentSummaryState extends State<s_IPPaymentSummary> {
  List<String> ipImages = [];
  bool _agreedToTerms = false;


  @override
  void initState() {
    super.initState();
    fetchPostImage();
  }

  Future<void> fetchPostImage() async {
    final doc = await FirebaseFirestore.instance
        .collection('instant_booking')
        .doc(widget.postId)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['IPImage'] is List) {
        setState(() {
          ipImages = List<String>.from(data['IPImage']);
        });
      }
    }
  }

  String formatDate(DateTime date) => DateFormat("d MMM yyyy").format(date);
  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _saveBookingToFirestore() async {
    await FirebaseFirestore.instance.collection('bookings').add({
      'bookingId': widget.bookingId,
      'serviceProviderId': widget.spId,
      'spName': widget.spName,
      'spImageURL': widget.spImageURL,
      'postId': widget.postId,
      'IPTitle': widget.IPTitle,
      'serviceCategory': widget.serviceCategory,
      'serviceSeekerId': widget.serviceSeekerId,
      'location': widget.location,
      'preferredDate': formatDate(widget.preferredDate),
      'preferredTime': formatTime(widget.preferredTime),
      'alternativeDate': widget.alternativeDate != null ? formatDate(widget.alternativeDate!) : null,
      'alternativeTime': widget.alternativeTime != null ? formatTime(widget.alternativeTime!) : null,
      'status': 'pending',
      'bookedAt': FieldValue.serverTimestamp(),
      'price': widget.totalPrice,
      'spUSecret': widget.toyyibSecretKey,
      'spCCode': widget.toyyibCategory,
      "providerHasSeen": false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> _createToyyibPayBill() async {
    try {
      final buo = BranchUniversalObject(
        canonicalIdentifier: 'booking/${widget.bookingId}',
        title: 'Booking Confirmed',
        contentDescription: 'Tap to confirm your booking in FixMate',
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('bookingId', widget.bookingId)
          ..addCustomMetadata('spId', widget.spId)
          ..addCustomMetadata('serviceSeekerId', widget.serviceSeekerId)
          ..addCustomMetadata('postId', widget.postId),
      );

      final lp = BranchLinkProperties(channel: 'toyyibpay', feature: 'payment');
      final response = await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
      final deepLink = response.success ? response.result : 'https://fixmate.com/deeplink-fallback';

      final bodyData = {
        'userSecretKey': widget.toyyibSecretKey,
        'categoryCode': widget.toyyibCategory,
        'billName': 'Service Booking',
        'billDescription': 'Payment for booking ID: ${widget.bookingId}',
        'billPriceSetting': '1',
        'billPayorInfo': '1',
        'billAmount': (widget.totalPrice * 100).toString(),
        'billReturnUrl': deepLink,
        'billCallbackUrl': 'https://your-server.com/toyyibpay-callback',
        'billExternalReferenceNo': widget.bookingId,
        'billTo': widget.userEmail,
        'billEmail': widget.userEmail,
        'billPhone': widget.userPhone,
      };

      final apiUrl = Uri.parse('https://toyyibpay.com/index.php/api/createBill');
      final responseToyyib = await http.post(apiUrl, body: bodyData);
      final responseData = jsonDecode(responseToyyib.body);

      if (responseToyyib.statusCode == 200 && responseData.isNotEmpty && responseData[0]['BillCode'] != null) {
        return "https://toyyibpay.com/${responseData[0]['BillCode']}";
      }
      return "";
    } catch (e) {
      print("❌ Error during payment bill creation: $e");
      return "";
    }
  }

  Future<void> _initiatePayment(BuildContext context) async {
    await _saveBookingToFirestore();
    final url = await _createToyyibPayBill();
    if (url.isNotEmpty) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to initiate payment. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfb9798),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Payment Summary",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        titleSpacing: 5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ipImages.isNotEmpty
              ? GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => s_InstantPostInfo(docId: widget.postId)),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(ipImages[0], height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      widget.IPTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          )
              : Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Service Provider", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(backgroundImage: NetworkImage(widget.spImageURL), radius: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(widget.spName, style: const TextStyle(fontSize: 16))),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Booking Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [const Icon(Icons.home_repair_service, color: Color(0xFFfb9798)), SizedBox(width: 8), Expanded(child: Text(widget.IPTitle))]),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.location_on, color: Color(0xFFfb9798)), SizedBox(width: 8), Expanded(child: Text(widget.location))]),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.calendar_today, color: Color(0xFFfb9798)), SizedBox(width: 8), Text("Preferred: ${formatDate(widget.preferredDate)} at ${formatTime(widget.preferredTime)}")]),
                  if (widget.alternativeDate != null && widget.alternativeTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(children: [const Icon(Icons.schedule_outlined, color: Colors.grey), SizedBox(width: 8), Text("Alternative: ${formatDate(widget.alternativeDate!)} at ${formatTime(widget.alternativeTime!)}")]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFfb9798).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Price", style: TextStyle(fontSize: 16)),
                Text("RM${widget.totalPrice}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2), // Slight nudge to align baseline
                child: Checkbox(
                  value: _agreedToTerms,
                  activeColor: const Color(0xFFfb9798),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _agreedToTerms = newValue ?? false;
                    });
                  },
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            constraints: const BoxConstraints(maxHeight: 400),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Terms & Conditions",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      "By proceeding with this payment, you agree to the following:\n\n"
                                          "1. Your booking is subject to the service provider's availability and confirmation.\n\n"
                                          "2. We strongly encourage you to consult the provider beforehand to ensure the service matches your expectations.\n\n"
                                          "3. You may request rescheduling or cancellation in line with the provider's stated policies.\n\n"
                                          "4. FixMate is here to help facilitate smooth communication and resolution, but actual service delivery is the responsibility of the provider.\n\n"
                                          "5. Refunds, if applicable, are processed by the provider and may require proof or discussion.\n\n"
                                          "💬 Tip: To avoid misunderstandings, kindly chat with your provider to confirm details before proceeding.",
                                      style: TextStyle(fontSize: 14, height: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close", style: TextStyle(color: Color(0xFFfb9798))),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text.rich(
                      TextSpan(
                        text: "I have read and agree to the ",
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        children: [
                          TextSpan(
                            text: "Terms & Conditions",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFfb9798),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // ElevatedButton.icon(
          //   icon: const Icon(
          //     Icons.payment,
          //     color: Colors.white,
          //     size: 24, // 👈 Bigger icon (default is 24, you can try 26 or 28 if needed)
          //   ),
          //   label: const Text(
          //     "Proceed to Payment",
          //     style: TextStyle(
          //       color: Colors.white,
          //       fontSize: 18, // 👈 Set text size to 16
          //     ),
          //   ),
          //   style: ElevatedButton.styleFrom(
          //     padding: const EdgeInsets.symmetric(vertical: 16),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(30),
          //     ),
          //     backgroundColor: const Color(0xFFfb9798),
          //   ),
          //   onPressed: () => _initiatePayment(context),
          // )
          ElevatedButton.icon(
            icon: const Icon( Icons.payment, color: Colors.white),
            label: Text(
              _agreedToTerms ? "Proceed to Payment" : "Please Agree to Terms",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              backgroundColor: _agreedToTerms ? const Color(0xFFfb9798) : Colors.grey,
              elevation: 3,
            ),
            onPressed: _agreedToTerms ? () => _initiatePayment(context) : null,
          ),
        ],
      ),
    );
  }
}