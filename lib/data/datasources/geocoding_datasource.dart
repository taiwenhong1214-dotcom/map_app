import 'package:dio/dio.dart';
import '../../core/coordinate/coordinate_converter.dart';

class GeocodingDataSource {
  final Dio _dio;

  GeocodingDataSource(this._dio);

  Future<LatLng84?> searchLocation(String query) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'CircularTravelApp', // Nominatim 要求提供 User-Agent
          },
        ),
      );

      if (response.data != null && response.data is List && response.data.isNotEmpty) {
        final result = response.data[0];
        final lat = double.tryParse(result['lat'].toString());
        final lon = double.tryParse(result['lon'].toString());
        if (lat != null && lon != null) {
          return LatLng84(lat, lon);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
