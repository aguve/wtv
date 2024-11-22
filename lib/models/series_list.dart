// To parse this JSON data, do
//
//     final serieList = serieListFromJson(jsonString);

import 'dart:convert';

SerieList serieListFromJson(String str) => SerieList.fromJson(json.decode(str));

String serieListToJson(SerieList data) => json.encode(data.toJson());

class SerieList {
  final int page;
  final List<Result> results;
  final int totalPages;
  final int totalResults;

  SerieList({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory SerieList.fromJson(Map<String, dynamic> json) => SerieList(
        page: json["page"] ?? 0,
        results: json["results"] != null
            ? List<Result>.from(json["results"].map((x) => Result.fromJson(x)))
            : [],
        totalPages: json["total_pages"] ?? 0,
        totalResults: json["total_results"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "page": page,
        "results": List<dynamic>.from(results.map((x) => x.toJson())),
        "total_pages": totalPages,
        "total_results": totalResults,
      };
}

class Result {
  final bool adult;
  final String? backdropPath;
  final List<int> genreIds;
  final int id;
  final List<String> originCountry;
  final String originalLanguage;
  final String originalName;
  final String? overview; // Permet null
  final double? popularity; // Permet null
  final String? posterPath; // Permet null
  final DateTime? firstAirDate; // Permet null
  final String name;
  final double? voteAverage;
  final int voteCount;

  Result({
    required this.adult,
    required this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originCountry,
    required this.originalLanguage,
    required this.originalName,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.firstAirDate,
    required this.name,
    required this.voteAverage,
    required this.voteCount,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        adult: json["adult"] ?? false,
        backdropPath: json["backdrop_path"],
        genreIds: List<int>.from(json["genre_ids"].map((x) => x)),
        id: json["id"],
        originCountry: List<String>.from(json["origin_country"].map((x) => x)),
        originalLanguage: json["original_language"] ?? '',
        originalName: json["original_name"] ?? '',
        overview: json["overview"],
        popularity:
            json["popularity"] != null ? json["popularity"].toDouble() : null,
        posterPath: json["poster_path"],
        firstAirDate:
            json["first_air_date"] != null && json["first_air_date"].isNotEmpty
                ? DateTime.parse(json["first_air_date"])
                : null,
        name: json["name"] ?? '',
        voteAverage: json["vote_average"] != null
            ? json["vote_average"].toDouble()
            : null,
        voteCount: json["vote_count"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "adult": adult,
        "backdrop_path": backdropPath,
        "genre_ids": List<dynamic>.from(genreIds.map((x) => x)),
        "id": id,
        "origin_country": List<dynamic>.from(originCountry.map((x) => x)),
        "original_language": originalLanguage,
        "original_name": originalName,
        "overview": overview,
        "popularity": popularity,
        "poster_path": posterPath,
        "first_air_date":
            "${firstAirDate!.year.toString().padLeft(4, '0')}-${firstAirDate?.month.toString().padLeft(2, '0')}-${firstAirDate?.day.toString().padLeft(2, '0')}",
        "name": name,
        "vote_average": voteAverage,
        "vote_count": voteCount,
      };
}
