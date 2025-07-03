import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  backgroundColor: Colors.black,
  iconTheme: IconThemeData(
    color: Colors.white54,
  ),
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text("PLARO",
        style: TextStyle(
          color: Colors.white54,
          fontSize: 20.0,
          letterSpacing: 0.0,
        ),),
      SizedBox(width: 30,),
      IconButton(onPressed: (){},
        icon: Icon(Icons.search),),
    ],
  ),
),
    );
  }
}
