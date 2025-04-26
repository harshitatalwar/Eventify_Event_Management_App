import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aivent/views/loginpage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'background_container.dart';
import 'EventDetail.dart';
import 'ViewPromotionsPage.dart'; // Import the ViewPromotionsPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "",
        appId: "1:670374321382:android:a4867aec03effdb8532f27",
        messagingSenderId: "670374321382",
        projectId: "aivent-5105a",
        storageBucket: "aivent-5105a.appspot.com"
    ),
  );
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    runApp(const MaterialApp(
      home: LoginPage(),
    ));
  } else {
    runApp(MyApp_());
  }
}

class MyApp_ extends StatelessWidget {
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
                MaterialPageRoute(builder: (context) => ViewPromotionEventsPage()),
              );
            },
            child: Text('View Your Events'),
          ),
        ),
      ),
    );
  }
}

class ViewPromotionEventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case where the user is not logged in
      return Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Events Registered by You'),
      ),
      body: BackgroundContainer(
        child: _buildEventList(currentUser.uid),
      ),
    );
  }

  Widget _buildEventList(String userId) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: getEventsRegisteredByCurrentUser(userId),
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
            return _buildEventTile(context, event);
          },
        );
      },
    );
  }

  Widget _buildEventTile(BuildContext context, DocumentSnapshot event) {
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
              _navigateToViewPromotionsPage(context, event.id); // Navigate to ViewPromotionsPage
            },
          );
        }
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  Future<List<DocumentSnapshot>> getEventsRegisteredByCurrentUser(String userId) async {
    QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
        .collection('approved_events')
        .get();

    List<DocumentSnapshot> eventsRegisteredByUser = [];

    for (var eventDoc in eventSnapshot.docs) {
      QuerySnapshot participantsSnapshot = await eventDoc.reference
          .collection('participants')
          .where('userId', isEqualTo: userId)
          .get();

      if (participantsSnapshot.docs.isNotEmpty) {
        eventsRegisteredByUser.add(eventDoc);
      }
    }

    return eventsRegisteredByUser;
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

  void _navigateToViewPromotionsPage(BuildContext context, String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewPromotionsPage(eventId: eventId),
      ),
    );
  }
}
