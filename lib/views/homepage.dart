// homepage.dart

import 'package:aivent/views/ViewPromotionEvents.dart';
import 'package:aivent/views/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../main.dart';
import 'EventDetail.dart';
import 'UserCreatedEventsPage.dart';
import 'UserRegisteredEventsPage.dart';
import 'event_form.dart';
import 'loginpage.dart'; // Import LoginPage for navigation
import 'background_container.dart';
import 'calendar.dart';


void main() {
  runApp(MaterialApp(home: HomePage()));
}

class HomePage extends StatefulWidget{
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showPastEvents = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Epic Event'),
        backgroundColor: Colors.purple.shade100,
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              // Handle menu button press
            },
          ),
        ],
      ),
      body: BackgroundContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Welcome to Your Hub for Seamless Event Coordination!',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showPastEvents = true;
                    });
                  },
                  child: Text(
                    'Past Events',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.purple.shade200),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showPastEvents = false;
                    });
                  },
                  child: Text(
                    'Current Events',
                    style: TextStyle(color: Colors.black),
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.purple.shade200),
                  ),
                ),
              ],
            ),
            Expanded(
              child: _buildEventList(_showPastEvents),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventForm()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                // Handle home button press
              },
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
              ),
              child: Text(
                'Epic Event',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('My Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              title: const Text('Created Events'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserCreatedEventsPage()),
                );
              },
            ),
            ListTile(
              title: const Text('Registered Events'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UserRegisteredEventsPage()),
                );
              },
            ),
            ListTile(
              title: Text('Calendar'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CalendarApp()),
                );
              },
            ),
            ListTile(
              title: const Text('View Promtions'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ViewPromotionEventsPage()),
                );
              },
            ),
            ListTile(
              title: Text('Sign Out'),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => LoginPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(bool showPastEvents) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('approved_events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        var events = snapshot.data!.docs;

        // Filter events based on start date
        events = events.where((event) {
          DateTime startDate = (event['startDate'] as Timestamp).toDate();
          if (showPastEvents) {
            return startDate.isBefore(DateTime.now());
          } else {
            return startDate.isSameDate(DateTime.now()) || startDate.isAfter(DateTime.now());
          }
        }).toList();

        if (events.isEmpty) {
          return Center(
            child: Text(
              showPastEvents ? 'No past events available' : 'No current events available',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            var event = events[index];
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
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error loading image');
        } else {
          String imageUrl = snapshot.data ?? '';
          DateTime startDate = (event['startDate'] as Timestamp).toDate();
          String formattedDate = "${startDate.day}/${startDate.month}/${startDate.year}";

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
            ),
            title: Text(event['eventName']),
            subtitle: Row(
              children: [
                Icon(Icons.calendar_today),
                SizedBox(width: 5),
                Text(formattedDate),
                SizedBox(width: 20),
                Icon(Icons.location_on),
                SizedBox(width: 5),
                Text(event['eventVenue']),
              ],
            ),
            onTap: () {
              _navigateToRegistrationForm(context, event.id);
            },
          );
        }
      },
    );
  }

  void _navigateToRegistrationForm(BuildContext context, String eventId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetails(eventId: eventId),
      ),
    );
  }

  Future<String> _getImageUrl(String imagePath) async {
    try {
      Reference storageReference = FirebaseStorage.instance.ref().child(imagePath);
      return await storageReference.getDownloadURL();
    } catch (e) {
      print('Error getting image URL: $e');
      return '';
    }
  }
}

extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return this.year == other.year && this.month == other.month && this.day == other.day;
  }
}
