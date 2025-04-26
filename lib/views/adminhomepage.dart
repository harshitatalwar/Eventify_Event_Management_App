import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'EventDetail.dart'; // Import the EventDetails page
import 'package:aivent/views/EventDetail.dart';
import 'package:aivent/views/registration_form.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'approved_events_page.dart';
import 'disapproved_events_page.dart';
import 'loginpage.dart'; // Import the LoginPage
import 'background_container.dart';

class AdminHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Add signout functionality here
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()), // Redirect to LoginPage
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
              ),
              child: Text('Navigation'),
            ),
            ListTile(
              title: Text('Approved Events'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ApprovedEventsPage()),
                );
              },
            ),
            ListTile(
              title: Text('Disapproved Events'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DisapprovedEventsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: BackgroundContainer(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('event_form').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            var events = snapshot.data!.docs;

            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetails(eventId: event.id),
                      ),
                    );
                  },
                  child: _buildEventTile(context, event),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventTile(BuildContext context, DocumentSnapshot event) {
    return FutureBuilder<String>(
      future: _getImageUrl(event['logoImage']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error loading image');
        } else {
          String imageUrl = snapshot.data ?? '';
          DateTime startDate = (event['startDate'] as Timestamp).toDate();
          String formattedDate = "${startDate.day}/${startDate.month}/${startDate.year}";

          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
              ),
              title: Text(event['eventName']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 5),
                            Text(formattedDate),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.location_on),
                            SizedBox(width: 5),
                            Text(event['eventVenue']),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                _navigateToRegistrationForm(context, event.id);
              },
              trailing: Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _approveEvent(context, event);
                      },
                      child: Text('Approve'),
                    ),
                    SizedBox(width: 8), // Add some spacing between buttons
                    ElevatedButton(
                      onPressed: () {
                        _disapproveEvent(context, event);
                      },
                      child: Text('Disapprove'),
                    ),
                  ],
                ),
              ),





            ),
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
      Reference storageReference = FirebaseStorage.instance.ref().child(
          imagePath);
      return await storageReference.getDownloadURL();
    } catch (e) {
      print('Error getting image URL: $e');
      return '';
    }
  }

  void _approveEvent(BuildContext context, DocumentSnapshot event) {
    Map<String, dynamic> eventData = event.data() as Map<String, dynamic>;
    eventData['status'] = 'Approved'; // Update the status field
    FirebaseFirestore.instance.collection('approved_events').add(eventData);
    FirebaseFirestore.instance.collection('event_form').doc(event.id).delete();
    // Show alert message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Event Approved'),
          content: Text('The event has been approved.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _disapproveEvent(BuildContext context, DocumentSnapshot event) {
    // Prompt admin to enter reason for disapproval
    TextEditingController _reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Disapprove Event'),
          content: TextField(
            controller: _reasonController,
            decoration: InputDecoration(hintText: 'Reason for Disapproval'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Get the reason for disapproval
                String reason = _reasonController.text;
                Navigator.of(context).pop(); // Close the dialog
                // Proceed with disapproval
                _performDisapproval(context, event, reason);
              },
              child: Text('Disapprove'),
            ),
          ],
        );
      },
    );
  }

  void _performDisapproval(BuildContext context, DocumentSnapshot event, String reason) {
    Map<String, dynamic> eventData = event.data() as Map<String, dynamic>;
    eventData['status'] = 'Disapproved'; // Update the status field
    eventData['disapprovalReason'] = reason; // Store the disapproval reason
    FirebaseFirestore.instance.collection('disapproved_events').add(eventData);
    FirebaseFirestore.instance.collection('event_form').doc(event.id).delete();
    // Show alert message
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Event Disapproved'),
          content: Text('The event has been disapproved.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
