import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wtv/models/movie_list.dart' as moviesResult;
import 'package:wtv/models/series_list.dart' as seriesResult;
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

    // plataformes de l'usuari
    List<Map<String, dynamic>> selectedPlatforms =
        await getSelectedPlatforms(uid);

    List selectedPlatformNames =
        selectedPlatforms.map((platform) => platform['name']).toList();

    try {
      final moviesResponse = await http.get(Uri.parse(moviesUrl));
      final seriesResponse = await http.get(Uri.parse(seriesUrl));

      if (moviesResponse.statusCode == 200 &&
          seriesResponse.statusCode == 200) {
        final moviesData = json.decode(moviesResponse.body)['results'] as List;
        final seriesData = json.decode(seriesResponse.body)['results'] as List;

        // Filtrar las pelis que coincideixen amb les plataformes seleccionades
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

        // Filtrar las series que coincideixen amb les plataformes seleccionades
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

  Future<List<Map<String, dynamic>>> searchMovies(
      List<String> tags, String apiKey, String uid) async {
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
      final movieList = moviesResult.movieListFromJson(response.body);
      // Especificar explícitamente el tipo en el Future.wait
      List<Map<String, dynamic>> returnData = await Future.wait(
          movieList.results.map((moviesResult.Result item) async {
        // Cridar fetchPlatforms per a cada pel·lícula
        List<String> platforms = await fetchPlatforms(item.id, 'movie');
        List<String> plat = platforms.isNotEmpty ? [platforms.first] : [];

        return {
          'title': item.title,
          'imageUrl': 'https://image.tmdb.org/t/p/w500${item.posterPath}',
          'platforms': plat, // Afegir el primer element de platforms
        };
      }).toList());

      debugPrint(returnData.runtimeType.toString());
      return returnData; // Ja no cal fer cast
    } else {
      throw Exception('Error al cargar las películas');
    }
  }

  Future<List<Map<String, dynamic>>> searchSeries(
      List<String> tags, String apiKey, String uid) async {
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
      final serieList = seriesResult.serieListFromJson(response.body);
      List<Map<String, dynamic>> returnData = await Future.wait(
          serieList.results.map((seriesResult.Result item) async {
        List<String> platforms = await fetchPlatforms(item.id, 'tv');
        List<String> plat = platforms.isNotEmpty ? [platforms.first] : [];
        return {
          'title': item.name,
          'imageUrl': 'https://image.tmdb.org/t/p/w500${item.posterPath}',
          'platforms': plat, // Afegir el primer element de platforms
        };
      }).toList());

      return returnData;
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
        automaticallyImplyLeading: false,
        title: const Text('WTV'),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Darrament a les teves plataformes:',
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
                          height: 410.0,
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
              const Text('Per gustos:',
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
                            future: Future.wait([
                              searchMovies(
                                  tagList,
                                  apiKey,
                                  FirebaseAuth.instance.currentUser!
                                      .uid), // Buscar pelis
                              searchSeries(
                                  tagList,
                                  apiKey,
                                  FirebaseAuth.instance.currentUser!
                                      .uid), // Buscar series
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
                                final movies = snapshot.data![0]; // pelis
                                final series = snapshot.data![1]; // series

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Gèneres: ${tagList.join(", ")}',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Pelis',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    // ListView de pelis
                                    SizedBox(
                                      height: 200,
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
                                                    height: 165,
                                                    width: 110,
                                                    fit: BoxFit.cover),
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 8.0,
                                                            left: 4.0,
                                                            right: 4.0),
                                                    child: Text(
                                                        '${movie['platforms'].join(', ')}'))
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        'Series',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 200,
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
                                                    height: 165,
                                                    width: 110,
                                                    fit: BoxFit.cover),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .only(
                                                      top: 8.0,
                                                      left: 4.0,
                                                      right:
                                                          4.0), // Afegir un padding superior
                                                  child: Text(
                                                    '${serie['platforms'].join(', ')}',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                  ],
                                );
                              } else {
                                return Center(
                                    child: Text('No s\'han trobat resultats.'));
                              }
                            },
                          );
                        },
                      );
                    } else {
                      return const Center(
                          child: Text('No s\'han trobat gèneres.'));
                    }
                  },
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
              MaterialPageRoute(builder: (context) => ReviewsPage()),
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
