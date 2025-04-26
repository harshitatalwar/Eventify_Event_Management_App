// event_form.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'background_container.dart';
// import 'package:image_picker/src/xfile.dart';



class EventForm extends StatefulWidget {
  @override
  _EventFormState createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController eventVenueController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();
  final TextEditingController adminsInfoController = TextEditingController();
  final TextEditingController targetAudienceController = TextEditingController();
  final TextEditingController shortDescriptionController = TextEditingController();
  final TextEditingController logoImageController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedImage;

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      if (_endDate != null && picked.isAfter(_endDate!)) {
        // Show an alert if start date is after end date
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Invalid Date"),
              content: Text("Start date cannot be after end date"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          _startDate = picked;
          startDateController.text =
          "${_startDate!.year}-${_startDate!.month}-${_startDate!.day}";
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _endDate) {
      if (_startDate != null && picked.isBefore(_startDate!)) {
        // Show an alert if end date is before start date
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Invalid Date"),
              content: Text("End date cannot be before start date"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          _endDate = picked;
          endDateController.text =
          "${_endDate!.year}-${_endDate!.month}-${_endDate!.day}";
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    // return BackgroundContainer(
      return Scaffold(
        appBar: AppBar(
          title: Text('Create Event'),
        ),
        body: BackgroundContainer(
          child:  Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: eventNameController,
                decoration: InputDecoration(labelText: 'Event Name'),
              ),
              TextField(
                controller: eventVenueController,
                decoration: InputDecoration(labelText: 'Event Venue'),
              ),
              TextFormField(
                readOnly: true,
                controller: startDateController,
                decoration: InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: IconButton(
                    onPressed: () => _selectStartDate(context),
                    icon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
              TextFormField(
                readOnly: true,
                controller: endDateController,
                decoration: InputDecoration(
                  labelText: 'End Date',
                  suffixIcon: IconButton(
                    onPressed: () => _selectEndDate(context),
                    icon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
              TextField(
                controller: startTimeController,
                decoration: InputDecoration(labelText: 'Start Time'),
              ),
              TextField(
                controller: endTimeController,
                decoration: InputDecoration(labelText: 'End Time'),
              ),
              TextField(
                controller: adminsInfoController,
                decoration: InputDecoration(labelText: 'Admins Info'),
              ),
              TextField(
                controller: targetAudienceController,
                decoration: InputDecoration(labelText: 'Target Audience'),
              ),
              TextField(
                controller: shortDescriptionController,
                decoration: InputDecoration(labelText: 'Short Description'),
              ),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveEventData();
                },
                child: Text('Create Event'),
                ),
             ],
            ),
          ),
        ),
      );

  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
          source: ImageSource.gallery);
      setState(() {
        _pickedImage = pickedImage;
        logoImageController.text =
            pickedImage?.path ?? ''; // Use the image path for now
      });
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _saveEventData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String? creatorId;

    // Get current user's ID
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      creatorId = currentUser.uid;
    } else {
      // Handle the case where the user is not logged in
      print('User not logged in');
      return;
    }

    // Convert date and time strings to DateTime objects
    DateTime startDate = DateTime(
      int.parse(startDateController.text.split('-')[0]), // Year
      int.parse(startDateController.text.split('-')[1]), // Month
      int.parse(startDateController.text.split('-')[2].split('T')[0]), // Day
      int.parse(startTimeController.text.split(':')[0]), // Hour
      int.parse(startTimeController.text.split(':')[1]), // Minute
    );

    DateTime endDate = DateTime(
      int.parse(endDateController.text.split('-')[0]), // Year
      int.parse(endDateController.text.split('-')[1]), // Month
      int.parse(endDateController.text.split('-')[2].split('T')[0]), // Day
      int.parse(endTimeController.text.split(':')[0]), // Hour
      int.parse(endTimeController.text.split(':')[1]), // Minute
    );

    if (_pickedImage != null) {
      // Upload image to Firebase Storage
      Reference storageReference = FirebaseStorage.instance.ref().child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = storageReference.putFile(File(_pickedImage!.path));
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      // Get the full path of the image
      String fullPath = snapshot.ref.fullPath;

      // Save data to Firestore collection
      await firestore.collection('event_form').add({
        'eventName': eventNameController.text,
        'eventVenue': eventVenueController.text,
        'startDate': startDate,
        'endDate': endDate,
        'startTime': startTimeController.text,
        'endTime': endTimeController.text,
        'adminsInfo': adminsInfoController.text,
        'targetAudience': targetAudienceController.text,
        'shortDescription': shortDescriptionController.text,
        'logoImage': storageReference.fullPath,
        'status': 'Pending',
        'createdBy': creatorId,
        "disapprovalReason": "Reason for Disapproval"// Include the creator's ID
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Event Created'),
            content: Text('On Approval your calendar will be updated for you'),
            actions: [
              TextButton(
                onPressed: () {
                  // Close the dialog and pop the screen
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

    } else {
      // Handle case where no image is picked
      print('No image picked');
    }
  }

}


