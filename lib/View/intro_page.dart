import 'package:flutter/material.dart';
import 'login_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: GestureDetector(
            onTap: (){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );},
            child: Center(
              child:Image.asset(
                'assets/plaro_logo.png',
                width: 200, // Adjust width as needed
                height: 200, // Adjust height as needed
                fit: BoxFit.contain, // Adjust the fit as needed
              ),
            ),
          ),
        ));
  }
}
