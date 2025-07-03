import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class MyImageWidget extends StatelessWidget {
  final String imageUrl;

  const MyImageWidget({Key? key, required this.imageUrl}) : super(key: key);

  String getImageUrl(String url) {
    // Your logic to get the image URL
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9, // Default aspect ratio
        child: CachedNetworkImage(
          imageUrl: getImageUrl(imageUrl),
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error, size: 50),
          ),
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}