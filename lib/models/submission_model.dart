enum SubmissionSyncStatus {

  pendingSync,
  syncing,
  synced,
  failed,
}

class OfflineSubmissionItem {
  final String localId;
  final int assignmentId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? notes;
  final List<String> photoPaths; // local file paths or base64 data
  final DateTime createdAt;
  final bool overrideGeofence;
  SubmissionSyncStatus syncStatus;
  String? errorMessage;

  OfflineSubmissionItem({
    required this.localId,
    required this.assignmentId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.notes,
    required this.photoPaths,
    required this.createdAt,
    this.overrideGeofence = false,
    this.syncStatus = SubmissionSyncStatus.pendingSync,
    this.errorMessage,
  });

  factory OfflineSubmissionItem.fromJson(Map<String, dynamic> json) {
    return OfflineSubmissionItem(
      localId: json['local_id']?.toString() ?? '',
      assignmentId: json['assignment_id'] is int
          ? json['assignment_id']
          : int.tryParse(json['assignment_id']?.toString() ?? '0') ?? 0,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      notes: json['notes']?.toString(),
      photoPaths: (json['photo_paths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      overrideGeofence: json['override_geofence'] == true,
      syncStatus: SubmissionSyncStatus.values.firstWhere(
        (e) => e.name == json['sync_status'],
        orElse: () => SubmissionSyncStatus.pendingSync,
      ),
      errorMessage: json['error_message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'local_id': localId,
    'assignment_id': assignmentId,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'notes': notes,
    'photo_paths': photoPaths,
    'created_at': createdAt.toIso8601String(),
    'override_geofence': overrideGeofence,
    'sync_status': syncStatus.name,
    'error_message': errorMessage,
  };
}

class ApiSubmissionResult {
  final bool success;
  final String message;
  final int? submissionId;
  final bool geofencePassed;
  final double? distanceMeters;
  final double? radiusMeters;
  final bool isPolygonBoundary;
  final String? status;
  final String? verificationStatus;

  const ApiSubmissionResult({
    required this.success,
    required this.message,
    this.submissionId,
    this.geofencePassed = true,
    this.distanceMeters,
    this.radiusMeters,
    this.isPolygonBoundary = false,
    this.status,
    this.verificationStatus,
  });

  bool get isGeofenceRejected => !geofencePassed || (!success && distanceMeters != null);

  factory ApiSubmissionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    final geofence = (json['geofence'] ?? data?['geofence']) as Map<String, dynamic>?;

    final dist = geofence?['distance_meters'] != null
        ? (geofence!['distance_meters'] as num).toDouble()
        : (data?['distance_meters'] != null ? (data!['distance_meters'] as num).toDouble() : null);

    final radius = geofence?['radius_meters'] != null
        ? (geofence!['radius_meters'] as num).toDouble()
        : null;

    final isPolygon = geofence?['polygon_boundary'] == true ||
        geofence?['polygon_validated'] == true;

    return ApiSubmissionResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      submissionId: data?['id'] is int ? data!['id'] : null,
      geofencePassed: geofence != null ? (geofence['passed'] == true) : (json['success'] == true),
      distanceMeters: dist,
      radiusMeters: radius,
      isPolygonBoundary: isPolygon,
      status: data?['status']?.toString() ?? (json['success'] == true ? 'submitted' : 'failed'),
      verificationStatus: data?['verification_status']?.toString() ?? (json['success'] == true ? 'pending' : 'rejected'),
    );
  }

  factory ApiSubmissionResult.fromError(String message, [dynamic errors]) {
    double? dist;
    double? radius;
    bool isPolygon = false;

    if (errors is Map) {
      final geofence = errors['geofence'] as Map<String, dynamic>?;
      if (geofence != null) {
        dist = (geofence['distance_meters'] as num?)?.toDouble();
        radius = (geofence['radius_meters'] as num?)?.toDouble();
        isPolygon = geofence['polygon_boundary'] == true;
      }
    }

    return ApiSubmissionResult(
      success: false,
      message: message,
      geofencePassed: false,
      distanceMeters: dist,
      radiusMeters: radius,
      isPolygonBoundary: isPolygon,
      status: 'rejected',
      verificationStatus: 'failed',
    );
  }
}
