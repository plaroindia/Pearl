import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'View/intro_page.dart';
import 'View/home_page.dart';
import 'View/login_page.dart';
import 'View/navipg.dart';
import 'View/followers_page.dart';
import 'View/following_page.dart';



void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/navipg': (context) => navCard(),
        'Followers_page': (context) => const FollowersPage(),
        'Followee_page': (context) => const FollowingPage(),
      },
      debugShowCheckedModeBanner: false,
      title: 'PLARO',
      home: IntroPage(),
    );
  }
}