import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/coordinate/coordinate_converter.dart';
import '../../../data/datasources/geocoding_datasource.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';
import 'package:dio/dio.dart';

class MapSearchBar extends ConsumerStatefulWidget {
  final ValueChanged<LatLng84> onLocationFound;

  const MapSearchBar({super.key, required this.onLocationFound});

  @override
  ConsumerState<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends ConsumerState<MapSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  late final GeocodingDataSource _geocodingDataSource;

  @override
  void initState() {
    super.initState();
    _geocodingDataSource = GeocodingDataSource(Dio());
  }

  Future<void> _search(AppStrings strings) async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus(); // 收起键盘

    final result = await _geocodingDataSource.searchLocation(query);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        widget.onLocationFound(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.searchNotFound)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _search(strings),
        decoration: InputDecoration(
          hintText: strings.searchPlaceholder,
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(14.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: () => _search(strings),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
