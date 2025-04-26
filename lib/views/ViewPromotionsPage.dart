import 'package:aivent/views/background_container.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'background_container.dart';

class ViewPromotionsPage extends StatelessWidget {
  final String eventId;

  const ViewPromotionsPage({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Promotions'),
      ),
      body: BackgroundContainer(
        child:StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promotions')
            .where('eventId', isEqualTo: eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No promotions found for this event'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var promotion = snapshot.data!.docs[index];
              return _buildPromotionCard(promotion);
            },
          );
        },
      ),
      ),
    );
  }

  Widget _buildPromotionCard(QueryDocumentSnapshot promotion) {
    String message = promotion['message'];
    String index = promotion['index'].toString();
    String? imageUrl = promotion['imageUrl'];

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          message,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'Index: $index',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 8),
            imageUrl != null
                ? FutureBuilder<String>(
              future: _getImageUrl(imageUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading image'));
                } else {
                  return Image.network(snapshot.data!);
                }
              },
            )
                : Center(child: Text('No image available')),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String> _getImageUrl(String imagePath) async {
    try {
      // Get download URL for the image path
      String downloadURL = await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error getting image URL: $e');
      throw e; // Rethrow the error so it can be handled by the caller
    }
  }
}
