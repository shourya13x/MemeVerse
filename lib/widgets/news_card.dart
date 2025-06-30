import 'package:flutter/material.dart';

class NewsCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final int ups;
  final String postLink;
  final String subreddit;
  const NewsCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.ups,
    required this.postLink,
    required this.subreddit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(child: ListTile(title: Text(title)));
  }
}
