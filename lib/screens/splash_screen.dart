import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 5), () {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );

    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topLeft,
            end: Alignment.bottomRight,

            colors: [


              Color.fromARGB(255, 9, 71, 3),
              Color(0xff4CAF50), // normal green

            ],
          ),
        ),

        child: Center(

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Container(

                padding: EdgeInsets.all(30),

                decoration: BoxDecoration(

                  color: Colors.white.withOpacity(0.25),

                  shape: BoxShape.circle,
                ),

                child: Icon(

                  Icons.grass,

                  size: 110,

                  color: Colors.white,
                ),
              ),

              SizedBox(height: 35),

              Text(

                "AgriSense AI",

                style: TextStyle(

                  fontSize: 38,

                  fontWeight: FontWeight.bold,

                  color: Colors.white,

                  letterSpacing: 1,
                ),
              ),

              SizedBox(height: 12),

              Text(

                "Multi-Agent Crop Advisory System",

                style: TextStyle(

                  fontSize: 17,

                  color: Colors.white70,
                ),
              ),

              SizedBox(height: 45),

              CircularProgressIndicator(
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
