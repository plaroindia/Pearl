import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class textPost extends StatefulWidget {
  const textPost({super.key});

  @override
  State<textPost> createState() => _textPostState();
}

class _textPostState extends State<textPost> {


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return Center(
      child: ListView(
        scrollDirection: Axis.vertical,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Create Text Post',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: isTablet ? 20 : 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
