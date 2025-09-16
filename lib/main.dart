import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'View/intro_page.dart';
import 'View/home_page.dart';
import 'View/login_page.dart';
import 'View/navipg.dart';
import 'ViewModel/theme_provider.dart';
import 'View/chat_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: MyApp()));
  initAppLinks();
}

Future<void> initAppLinks() async {
  final appLinks = AppLinks();

  // Handle initial deep link (cold start)
  final initialLink = await appLinks.getInitialLink();
  if (initialLink != null) {
    _handleLink(initialLink.toString());
  }

  // Handle links while app is running
  appLinks.uriLinkStream.listen((uri) {
    _handleLink(uri.toString());
  });
}

void _handleLink(String link) {
  debugPrint('Received deep link: $link');
  final uri = Uri.parse(link);

  // Check for reset-password route
  if (uri.path == '/reset-password' && uri.queryParameters['token'] != null) {
    final token = uri.queryParameters['token']!;
    navigatorKey.currentState?.pushNamed('/reset-password', arguments: token);
  }
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,

      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/navipg': (context) => navCard(),
        '/chat_list':
            (context) =>
            ChatList(userId: Supabase.instance.client.auth.currentUser!.id),
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