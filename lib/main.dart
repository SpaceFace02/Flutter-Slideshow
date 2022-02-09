import 'package:flutter/material.dart';
import "package:firebase_core/firebase_core.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "dart:async";

void main() async {
  // Ensures that initializeApp is called before runApp as it is a future, and we wanna remove unnecessary errors.
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Slideshow',
      home: FirestoreSlideshow(),
    );
  }
}

class FirestoreSlideshow extends StatefulWidget {
  const FirestoreSlideshow({Key? key}) : super(key: key);

  @override
  _FirestoreSlideshowState createState() => _FirestoreSlideshowState();
}

class _FirestoreSlideshowState extends State<FirestoreSlideshow> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final PageController ctrl = PageController(viewportFraction: 0.7);
  Stream? slides;
  String activeTag = 'calm';

  // Keep track of current page to prevent unnecessary renders and optimize performance.
  int currentPage = 0;

  //Get the stream, We pass in the tag to get the info from. tags is the field name in the firestore.
  void queryFirestore({String tag = "calm"}) {
    slides = db
        .collection("photos")
        .where('tags', arrayContains: tag)
        .snapshots()
        .map((list) => list.docs.map((doc) => doc.data()));
    //.snapshots() gives you a list of stream async snapshots you can map over to obtain a stream of query Snapshots, which you map over again, to get individual snapshots and extract the data from them.

    setState(() {
      activeTag = tag;
    });
  }

  @override
  void initState() {
    queryFirestore(tag: "calm");

    ctrl.addListener(() {
      int next = ctrl.page!.round();
      print("The below line is the next index rounded down.");
      print(next);

      // Now when swipe left or right, page number changes, next updates. if previous page value was 2, we swipe left, now next is 3, which is not equal to 2, then we set the currentPage to be next, i.e 3. Now both have same values.
      if (currentPage != next) {
        setState(() {
          currentPage = next;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        // Prevent null values.
        initialData: [],
        builder: (context, AsyncSnapshot snap) {
          List slideList = snap.data.toList();
          if (snap.hasError) {
            return Text(snap.error.toString());
          } else if (snap.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          return PageView.builder(
              controller: ctrl,
              itemCount: slideList.length + 1,
              itemBuilder: (context, int index) {
                if (index == 0) {
                  return selectTag();
                }
                // The images on the left or right, must be different styled than the middle one, hence the active prop. If the current index is the currentPage, then style the currentPage differently and the others differently.
                bool active = index == currentPage;
                return photoSlideShow(slideList[index - 1], active);
              });
        },
        stream: slides,
      ),
    );
  }

  //Map here represents a JSON object.
  photoSlideShow(Map data, bool active) {
    final double blur = active ? 50 : 0;
    final double offset = active ? 20 : 0;
    final double top = active ? 50 : 100;

    // Flutter automatically performs animation when any of the properties in this widget change.
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInQuint,
      margin: EdgeInsets.only(top: top, bottom: 50, right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage(data['image']),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: blur,
            offset: Offset(offset, offset),
          )
        ],
      ),
      child: Center(
        child: Text(
          data['title'],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  selectTag() {
    return Container(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Your Stories",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            "FILTER TAGS",
            style: TextStyle(color: Colors.black54, fontSize: 30),
          ),
        ),
        buildTagButton('calm'),
        SizedBox(
          height: 10,
        ),
        buildTagButton('landscape'),
        SizedBox(
          height: 10,
        ),
        buildTagButton('anger'),
        SizedBox(
          height: 10,
        ),
        buildTagButton('happy'),
        SizedBox(
          height: 10,
        ),
        buildTagButton('food'),
        SizedBox(
          height: 10,
        ),
      ],
    ));
  }

  buildTagButton(String tag) {
    Color color = tag == activeTag ? Colors.purpleAccent : Colors.white;
    return FlatButton(
      color: color,
      onPressed: () {
        queryFirestore(tag: tag);
      },
      child: Text("#$tag"),
    );
  }
}

//Experiment with PageBuilder and props to activates as bblur etc. Change boxshadow from list to normal. Select tag props.
