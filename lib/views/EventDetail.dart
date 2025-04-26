import 'package:aivent/views/registration_form.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "",
      appId: "1:670374321382:android:a4867aec03effdb8532f27",
      messagingSenderId: "670374321382",
      projectId: "aivent-5105a",
      storageBucket: "aivent-5105a.appspot.com",
    ),
  ); // Initialize Firebase
  runApp(MaterialApp(
    home: EventDetails(eventId: 'Qudrh6OPPZPWHzRBJdGf'),
  ));
}

class EventDetails extends StatelessWidget {
  final String eventId;

  const EventDetails({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _getEventData(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Event not found'));
          }

          var eventData = snapshot.data!.data() as Map<String, dynamic>;
          String eventName = eventData['eventName'];
          String eventVenue = eventData['eventVenue'];
          String startDate = _convertTimestampToString(eventData['startDate']);
          String endDate = _convertTimestampToString(eventData['endDate']);
          String startTime = eventData['startTime'];
          String endTime = eventData['endTime'];
          String adminsInfo = eventData['adminsInfo'];
          String targetAudience = eventData['targetAudience'];
          String shortDescription = eventData['shortDescription'];
          String logoImage = eventData['logoImage'];
          String status = eventData['status'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    FutureBuilder<String>(
                      future: _getImageUrl(logoImage),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error loading image');
                        } else {
                          String imageUrl = snapshot.data ?? '';
                          return Image.network(imageUrl);
                        }
                      },
                    ),
                    Container(
                      width: double.infinity,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0, -1),
                          end: Alignment(0, 1),
                          colors: <Color>[Color(0x96000000), Color(0x00000000)],
                          stops: <double>[0, 1],
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  margin: EdgeInsets.only(top: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Color(0xff110c26),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/Date.jpg',
                            width: 48,
                            height: 48,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  startDate,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff110c26),
                                  ),
                                ),
                                Text(
                                  '$startDate - $endDate, $startTime - $endTime',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xff747688),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/Location.jpg',
                            width: 48,
                            height: 48,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventVenue,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff110c26),
                                  ),
                                ),
                                Text(
                                  'Venue',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xff747688),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/Organizer.jpg',
                            width: 48,
                            height: 48,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminsInfo,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff110c26),
                                  ),
                                ),
                                Text(
                                  'Organizer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xff747688),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        margin: EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About Event',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff110c26),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              shortDescription,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xff747688),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      if (status != 'Disapproved')
                        Container(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrationForm(eventId: eventId),
                              ),
                            );
                            // Handle button press (e.g., navigate to ticket purchase screen)
                          },
                          child: Text(
                            'REGISTER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1,
                              fontStyle: FontStyle.italic,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<DocumentSnapshot> _getEventData(String eventId) async {
  try {
    // Check if the event exists in the approved_events collection
    DocumentSnapshot eventSnapshot = await FirebaseFirestore.instance
        .collection('approved_events')
        .doc(eventId)
        .get();

    if (eventSnapshot.exists) {
      return eventSnapshot;
    } else {
      // If not found in approved_events, check disapproved_events collection
      eventSnapshot = await FirebaseFirestore.instance
          .collection('disapproved_events')
          .doc(eventId)
          .get();
      return eventSnapshot;
    }
  } catch (e) {
    print('Error getting event data: $e');
    throw e; // Rethrow the error so it can be handled by the caller
  }
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

String _convertTimestampToString(Timestamp timestamp) {
  // Convert Timestamp to DateTime
  DateTime dateTime = timestamp.toDate();
  // Format DateTime as required
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
