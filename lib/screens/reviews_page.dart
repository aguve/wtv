import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wtv/screens/custom_search_delegate.dart';
import 'package:wtv/screens/home_page.dart';
import 'package:wtv/screens/profile_page.dart';
import 'package:wtv/screens/social_page.dart';
import 'package:wtv/screens/splash.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        leading: IconButton(
          onPressed: () {
            showSearch(context: context, delegate: CustomSearchDelegate());
          },
          icon: const Icon(Icons.search),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (String result) async {
              /* ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opció seleccionada: $result'))); */
              switch (result) {
                case 'logout':
                  await FirebaseAuth.instance.signOut();
                  Navigator.popUntil(context, (route) => route.isFirst);
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => Splash()));
                  break;
                case 'settings':
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Text('Sortir'),
                      SizedBox(width: 25),
                      Icon(Icons.logout),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Text('Opcions'),
                      SizedBox(width: 5),
                      Icon(Icons.settings),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: const Center(child: Text('Què en penses?')),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(255, 79, 57, 204),
        unselectedItemColor: Colors.grey,
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SocialPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReviewsPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.reviews_outlined),
            label: '',
          ),
        ],
      ),
    );
  }
}
