// ignore: unnecessary_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fua;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:wtv/screens/home_page.dart';
import 'package:wtv/screens/profile_page.dart';
import 'package:wtv/styles/app_sytles.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String status = "";
  final providers = [fua.EmailAuthProvider()];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv,
              size: 100,
              color: AppSytles.platinium,
            ),
            Text(
              status,
              style: TextStyle(
                color: AppSytles.platinium,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => SignInScreen(
                    providers: providers,
                    actions: [
                      AuthStateChangeAction<SignedIn>((context, state) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomePage()));
                      }),
                      AuthStateChangeAction<UserCreated>((context, state) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProfilePage()));
                      }),
                    ],
                  )));
    } else {
      final uid = user.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final profileName = data?['displayName'] ?? '';
        final profileImage = data?['profileImage'] ?? '';

        if (profileName.isEmpty && profileImage.isEmpty) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => ProfilePage()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomePage()));
        }
      } /*  else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ProfilePage()));
      } */
    }
  }

  /* void changeStatus(String st) {
    status = st;
    setState(() {});
  } */
}
