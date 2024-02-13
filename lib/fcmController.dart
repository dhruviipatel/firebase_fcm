import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class FcmController extends GetxController {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  // FirebaseFirestore firestore = FirebaseFirestore.instance;
  RxString myToken = ''.obs;
  requestPermission() async {
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
    await messaging.getToken().then((token) {
      myToken.value = token!;
      print(myToken);
      storeToken(token);
    });
  }

  void storeToken(String token) async {
    //await firestore.collection('Utoken').doc("User1").set({'token': token});
  }

  initInfo() {
    var androidInitialize =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitialize = const DarwinInitializationSettings();

    var initSettings =
        InitializationSettings(android: androidInitialize, iOS: iosInitialize);

    FlutterLocalNotificationsPlugin().initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) async {
      try {
        if (details.payload != null && details.payload!.isNotEmpty) {
          print("payload not empty");
          //navigation
        } else {
          print("payload is empty");
        }
      } catch (e) {
        return;
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
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
}
