import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openMapDirections(double lat, double lng) async {
  final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

  if (kIsWeb) {
    await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    return;
  }

  final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
  if (await canLaunchUrl(geoUri)) {
    await launchUrl(geoUri, mode: LaunchMode.externalApplication);
  } else {
    await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
  }
}
