import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pinch_zoom_image_updated/pinch_zoom_image_updated.dart';

Widget cachedNetworkImage(String mediaUrl) {
  return PinchZoomImage(
    image: CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Icon(Icons.error),
    ),
  );
}
