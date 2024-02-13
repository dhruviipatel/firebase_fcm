// import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:fcm_push_notification/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //step 1
  await FirebaseMessaging.instance.getInitialMessage();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return DismissKeyboard(
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter FCM',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: HomeScreen()),
    );
  }
}

// The DismissKeybaord widget (it's reusable)
class DismissKeyboard extends StatelessWidget {
  final Widget child;
  const DismissKeyboard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus &&
            currentFocus.focusedChild != null) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: child,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

String? mytoken;

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    requestPermission();
    getToken();
    initInfo();
    super.initState();
  }

  requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("Permission Granted");
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print("Provisional permission granted");
    } else {
      print("Permission declined");
    }
  }

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        mytoken = token;
        print(mytoken);
      });
      storeToken(token!);
    });
  }

  void storeToken(String token) async {
    // await FirebaseFirestore.instance
    //     .collection('Utoken')
    //     .doc("User1")
    //     .set({'token': token});
  }

  initInfo() {
    //print("in init info");
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitialize = const DarwinInitializationSettings();

    var initSettings =
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);

    FlutterLocalNotificationsPlugin().initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) async {
      print("in init info");
      try {
        if (details.payload != null && details.payload!.isNotEmpty) {
          print("not empty");
        } else {
          print("empty");
        }
      } catch (e) {
        log(e.toString());
        return;
      }
    });
    FirebaseMessaging.onBackgroundMessage((message) async {
      print("title: ${message.notification?.title}");
      print("body: ${message.notification?.body}");
      print("payload: ${message.data}");
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(".......tite.....${message.notification?.title}");
      var msgtitle = message.notification?.title;
      var msgbody = message.notification?.body;
      BigTextStyleInformation btsInfo = BigTextStyleInformation(
          message.notification!.body.toString(),
          htmlFormatBigText: true,
          contentTitle: message.notification!.title.toString(),
          htmlFormatContentTitle: true);

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'fcmTest', 'fcmTest',
          styleInformation: btsInfo,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true);

      NotificationDetails notifyDetails =
          NotificationDetails(android: androidDetails);
      await FlutterLocalNotificationsPlugin().show(
          0, msgtitle, msgbody, notifyDetails,
          payload: message.data[['body']]);
    });
  }

  sendPushNotifications(token, title, msgbody) async {
    try {
      var url = 'https://fcm.googleapis.com/fcm/send';
      var headers = {
        'Content-Type': 'application/json',
        'Authorization':
            'key=AAAAOpYpqJU:APA91bEKa69ONwnA3wfF1CIyQurrrUcYhEt9lTzltePcxMZl0jwgH3h5_iXgiIv9y71PnDlzAs34KjuRZk6o0Y63rWmf21O-4TQvC7Y7wS48-W75hy70hrOmXFzA7WLWtKOVzOJJY9zs'
      };

      var body = {
        'priority': 'high',
        'data': <String, dynamic>{
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'status': 'done',
          'body': msgbody,
          'title': title,
        },
        "notification": <String, dynamic>{
          "title": title,
          "body": msgbody,
          "android_channel_id": "fcmTest"
        },
        "to": token,
      };
      http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
    } catch (e) {
      if (kDebugMode) {
        print("error in pushnotifications");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var textcontroller = TextEditingController();
    var namecontroller = TextEditingController();
    var bodycontroller = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Flutter FCM",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: namecontroller,
              decoration: InputDecoration(hintText: "Name"),
            ),
            TextFormField(
              controller: textcontroller,
              decoration: InputDecoration(hintText: "Title"),
            ),
            TextFormField(
              controller: bodycontroller,
              decoration: InputDecoration(hintText: "Body"),
            ),
            SizedBox(height: 20),
            InkWell(
              onTap: () {
                if (namecontroller.text != '' &&
                    textcontroller.text != '' &&
                    bodycontroller.text != '') {
                  //sendPushNotifications(token, title, msgbody)
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("All fields are required")));
                }
              },
              child: Container(
                height: 40,
                width: double.infinity,
                color: Colors.blue,
                child: Center(
                  child: Text("Submit"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
