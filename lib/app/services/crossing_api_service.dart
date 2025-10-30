// // // lib/services/crossing_api_service.dart
// // import 'package:dio/dio.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:get/get.dart';
// // import '../model/railway_crossing_model.dart';
// //
// // class CrossingApiService extends GetxService {
// //   final Dio _dio = Dio();
// //   final String baseUrl = 'https://data.transportation.gov/resource/vhwz-raag.json';
// //   final int apiMaxLimit = 1000; // API's maximum limit per request
// //
// //   Future<List<RailwayCrossing>> fetchCrossingsPaginated({
// //     int offset = 0,
// //     int limit = 50,
// //     Map<String, dynamic>? additionalParams,
// //   }) async {
// //     try {
// //       // Ensure we don't exceed API's maximum limit
// //       final effectiveLimit = limit > apiMaxLimit ? apiMaxLimit : limit;
// //
// //       final params = {
// //         '\$offset': offset,
// //         '\$limit': effectiveLimit,
// //         ...?additionalParams,
// //       };
// //
// //       final response = await _dio.get(baseUrl, queryParameters: params);
// //
// //       if (response.statusCode == 200) {
// //         return (response.data as List)
// //             .map((json) => RailwayCrossing.fromJson(json))
// //             .toList();
// //       }
// //       throw Exception('Failed to load crossings: Status ${response.statusCode}');
// //     } catch (e) {
// //       Get.snackbar(
// //         'Error',
// //         'Failed to fetch crossings: ${e.toString()}',
// //         snackPosition: SnackPosition.BOTTOM,
// //       );
// //       rethrow;
// //     }
// //   }
// //
// //   // New method to fetch large datasets in chunks
// //   Future<List<RailwayCrossing>> fetchAllCrossings({
// //     int chunkSize = 1000,
// //     Map<String, dynamic>? filterParams,
// //   }) async {
// //     final allCrossings = <RailwayCrossing>[];
// //     int offset = 0;
// //     bool hasMore = true;
// //
// //     while (hasMore) {
// //       try {
// //         final crossings = await fetchCrossingsPaginated(
// //           offset: offset,
// //           limit: chunkSize,
// //           additionalParams: filterParams,
// //         );
// //
// //         if (crossings.isNotEmpty) {
// //           allCrossings.addAll(crossings);
// //           offset += crossings.length;
// //           hasMore = crossings.length == chunkSize;
// //         } else {
// //           hasMore = false;
// //         }
// //       } catch (e) {
// //         // Log error but continue with what we have
// //         debugPrint('Error fetching chunk at offset $offset: $e');
// //         hasMore = false;
// //       }
// //     }
// //
// //     return allCrossings;
// //   }
// // }
//
// // import 'package:dio/dio.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:get/get.dart' as getx;
// // import 'package:connectivity_plus/connectivity_plus.dart';
// // import '../local_database/local_databse.dart';
// // import '../model/railway_crossing_model.dart';
// //
// // class CrossingApiService extends getx.GetxService {
// //   final Dio _dio = Dio();
// //   final String baseUrl = 'https://data.transportation.gov/resource/vhwz-raag.json';
// //
// //   // Based on SODA 2.0 API limitations
// //   final int apiMaxLimit = 1000;
// //
// //   final getx.RxInt _totalApiCalls = 0.obs;
// //   final getx.RxInt _totalRecordsFetched = 0.obs;
// //
// //   int get totalApiCalls => _totalApiCalls.value;
// //   int get totalRecordsFetched => _totalRecordsFetched.value;
// //
// //   @override
// //   void onInit() {
// //     super.onInit();
// //     _configureHttpClient();
// //   }
// //
// //   void _configureHttpClient() {
// //     _dio.options.connectTimeout = const Duration(seconds: 10);
// //     _dio.options.receiveTimeout = const Duration(seconds: 20);
// //
// //     _dio.interceptors.add(LogInterceptor(
// //       requestBody: kDebugMode,
// //       responseBody: kDebugMode,
// //     ));
// //
// //     _dio.interceptors.add(
// //       InterceptorsWrapper(
// //         onError: (e, handler) async {
// //           if (_shouldRetry(e)) {
// //             try {
// //               return handler.resolve(await _retry(e.requestOptions));
// //             } catch (e) {
// //               return handler.next(e as DioException);
// //             }
// //           }
// //           return handler.next(e);
// //         },
// //       ),
// //     );
// //   }
// //
// //   bool _shouldRetry(DioException error) {
// //     return error.type == DioExceptionType.connectionTimeout ||
// //         error.type == DioExceptionType.receiveTimeout ||
// //         error.response?.statusCode == 503 ||
// //         error.response?.statusCode == 502;
// //   }
// //
// //   Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
// //     final options = Options(
// //       method: requestOptions.method,
// //       headers: requestOptions.headers,
// //     );
// //
// //     return _dio.request<dynamic>(
// //       requestOptions.path,
// //       data: requestOptions.data,
// //       queryParameters: requestOptions.queryParameters,
// //       options: options,
// //     );
// //   }
// //
// //   // Check for internet connectivity
// //   Future<bool> isInternetAvailable() async {
// //     var connectivityResult = await Connectivity().checkConnectivity();
// //     if (connectivityResult == ConnectivityResult.none) {
// //       return false; // No internet connection
// //     }
// //     return true; // Internet connection available
// //   }
// //
// //   // Core pagination function
// //   Future<List<RailwayCrossingTemp>> fetchCrossingsPaginated({
// //     int offset = 0,
// //     int limit = 1000,
// //   }) async {
// //     try {
// //       final effectiveLimit = limit > apiMaxLimit ? apiMaxLimit : limit;
// //
// //       final params = {
// //         '\$offset': offset,
// //         '\$limit': effectiveLimit,
// //       };
// //
// //       _totalApiCalls.value++;
// //
// //       // Check for internet connection
// //       if (await isInternetAvailable()) {
// //         final response = await _dio.get(baseUrl, queryParameters: params);
// //
// //         if (response.statusCode == 200) {
// //           final crossings = (response.data as List)
// //               .map((json) => RailwayCrossingTemp.fromJson(json))
// //               .toList();
// //
// //           _totalRecordsFetched.value += crossings.length;
// //           return crossings;
// //         }
// //
// //         throw Exception('Failed to load crossings: Status ${response.statusCode}');
// //       } else {
// //         throw Exception('No internet connection. Please check your network settings.');
// //       }
// //     } catch (e) {
// //       debugPrint('API Error: ${e.toString()}');
// //       rethrow;
// //     }
// //   }
// //
// //   // Basic search function (using LIKE)
// //   Future<List<RailwayCrossing>> searchCrossings(String query, {int limit = 100}) async {
// //     try {
// //       final searchCondition = 'location_description LIKE "%$query%" OR crossing_id LIKE "%$query%"';
// //
// //       final params = {
// //         '\$where': searchCondition,
// //         '\$limit': limit,
// //       };
// //
// //       _totalApiCalls.value++;
// //
// //       // Check for internet connection
// //       if (await isInternetAvailable()) {
// //         final response = await _dio.get(baseUrl, queryParameters: params);
// //
// //         if (response.statusCode == 200) {
// //           return (response.data as List)
// //               .map((json) => RailwayCrossing.fromJson(json))
// //               .toList();
// //         }
// //
// //         throw Exception('Search failed: Status ${response.statusCode}');
// //       } else {
// //         throw Exception('No internet connection. Please check your network settings.');
// //       }
// //     } catch (e) {
// //       getx.Get.snackbar(
// //         'Search Error',
// //         'Failed to search crossings: ${e.toString()}',
// //         snackPosition: getx.SnackPosition.BOTTOM,
// //       );
// //       return [];
// //     }
// //   }
// //
// //   // Download entire dataset in background
// //   Future<void> downloadBulkData({
// //     required Function(double progress) onProgress,
// //     required Function(List<RailwayCrossingTemp> data) onComplete,
// //     required Function(String error) onError,
// //   }) async {
// //     try {
// //       int totalRecords = await _estimateTotalRecords();
// //       int fetchedRecords = 0;
// //       int offset = 0;
// //       final allData = <RailwayCrossingTemp>[];
// //
// //       while (true) {
// //         try {
// //           final batch = await fetchCrossingsPaginated(
// //             offset: offset,
// //             limit: apiMaxLimit,
// //           );
// //
// //           if (batch.isEmpty) break;
// //
// //           allData.addAll(batch);
// //           fetchedRecords += batch.length;
// //           offset += batch.length;
// //
// //           onProgress(totalRecords > 0 ? fetchedRecords / totalRecords : 0.0);
// //
// //           await Future.delayed(const Duration(milliseconds: 500));
// //
// //           if (batch.length < apiMaxLimit) break;
// //         } catch (e) {
// //           debugPrint('Error fetching batch at offset $offset: $e');
// //           offset += apiMaxLimit;
// //
// //           if (allData.isEmpty && offset > 3 * apiMaxLimit) {
// //             throw Exception('Multiple fetch failures, aborting bulk download');
// //           }
// //         }
// //       }
// //
// //       onComplete(allData);
// //     } catch (e) {
// //       onError(e.toString());
// //     }
// //   }
// //
// //   // Estimate total record count
// //   Future<int> _estimateTotalRecords() async {
// //     try {
// //       final response = await _dio.get(baseUrl, queryParameters: {
// //         '\$select': 'count(*) as count',
// //       });
// //
// //       if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
// //         return int.tryParse(response.data[0]['count'].toString()) ?? 0;
// //       }
// //
// //       return 0;
// //     } catch (e) {
// //       debugPrint('Error estimating record count: $e');
// //       return 0;
// //     }
// //   }
// // }
//
//
// // lib/services/crossing_api_service.dart
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../model/railway_crossing_model.dart';
//
// class CrossingApiService extends GetxService {
//   final Dio _dio = Dio();
//   final String baseUrl = 'https://data.transportation.gov/resource/vhwz-raag.json';
//   final int apiMaxLimit = 1000;
//
//   Future<List<RailwayCrossing>> fetchCrossingsPaginated({
//     int offset = 0,
//     int limit = 50,
//     LatLngBounds? bounds,
//     String? searchQuery,
//   }) async {
//     try {
//       // Validate limit doesn't exceed API maximum
//       final effectiveLimit = limit > apiMaxLimit ? apiMaxLimit : limit;
//
//       // Build query parameters
//       final params = <String, dynamic>{
//         '\$limit': effectiveLimit,
//         '\$offset': offset,
//       };
//
//       // Add geographic bounds filtering if provided
//       if (bounds != null) {
//         params['\$where'] = '''
//           latitude >= ${bounds.southwest.latitude} AND
//           latitude <= ${bounds.northeast.latitude} AND
//           longitude >= ${bounds.southwest.longitude} AND
//           longitude <= ${bounds.northeast.longitude}
//         ''';
//       }
//
//       // Add search query if provided
//       if (searchQuery != null && searchQuery.isNotEmpty) {
//         params['\$q'] = searchQuery;
//       }
//
//       // Add app token if required (some Socrata APIs need this)
//       // params['\$$app_token'] = 'YOUR_APP_TOKEN';
//
//       debugPrint('Making API request with params: $params');
//
//       final response = await _dio.get(
//         baseUrl,
//         queryParameters: params,
//         options: Options(
//           validateStatus: (status) => status! < 500, // Don't throw for 400 errors
//         ),
//       );
//
//       if (response.statusCode == 200) {
//         final data = response.data as List;
//         return data.map((json) => RailwayCrossing.fromJson(json)).toList();
//       } else if (response.statusCode == 400) {
//         throw Exception('Bad request: ${response.statusMessage}');
//       } else {
//         throw Exception('Failed to load crossings: Status ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('API Error: $e');
//       Get.snackbar(
//         'Error',
//         'Failed to fetch crossings: ${e.toString()}',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       rethrow;
//     }
//   }
//
//   String _buildBoundsCondition(LatLngBounds bounds) {
//     return """
//       latitude >= ${bounds.southwest.latitude} AND
//       latitude <= ${bounds.northeast.latitude} AND
//       longitude >= ${bounds.southwest.longitude} AND
//       longitude <= ${bounds.northeast.longitude}
//     """;
//   }
//
//   Future<List<RailwayCrossing>> fetchAllCrossings({
//     int chunkSize = 1000,
//     LatLngBounds? bounds,
//     String? searchQuery,
//   }) async {
//     final allCrossings = <RailwayCrossing>[];
//     int offset = 0;
//     bool hasMore = true;
//
//     while (hasMore) {
//       try {
//         final crossings = await fetchCrossingsPaginated(
//           offset: offset,
//           limit: chunkSize,
//           bounds: bounds,
//           searchQuery: searchQuery,
//         );
//
//         if (crossings.isNotEmpty) {
//           allCrossings.addAll(crossings);
//           offset += crossings.length;
//           hasMore = crossings.length == chunkSize;
//
//           // Show progress for large downloads
//           if (bounds == null && searchQuery == null) {
//             debugPrint('Fetched ${allCrossings.length} crossings so far...');
//           }
//         } else {
//           hasMore = false;
//         }
//       } catch (e) {
//         // Log error but continue with what we have
//         debugPrint('Error fetching chunk at offset $offset: $e');
//         hasMore = false;
//       }
//     }
//
//     return allCrossings;
//   }
//
//   // Add caching layer
//   final _cache = <String, List<RailwayCrossing>>{};
//
//   Future<List<RailwayCrossing>> fetchCachedCrossings({
//     required String cacheKey,
//     int offset = 0,
//     int limit = 50,
//     LatLngBounds? bounds,
//     String? searchQuery,
//     bool forceRefresh = false,
//   }) async {
//     if (!forceRefresh && _cache.containsKey(cacheKey)) {
//       return _cache[cacheKey]!;
//     }
//
//     final crossings = await fetchCrossingsPaginated(
//       offset: offset,
//       limit: limit,
//       bounds: bounds,
//       searchQuery: searchQuery,
//     );
//
//     _cache[cacheKey] = crossings;
//     return crossings;
//   }
// }
