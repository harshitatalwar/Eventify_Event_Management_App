import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aivent/views/loginpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:aivent/views/EventDetail.dart';
import 'package:aivent/views/background_container.dart';
import 'package:aivent/views/Promotions.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyA0LJr4wQoNoQbGymac4Zu56rm8VYplJpE",
          appId: "1:670374321382:android:a4867aec03effdb8532f27",
          messagingSenderId: "670374321382",
          projectId: "aivent-5105a",
          storageBucket: "aivent-5105a.appspot.com"
      )
  );
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    runApp(const MaterialApp(
      home: LoginPage(),
    ));
  } else {
    runApp(App());
  }

}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Created Events',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: BackgroundContainer(
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserCreatedEventsPage()),
              );
            },
            child: Text('View Your Events'),
          ),
        ),
      ),
    );
  }
}

class UserCreatedEventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case where the user is not logged in
      return Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Events Created by You'),
      ),
      body: BackgroundContainer(
        child:_buildEventList(currentUser.uid),
      ),
    );
  }

  Widget _buildEventList(String userId) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: getEventsCreatedByCurrentUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No events found'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var event = snapshot.data![index];
            return _buildEventTile(event);
          },
        );
      },
    );
  }


  Widget _buildEventTile(DocumentSnapshot event) {
    return FutureBuilder<String>(
      future: _getImageUrl(event['logoImage']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text(event['eventName']),
            subtitle: Row(
              children: [
                Icon(Icons.calendar_today),
                SizedBox(width: 5),
                Text(_formatDate(event['startDate'])),
                SizedBox(width: 20),
                Icon(Icons.location_on),
                SizedBox(width: 5),
                Text(event['eventVenue']),
              ],
            ),
            onTap: () {
              _navigateToEventDetails(context, event.id); // Navigate to event details
            },
          );
        } else if (snapshot.hasError) {
          return ListTile(
            title: Text(event['eventName']),
            subtitle: Row(
              children: [
                Icon(Icons.calendar_today),
                SizedBox(width: 5),
                Text(_formatDate(event['startDate'])),
                SizedBox(width: 20),
                Icon(Icons.location_on),
                SizedBox(width: 5),
                Text(event['eventVenue']),
              ],
            ),
          );
        } else {
          String imageUrl = snapshot.data ?? '';
          String status = event['status'];
          String? disapprovalReason;

          if (status == 'Disapproved') {
            disapprovalReason = event['disapprovalReason'];
          }

          // Determine whether to show the promote button
          bool showPromoteButton = event['createdBy'] == FirebaseAuth.instance.currentUser?.uid &&
              status == 'Approved';

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
            ),
            title: Text(event['eventName']),
            subtitle: Row(
              children: [
                Icon(Icons.calendar_today),
                SizedBox(width: 5),
                Text(_formatDate(event['startDate'])),
                SizedBox(width: 20),
                Icon(Icons.location_on),
                SizedBox(width: 5),
                Text(event['eventVenue']),
              ],
            ),
            onTap: () {
              _navigateToEventDetails(context, event.id); // Add navigation logic if needed
            },
            // Show promote button if the event is created by the current user and is approved
            trailing: showPromoteButton
                ? ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PromotionsPage(eventId: event.id),
                  ),
                );
              },
              child: Text('Promote'),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Status: $status'),
                if (status == 'Disapproved' && disapprovalReason != null)
                  Text('Reason: $disapprovalReason'),
              ],
            ),
          );
        }
      },
    );
  }
  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  Future<List<DocumentSnapshot>> getEventsCreatedByCurrentUser(String userId) async {
    QuerySnapshot approvedSnapshot = await FirebaseFirestore.instance
        .collection('approved_events')
        .where('createdBy', isEqualTo: userId)
        .get();

    QuerySnapshot disapprovedSnapshot = await FirebaseFirestore.instance
        .collection('disapproved_events')
        .where('createdBy', isEqualTo: userId)
        .get();

    List<DocumentSnapshot> allEvents = [];
    allEvents.addAll(approvedSnapshot.docs);
    allEvents.addAll(disapprovedSnapshot.docs);

    return allEvents;
  }


  Future<String> _getImageUrl(String imagePath) async {
    try {
      Reference storageReference = FirebaseStorage.instance.ref().child(imagePath);
      return await storageReference.getDownloadURL();
    } catch (e) {
      print('Error getting image URL: $e');
      return ''; // Return empty string on error
    }
  }
  void _navigateToEventDetails(BuildContext context, String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetails(eventId: eventId),
      ),
    );
  }
}


