import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'EventDetail.dart';
import 'background_container.dart';

class DisapprovedEventsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disapproved Events'),
      ),
      body: BackgroundContainer(
        child: _buildEventList(context),
      ),
    );
  }

  Widget _buildEventList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('disapproved_events').snapshots(),
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

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
            ),
            title: Text(event['eventName']),
            subtitle: Text(event['eventVenue']),
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
