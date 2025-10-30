class SafetyVideoModel {
  int? id;
  String? title;
  String? source;
  String? duration;
  String? url;
  String? embed;
  String? thumbnail;

  SafetyVideoModel(
      {this.id,
        this.title,
        this.source,
        this.duration,
        this.url,
        this.embed,
        this.thumbnail});

  SafetyVideoModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    source = json['source'];
    duration = json['duration'];
    url = json['url'];
    embed = json['embed'];
    thumbnail = json['thumbnail'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['source'] = this.source;
    data['duration'] = this.duration;
    data['url'] = this.url;
    data['embed'] = this.embed;
    data['thumbnail'] = this.thumbnail;
    return data;
  }
}
