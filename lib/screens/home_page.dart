import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wtv/screens/custom_search_delegate.dart';
import 'package:wtv/screens/profile_page.dart';
import 'package:wtv/screens/reviews_page.dart';
import 'package:wtv/screens/social_page.dart';
import 'package:wtv/screens/splash.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _items;

  @override
  void initState() {
    super.initState();
    _items = fetchMoviesAndSeries();
  }

  Future<List<Map<String, dynamic>>> fetchMoviesAndSeries() async {
    const String apiKey = 'c399b9dc6a126d4c4de99e265544cabb';
    final String moviesUrl =
        'https://api.themoviedb.org/3/trending/movie/week?api_key=$apiKey';
    final String seriesUrl =
        'https://api.themoviedb.org/3/trending/tv/week?api_key=$apiKey';

    try {
      final moviesResponse = await http.get(Uri.parse(moviesUrl));
      final seriesResponse = await http.get(Uri.parse(seriesUrl));

      if (moviesResponse.statusCode == 200 &&
          seriesResponse.statusCode == 200) {
        final moviesData = json.decode(moviesResponse.body)['results'] as List;
        final seriesData = json.decode(seriesResponse.body)['results'] as List;

        // Obtener los primeros 5 resultados de cada
        final List<Map<String, dynamic>> movies =
            await Future.wait(moviesData.take(5).map((item) async {
          final platforms = await fetchPlatforms(item['id'], 'movie');
          return {
            'title': item['title'] ?? item['name'],
            'imageUrl': 'https://image.tmdb.org/t/p/w500${item['poster_path']}',
            'platforms': platforms,
          };
        }).toList());

        final List<Map<String, dynamic>> series =
            await Future.wait(seriesData.take(5).map((item) async {
          final platforms = await fetchPlatforms(item['id'], 'tv');
          return {
            'title': item['title'] ?? item['name'],
            'imageUrl': 'https://image.tmdb.org/t/p/w500${item['poster_path']}',
            'platforms': platforms,
          };
        }).toList());

        return [...movies, ...series]; // Combinar ambos
      } else {
        throw Exception('Error al cargar datos de TMDB');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<String>> fetchPlatforms(int id, String type) async {
    const String apiKey = 'c399b9dc6a126d4c4de99e265544cabb';
    final String url =
        'https://api.themoviedb.org/3/$type/$id/watch/providers?api_key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results =
          data['results']['ES']; // Cambia el país según sea necesario
      if (results != null && results['flatrate'] != null) {
        return (results['flatrate'] as List)
            .map((item) => item['provider_name'].toString())
            .toList();
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WTV'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Per a tu:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 430,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _items,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final items = snapshot.data!;
                      return CarouselSlider.builder(
                        options: CarouselOptions(
                          height: 400.0, // Ajusta la altura según lo necesario
                          autoPlay: false,
                          enlargeCenterPage: true,
                          enableInfiniteScroll: false,
                          viewportFraction: 0.8,
                          scrollPhysics: const BouncingScrollPhysics(),
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index, realIndex) {
                          final item = items[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors
                                  .white, // Fondo blanco para resaltar el contenido
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Imagen del carrusel
                                Container(
                                  height: 320,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                    image: DecorationImage(
                                      image: NetworkImage(item['imageUrl']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // Text del títol
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    item['title'],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // Text de la plataforma
                                if (item['platforms'] != null &&
                                    item['platforms'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      'Plataforma: ${item['platforms'].join(", ")}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text('Vist darrerament:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              const Text('Categories:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('Núvol de tags',
                      style: TextStyle(color: Colors.black54)),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: const Color.fromARGB(255, 79, 57, 204),
        unselectedItemColor: Colors.grey,
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
              MaterialPageRoute(builder: (context) => const SocialPage()),
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
