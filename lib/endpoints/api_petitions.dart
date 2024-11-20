import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wtv/models/movie_list.dart' as moviesResult;
import 'package:wtv/models/series_list.dart' as seriesResult;
import 'package:wtv/models/streaming_provider.dart';

class ApiPetitions {
  static const String apiKey =
      'c399b9dc6a126d4c4de99e265544cabb'; // La teva clau d'API

  static Future<List<StreamingProvider>> fetchProviders() async {
    final String apiUrl = 'https://api.themoviedb.org/3/watch/providers/tv';
    final response = await http.get(
        Uri.parse('$apiUrl?api_key=$apiKey&language=es-ES&watch_region=ES'));
    //https://api.themoviedb.org/3/watch/providers/movie?api_key=c399b9dc6a126d4c4de99e265544cabb&language=es-ES&watch_region=ES
    //https://api.themoviedb.org/3/watch/providers/tv?api_key=c399b9dc6a126d4c4de99e265544cabb&language=es-ES

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List providersJson = data['results'];
      return providersJson
          .map((json) => StreamingProvider.fromJson(json))
          .toList();
    } else {
      throw Exception('Error carregant les plataformes de streaming');
    }
  }

  static Future<List<String>> fetchGenres() async {
    final String apiKey = 'c399b9dc6a126d4c4de99e265544cabb';
    final String apiUrl = 'https://api.themoviedb.org/3/genre/movie/list';
    final response =
        await http.get(Uri.parse('$apiUrl?api_key=$apiKey&language=es-ES'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List genresJson = data['genres'];
      return genresJson.map((json) => json['name'].toString()).toList();
    } else {
      throw Exception('Error carregant els gèneres');
    }
  }

  //
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

  Future<List<Map<String, dynamic>>> searchMovies(
      List<String> tags, String apiKey, String uid) async {
    Map<String, int> genresMap = await getGenresMap(apiKey);
    // Recuperar les plataformes seleccionades per l'usuari
    List<Map<String, dynamic>> selectedPlatforms =
        await getSelectedPlatforms(uid);
    List<int> selectedPlatformIds = [];
    for (var platform in selectedPlatforms) {
      selectedPlatformIds.add(platform['id']);
    }
    //selectedPlatforms.map((platform) => platform['id']).toList();

    // Crear una cadena amb els ID de les plataformes seleccionades
    //String platformsQuery = selectedPlatformIds.join(',');

    String url =
        'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&language=es-ES&with_genres=';

    List<int> genreIds = tags
        .map((tag) => genresMap[tag]) // Mapea los tags a los IDs de géneros
        .where((id) => id != null) // Filtra los valores nulos
        .cast<int>() // Convierte el tipo de la lista a List<int>
        .toList(); // Convierte a lista

    String genreIdsString = genreIds.join(',');
    url += genreIdsString;
    // Afegir el paràmetre de proveïdors de streaming a la consulta
    /* if (platformsQuery.isNotEmpty) {
      url += '&with_watch_providers=$platformsQuery&watch_region=ES';
    } */

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
}
