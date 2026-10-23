import 'field_boundary_model.dart';
import '../core/utils/date_formatter.dart';

class TaskTemplateDetail {

  final int id;
  final String taskCode;
  final String name;
  final String category;
  final String? instructions;
  final bool requiresEvidencePhoto;
  final int minPhotosRequired;
  final bool requiresGeofenceValidation;
  final String status;

  const TaskTemplateDetail({
    required this.id,
    required this.taskCode,
    required this.name,
    required this.category,
    this.instructions,
    this.requiresEvidencePhoto = true,
    this.minPhotosRequired = 1,
    this.requiresGeofenceValidation = true,
    this.status = 'active',
  });

  factory TaskTemplateDetail.fromJson(Map<String, dynamic> json) {
    return TaskTemplateDetail(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      taskCode: json['task_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      instructions: json['instructions']?.toString(),
      requiresEvidencePhoto: json['requires_evidence_photo'] == true,
      minPhotosRequired: json['min_photos_required'] is int
          ? json['min_photos_required']
          : int.tryParse(json['min_photos_required']?.toString() ?? '1') ?? 1,
      requiresGeofenceValidation: json['requires_geofence_validation'] == true,
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'task_code': taskCode,
    'name': name,
    'category': category,
    'instructions': instructions,
    'requires_evidence_photo': requiresEvidencePhoto,
    'min_photos_required': minPhotosRequired,
    'requires_geofence_validation': requiresGeofenceValidation,
    'status': status,
  };
}

class FarmLocationDetail {
  final int id;
  final String locationCode;
  final String name;
  final String type;
  final String address;
  final double? latitude;
  final double? longitude;
  final int geofenceRadiusMeters;
  final String status;
  final dynamic boundary;
  final double? area;
  final String areaUnit;

  const FarmLocationDetail({
    required this.id,
    required this.locationCode,
    required this.name,
    required this.type,
    required this.address,
    this.latitude,
    this.longitude,
    this.geofenceRadiusMeters = 100,
    this.status = 'active',
    this.boundary,
    this.area,
    this.areaUnit = 'একর',
  });

  FieldBoundaryModel? get fieldBoundary {
    if (boundary != null) {
      final parsed = FieldBoundaryModel.fromGeoJson(boundary);
      if (parsed.isNotEmpty) return parsed;
    }
    if (latitude != null && longitude != null && latitude != 0.0 && longitude != 0.0) {
      return FieldBoundaryModel.fromCenterAndRadius(
        latitude!,
        longitude!,
        geofenceRadiusMeters > 0 ? geofenceRadiusMeters.toDouble() : 40.0,
      );
    }
    return null;
  }

  bool get hasBoundaryPolygon => fieldBoundary != null && fieldBoundary!.isNotEmpty;

  double? get effectiveLatitude => latitude ?? fieldBoundary?.centroid.latitude;
  double? get effectiveLongitude => longitude ?? fieldBoundary?.centroid.longitude;

  String get formattedArea {
    if (area != null && area! > 0) {
      return '$area $areaUnit';
    }
    if (fieldBoundary != null && fieldBoundary!.isNotEmpty) {
      final calculated = fieldBoundary!.calculateAreaAcres();
      return '${calculated.toStringAsFixed(2)} একর';
    }
    return '';
  }

  factory FarmLocationDetail.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final center = json['center'] as Map<String, dynamic>?;

    final lat = coords != null && coords['latitude'] != null
        ? double.tryParse(coords['latitude'].toString())
        : (center != null && center['latitude'] != null
            ? double.tryParse(center['latitude'].toString())
            : (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null));

    final lng = coords != null && coords['longitude'] != null
        ? double.tryParse(coords['longitude'].toString())
        : (center != null && center['longitude'] != null
            ? double.tryParse(center['longitude'].toString())
            : (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null));

    return FarmLocationDetail(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      locationCode: json['location_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Field',
      address: json['address']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
      geofenceRadiusMeters: json['geofence_radius_meters'] is int
          ? json['geofence_radius_meters']
          : int.tryParse(json['geofence_radius_meters']?.toString() ?? '100') ?? 100,
      status: json['status']?.toString() ?? 'active',
      boundary: json['boundary'] ?? json['boundary_geojson'],
      area: json['area'] != null ? double.tryParse(json['area'].toString()) : null,
      areaUnit: json['area_unit']?.toString() ?? 'একর',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'location_code': locationCode,
    'name': name,
    'type': type,
    'address': address,
    'coordinates': {
      'latitude': latitude,
      'longitude': longitude,
    },
    'geofence_radius_meters': geofenceRadiusMeters,
    'status': status,
    'boundary': boundary,
    'area': area,
    'area_unit': areaUnit,
  };
}

class TaskAssignmentModel {
  final int id;
  final String scheduledDate;
  final String? startTime;
  final String? endTime;
  final String priority;
  final String status; // 'assigned', 'in_progress', 'completed'
  final String? notes;
  final String? assignedAt;
  final String? startedAt;
  final String? completedAt;
  final TaskTemplateDetail? task;
  final FarmLocationDetail? location;
  final Map<String, dynamic>? farmer;
  final TaskSubmissionSummary? submission;

  const TaskAssignmentModel({
    required this.id,
    required this.scheduledDate,
    this.startTime,
    this.endTime,
    this.priority = 'normal',
    required this.status,
    this.notes,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.task,
    this.location,
    this.farmer,
    this.submission,
  });

  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  String get displayTitle => task?.name ?? 'কৃষি কাজ';
  String get displayCategory => task?.category ?? 'মাঠ কাজ';
  String get displayLocation => location?.name ?? 'ফার্ম লোকেশন';
  String get displayAddress => location?.address ?? '';
  int get minPhotosRequired => task?.minPhotosRequired ?? 1;

  String get timeFormatted {
    return DateFormatter.formatTimeRange(startTime, endTime);
  }

  factory TaskAssignmentModel.fromJson(Map<String, dynamic> json) {
    return TaskAssignmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      scheduledDate: json['scheduled_date']?.toString() ?? '',
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'assigned',
      notes: json['notes']?.toString(),
      assignedAt: json['assigned_at']?.toString(),
      startedAt: json['started_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      task: json['task'] is Map<String, dynamic> ? TaskTemplateDetail.fromJson(json['task']) : null,
      location: json['location'] is Map<String, dynamic>
          ? FarmLocationDetail.fromJson(json['location'])
          : null,
      farmer: json['farmer'] is Map<String, dynamic> ? json['farmer'] : null,
      submission: json['submission'] is Map<String, dynamic>
          ? TaskSubmissionSummary.fromJson(json['submission'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'scheduled_date': scheduledDate,
    'start_time': startTime,
    'end_time': endTime,
    'priority': priority,
    'status': status,
    'notes': notes,
    'assigned_at': assignedAt,
    'started_at': startedAt,
    'completed_at': completedAt,
    'task': task?.toJson(),
    'location': location?.toJson(),
    'farmer': farmer,
  };
}

class TaskSubmissionSummary {
  final int id;
  final bool geofencePassed;
  final double? distanceMeters;
  final bool isLate;
  final String? submittedAt;
  final String? status;
  final String? verificationStatus;
  final List<String> photoUrls;

  const TaskSubmissionSummary({
    required this.id,
    this.geofencePassed = true,
    this.distanceMeters,
    this.isLate = false,
    this.submittedAt,
    this.status,
    this.verificationStatus,
    this.photoUrls = const [],
  });

  factory TaskSubmissionSummary.fromJson(Map<String, dynamic> json) {
    bool geoPassed = true;
    double? dist;
    if (json['geofence'] is Map) {
      final g = json['geofence'] as Map<String, dynamic>;
      geoPassed = g['passed'] == true;
      dist = (g['distance_meters'] as num?)?.toDouble();
    } else if (json['geofence_passed'] != null) {
      geoPassed = json['geofence_passed'] == true || json['geofence_passed'] == 1;
    }

    final bool late = json['is_late'] == true || json['is_late'] == 1;

    final List<String> photos = [];
    if (json['evidence_photos'] is List) {
      for (final p in json['evidence_photos'] as List) {
        if (p is Map && p['url'] != null) {
          photos.add(p['url'].toString());
        }
      }
    } else if (json['photos'] is List) {
      for (final p in json['photos'] as List) {
        if (p != null) photos.add(p.toString());
      }
    }

    return TaskSubmissionSummary(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      geofencePassed: geoPassed,
      distanceMeters: dist,
      isLate: late,
      submittedAt: json['submitted_at']?.toString(),
      status: json['status']?.toString(),
      verificationStatus: json['verification_status']?.toString(),
      photoUrls: photos,
    );
  }
}
