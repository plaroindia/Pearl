import 'package:flutter/material.dart';
import 'signin_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87, // Use the theme color you have
      appBar: AppBar(
        //title: Text('PLARO',style: TextStyle(color: Colors.grey)),
        backgroundColor: Colors.black87, // Customize as needed
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Sign In",style: TextStyle(color: Colors.blue,fontSize: 30.0,fontWeight: FontWeight.bold )),
            SizedBox(height: 30.0,),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                fillColor: Colors.grey,
                filled: false,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey), // Set border color to white
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Set border color to white
                ),
                labelStyle: TextStyle(color: Colors.grey),
              ),
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Colors.blue), // Set input text color to blue
            ),

            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                fillColor: Colors.grey,
                filled: false,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey), // Set border color to white
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white), // Set border color to white
                ),
                labelStyle: TextStyle(color: Colors.grey),
              ),
              style: TextStyle(color: Colors.blue),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: (){},//_signIn,
              child: Text('Sign In',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
            TextButton(onPressed: (){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SigninScreen()),
              );},
              child: Text(
                "Don't have an account? Sign up",
                style: TextStyle(color: Colors.grey),
              ),),
            const SizedBox(height: 50),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: (){},//_handleGoogleSignIn,
              icon: Image.asset(
                'assets/google.png',
                width: 23,
                height: 23,
                fit: BoxFit.contain,
              ),
              label: const Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white54,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
