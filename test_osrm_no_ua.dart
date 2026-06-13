import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 5000),
  ));

  try {
    final res = await dio.get('https://router.project-osrm.org/route/v1/driving/139.6917,35.6895;139.7067,35.7015?geometries=geojson&overview=full');
    print(res.data['routes'][0]['weight']);
    print("Success without User-Agent");
  } catch (e) {
    print('Error without User-Agent: $e');
  }
}
