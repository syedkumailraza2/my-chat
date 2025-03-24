import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mychat/screens/home_screen.dart';
import 'package:mychat/screens/login_screen.dart';
import 'package:mychat/screens/signup_screen.dart';
import 'screens/join_screen.dart';
import 'services/signalling.service.dart';

void main() async{
  // start videoCall app
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  runApp(VideoCallApp());
}

class VideoCallApp extends StatelessWidget {
  VideoCallApp({super.key});

  // signalling server url
  final String websocketUrl = 'https://mychat-backend-fml5.onrender.com';

  // generate callerID of local user
  final String selfCallerID =
      Random().nextInt(999999).toString().padLeft(6, '0');
      

  @override
  Widget build(BuildContext context) {
    // init signalling service
    SignallingService.instance.init(
      websocketUrl: websocketUrl,
      selfCallerID: selfCallerID,
    );

    // return material app
    return MaterialApp(
      // darkTheme: ThemeData.dark().copyWith(
      //   useMaterial3: true,
      //   colorScheme: const ColorScheme.dark(),
      // ),
      // themeMode: ThemeMode.dark,
      // home: JoinScreen(selfCallerId: selfCallerID),
      //home: SignupPage(socketId: selfCallerID,),
      home: LoginPage(socketId: selfCallerID),
      debugShowCheckedModeBanner: false,
    );
  }
}