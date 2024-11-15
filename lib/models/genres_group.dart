class GenreGroup {
  final List<String> genres;

  GenreGroup({required this.genres});

  factory GenreGroup.fromJson(Map<String, dynamic> json) {
    return GenreGroup(
      genres: List<String>.from(json['genres']),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'genres': genres,
    };
  }
}
