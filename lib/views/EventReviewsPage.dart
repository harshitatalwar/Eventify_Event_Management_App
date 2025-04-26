import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aivent/views/ReviewForm.dart'; // Import the ReviewForm page
import 'background_container.dart';

class EventReviewsPage extends StatelessWidget {
  final String eventId;

  const EventReviewsPage({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Reviews'),
      ),
      body: BackgroundContainer(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('approved_events')
            .doc(eventId)
            .collection('event_reviews')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No reviews found for this event'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var review = snapshot.data!.docs[index];
              return ListTile(
                title: Text('Rating: ${review['rating']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['reviewText']),
                    SizedBox(height: 8),
                    if (review['imageUrls'] != null)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: review['imageUrls'].length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Image.network(
                                review['imageUrls'][index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  // Navigate to the ReviewForm page with the eventId
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => ReviewForm(eventId: eventId),
                  //   ),
                  // );
                },
              );
            },
          );

        },
      ),
      ),
    );
  }
}
