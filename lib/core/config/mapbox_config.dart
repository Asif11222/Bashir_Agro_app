/// Mapbox and Raster Tile Configuration for Bashir Agro
/// Supports both Mapbox Satellite Streets (when token is provided)
/// and Ultra High-Resolution Google Hybrid Satellite & OpenStreetMap fallback.
class MapboxConfig {
  /// Optional Mapbox access token.
  /// If configured, the app uses official Mapbox styles (satellite-streets-v12, streets-v12).
  /// If omitted or empty, it automatically uses ultra high-res Google Hybrid Satellite
  /// and OpenStreetMap raster tiles (zero-auth, 100% resilient).
  static String? accessToken;

  /// Satellite style tile URL template
  static String getSatelliteTileUrl() {
    if (accessToken != null && accessToken!.trim().isNotEmpty) {
      return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${accessToken!.trim()}';
    }
    // High-resolution Google Hybrid Satellite (photographic imagery + roads + field boundaries)
    return 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
  }

  /// Street style tile URL template
  static String getStreetTileUrl() {
    if (accessToken != null && accessToken!.trim().isNotEmpty) {
      return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=${accessToken!.trim()}';
    }
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// Subdomains for load balancing tile servers
  static List<String> getSatelliteSubdomains() {
    if (accessToken != null && accessToken!.trim().isNotEmpty) {
      return const ['a', 'b', 'c', 'd'];
    }
    return const ['0', '1', '2', '3'];
  }

  static List<String> getStreetSubdomains() {
    return const ['a', 'b', 'c'];
  }
}
