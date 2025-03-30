// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:url_launcher/url_launcher.dart';
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
//   }) : super(key: key);
//
//   Future<String> _createToyyibPayBill() async {
//     try {
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
//         'billReturnUrl': 'https://yourapp.com/payment-success?bookingId=$bookingId',
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
//       var response = await http.post(apiUrl, body: bodyData);
//
//       print("🔹 Response Status Code: ${response.statusCode}");
//       print("🔹 Response Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         List<dynamic> responseData = jsonDecode(response.body); // ✅ FIX: Expecting a list
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
//         print("❌ Failed to create bill: ${response.body}");
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


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:intl/intl.dart'; // At the top

class s_IPPaymentSummary extends StatelessWidget {
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
    Key? key,
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
  }) : super(key: key);


  String formatDate(DateTime date) => DateFormat("d MMM yyyy", "ms_MY").format(date);
  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt); // e.g., 12:30 PM
  }


  Future<void> _saveBookingToFirestore() async {
    await FirebaseFirestore.instance.collection('bookings').add({
      'bookingId': bookingId,
      'serviceProviderId': spId,
      'spName': spName,
      'spImageURL': spImageURL,
      'postId': postId,
      'IPTitle': IPTitle,
      'serviceCategory': serviceCategory,
      'serviceSeekerId': serviceSeekerId,
      'location': location,
      'preferredDate': formatDate(preferredDate),
      'preferredTime': formatTime(preferredTime),
      'alternativeDate': alternativeDate != null ? formatDate(alternativeDate!) : null,
      'alternativeTime': alternativeTime != null ? formatTime(alternativeTime!) : null,
      'status': 'pending',
      'bookedAt': FieldValue.serverTimestamp(),
      'price': totalPrice,
      'spUSecret': toyyibSecretKey,
      'spCCode': toyyibCategory,
    });
  }

  Future<String> _generateBranchLink(String bookingId) async {
    BranchUniversalObject buo = BranchUniversalObject(
      canonicalIdentifier: 'booking/$bookingId',
      title: 'Your Booking ID',
      contentDescription: 'Tap to view your booking details',
      contentMetadata: BranchContentMetaData()
        ..addCustomMetadata('bookingId', bookingId),
    );

    BranchLinkProperties lp = BranchLinkProperties(
      channel: 'fixmate',
      feature: 'booking',
    );

    BranchResponse response = await FlutterBranchSdk.getShortUrl(
      buo: buo,
      linkProperties: lp,
    );

    if (response.success) {
      print('✅ Branch deep link sent to ToyyibPay: ${response.result}');
      return response.result;
    } else {
      print('❌ Branch link error: ${response.errorMessage}');
      return 'https://fixmate.com/deeplink-fallback';
    }
  }

  // Future<String> _createToyyibPayBill() async {
  //   try {
  //     Uri apiUrl = Uri.parse('https://toyyibpay.com/index.php/api/createBill');
  //
  //     Map<String, String> bodyData = {
  //       'userSecretKey': toyyibSecretKey,
  //       'categoryCode': toyyibCategory,
  //       'billName': 'Service Booking',
  //       'billDescription': 'Payment for booking ID: $bookingId',
  //       'billPriceSetting': '1',
  //       'billPayorInfo': '1',
  //       'billAmount': (totalPrice * 100).toString(),
  //       // 'billReturnUrl': 'https://yourapp.com/payment-success?bookingId=$bookingId',
  //       'billReturnUrl': await _generateBranchLink(bookingId),
  //       'billCallbackUrl': 'https://your-server.com/toyyibpay-callback',
  //       'billExternalReferenceNo': bookingId,
  //       'billTo': userEmail,
  //       'billEmail': userEmail,
  //       'billPhone': userPhone,
  //     };
  //
  //     print("🔹 Sending Request to ToyyibPay...");
  //     print("📝 Request Data: $bodyData");
  //
  //     var response = await http.post(apiUrl, body: bodyData);
  //
  //     print("🔹 Response Status Code: ${response.statusCode}");
  //     print("🔹 Response Body: ${response.body}");
  //
  //     if (response.statusCode == 200) {
  //       List<dynamic> responseData = jsonDecode(response.body); // ✅ FIX: Expecting a list
  //
  //       if (responseData.isNotEmpty && responseData[0].containsKey('BillCode')) {
  //         String billCode = responseData[0]['BillCode'];
  //         String paymentUrl = "https://toyyibpay.com/$billCode";
  //         print("✅ Payment URL: $paymentUrl");
  //         return paymentUrl;
  //       } else {
  //         print("⚠️ Unexpected response format from ToyyibPay.");
  //         return "";
  //       }
  //     } else {
  //       print("❌ Failed to create bill: ${response.body}");
  //       return "";
  //     }
  //   } catch (e) {
  //     print("❌ Error creating ToyyibPay bill: $e");
  //     return "";
  //   }
  // }

  Future<String> _createToyyibPayBill() async {

    try {
      // 🔹 STEP 1: Generate Branch Deep Link FIRST
      String? deepLink;
      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: 'booking/$bookingId',
        title: 'Booking Confirmed',
        contentDescription: 'Tap to confirm your booking in FixMate',
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata('bookingId', bookingId),
      );

      BranchLinkProperties lp = BranchLinkProperties(
        channel: 'toyyibpay',
        feature: 'payment',
      );

      BranchResponse response = await FlutterBranchSdk.getShortUrl(
        buo: buo,
        linkProperties: lp,
      );

      if (response.success) {
        deepLink = response.result;
        print("✅ Generated Branch Deep Link: $deepLink");
      } else {
        print("❌ Failed to generate Branch deep link: ${response.errorMessage}");
        deepLink = 'https://fixmate.com/deeplink-fallback'; // Fallback link
      }

      // 🔹 STEP 2: Prepare ToyyibPay Bill Request
      Uri apiUrl = Uri.parse('https://toyyibpay.com/index.php/api/createBill');

      Map<String, String> bodyData = {
        'userSecretKey': toyyibSecretKey,
        'categoryCode': toyyibCategory,
        'billName': 'Service Booking',
        'billDescription': 'Payment for booking ID: $bookingId',
        'billPriceSetting': '1',
        'billPayorInfo': '1',
        'billAmount': (totalPrice * 100).toString(),
        'billReturnUrl': deepLink!,
        'billCallbackUrl': 'https://your-server.com/toyyibpay-callback',
        'billExternalReferenceNo': bookingId,
        'billTo': userEmail,
        'billEmail': userEmail,
        'billPhone': userPhone,
      };

      print("🔹 Sending Request to ToyyibPay...");
      print("📝 Request Data: $bodyData");

      var responseToyyib = await http.post(apiUrl, body: bodyData);

      print("🔹 Response Status Code: ${responseToyyib.statusCode}");
      print("🔹 Response Body: ${responseToyyib.body}");

      if (responseToyyib.statusCode == 200) {
        List<dynamic> responseData = jsonDecode(responseToyyib.body);

        if (responseData.isNotEmpty && responseData[0].containsKey('BillCode')) {
          String billCode = responseData[0]['BillCode'];
          String paymentUrl = "https://toyyibpay.com/$billCode";
          print("✅ Payment URL: $paymentUrl");
          return paymentUrl;
        } else {
          print("⚠️ Unexpected response format from ToyyibPay.");
          return "";
        }
      } else {
        print("❌ Failed to create bill: ${responseToyyib.body}");
        return "";
      }
    } catch (e) {
      print("❌ Error creating ToyyibPay bill: $e");
      return "";
    }
  }


  /// 🚀 Launch Payment in Browser
  Future<void> _initiatePayment() async {
    await _saveBookingToFirestore();

    String paymentUrl = await _createToyyibPayBill();
    if (paymentUrl.isNotEmpty) {

      Uri uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print("❌ Could not launch payment URL: $paymentUrl");
      }
    } else {
      print("⚠️ Payment URL is empty. Check API response.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Payment Summary")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(spImageURL, height: 100, fit: BoxFit.cover),
            SizedBox(height: 10),
            Text(spName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(IPTitle, style: TextStyle(fontSize: 16, color: Colors.grey)),
            Divider(),
            Text("Location: $location"),
            Text("Preferred Date: ${preferredDate.toLocal()}"),
            Text("Preferred Time: ${preferredTime.format(context)}"),
            if (alternativeDate != null) Text("Alternative Date: ${alternativeDate!.toLocal()}"),
            if (alternativeTime != null) Text("Alternative Time: ${alternativeTime!.format(context)}"),
            SizedBox(height: 20),
            Text("Total Price: RM$totalPrice", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // Spacer(),
            ElevatedButton(
              onPressed: _initiatePayment,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text("Buy Now"),
            ),
          ],
        ),
      ),
    );
  }
}
