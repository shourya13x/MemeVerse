class Meme {
  String? postLink;
  String? subreddit;
  String? title;
  String? url;
  bool? nsfw;
  bool? spoiler;
  String? author;
  int? ups;
  List<String>? preview;

  Meme({
    this.postLink,
    this.subreddit,
    this.title,
    this.url,
    this.nsfw,
    this.spoiler,
    this.author,
    this.ups,
    this.preview,
  });

  Meme.fromJson(Map<String, dynamic> json) {
    postLink = json['postLink'];
    subreddit = json['subreddit'];
    title = json['title'];
    url = json['url'];
    nsfw = json['nsfw'];
    spoiler = json['spoiler'];
    author = json['author'];
    ups = json['ups'];
    preview = json['preview'] != null ? json['preview'].cast<String>() : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['postLink'] = postLink;
    data['subreddit'] = subreddit;
    data['title'] = title;
    data['url'] = url;
    data['nsfw'] = nsfw;
    data['spoiler'] = spoiler;
    data['author'] = author;
    data['ups'] = ups;
    data['preview'] = preview;
    return data;
  }
}
