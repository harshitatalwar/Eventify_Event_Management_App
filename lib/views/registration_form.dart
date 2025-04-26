import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'background_container.dart';

class RegistrationForm extends StatefulWidget {
  final String eventId;

  RegistrationForm({required this.eventId});

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    // Get the current user
    User? user = _auth.currentUser;

    // Set the initial value of the emailController to the user's email address
    if (user != null) {
      emailController.text = user.email ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Registration Form'),
      ),
      body: BackgroundContainer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: mobileNumberController,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _registerParticipant(widget.eventId); // Pass event ID
                  },
                  child: Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registerParticipant(String eventId) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Check if the user is the creator of the event
        DocumentSnapshot eventSnapshot = await firestore
            .collection('approved_events')
            .doc(eventId)
            .get();

        String? creatorId = eventSnapshot['createdBy'];

        if (creatorId == user.uid) {
          // If the user is the creator of the event, show an error message
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Cannot Register'),
              content: Text('You cannot register for an event that you created.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
          return; // Exit the method
        }

        // Check if the user has already registered for the event
        QuerySnapshot participantSnapshot = await firestore
            .collection('approved_events')
            .doc(eventId)
            .collection('participants')
            .where('userId', isEqualTo: user.uid)
            .get();

        // If the user has already registered, prevent duplicate registration
        if (participantSnapshot.docs.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Already Registered'),
              content: Text('You have already registered for this event.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
          return; // Exit the method
        }

        // Get the current user's display name (username)
        String? username = user.displayName;

        // Proceed with registration
        await firestore
            .collection('approved_events')
            .doc(eventId)
            .collection('participants')
            .add({
          'userId': user.uid,
          'ParticipantName': username,
          'ParticipantNumber': mobileNumberController.text,
          'ParticipantEmail': user.email, // You can still record the email if needed
          'timestamp': FieldValue.serverTimestamp(),
        });

        // After saving the data, you may navigate back or perform other actions
        Navigator.pop(context);
      } else {
        // User is not logged in, handle accordingly
        print('User not logged in');
      }
    } catch (e) {
      // Error handling
      print('Error registering participant: $e');
    }
  }
}
