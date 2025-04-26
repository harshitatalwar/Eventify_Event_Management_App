import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'background_container.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyA0LJr4wQoNoQbGymac4Zu56rm8VYplJpE",
        appId: "1:670374321382:android:a4867aec03effdb8532f27",
        messagingSenderId: "670374321382",
        projectId: "aivent-5105a",
        storageBucket: "aivent-5105a.appspot.com"
    ),
  ); // Initialize Firebase
  runApp(MaterialApp(
    home: CalendarApp(),
  ));
}

class CalendarApp extends StatefulWidget {
  const CalendarApp({Key? key}) : super(key: key);

  @override
  State<CalendarApp> createState() => _MyAppState();
}

class _MyAppState extends State<CalendarApp> {
  late User _currentUser;
  Map<DateTime, List<Event>> _events = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _currentUser = FirebaseAuth.instance.currentUser!;
    _events = {};
    _populateEvents().then((_) {
      setState(() {}); // Refresh the UI after populating events
    });
  }

  Future<void> _populateEvents() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Initialize a list to store event IDs where the current user is involved
      List<String> eventIds = [];

      // Query events created by the current user
      QuerySnapshot createdBySnapshot = await firestore
          .collection('approved_events')
          .where('createdBy', isEqualTo: _currentUser.uid)
          .get();

      // Add event IDs where the current user is the creator
      eventIds.addAll(createdBySnapshot.docs.map((doc) => doc.id));

      // Query events where the current user is a participant
      QuerySnapshot participantSnapshot = await firestore
          .collection('approved_events')
          .get();

      for (QueryDocumentSnapshot doc in participantSnapshot.docs) {
        QuerySnapshot participantDocSnapshot = await doc.reference
            .collection('participants')
            .where('userId', isEqualTo: _currentUser.uid)
            .get();

        if (participantDocSnapshot.docs.isNotEmpty) {
          eventIds.add(doc.id);
        }
      }

      // Fetch all events where the current user is involved
      QuerySnapshot allEventsSnapshot = await firestore
          .collection('approved_events')
          .where(FieldPath.documentId, whereIn: eventIds)
          .get();

      // Update _events map with fetched events, marking start dates
      Map<DateTime, List<Event>> updatedEvents = {};
      allEventsSnapshot.docs.forEach((doc) {
        DateTime eventDate = (doc['startDate'] as Timestamp).toDate();
        updatedEvents[eventDate] ??= [];
        updatedEvents[eventDate]!.add(Event(
          eventName: doc['eventName'],
          startTime: doc['startTime'],
        ));
      });

      setState(() {
        _events = updatedEvents;
        // Select the first date with events involving the current user
        _selectedDay = _events.keys.first;
      });
    } catch (e) {
      print("Error populating events: $e");
    }
  }



  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    await _fetchEvents(selectedDay);
  }

  Future<void> _fetchEvents(DateTime day) async {
    try {
      QuerySnapshot createdBySnapshot = await FirebaseFirestore.instance
          .collection('approved_events')
          .where('createdBy', isEqualTo: _currentUser.uid)
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
          .where('startDate', isLessThan: Timestamp.fromDate(day.add(Duration(days: 1))))
          .get();

      List<Event> events = [];

      createdBySnapshot.docs.forEach((doc) {
        events.add(Event(
          eventName: doc['eventName'],
          startTime: doc['startTime'],
        ));
      });

      QuerySnapshot participantSnapshot = await FirebaseFirestore.instance
          .collection('approved_events')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
          .where('startDate', isLessThan: Timestamp.fromDate(day.add(Duration(days: 1))))
          .get();

      for (QueryDocumentSnapshot doc in participantSnapshot.docs) {
        QuerySnapshot participantDocSnapshot = await doc.reference
            .collection('participants')
            .where('userId', isEqualTo: _currentUser.uid)
            .get();

        if (participantDocSnapshot.docs.isNotEmpty) {
          events.add(Event(
            eventName: doc['eventName'],
            startTime: doc['startTime'],
          ));
        }
      }

      setState(() {
        _selectedEvents.value = events;
      });
    } catch (e, stackTrace) {
      print("Error fetching events: $e");
      print("Stack trace: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome to calendar")),
      body: BackgroundContainer(
      child: content(),
      ),
    );
  }

  Widget content() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Selected Day: " + _focusedDay.toString().split(" ")[0]),
            Container(
              child: TableCalendar(
                locale: "en_US",
                rowHeight: 46,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                availableGestures: AvailableGestures.all,
                // selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2023, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                onDaySelected: _onDaySelected,
                eventLoader: null,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    // Check if there are events involving the current user for this date
                    if (_events.keys.any((eventDate) => isSameDay(eventDate, date))) {
                      return Icon(Icons.event, color: Colors.redAccent); // Display marker for dates with events involving the current user
                    }
                    return null; // No events involving the current user, no marker
                  },
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                ),
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
            SizedBox(height: 300),
            ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Set the background color to white
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5), // Add a shadow
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: Offset(0, 2), // changes position of shadow
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              value[index].eventName,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              value[index].startTime,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),



          ],
        ),
      ),
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _selectedEvents.value;
  }
}

class Event {
  final String eventName;
  final String startTime;

  Event({
    required this.eventName,
    required this.startTime,
  });
}
