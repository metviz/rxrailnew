class SafetyVideoModel {
  int? id;
  String? title;
  String? source;
  String? duration;
  String? url;
  String? embed;
  String? thumbnail;
  DateTime? publishedAt;

  SafetyVideoModel({
    this.id,
    this.title,
    this.source,
    this.duration,
    this.url,
    this.embed,
    this.thumbnail,
    this.publishedAt,
  });

  SafetyVideoModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    source = json['source'];
    duration = json['duration'];
    url = json['url'];
    embed = json['embed'];
    thumbnail = json['thumbnail'];
    publishedAt = json['publishedAt'] != null
        ? DateTime.tryParse(json['publishedAt'])
        : null;
  }

  /// Extract the YouTube video ID from the url or embed field.
  String get videoId {
    final u = url ?? embed ?? '';
    final m = RegExp(r'(?:v=|embed/|youtu\.be/|shorts/)([a-zA-Z0-9_-]{11})').firstMatch(u);
    return m?.group(1) ?? '';
  }
}
