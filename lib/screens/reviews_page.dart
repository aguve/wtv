import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wtv/screens/home_page.dart';
import 'package:wtv/screens/profile_page.dart';
import 'package:wtv/screens/social_page.dart';
import 'package:wtv/screens/splash.dart';
import 'package:wtv/styles/app_sytles.dart';

class ReviewsPage extends StatefulWidget {
  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _movieData;
  final _reviewController = TextEditingController();
  final String _tmdbApiKey = 'c399b9dc6a126d4c4de99e265544cabb';

  Future<void> _searchMovie() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final url = Uri.parse(
        'https://api.themoviedb.org/3/search/movie?query=$query&api_key=$_tmdbApiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'].isNotEmpty) {
        setState(() {
          _movieData =
              data['results'][0]; // Agafem el primer resultat de la cerca
        });
      } else {
        setState(() {
          _movieData = null;
        });
      }
    } else {
      setState(() {
        _movieData = null;
      });
    }
  }

  Future<void> _saveReview() async {
    if (_movieData == null || _reviewController.text.isEmpty) return;

    final userReview = _reviewController.text.trim();
    final userName = 'Nom d\'usuari'; // Pots obtenir-ho de l'usuari actual

    final reviewData = {
      'movieId': _movieData!['id'],
      'movieTitle': _movieData!['title'],
      'review': userReview,
      'userName': userName,
      'date': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('reviews').add(reviewData);
    _reviewController.clear(); // Esborrar el camp de ressenya
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Ressenya guardada!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Reviews',
          style: TextStyle(
            color: AppSytles.platinium,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppSytles.platinium,
            ),
            onSelected: (String result) async {
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cerca pel·lícula o sèrie',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: _searchMovie,
                  ),
                ),
              ),
              SizedBox(height: 20),
              _movieData != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // La imatge ocupa la meitat superior de la pantalla
                        Container(
                          height: MediaQuery.of(context).size.height *
                              0.4, // Mitja pantalla per la imatge
                          //width: double.infinity,

                          child: Image.network(
                            'https://image.tmdb.org/t/p/w500${_movieData!['poster_path']}',
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Informació del film a la part inferior
                        Text(
                            '${_movieData!['title']} (${_movieData!['release_date']?.substring(0, 4)})',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Estrena: ${_movieData!['release_date']}',
                            style: TextStyle(fontSize: 16)),
                        Text('Valoració: ${_movieData!['vote_average']}',
                            style: TextStyle(fontSize: 16)),
                        SizedBox(height: 20),
                        // Camp per escriure la ressenya
                        TextField(
                          controller: _reviewController,
                          decoration: InputDecoration(
                            labelText: 'Escriu una ressenya',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 4,
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _saveReview,
                          child: Text('Guardar Ressenya'),
                        ),
                      ],
                    )
                  : Text('No es troben resultats per aquesta cerca.'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppSytles.prussianBlue,
        selectedItemColor: AppSytles.platinium,
        unselectedItemColor: AppSytles.sapphire,
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
              MaterialPageRoute(builder: (context) => ReviewsPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Afegeix separació
              child: Icon(Icons.home),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Afegeix separació
              child: Icon(Icons.manage_accounts),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Afegeix separació
              child: Icon(Icons.groups),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(top: 8.0), // Afegeix separació
              child: Icon(Icons.reviews_outlined),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
