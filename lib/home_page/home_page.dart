import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class home_page extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 428,
          height: 926,
          decoration: ShapeDecoration(
            color: Color(0xFFFFFFF2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -58,
                top: 73,
                child: Container(
                  width: 569,
                  height: 514,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/FixMate_Logo.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -19,
                top: 0,
                child: Container(
                  width: 437,
                  height: 47,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 332,
                        top: 19,
                        child: Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 19.97,
                                height: 12,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                  ],
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 17,
                                height: 12.50,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                  ],
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                width: 27.33,
                                height: 13,
                                child: FlutterLogo(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 282,
                        top: 6,
                        child: Container(
                          width: 6,
                          height: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 6,
                                  decoration: ShapeDecoration(shape: OvalBorder()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 70.50,
                        top: 17,
                        child: Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '9:41',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontFamily: 'SF Pro Text',
                                  fontWeight: FontWeight.w600,
                                  height: 1,
                                  letterSpacing: -0.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 58,
                top: 546,
                child: Container(
                  width: 315,
                  height: 60,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4C95ADFE),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 315,
                          height: 60,
                          decoration: ShapeDecoration(
                            color: Color(0xFF464E65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 130,
                        top: 18,
                        child: Text(
                          'Login',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            height: 1.20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 56,
                top: 630,
                child: Container(
                  width: 315,
                  height: 60,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x4C95ADFE),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 315,
                          height: 60,
                          decoration: ShapeDecoration(
                            color: Color(0xFFFB9798),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 116,
                        top: 18,
                        child: Text(
                          'Register',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            height: 1.20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 105,
                top: 714,
                child: SizedBox(
                  width: 224,
                  height: 60,
                  child: SizedBox(
                    width: 224,
                    height: 60,
                    child: Text(
                      'Having Trouble logging in?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 40,
                top: 830,
                child: SizedBox(
                  width: 221,
                  height: 27,
                  child: SizedBox(
                    width: 221,
                    height: 27,
                    child: Text(
                      'Login means you agree to ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 104,
                top: 744,
                child: SizedBox(
                  width: 73,
                  height: 60,
                  child: SizedBox(
                    width: 73,
                    height: 60,
                    child: Text(
                      'Contact',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 174,
                top: 744,
                child: SizedBox(
                  width: 155,
                  height: 27,
                  child: SizedBox(
                    width: 155,
                    height: 27,
                    child: Text(
                      'Customer Service',
                      style: TextStyle(
                        color: Color(0xFF5094D3),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 241,
                top: 830,
                child: SizedBox(
                  width: 154,
                  height: 25,
                  child: SizedBox(
                    width: 154,
                    height: 25,
                    child: Text(
                      'Terms of Service ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 169,
                top: 855,
                child: SizedBox(
                  width: 119,
                  height: 27,
                  child: SizedBox(
                    width: 119,
                    height: 27,
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 125,
                top: 855,
                child: SizedBox(
                  width: 44,
                  height: 20,
                  child: SizedBox(
                    width: 44,
                    height: 20,
                    child: Text(
                      'and',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}