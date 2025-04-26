import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aivent/views/loginpage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'background_container.dart';
import 'EventReviewsPage.dart';

class ReviewGivePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case where the user is not logged in
      return Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews Given'),
      ),
      body: BackgroundContainer(
      child: _buildEventList(currentUser.uid),
      ),
    );
  }

  Widget _buildEventList(String userId) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: getEventsWithUserReviews(userId),
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
            return _buildEventTile(context,event);
          },
        );
      },
    );
  }

  Widget _buildEventTile(BuildContext context, DocumentSnapshot event) {
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
        // Navigate to the EventReviewsPage with the eventId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventReviewsPage(eventId: event.id),
          ),
        );
      },
    );
  }


  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  Future<List<DocumentSnapshot>> getEventsWithUserReviews(String userId) async {
    QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
        .collection('approved_events')
        .get();

    List<DocumentSnapshot> eventsWithUserReviews = [];

    for (var eventDoc in eventSnapshot.docs) {
      QuerySnapshot reviewsSnapshot = await eventDoc.reference
          .collection('event_reviews')
          .where('userId', isEqualTo: userId)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        eventsWithUserReviews.add(eventDoc);
      }
    }

    return eventsWithUserReviews;
  }
}
