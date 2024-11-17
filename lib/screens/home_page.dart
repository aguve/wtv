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
  late Future<List<Map<String, dynamic>>> _filmsAndTv4u;
  late Future<List<List<String>>> genresFromFirestore;
  late Future<List<List<Map<String, dynamic>>>> moviesAndSeries;
  final String apiKey = 'c399b9dc6a126d4c4de99e265544cabb';
  late final List<List<String>> selectedTags;

  @override
  void initState() {
    super.initState();
    _filmsAndTv4u =
        fetchMoviesAndSeries(FirebaseAuth.instance.currentUser!.uid);
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
        var first5movies = moviesData.take(20);
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

        var first5series = seriesData.take(20);
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
  Future<List<Map<String, dynamic>>> searchMovies(
      List<String> tags, String apiKey) async {
    Map<String, int> genresMap = await getGenresMap(apiKey);
    String url =
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&language=es-ES&with_genres=';

    List<int> genreIds = tags
        .map((tag) => genresMap[tag]) // Mapea los tags a los IDs de géneros
        .where((id) => id != null) // Filtra los valores nulos
        .cast<int>() // Convierte el tipo de la lista a List<int>
        .toList(); // Convierte a lista

    String genreIdsString = genreIds.join(',');

    url += genreIdsString;

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body)['results'];
      return data.map((item) {
        return {
          'title': item['title'],
          'imageUrl': 'https://image.tmdb.org/t/p/w500${item['poster_path']}',
          'platforms':
              item['platforms'] ?? [], // Asegúrate de que platforms no sea null
        };
      }).toList();
    } else {
      throw Exception('Error al cargar las películas');
    }
  }

  Future<List<Map<String, dynamic>>> searchSeries(
      List<String> tags, String apiKey) async {
    Map<String, int> genresMap = await getGenresMap(apiKey);
    String url =
        'https://api.themoviedb.org/3/discover/tv?api_key=$apiKey&language=es-ES&with_genres=';

    List<int> genreIds = tags
        .map((tag) => genresMap[tag]) // Mapea los tags a los IDs de géneros
        .where((id) => id != null) // Filtra los valores nulos
        .cast<int>() // Convierte el tipo de la lista a List<int>
        .toList(); // Convierte a lista

    String genreIdsString = genreIds.join(',');

    url += genreIdsString;

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body)['results'];
      return data.map((item) {
        return {
          'title': item['name'],
          'imageUrl': 'https://image.tmdb.org/t/p/w500${item['poster_path']}',
          'platforms': item['platforms'] ?? [],
        };
      }).toList();
    } else {
      throw Exception('Error al cargar las series');
    }
  }

  Future<List<String>> fetchPlatforms(int id, String type) async {
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

  Future<Map<String, int>> getGenresMap(String apiKey) async {
    final movieGenresUrl =
        'https://api.themoviedb.org/3/genre/movie/list?api_key=$apiKey&language=es-ES';
    final tvGenresUrl =
        'https://api.themoviedb.org/3/genre/tv/list?api_key=$apiKey&language=es-ES';

    try {
      final movieResponse = await http.get(Uri.parse(movieGenresUrl));
      final tvResponse = await http.get(Uri.parse(tvGenresUrl));

      if (movieResponse.statusCode == 200 && tvResponse.statusCode == 200) {
        // Parse the movie genres and tv genres
        final movieGenres = json.decode(movieResponse.body)['genres'] as List;
        final tvGenres = json.decode(tvResponse.body)['genres'] as List;

        // Map genre names to ids for movies and tv
        Map<String, int> genresMap = {};

        // Map movie genres
        for (var genre in movieGenres) {
          genresMap[genre['name']] = genre['id'];
        }

        // Map tv genres
        for (var genre in tvGenres) {
          genresMap[genre['name']] = genre['id'];
        }

        return genresMap;
      } else {
        throw Exception('Failed to load genres');
      }
    } catch (e) {
      print('Error: $e');
      return {};
    }
  }

  Future<List<String>> fetchGenres() async {
    const String apiKey = 'c399b9dc6a126d4c4de99e265544cabb';
    const String url =
        'https://api.themoviedb.org/3/genre/movie/list?api_key=$apiKey&language=es-ES';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<String> genres = [];
        for (var genre in data['genres']) {
          genres.add(genre['name']);
        }

        return genres;
      } else {
        throw Exception('Error al obtener los géneros de TMDB');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
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
                  future: _filmsAndTv4u,
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
                                    height: 340,
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
                height: 450,
                child: FutureBuilder<List<List<String>>>(
                  future: genresFromFirestore,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (snapshot.hasData) {
                      final selectedTags = snapshot.data!;

                      return ListView.builder(
                        itemCount: selectedTags.length,
                        itemBuilder: (context, index) {
                          final tagList = selectedTags[index];

                          return FutureBuilder<
                              List<List<Map<String, dynamic>>>>(
                            // Modificamos el tipo aquí
                            future: Future.wait([
                              searchMovies(tagList, apiKey), // Buscar películas
                              searchSeries(tagList, apiKey), // Buscar series
                            ]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text('Error: ${snapshot.error}'));
                              } else if (snapshot.hasData) {
                                final movies = snapshot.data![0]; // Películas
                                final series = snapshot.data![1]; // Series

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Mostrar el título con los tags
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Géneros: ${tagList.join(", ")}',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),

                                    // ListView horizontal para las películas
                                    SizedBox(
                                      height: 250,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: movies.length,
                                        itemBuilder: (context, movieIndex) {
                                          final movie = movies[movieIndex];
                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Column(
                                              children: [
                                                Image.network(movie['imageUrl'],
                                                    height: 150,
                                                    width: 100,
                                                    fit: BoxFit.cover),
                                                Text(movie['title'],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                    'Plataforma: ${movie['platforms'].join(', ')}'),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // ListView horizontal para las series
                                    SizedBox(
                                      height: 250,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: series.length,
                                        itemBuilder: (context, seriesIndex) {
                                          final serie = series[seriesIndex];
                                          return Card(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Column(
                                              children: [
                                                Image.network(serie['imageUrl'],
                                                    height: 150,
                                                    width: 100,
                                                    fit: BoxFit.cover),
                                                Text(serie['title'],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text(
                                                    'Plataforma: ${serie['platforms'].join(', ')}'),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return Center(
                                    child:
                                        Text('No se encontraron resultados.'));
                              }
                            },
                          );
                        },
                      );
                    } else {
                      return const Center(
                          child: Text('No se encontraron géneros.'));
                    }
                  },
                ),
              ),
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
