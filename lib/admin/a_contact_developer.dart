import 'package:fix_mate/admin/admin_layout.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class contact_developer extends StatefulWidget {
  static String routeName = "/admin/contact_developer";

  const contact_developer({Key? key}) : super(key: key);

  @override
  _contact_developerState createState() => _contact_developerState();
}

class _contact_developerState extends State<contact_developer> {
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
    return AdminLayout(
      selectedIndex: 2,
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
        // centerTitle: true,
        title: Text(
          "Contact Developers",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,),
        ),
        titleSpacing: 25,
        automaticallyImplyLeading: false,
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: Text(
                    "FixMate Application Developer(s):",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.left,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Feel free to contact us if there is any severe issue in regard to the FixMate application.",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width * 0.8, // 90% of screen width
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Main Developer :",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Yee Wei En",
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Full Stack Fixmate Developer",
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          SizedBox(height: 20),
                          // WhatsApp Button inside Card
                          ElevatedButton.icon(
                            onPressed: _launchWhatsApp,
                            icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
                            label: Text(
                              "Contact via WhatsApp",
                              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Colors.green,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          // Email Button inside Card
                          ElevatedButton.icon(
                            onPressed: _launchEmail,
                            icon: Icon(Icons.email, color: Colors.white),
                            label: Text(
                              "Contact via Email",
                              style: TextStyle(fontSize: 16, color:Colors.white, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xFFFF9342),
                              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      )
    );
  }
}
