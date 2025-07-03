import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'View/intro_page.dart';
import 'View/home_page.dart';
import 'View/login_page.dart';
import 'constants/auth_keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
   );
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
      title: 'PLARO',
      home: IntroPage(),
    );
  }
}