import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  late Future<List<List<String>>> genresFromFirestore;
  late Future<List<List<Map<String, dynamic>>>> moviesAndSeries;
  static const String apiKey = 'c399b9dc6a126d4c4de99e265544cabb';

  @override
  void initState() {
    super.initState();
    _items = fetchMoviesAndSeries(FirebaseAuth.instance.currentUser!.uid);
    genresFromFirestore =
        getGenresLists(FirebaseAuth.instance.currentUser!.uid);
  }

  Future<List<Map<String, dynamic>>> fetchMoviesAndSeries(String uid) async {
    final String moviesUrl =
        'https://api.themoviedb.org/3/trending/movie/week?api_key=$apiKey';
    final String seriesUrl =
        'https://api.themoviedb.org/3/trending/tv/week?api_key=$apiKey';

    // Obtener las plataformas seleccionadas del usuario
    List<Map<String, dynamic>> selectedPlatforms =
        await getSelectedPlatforms(uid);

    // Extraemos solo los nombres de las plataformas seleccionadas
    List selectedPlatformNames =
        selectedPlatforms.map((platform) => platform['name']).toList();

    try {
      final moviesResponse = await http.get(Uri.parse(moviesUrl));
      final seriesResponse = await http.get(Uri.parse(seriesUrl));

      if (moviesResponse.statusCode == 200 &&
          seriesResponse.statusCode == 200) {
        final moviesData = json.decode(moviesResponse.body)['results'] as List;
        final seriesData = json.decode(seriesResponse.body)['results'] as List;

        // Filtrar las películas que coinciden con las plataformas seleccionadas
        var first5movies = moviesData.take(10);
        List<Map<String, dynamic>> movies = [];

        for (var item in first5movies) {
          final platforms = await fetchPlatforms(item['id'], 'movie');
          final filteredPlatforms = platforms
              .where((platform) => selectedPlatformNames.contains(platform))
              .toList();
          if (filteredPlatforms.isNotEmpty) {
            movies.add({
              'title': item['title'] ?? item['name'],
              'imageUrl':
                  'https://image.tmdb.org/t/p/w500${item['poster_path']}',
              'platforms': filteredPlatforms,
            });
          }
        }

        var first5series = seriesData.take(10);
        List<Map<String, dynamic>> series = [];

        for (var item in first5series) {
          final platforms = await fetchPlatforms(item['id'], 'tv');
          final filteredPlatforms = platforms
              .where((platform) => selectedPlatformNames.contains(platform))
              .toList();
          if (filteredPlatforms.isNotEmpty) {
            series.add({
              'title': item['title'] ?? item['name'],
              'imageUrl':
                  'https://image.tmdb.org/t/p/w500${item['poster_path']}',
              'platforms': filteredPlatforms,
            });
          }
        }

        return [...movies, ...series];
      } else {
        throw Exception('Error al cargar datos de TMDB');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  //
  Future<List<Map<String, dynamic>>> fetchMoviesAndSeriesByGenres(
      List<String> genres) async {
    List<Map<String, dynamic>> moviesAndSeries = [];

    for (var genre in genres) {
      // Obtener las películas por género
      final genreQuery = Uri.parse(
          'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&with_genres=$genre&sort_by=release_date.desc&page=1');
      final response = await http.get(genreQuery);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        moviesAndSeries.addAll(data['results']
            .take(4)
            .toList()); // Tomamos las primeras 4 películas
      }

      // Obtener las series por género
      final seriesQuery = Uri.parse(
          'https://api.themoviedb.org/3/discover/tv?api_key=$apiKey&with_genres=$genre&sort_by=release_date.desc&page=1');
      final seriesResponse = await http.get(seriesQuery);

      if (seriesResponse.statusCode == 200) {
        final seriesData = json.decode(seriesResponse.body);
        moviesAndSeries.addAll(seriesData['results']
            .take(4)
            .toList()); // Tomamos las primeras 4 series
      }
    }

    return moviesAndSeries; // Devuelve una lista plana de películas y series
  }

  Future<List<String>> fetchPlatforms(int id, String type) async {
    const String apiKey = 'c399b9dc6a126d4c4de99e265544cabb';
    final String url =
        'https://api.themoviedb.org/3/$type/$id/watch/providers?api_key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results']['ES'];
      if (results != null && results['flatrate'] != null) {
        return (results['flatrate'] as List)
            .map((item) => item['provider_name'].toString())
            .toList();
      }
    }
    return [];
  }

  Future<List<List<String>>> getGenresLists(String uid) async {
    List<List<String>> genresLists = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('groups')
          .get();

      for (var doc in querySnapshot.docs) {
        List<String> genres = List<String>.from(doc['genres']);
        genresLists.add(genres);
      }

      return genresLists;
    } catch (e) {
      print('Error obtenint llistes de tags: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSelectedStreamingPlatforms(
      String uid) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        List<dynamic> platforms = userDoc['selectedStreamingPlatforms'] ?? [];

        List<Map<String, dynamic>> selectedPlatforms = platforms
            .map((platform) => {
                  'index': platform['index'], // Index de la plataforma
                  'name': platform['name'], // Nom de la plataforma
                })
            .toList();

        return selectedPlatforms;
      } else {
        print('El document no existeix');
        return [];
      }
    } catch (e) {
      print('Error en obtenir les plataformes seleccionades: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSelectedPlatforms(String uid) async {
    // Obtener el documento del usuario desde Firestore
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Asegúrate de que el documento existe
    if (userDoc.exists) {
      // Obtener las plataformas seleccionadas (array)
      List<dynamic> selectedPlatformsData =
          userDoc['selectedStreamingPlatforms'] ?? [];

      List<Map<String, dynamic>> selectedPlatforms = [];

      // Usamos forEach para recorrer cada elemento del array y devolverlo en el formato deseado
      selectedPlatformsData.forEach((platform) {
        selectedPlatforms.add({
          'id': platform['index'], // El índice de la plataforma
          'name': platform['name'], // El nombre de la plataforma
        });
      });

      return selectedPlatforms;
    } else {
      print('El documento del usuario no existe');
      return [];
    }
  }

  Future<List<String>> getPlatformNames(String uid) async {
    // Obtener el documento del usuario desde Firestore
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Asegúrate de que el documento existe
    if (userDoc.exists) {
      // Obtener las plataformas seleccionadas (array)
      List<dynamic> selectedPlatformsData =
          userDoc['selectedStreamingPlatforms'] ?? [];

      // Usamos map para extraer solo los 'name' de cada plataforma
      List<String> platformNames =
          selectedPlatformsData.map<String>((platform) {
        return platform['name']; // Solo obtenemos el 'name'
      }).toList();

      return platformNames;
    } else {
      print('El documento del usuario no existe');
      return [];
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Per a tu:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 450,
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
                          height: 420.0, // Ajusta la altura según lo necesario
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
                                Flexible(
                                  child: Container(
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
                    //print(genresFromFirestore);
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
