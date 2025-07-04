import 'package:flutter/material.dart';
import 'set_profile.dart';
// import 'feed_dat.dart';
// import 'post.dart';
// import 'create_screen.dart';
// import 'package:audioplayers/audioplayers.dart';



class ProfileScreen extends StatefulWidget{
  @override
  State<ProfileScreen> createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen>  {
  // //This variable are for user_credentials
  // String? username;
  // String? prof_pic;
  // String? user_id;
  // String? study;
  // String? bio;
  //
  //
  // //Below is for feed logic
  // List<String> imageUrls = [];
  // List<Feed> feedo = [];
  // List<Feed> feeds = [];
  // User? user = FirebaseAuth.instance.currentUser;
  //
  //
  //
  // final List<Comment> comment1=[
  //   Comment(username:"dabster_master", profileImage: "assets/pingirl.png", content: "nice da", timeAgo: '3h'),
  // ];
  // final List<Comment> comment2 = [
  //   Comment(username: "cami_dunhy", profileImage: "assets/gpuhairrender.png", content: "This is amazing!", timeAgo: '1h', likes: 10,),
  //   Comment(username: "brad_pitt", profileImage: "assets/pingirl.png", content: "Great job!", timeAgo: '2h', likes: 3,),
  // ];

  // void _playBeep() async {
  //   AudioPlayer player = AudioPlayer();
  //   await player.setVolume(1.0);
  //   await player.play(DeviceFileSource('assets/sounds/beep.mp3'));  // Ensure the file path is correct
  //   await player.resume();  // Play the sound
  // }
  // Future<void> deletePost(int index) async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user == null) return;
  //
  //     // Get the feed to delete
  //     Feed feedToDelete = feedo[index];
  //
  //     // Delete from Firebase
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .collection('feeds')
  //         .where('image_url', isEqualTo: feedToDelete.ufeed)
  //         .get()
  //         .then((querySnapshot) {
  //       for (var doc in querySnapshot.docs) {
  //         doc.reference.delete();
  //       }
  //     });
  //
  //     // Update the state
  //     setState(() {
  //       feedo.removeAt(index);
  //     });
  //
  //     // Show success message
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Post deleted successfully'),
  //           backgroundColor: Colors.green,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print("Error deleting post: $e");
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Error deleting post'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }
  // void _likeFeed(int index) {
  //   setState(() {
  //     feeds[index].likes++; // Increment likes for the specific feed
  //   });
  // }
  // Future<void> _loadUserData() async {
  //   if (user == null) {
  //     // print("No user logged in");
  //     return;
  //   }
  //
  //   try {
  //     DocumentSnapshot userData = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user!.uid)
  //         .get();
  //
  //     if (userData.exists) {
  //       setState(() {
  //         username = userData.get('username');
  //         user_id = userData.get('userId');
  //         study = userData.get('school');
  //         bio = userData.get('bio');
  //         prof_pic = userData.get('profileImageUrl');
  //       });
  //     } else {
  //       print("User document does not exist");
  //     }
  //   } catch (e) {
  //     print("Error loading user data: $e");
  //   }
  // }
  //
  //
  // Future<List<Feed>> _retrieveUserFeeds() async {
  //   try {
  //     print("Starting _retrieveUserFeeds");
  //
  //     // List to store the user's feeds
  //     List<Feed> allFeeds = [];
  //
  //     // Query Firestore to get feeds for the current user
  //     QuerySnapshot feedSnapshot = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user!.uid)  // Ensure user is logged in and user!.uid is not null
  //         .collection('feeds')
  //         .get();
  //
  //     // Map each feed document to the Feed class
  //     for (var doc in feedSnapshot.docs) {
  //       var username = doc['username'] as String?;
  //       var profpic = doc['prof_pic'] as String?;
  //       var imageUrl = doc['image_url'] as String?;
  //       var caption = doc['caption'] as String? ?? '';
  //       var likes = doc['likes'] as int? ?? 0;
  //       var comments = doc['comments'] as List<dynamic>? ?? [];
  //       var shares = doc['shares'] as int? ?? 0;
  //
  //       // Create a Feed object and add to allFeeds list
  //       allFeeds.add(
  //         Feed(
  //           user: username,
  //           profilePic: profpic ?? '',
  //           ufeed: imageUrl ?? '',
  //           caption: caption,
  //           likes: likes,
  //           comments: comments.length,
  //           shares: shares,
  //           commentsList: comments.map((c) => Comment.fromMap(c)).toList(),
  //         ),
  //       );
  //     }
  //
  //     // Check if feeds were retrieved
  //     if (allFeeds.isNotEmpty) {
  //       setState(() {
  //         feedo = allFeeds;  // Update state with all user feeds
  //       });
  //       print("State updated with ${feedo.length} feeds");
  //     } else {
  //       print("No feeds found");
  //     }
  //
  //     return allFeeds;
  //   } catch (e, stackTrace) {
  //     print("Error retrieving feeds: $e");
  //     print("Stack trace: $stackTrace");
  //     return [];
  //   }
  // }


  @override
  void initState() {
    super.initState();
    // _loadUserData();
    // _retrieveUserFeeds();
  }

  @override
  Widget build(BuildContext context) {
    // final List<Feed> firstColumnPosts = [];
    // final List<Feed> secondColumnPosts = [];
    //
    // // Evenly split the posts between two columns
    // for (int i = 0; i < feedo.length; i++) {
    //   if (i % 2 == 0) {
    //     firstColumnPosts.add(feedo[i]);
    //   } else {
    //     secondColumnPosts.add(feedo[i]);
    //   }
    // }
    return Center(
      child:RefreshIndicator(
        onRefresh: () async {
          // await _retrieveUserFeeds();
          // await _loadUserData();
        },
        color: Colors.blue,
        backgroundColor: Colors.black,
        displacement: 40.0,
        child: ListView(
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // CircleAvatar(
                          //   backgroundImage: prof_pic != null ? NetworkImage(prof_pic!) : AssetImage('assets/pingirl.png'),
                          //   radius: 15.0,
                          // ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("me",//'$user_id',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 20.0,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SizedBox(height: 20.0),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding:  const EdgeInsets.fromLTRB(10.0,20.0,10.0,10.0),
                            child:
                            CircleAvatar(
                              //backgroundImage: prof_pic != null ? NetworkImage(prof_pic!) : AssetImage('assets/pingirl.png'),
                              radius: 45.0,
                            ),
                          ),
                           Text("me",//'$username',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 20.0,
                              letterSpacing: 2.0,
                            ),
                          ),
                           Text('me',//'$study',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.0,
                              letterSpacing: 1.0,
                            ),
                          ),
                           Text('me',//'$bio',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 13.0,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor:Colors.black54,
                                    side: const BorderSide(width: 3.0, color: Colors.blue),
                                    foregroundColor :Colors.blue,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0))
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SetProfile()),
                                  );
                                },
                                child: const Text("Profile"),
                              ),
                              const SizedBox(width: 30.0),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor:Colors.black54,
                                    side: const BorderSide(width: 3.0, color: Colors.purple),
                                    foregroundColor :Colors.purple,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(100.0))
                                ),
                                onPressed: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(builder: (context) => const AddFeed()),
                                  // );
                                },
                                child: const Text("Create"),
                              ),
                              const SizedBox(width: 30.0),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(foregroundColor: Colors.blue,
                                    backgroundColor: Colors.black54,
                                    side: const BorderSide(width: 3.0, color: Colors.blue),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10.0))
                                ),
                                onPressed: () {
                                },
                                child: const Text("Friends"),
                              ),
                            ],
                          ),
                          const SizedBox(height:6.0),

                        ]
                    ),
                    const SizedBox(height:6.0),
                    const Row(
                      children: [
                        Icon(Icons.view_array_outlined,color: Colors.grey,size: 40.0,),
                        SizedBox(width: 6.0,),
                        Text("Your Posts :",style: TextStyle(color: Colors.grey,fontSize: 20.0),),
                      ],
                    ),
                    const SizedBox(height:6.0),
                    const Divider(
                      height: 1.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(height:10.0),
                    SingleChildScrollView(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Expanded(
                          //   child: ListView.builder(
                          //     shrinkWrap: true,
                          //     physics: const NeverScrollableScrollPhysics(),
                          //     itemCount: firstColumnPosts.length,
                          //     itemBuilder: (context, index) {
                          //       final feed = firstColumnPosts[index];
                          //       print("Building FeedCard for image: ${feed.ufeed}");
                          //       return PostCard(
                          //         index: index,
                          //         feed: feed,
                          //         onLike: () => _likeFeed(index),
                          //         comments: feed.commentsList,
                          //         onDelete: deletePost, // Add this
                          //       );
                          //     },
                          //   ),
                          // ),
                          // const SizedBox(width: 10.0),
                          // Expanded(
                          //   child: ListView.builder(
                          //     shrinkWrap: true,
                          //     physics: const NeverScrollableScrollPhysics(),
                          //     itemCount: secondColumnPosts.length,
                          //     itemBuilder: (context, index) {
                          //       final feed = secondColumnPosts[index];
                          //       print("Building FeedCard for image: ${feed.ufeed}");
                          //       return PostCard(
                          //         index: index,
                          //         feed: feed,
                          //         onLike: () => _likeFeed(index),
                          //         comments: feed.commentsList,
                          //         onDelete: deletePost, // Add this
                          //       );
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                    ),

                  ]),
            ),
          ]
            ),
      ),
    );
  }
}






