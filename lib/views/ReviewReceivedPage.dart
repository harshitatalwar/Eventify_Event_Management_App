import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart'; // Import FL Chart
import 'background_container.dart';
import 'EventReviewsPage.dart';

class ReviewReceivedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Handle the case where the user is not logged in
      return Center(child: Text('User not logged in'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Events with Reviews Received'),
      ),
      body: BackgroundContainer(
        child: _buildEventList(currentUser.uid),
      ),
    );
  }

  Widget _buildEventList(String userId) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: getEventsWithReviewsReceived(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No events found with reviews received'));
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
    return Card(
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event['eventName'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text('Start Date: ${_formatDate(event['startDate'])}'),
            Text('Venue: ${event['eventVenue']}'),
            SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(1, '1 Star', Colors.red),
                _buildLegendItem(2, '2 Star', Colors.orange),
                _buildLegendItem(3, '3 Star', Colors.yellow),
                _buildLegendItem(4, '4 Star', Colors.green),
                _buildLegendItem(5, '5 Star', Colors.blue),
              ],
            ),
            SizedBox(height: 10),
            FutureBuilder<Map<int, int>>(
              future: countRatings(event.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No ratings yet'));
                }
                return _buildPieChart(snapshot.data!);
              },
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigate to EventReviewsPage with eventId
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventReviewsPage(eventId: event.id),
                  ),
                );
              },
              child: Text('View Detailed Reviews'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(int rating, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        SizedBox(width: 4),
        Text('$text'),
      ],
    );
  }

  String _formatDate(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
  }

  Future<List<DocumentSnapshot>> getEventsWithReviewsReceived(String userId) async {
    QuerySnapshot eventSnapshot = await FirebaseFirestore.instance
        .collection('approved_events')
        .where('createdBy', isEqualTo: userId)
        .get();

    List<DocumentSnapshot> eventsWithReviewsReceived = [];

    for (var eventDoc in eventSnapshot.docs) {
      QuerySnapshot reviewsSnapshot = await eventDoc.reference
          .collection('event_reviews')
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        eventsWithReviewsReceived.add(eventDoc);
      }
    }

    return eventsWithReviewsReceived;
  }

  Future<Map<int, int>> countRatings(String eventId) async {
    QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
        .collection('approved_events')
        .doc(eventId)
        .collection('event_reviews')
        .get();

    Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    reviewsSnapshot.docs.forEach((doc) {
      int rating = doc['rating'];
      if (ratingCounts.containsKey(rating)) {
        ratingCounts[rating] = ratingCounts[rating]! + 1;
      }
    });

    return ratingCounts;
  }

  Widget _buildPieChart(Map<int, int> ratingCounts) {
    List<PieChartSectionData> sections = ratingCounts.entries.map((entry) {
      int rating = entry.key;
      int count = entry.value;
      Color color = _getColorForRating(rating);
      return PieChartSectionData(
        value: count.toDouble(),
        color: color,
        title: count.toString(),
        radius: 80,
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 1,
      child: PieChart(
        PieChartData(
          sections: sections,
          borderData: FlBorderData(show: false),
          centerSpaceRadius: 0,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Color _getColorForRating(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
