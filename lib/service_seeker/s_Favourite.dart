import 'package:fix_mate/service_seeker/s_layout.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class s_Favourite extends StatefulWidget {
  static String routeName = "/service_seeker/s_Favourite";

  const s_Favourite({Key? key}) : super(key: key);

  @override
  _s_FavouriteState createState() => _s_FavouriteState();
}

class _s_FavouriteState extends State<s_Favourite> {
  // Launch WhatsApp using the URL scheme
  void _launchWhatsApp() async {
    final whatsappUrl = "https://wa.me/60186231106";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open WhatsApp.")),
      );
    }
  }

  // Launch email with prefilled subject and body
  void _launchEmail() async {
    final email = "enweiyee0923@gmail.com";
    final subject = Uri.encodeComponent("Issue with FixMate Application");
    final body = Uri.encodeComponent("Hello,\n\nI have an issue with the FixMate application:");
    final emailUrl = "mailto:$email?subject=$subject&body=$body";
    if (await canLaunch(emailUrl)) {
      await launch(emailUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open the email client.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SeekerLayout(
        selectedIndex: 2,
        child: Scaffold(
          backgroundColor: Color(0xFFFFF8F2),
          appBar: AppBar(
            backgroundColor: Color(0xFFfb9798),
            // leading: IconButton(
            //   icon: Icon(Icons.arrow_back_ios_new_rounded),
            //   onPressed: () {
            //     Navigator.pop(context);
            //   },
            // ),
            // centerTitle: true,
            title: Text(
              "Favourite",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,),
            ),
            titleSpacing: 25,
            automaticallyImplyLeading: false,
          ),

          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction, size: 80, color: Color(0xFFfb9798)),
                  const SizedBox(height: 20),
                  const Text(
                    "Coming Soon!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "We're working hard to bring you this feature. Stay tuned!",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        )
    );
  }
}
