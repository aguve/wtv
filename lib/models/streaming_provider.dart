class StreamingProvider {
  final int id;
  final String name;
  final String logoUrl;

  StreamingProvider(
      {required this.id, required this.name, required this.logoUrl});

  factory StreamingProvider.fromJson(Map<String, dynamic> json) {
    final String imageBaseUrl = 'https://image.tmdb.org/t/p/original';
    return StreamingProvider(
      id: json['provider_id'],
      name: json['provider_name'],
      logoUrl: '$imageBaseUrl${json['logo_path']}',
    );
  }
}
