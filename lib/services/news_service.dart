import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TechNewsController extends ChangeNotifier {
  bool isLoading = false;
  bool isError = false;
  bool isLoadingMore = false;
  String? newsAfter;
  List<dynamic> news = [];

  final BuildContext context;
  TechNewsController({required this.context});

  static const String clientId = 'TqRq2kHD07fQX7iEWtKMaQ';
  static const String clientSecret = 'NDhq7sNYcBbYPDG-YdZk6HU1gQRKEw';
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  static Future<void> _authenticate() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return;
    }
    final response = await http.post(
      Uri.parse('https://www.reddit.com/api/v1/access_token'),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
    } else {
      throw Exception('Reddit Auth failed: ${response.body}');
    }
  }

  Future<void> fetchInitialNews() async {
    isLoading = true;
    isError = false;
    newsAfter = null;
    notifyListeners();

    try {
      await _authenticate();
      final techSubreddits = [
        'technology',
        'programming',
        'webdev',
        'android',
        'ios',
        'flutter',
        'dart',
        'machinelearning',
        'artificial',
        'cybersecurity',
      ];
      final subreddit = techSubreddits.join('+');
      final url = 'https://oauth.reddit.com/r/$subreddit/hot?limit=20';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'User-Agent': 'TechNewsExplorer/0.1 by Western-Carry-6201',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List children = data['data']['children'];
        newsAfter = data['data']['after'];

        news =
            children
                .map((item) => item['data'])
                .where(
                  (item) =>
                      item['title'] != null &&
                      item['url'] != null &&
                      !item['over_18'] &&
                      !item['spoiler'],
                )
                .map(
                  (item) => {
                    'title': item['title'],
                    'url': item['url'],
                    'ups': item['ups'] ?? 0,
                    'postLink': 'https://reddit.com${item['permalink']}',
                    'subreddit': item['subreddit'],
                    'author': item['author'],
                    'numComments': item['num_comments'] ?? 0,
                    'created': item['created_utc'],
                    'selftext': item['selftext'] ?? '',
                    'thumbnail': item['thumbnail'] ?? '',
                  },
                )
                .toList();

        isLoading = false;
        isError = false;
      } else {
        throw Exception('Failed to load tech news: ${response.statusCode}');
      }
    } catch (e) {
      isLoading = false;
      isError = true;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tech news: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    notifyListeners();
  }

  Future<void> fetchMoreNews() async {
    if (isLoadingMore || newsAfter == null) return;

    isLoadingMore = true;
    notifyListeners();

    try {
      await _authenticate();
      final techSubreddits = [
        'technology',
        'programming',
        'webdev',
        'android',
        'ios',
        'flutter',
        'dart',
        'machinelearning',
        'artificial',
        'cybersecurity',
      ];
      final subreddit = techSubreddits.join('+');
      final url =
          'https://oauth.reddit.com/r/$subreddit/hot?limit=20&after=$newsAfter';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'User-Agent': 'TechNewsExplorer/0.1 by Western-Carry-6201',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List children = data['data']['children'];
        newsAfter = data['data']['after'];

        final newNews =
            children
                .map((item) => item['data'])
                .where(
                  (item) =>
                      item['title'] != null &&
                      item['url'] != null &&
                      !item['over_18'] &&
                      !item['spoiler'],
                )
                .map(
                  (item) => {
                    'title': item['title'],
                    'url': item['url'],
                    'ups': item['ups'] ?? 0,
                    'postLink': 'https://reddit.com${item['permalink']}',
                    'subreddit': item['subreddit'],
                    'author': item['author'],
                    'numComments': item['num_comments'] ?? 0,
                    'created': item['created_utc'],
                    'selftext': item['selftext'] ?? '',
                    'thumbnail': item['thumbnail'] ?? '',
                  },
                )
                .toList();

        news.addAll(newNews);
        isLoadingMore = false;
      } else {
        throw Exception(
          'Failed to load more tech news: ${response.statusCode}',
        );
      }
    } catch (e) {
      isLoadingMore = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more tech news: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    notifyListeners();
  }

  void dispose() {
    super.dispose();
  }
}
