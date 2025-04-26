import 'package:aivent/views/ReviewForm.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aivent/views/loginpage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'background_container.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "",
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
    runApp(const MyApp());
  }

}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Created Events',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body:BackgroundContainer(
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReviewEventsPage()),
              );
            },
            child: const Text('View Your Events'),
          ),
        ),
      ),
    );
  }
}


class ReviewEventsPage extends StatelessWidget {
  const ReviewEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case where the user is not logged in
      return const Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Review'),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No events found'));
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
                const Icon(Icons.calendar_today),
                const SizedBox(width: 5),
                Text(_formatDate(event['startDate'])),
                const SizedBox(width: 20),
                const Icon(Icons.location_on),
                const SizedBox(width: 5),
                Text(event['eventVenue']),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return ListTile(
            title: Text(event['eventName']),
            subtitle: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 5),
                Text(_formatDate(event['startDate'])),
                const SizedBox(width: 20),
                const Icon(Icons.location_on),
                const SizedBox(width: 5),
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
                const Icon(Icons.calendar_today),
                const SizedBox(width: 5),
                Text(_formatDate(event['startDate'])),
                const SizedBox(width: 20),
                const Icon(Icons.location_on),
                const SizedBox(width: 5),
                Text(event['eventVenue']),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReviewForm(eventId: event.id /* Pass event data here */)),
            ),
            // Add navigation logic if needed

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
}