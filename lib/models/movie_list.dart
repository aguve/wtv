// To parse this JSON data, do
//
//     final movieList = movieListFromJson(jsonString);

import 'dart:convert';

MovieList movieListFromJson(String str) => MovieList.fromJson(json.decode(str));

String movieListToJson(MovieList data) => json.encode(data.toJson());

class MovieList {
  final int page;
  final List<Result> results;
  final int totalPages;
  final int totalResults;

  MovieList({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory MovieList.fromJson(Map<String, dynamic> json) => MovieList(
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
  final String? backdropPath; // Permet null
  final List<int> genreIds;
  final int id;
  final String originalLanguage;
  final String originalTitle;
  final String? overview; // Permet null
  final double? popularity; // Permet null
  final String? posterPath; // Permet null
  final DateTime? releaseDate; // Permet null
  final String title;
  final bool video;
  final double? voteAverage; // Permet null
  final int voteCount;

  Result({
    required this.adult,
    required this.backdropPath,
    required this.genreIds,
    required this.id,
    required this.originalLanguage,
    required this.originalTitle,
    required this.overview,
    required this.popularity,
    required this.posterPath,
    required this.releaseDate,
    required this.title,
    required this.video,
    required this.voteAverage,
    required this.voteCount,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        adult: json["adult"] ?? false,
        backdropPath: json["backdrop_path"], // Permet null
        genreIds: List<int>.from(json["genre_ids"].map((x) => x)),
        id: json["id"],
        originalLanguage: json["original_language"] ?? '',
        originalTitle: json["original_title"] ?? '',
        overview: json["overview"], // Permet null
        popularity:
            json["popularity"] != null ? json["popularity"].toDouble() : null,
        posterPath: json["poster_path"], // Permet null
        releaseDate:
            json["release_date"] != null && json["release_date"].isNotEmpty
                ? DateTime.parse(json["release_date"])
                : null,
        title: json["title"] ?? '',
        video: json["video"] ?? false,
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
        "original_language": originalLanguage,
        "original_title": originalTitle,
        "overview": overview,
        "popularity": popularity,
        "poster_path": posterPath,
        "release_date": releaseDate?.toIso8601String(),
        "title": title,
        "video": video,
        "vote_average": voteAverage,
        "vote_count": voteCount,
      };
}
