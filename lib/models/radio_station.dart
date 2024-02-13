class RadioStation {
  final String name;
  final String url;
  final String homepage;
  final String favicon;
  final String tags;
  final String country;
  final String state;
  final String language;
  final int votes;
  final bool favourited;

  RadioStation({
    required this.name,
    required this.url,
    required this.homepage,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.state,
    required this.language,
    required this.votes,
    this.favourited = false,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      name: json['name'],
      url: json['url'],
      homepage: json['homepage'],
      favicon: json['favicon'],
      tags: json['tags'],
      country: json['country'],
      state: json['state'],
      language: json['language'],
      votes: json['votes'],
    );
  }
}
