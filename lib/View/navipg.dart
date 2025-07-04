import 'package:flutter/material.dart';
// import 'feed_dat.dart';
import 'home_page.dart';
// import 'shorts.dart';
// import 'chatlist.dart';
import 'Profile.dart';

void main() => runApp(MaterialApp(
  home: navCard(),
));

class navCard extends StatefulWidget {
  @override
  State<navCard> createState() => _navCardState();
}
class _navCardState extends State<navCard> {
  //String wanted= '';
  //TextEditingController _otp = TextEditingController();
  //var _formkey= GlobalKey<FormState>();
  // SpellCheck(),

  int _selectedIndex = 0;
  final List<Widget> _pages = [
    HomeScreen(),
    NotificationsScreen(),
    ProfileScreen(),
    // Shorts(),
    // MessagesScreen(),
  ];




  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 0.0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // BottomNavigationBarType.shifting
        elevation: 3.0,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        iconSize: 20.0,
        backgroundColor: Colors.transparent,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.transparent,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile'
          ),
          // BottomNavigationBarItem(
          //     icon: Icon(Icons.slow_motion_video_rounded),
          //     label: 'Bytes'
          // ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.messenger_outline),
          //   label: "chats",
          // ),
        ],
      ),

    );
  }
}




// class SpellCheck extends StatefulWidget{
//   @override
//   State<SpellCheck> createState() => _SpellCheck();
// }
// class _SpellCheck extends State<SpellCheck> {
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       title: 'Video Player Demo',
//       // home: VideoPlayerScreen(),
//     );
//   }



class NotificationsScreen extends StatefulWidget{
  @override
  State<NotificationsScreen> createState() => _NotificationsScreen();
}

class _NotificationsScreen extends State<NotificationsScreen>  {
  Widget Noti_card(noticard) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade900.withOpacity(0.7),
            blurRadius: 5.0,
            spreadRadius: 2.0,
            offset: const Offset(0.0, 1.0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('assets/pingirl.png'),
                radius: 15.0,
              ),
              SizedBox(width: 13.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(noticard.ouser,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 20.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(height: 3.0),
                  Text(noticard.note,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15.0,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(width: 30.0),
          Text(noticard.lstsn,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.0,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Center(child:ListView(
        scrollDirection: Axis.vertical,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0,5.0,10.0,0.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 400,
                    height: 53,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade900.withOpacity(0.7),
                          blurRadius: 5.0,
                          spreadRadius: 2.0,
                          offset: const Offset(0.0, 1.0),
                        ),
                      ],
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("baan_kai_",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 20.0,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(height: 3.0),
                  // Noti_card(noticard(ouser:"cami_123",note:'liked your reel',lstsn:'3 mins ago'),),
                  // SizedBox(height: 10.0),
                  // Noti_card(noticard(ouser:"sade_sink",note:'posted a photo',lstsn:'1 mins ago'),),
                  // SizedBox(height: 3.0),
                  // Noti_card(noticard(ouser:"cami_123",note:'liked your reel',lstsn:'3 mins ago'),),
                  // SizedBox(height: 10.0),
                  // Noti_card(noticard(ouser:"sade_sink",note:'posted a photo',lstsn:'1 mins ago'),),
                  // SizedBox(height: 3.0),
                  // Noti_card(noticard(ouser:"cami_123",note:'liked your reel',lstsn:'3 mins ago'),),
                  // SizedBox(height: 10.0),
                  // Noti_card(noticard(ouser:"sade_sink",note:'posted a photo',lstsn:'1 mins ago'),),
                  // SizedBox(height: 10.0),
                  // Noti_card(noticard(ouser:"cami_sink",note:'posted a photo',lstsn:'1 mins ago'),),
                ]),
          ),
        ]
    ),
    );
  }
}



