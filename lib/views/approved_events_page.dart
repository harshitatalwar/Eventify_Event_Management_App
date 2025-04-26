import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'EventDetail.dart';
import 'background_container.dart';

class ApprovedEventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approved Events'),
      ),
      body: BackgroundContainer(
        child: _buildEventList(),
      ),
    );
  }

  Widget _buildEventList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('approved_events').snapshots(),
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
            var event = events[index];
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
              _navigateToEventDetails(context, event.id);
            },
          );
        }
      },
    );
  }

  void _navigateToEventDetails(BuildContext context, String eventId) {
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
