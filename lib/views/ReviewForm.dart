import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'background_container.dart';

class ReviewForm extends StatefulWidget {
  final String eventId; // Add a field to receive event ID

  const ReviewForm({Key? key, required this.eventId}) : super(key: key);

  @override
  _ReviewFormState createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  int _rating = 0;
  String _reviewText = "";
  List<File> _selectedImages = []; // List to hold selected images
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Review'),
      ),
      body: BackgroundContainer(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => _buildStar(index + 1)),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Write your review",
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please enter your review";
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() => _reviewText = value),
                  maxLines: 5, // Allow for multiline text input
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Submit review logic (send data to Firestore)
                      _submitReview();
                    }
                  },
                  child: const Text("Submit Review"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Open image picker
                    _pickImage();
                  },
                  child: Text("Add Image"),
                ),
                SizedBox(height: 10),
                // Display selected images
                _buildImagePreview(),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildStar(int starValue) {
    return IconButton(
      icon: Icon(
        Icons.star,
        color: _rating >= starValue ? Colors.amber : Colors.grey,
      ),
      onPressed: () => setState(() => _rating = starValue),
    );
  }

  // Function to open image picker
  Future<void> _pickImage() async {
    final pickedFile = await _picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  // Widget to display selected images
  Widget _buildImagePreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.file(
              _selectedImages[index],
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  void _submitReview() async {
    try {
      // Get the current user's ID
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Check if the user has already submitted a review for this event
      QuerySnapshot existingReviewsSnapshot = await FirebaseFirestore.instance
          .collection('approved_events')
          .doc(widget.eventId)
          .collection('event_reviews')
          .where('userId', isEqualTo: userId)
          .get();

      if (existingReviewsSnapshot.docs.isNotEmpty) {
        // If the user has already submitted a review, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have already submitted a review for this event')),
        );
        return; // Exit the function without submitting the review
      }

      // Check if the current user is the creator of the event
      DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
          .collection('approved_events')
          .doc(widget.eventId)
          .get();

      String? creatorId = eventSnapshot['createdBy'];

      if (creatorId == userId) {
        // If the user is the creator of the event, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You cannot review an event you created')),
        );
        return; // Exit the function without submitting the review
      }

      // Check if the current user is registered for the event
      QuerySnapshot participantsSnapshot = await FirebaseFirestore.instance
          .collection('approved_events')
          .doc(widget.eventId)
          .collection('participants')
          .where('userId', isEqualTo: userId)
          .get();

      if (participantsSnapshot.docs.isEmpty) {
        // If the user is not registered for the event, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are not registered for this event')),
        );
        return; // Exit the function without submitting the review
      }

      // Get a reference to the event's review collection
      CollectionReference reviewsRef = FirebaseFirestore.instance
          .collection('approved_events')
          .doc(widget.eventId)
          .collection('event_reviews');

      // Upload images to Firebase Storage and get their URLs
      List<String> imageUrls = await _uploadImages();

      // Add a new document with auto-generated ID
      await reviewsRef.add({
        'userId': userId, // Include userId in the review data
        'rating': _rating,
        'reviewText': _reviewText,
        'imageUrls': imageUrls, // Add URLs of uploaded images
        'timestamp': FieldValue.serverTimestamp(), // Add timestamp of when the review was submitted
      });

      // Show a success message or navigate back after successful submission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully')),
      );

      // Optionally, navigate back to the previous screen
      Navigator.pop(context);
    } catch (e) {
      // Handle errors here
      print('Error submitting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review')),
      );
    }
  }


  // Function to upload images to Firebase Storage
  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];

    for (File imageFile in _selectedImages) {
      try {
        // Create a reference to the location you want to upload to in firebase
        Reference ref = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        // Upload the file to firebase
        await ref.putFile(imageFile);

        // Get the download URL
        String downloadURL = await ref.getDownloadURL();

        // Add download URL to list
        imageUrls.add(downloadURL);
      } catch (e) {
        // Handle errors
        print('Error uploading image: $e');
      }
    }

    return imageUrls;
  }
}
