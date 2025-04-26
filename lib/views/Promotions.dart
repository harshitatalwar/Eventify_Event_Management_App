import 'dart:io';
import 'package:aivent/views/background_container.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PromotionsPage extends StatefulWidget {
  final String eventId;

  const PromotionsPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _PromotionsPageState createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _indexController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedImage;

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Promote Event'),
      ),
      body: BackgroundContainer(
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/background_image.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'Promotion Message',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _indexController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Index (Optional)',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                _buildImagePicker(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _submitPromotion(context);
                  },
                  child: Text('Submit Promotion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildImagePicker() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _pickImage,
          child: Text('Pick Image'),
        ),
        SizedBox(width: 10),
        _pickedImage != null
            ? Expanded(
          child: Image.file(
            File(_pickedImage!.path),
            height: 100,
          ),
        )
            : SizedBox.shrink(),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      setState(() {
        _pickedImage = pickedImage;
      });
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _submitPromotion(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final message = _messageController.text;
    final index = int.tryParse(_indexController.text) ?? 0;

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a promotion message')),
      );
      return;
    }

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        // Upload image to Firebase Storage
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('promotion_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        UploadTask uploadTask = storageReference.putFile(File(_pickedImage!.path));
        TaskSnapshot snapshot = await uploadTask;

        // Get the image URL
        imageUrl = snapshot.ref.fullPath;
      }

      await FirebaseFirestore.instance.collection('promotions').add({
        'eventId': widget.eventId,
        'userId': currentUser.uid,
        'message': message,
        'index': index,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit promotion: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _indexController.dispose();
    super.dispose();
  }
}
