import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'View/intro_page.dart';
import 'View/home_page.dart';
import 'View/login_page.dart';
import 'View/navipg.dart';
import 'View/followers_page.dart';
import 'View/following_page.dart';
import 'View/foll_page.dart';
import 'package:plaro_3/View/foll_page.dart';
import 'ViewModel/theme_provider.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/navipg': (context) => navCard(),
        // 'Followers_page': (context) => const FollowersPage(),
        // 'Followee_page': (context) => const FollowingPage(),
        //'/FollowPage': (context) => const FollowPage(userId: userId)
      },
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      title: 'PLARO',
      home: IntroPage(),
    );
  }
}