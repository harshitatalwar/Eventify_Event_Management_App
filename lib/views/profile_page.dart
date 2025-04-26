import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'background_container.dart';
import 'package:aivent/views/ReviewEventsPage.dart';
import 'package:aivent/views/UserCreatedEventsPage.dart';
import 'package:aivent/views/UserRegisteredEventsPage.dart';
import 'package:aivent/views/ReviewGivenPage.dart';
import 'package:aivent/views/ReviewReceivedPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA0LJr4wQoNoQbGymac4Zu56rm8VYplJpE",
        appId: "1:670374321382:android:a4867aec03effdb8532f27",
        messagingSenderId: "670374321382",
        projectId: "aivent-5105a",
        storageBucket: "aivent-5105a.appspot.com",
      )
  );
  runApp(const MaterialApp(home: ProfilePage()));
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userEmailController = TextEditingController();
  final TextEditingController userAboutController = TextEditingController();
  final TextEditingController userImageController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _pickedImage;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final firestore = FirebaseFirestore.instance;
      final userData = await firestore.collection('users').doc(currentUser.uid).get();
      setState(() {
        userNameController.text = userData['userName'];
        userEmailController.text = userData['userEmail'];
        userAboutController.text = userData['userAbout'];
        userImageController.text = userData['userImage'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' Your Profile'),
        actions: _isEditMode
            ? [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditMode = false;
              });
              _saveUserData();
            },
            icon: const Icon(Icons.save),
          ),
        ]
            : [
          IconButton(
            onPressed: () {
              setState(() {
                _isEditMode = true;
              });
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: BackgroundContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _isEditMode ? _pickImage : null,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: Colors.blue,
                      backgroundImage: userImageController.text.isNotEmpty
                          ? NetworkImage(userImageController.text)
                          : null,
                      child: _isEditMode
                          ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    userNameController.text,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userEmailController.text,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      title: Text('Name'),
                      subtitle: TextField(
                        controller: userNameController,
                        decoration: InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    ListTile(
                      title: Text('Email'),
                      subtitle: TextField(
                        controller: userEmailController,
                        decoration: InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    ListTile(
                      title: Text('About'),
                      subtitle: TextField(
                        controller: userAboutController,
                        maxLines: 3,
                        decoration: InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_isEditMode) ...[
                      ElevatedButton(
                        onPressed: _saveUserData,
                        child: const Text('Save'),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ProfileButton(
                          text: 'Registered Events',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserRegisteredEventsPage()),
                            );
                          },
                        ),
                        ProfileButton(
                          text: 'Created Events',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UserCreatedEventsPage()),
                            );
                          },
                        ),
                        ProfileButton(
                          text: 'Review',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ReviewEventsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ProfileButton(
                          text: 'Your Reviews',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ReviewGivePage()),
                            );
                          },
                        ),
                        ProfileButton(
                          text: 'Received Reviews',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ReviewReceivedPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedImage != null) {
        setState(() {
          _pickedImage = pickedImage;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _saveUserData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String? creatorId;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      creatorId = currentUser.uid;
    } else {
      print('User not logged in');
      return;
    }

    try {
      String? imagePath;
      if (_pickedImage != null) {
        List<int> imageData = await _pickedImage!.readAsBytes();
        Uint8List uint8ImageData = Uint8List.fromList(imageData);

        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        UploadTask uploadTask = storageReference.putData(uint8ImageData);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

        imagePath = await storageReference.getDownloadURL();
      } else {
        imagePath = userImageController.text;
      }

      await firestore.collection('users').doc(currentUser.uid).set({
        'userName': userNameController.text,
        'userEmail': userEmailController.text,
        'userAbout': userAboutController.text,
        'userImage': imagePath,
        'createdBy': creatorId,
      });

      setState(() {
        _isEditMode = false;
        _pickedImage = null;
      });
    } catch (e) {
      print('Error saving user data: $e');
    }
  }
}

class ProfileButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const ProfileButton({Key? key, required this.text, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

