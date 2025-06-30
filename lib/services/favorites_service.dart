import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:api_integration/models/meme_model.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_memes';

  // Get all favorite memes
  static Future<List<Meme>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

      print('Loading favorites from storage. Count: ${favoritesJson.length}');
      if (favoritesJson.isNotEmpty) {
        print('First favorite JSON: ${favoritesJson.first}');
      }

      final favorites =
          favoritesJson
              .map((json) {
                try {
                  final meme = Meme.fromJson(jsonDecode(json));
                  print('Successfully parsed meme: ${meme.title}');
                  return meme;
                } catch (e) {
                  print('Error parsing meme JSON: $e');
                  print('Problematic JSON: $json');
                  return null;
                }
              })
              .where((meme) => meme != null)
              .cast<Meme>()
              .toList();

      print('Loaded ${favorites.length} favorites');
      return favorites;
    } catch (e) {
      print('Error loading favorites: $e');
      return [];
    }
  }

  // Add a meme to favorites
  static Future<bool> addToFavorites(Meme meme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

      // Check if meme is already in favorites
      final memeJson = jsonEncode(meme.toJson());
      print('Adding meme to favorites: ${meme.title}');
      print('Meme URL: ${meme.url}');
      print('Meme JSON: $memeJson');
      print('Current favorites count: ${favoritesJson.length}');

      if (favoritesJson.contains(memeJson)) {
        print('Meme already in favorites');
        return false; // Already in favorites
      }

      favoritesJson.add(memeJson);
      await prefs.setStringList(_favoritesKey, favoritesJson);
      print('Successfully added meme. New count: ${favoritesJson.length}');
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  // Remove a meme from favorites
  static Future<bool> removeFromFavorites(Meme meme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

      final memeJson = jsonEncode(meme.toJson());
      final removed = favoritesJson.remove(memeJson);

      if (removed) {
        await prefs.setStringList(_favoritesKey, favoritesJson);
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Check if a meme is in favorites
  static Future<bool> isFavorite(Meme meme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];

      final memeJson = jsonEncode(meme.toJson());
      return favoritesJson.contains(memeJson);
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  // Clear all favorites
  static Future<bool> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      print('Cleared all favorites');
      return true;
    } catch (e) {
      print('Error clearing favorites: $e');
      return false;
    }
  }

  // Clear corrupted favorites (for debugging)
  static Future<bool> clearCorruptedFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      print('Cleared corrupted favorites data');
      return true;
    } catch (e) {
      print('Error clearing corrupted favorites: $e');
      return false;
    }
  }

  // Get favorites count
  static Future<int> getFavoritesCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      return favoritesJson.length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }
}
