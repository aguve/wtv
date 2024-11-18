import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wtv/models/streaming_provider.dart';

class ApiPetitions {
  static const String apiKey =
      'c399b9dc6a126d4c4de99e265544cabb'; // La teva clau d'API

  static Future<List<StreamingProvider>> fetchProviders() async {
    final String apiUrl = 'https://api.themoviedb.org/3/watch/providers/tv';
    final response = await http.get(
        Uri.parse('$apiUrl?api_key=$apiKey&language=es-ES&watch_region=ES'));

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
}
