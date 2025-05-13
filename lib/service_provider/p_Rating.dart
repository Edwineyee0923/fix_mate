import 'package:fix_mate/service_provider/p_layout.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class p_Rating extends StatefulWidget {
  static String routeName = "/service_provider/p_Rating";

  const p_Rating({Key? key}) : super(key: key);

  @override
  _p_RatingState createState() => _p_RatingState();
}

class _p_RatingState extends State<p_Rating> {



  @override
  Widget build(BuildContext context) {
    return ProviderLayout(
        selectedIndex: 2,
        child: Scaffold(
          backgroundColor: Color(0xFFFFF8F2),
          appBar: AppBar(
            backgroundColor: Color(0xFF464E65),
            // leading: IconButton(
            //   icon: Icon(Icons.arrow_back_ios_new_rounded),
            //   onPressed: () {
            //     Navigator.pop(context);
            //   },
            // ),
            // centerTitle: true,
            title: Text(
              "Rating",
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
                  Icon(Icons.construction, size: 80, color: Color(0xFF464E65)),
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
