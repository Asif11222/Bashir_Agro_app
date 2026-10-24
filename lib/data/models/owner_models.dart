import '../../core/utils/task_thumbnail_resolver.dart';
import '../../models/field_boundary_model.dart';
import '../../core/utils/date_formatter.dart';

class FarmerItemModel {
  final String id;
  final String name;
  final String phone;
  final String region;
  final String farmType;
  final int progressPercent;
  final bool isAssigned; // নিয়োজিত or অনিয়োজিত
  final String avatarPath;
  final double landArea; // e.g. 5.0 acres
  final List<String> farmingCategories; // e.g. ['সবজি', 'ধান', 'মাছ', 'গরু']

  const FarmerItemModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.region,
    required this.farmType,
    required this.progressPercent,
    required this.isAssigned,
    this.avatarPath = '',
    this.landArea = 0.0,
    this.farmingCategories = const [],
  });

  factory FarmerItemModel.fromJson(Map<String, dynamic> json) {
    final total = int.tryParse(json['total_tasks']?.toString() ?? '0') ?? 0;
    final completed = int.tryParse(json['completed_tasks']?.toString() ?? '0') ?? 0;
    final active = int.tryParse(json['active_tasks']?.toString() ?? '0') ?? 0;

    final assignmentFlag = json['is_assigned'];
    final bool assigned = assignmentFlag == true ||
        assignmentFlag == 1 ||
        assignmentFlag == '1' ||
        assignmentFlag == 'true' ||
        (assignmentFlag == null &&
            (active > 0 || (total > 0 && total > completed)));

    final locations = json['locations'] as List<dynamic>?;
    String region = json['region']?.toString() ?? '';
    if (region.isEmpty && locations != null && locations.isNotEmpty) {
      final firstLoc = locations.first;
      if (firstLoc is Map<String, dynamic>) {
        region = firstLoc['name']?.toString() ?? '';
      }
    }
    if (region.isEmpty) {
      region = json['address']?.toString() ?? 'বাংলাদেশ';
    }

    double landArea = (json['land_area'] is num)
        ? (json['land_area'] as num).toDouble()
        : 0.0;
    if (landArea <= 0.0 && locations != null && locations.isNotEmpty) {
      for (final loc in locations) {
        if (loc is Map<String, dynamic>) {
          final area = loc['area'];
          if (area is num) {
            landArea += area.toDouble();
          }
        }
      }
    }
    if (landArea <= 0.0) {
      landArea = 4.0;
    }

    return FarmerItemModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      region: region,
      farmType:
          json['farm_type']?.toString() ??
          json['primary_activity']?.toString() ??
          'কৃষি চাষ',
      progressPercent: json['progress_percent'] is int
          ? json['progress_percent']
          : int.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0,
      isAssigned: assigned,
      avatarPath: json['profile_photo_url']?.toString() ?? '',
      landArea: (json['land_area'] is num)
          ? (json['land_area'] as num).toDouble()
          : 0.0,
      farmingCategories: json['farming_categories'] is List
          ? (json['farming_categories'] as List)
                .map((e) => e.toString())
                .toList()
          : const [],
    );
  }

  FarmerItemModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? region,
    String? farmType,
    int? progressPercent,
    bool? isAssigned,
    String? avatarPath,
    double? landArea,
    List<String>? farmingCategories,
  }) {
    return FarmerItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      farmType: farmType ?? this.farmType,
      progressPercent: progressPercent ?? this.progressPercent,
      isAssigned: isAssigned ?? this.isAssigned,
      avatarPath: avatarPath ?? this.avatarPath,
      landArea: landArea ?? this.landArea,
      farmingCategories: farmingCategories ?? this.farmingCategories,
    );
  }
}

class OwnerWorkStatus {
  static String label(String status) {
    switch (status) {
      case 'completed':
        return 'সম্পন্ন';
      case 'in_progress':
        return 'চলমান';
      case 'cancelled':
        return 'বাতিল';
      case 'late':
        return 'দেরি';
      case 'assigned':
      case 'pending':
        return 'নির্ধারিত';
      default:
        return 'অজানা';
    }
  }

  static String? verificationLabel(bool? geofencePassed, bool? isLate) {
    if (geofencePassed == null || isLate == null) return null;
    if (!geofencePassed && isLate) return 'সময় ও লোকেশনে সমস্যা';
    if (!geofencePassed) return 'লোকেশনে সমস্যা';
    if (isLate) return 'সময়ে সমস্যা';
    return 'সব ঠিক';
  }
}

class FarmerActivityItemModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final String location;
  final String scheduledDate;
  final String statusText;
  final String? submittedAt;
  final bool? geofencePassed;
  final bool? isLate;
  final List<String> photoUrls;
  final String thumbnailType;

  const FarmerActivityItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.location,
    this.scheduledDate = '',
    this.statusText = 'নির্ধারিত',
    this.submittedAt,
    this.geofencePassed,
    this.isLate,
    this.photoUrls = const [],
    this.thumbnailType = 'vegetable',
  });

  bool get isCompleted => statusText == 'সম্পন্ন';

  factory FarmerActivityItemModel.fromJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final submission = json['submission'] as Map<String, dynamic>?;
    final geofence = submission?['geofence'] as Map<String, dynamic>?;
    final evidence = submission?['evidence_photos'] as List<dynamic>? ?? [];
    final startTime = json['start_time']?.toString() ?? '';
    final date = json['scheduled_date']?.toString() ?? '';
    return FarmerActivityItemModel(
      id: json['id']?.toString() ?? '',
      title: task?['name']?.toString() ?? 'কৃষি কাজ',
      description:
          json['notes']?.toString() ?? task?['instructions']?.toString() ?? '',
      time: startTime.isEmpty ? date : '$date ($startTime)',
      scheduledDate: date,
      location: location?['name']?.toString() ?? 'লোকেশন নেই',
      statusText: OwnerWorkStatus.label(json['status']?.toString() ?? ''),
      submittedAt: submission?['submitted_at']?.toString(),
      geofencePassed: geofence?['passed'] is bool
          ? geofence!['passed'] as bool
          : null,
      isLate: submission?['is_late'] is bool
          ? submission!['is_late'] as bool
          : null,
      thumbnailType: TaskThumbnailResolver.resolve(
        category: task?['category']?.toString(),
        name: task?['name']?.toString(),
      ),
      photoUrls: evidence
          .whereType<Map<String, dynamic>>()
          .map((photo) => photo['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }
}

class OwnerTaskPlanModel {
  final String id;
  final String title;
  final String timeRange;
  final String farmerName;
  final String location;
  final String statusText;
  final String? scheduledDate;
  final String? submittedAt;
  final bool isPastDeadline;
  final bool hasSubmission;
  final bool? geofencePassed;
  final bool? isLate;
  final List<String> photoUrls;
  final String thumbnailType;

  bool get isCompleted => statusText == 'সম্পন্ন';

  String? get completionIssueLabel => isCompleted && hasSubmission
      ? OwnerWorkStatus.verificationLabel(geofencePassed, isLate)
      : null;

  const OwnerTaskPlanModel({
    required this.id,
    required this.title,
    required this.timeRange,
    required this.farmerName,
    required this.location,
    required this.statusText,
    this.scheduledDate,
    this.submittedAt,
    this.isPastDeadline = false,
    this.hasSubmission = false,
    this.geofencePassed,
    this.isLate,
    this.photoUrls = const [],
    this.thumbnailType = 'vegetable',
  });

  factory OwnerTaskPlanModel.fromJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>?;
    final farmer = json['farmer'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final submission = json['submission'] as Map<String, dynamic>?;
    final geofence = submission?['geofence'] as Map<String, dynamic>?;
    final evidence = submission?['evidence_photos'] as List<dynamic>? ?? [];

    final startTime = json['start_time']?.toString() ?? '';
    final endTime = json['end_time']?.toString() ?? '';
    final timeRange = startTime.isNotEmpty && endTime.isNotEmpty
        ? '$startTime – $endTime'
        : (startTime.isNotEmpty ? startTime : 'সময় নির্ধারিত নেই');

    return OwnerTaskPlanModel(
      id: json['id']?.toString() ?? '',
      title: task?['name']?.toString() ?? 'কৃষি কাজ',
      timeRange: timeRange,
      farmerName: farmer?['full_name']?.toString() ?? 'কৃষক নেই',
      location: location?['name']?.toString() ?? 'লোকেশন নেই',
      statusText: OwnerWorkStatus.label(json['status']?.toString() ?? ''),
      scheduledDate: json['scheduled_date']?.toString(),
      submittedAt: submission?['submitted_at']?.toString(),
      isPastDeadline: json['is_past_deadline'] == true,
      hasSubmission: submission != null,
      geofencePassed: geofence?['passed'] is bool
          ? geofence!['passed'] as bool
          : null,
      isLate: submission?['is_late'] is bool
          ? submission!['is_late'] as bool
          : null,
      thumbnailType: TaskThumbnailResolver.resolve(
        category: task?['category']?.toString(),
        name: task?['name']?.toString(),
      ),
      photoUrls: evidence
          .whereType<Map<String, dynamic>>()
          .map((photo) => photo['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }
}

class OwnerDashboardKpis {
  final int totalFarmers;
  final int newFarmersThisMonth;
  final int todayTasks;
  final int completedTasks;
  final int pendingTasks;
  final int completionPercent;

  const OwnerDashboardKpis({
    this.totalFarmers = 0,
    this.newFarmersThisMonth = 0,
    this.todayTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.completionPercent = 0,
  });

  factory OwnerDashboardKpis.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardKpis(
      totalFarmers: json['total_farmers'] is int
          ? json['total_farmers']
          : int.tryParse(json['total_farmers']?.toString() ?? '0') ?? 0,
      newFarmersThisMonth: json['new_farmers_this_month'] is int
          ? json['new_farmers_this_month']
          : int.tryParse(json['new_farmers_this_month']?.toString() ?? '0') ??
                0,
      todayTasks: json['today_tasks'] is int
          ? json['today_tasks']
          : int.tryParse(json['today_tasks']?.toString() ?? '0') ?? 0,
      completedTasks: json['completed_tasks'] is int
          ? json['completed_tasks']
          : int.tryParse(json['completed_tasks']?.toString() ?? '0') ?? 0,
      pendingTasks: json['pending_tasks'] is int
          ? json['pending_tasks']
          : int.tryParse(json['pending_tasks']?.toString() ?? '0') ?? 0,
      completionPercent: json['completion_percent'] is int
          ? json['completion_percent']
          : int.tryParse(json['completion_percent']?.toString() ?? '0') ?? 0,
    );
  }
}

class OwnerLocationItem {
  final int id;
  final String name;
  final String locationCode;
  final String type;
  final String address;
  final double? area;
  final String areaUnit;
  final double? latitude;
  final double? longitude;
  final dynamic boundary;
  final int geofenceRadiusMeters;
  final String status;
  final int farmersCount;
  final int tasksCount;

  const OwnerLocationItem({
    required this.id,
    required this.name,
    this.locationCode = 'LOC-001',
    this.type = 'খামার জমি',
    this.address = 'বাংলাদেশ',
    this.area,
    this.areaUnit = 'একর',
    this.latitude,
    this.longitude,
    this.boundary,
    this.geofenceRadiusMeters = 20,
    this.status = 'active',
    this.farmersCount = 0,
    this.tasksCount = 0,
  });

  factory OwnerLocationItem.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final lat = coords != null
        ? double.tryParse(coords['latitude']?.toString() ?? '')
        : double.tryParse(json['latitude']?.toString() ?? '');
    final lng = coords != null
        ? double.tryParse(coords['longitude']?.toString() ?? '')
        : double.tryParse(json['longitude']?.toString() ?? '');

    return OwnerLocationItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      locationCode: json['location_code']?.toString() ?? 'LOC-${json['id']}',
      type: json['type']?.toString() ?? 'খামার জমি',
      address: json['address']?.toString() ?? 'কৃষি অঞ্চল',
      area: (json['area'] is num)
          ? (json['area'] as num).toDouble()
          : double.tryParse(json['area']?.toString() ?? ''),
      areaUnit: json['area_unit']?.toString() ?? 'একর',
      latitude: lat,
      longitude: lng,
      boundary: json['boundary'] ?? json['boundary_geojson'],
      geofenceRadiusMeters: json['geofence_radius_meters'] is int
          ? json['geofence_radius_meters']
          : int.tryParse(json['geofence_radius_meters']?.toString() ?? '20') ??
                20,
      status: json['status']?.toString() ?? 'active',
      farmersCount: json['farmers_count'] is int
          ? json['farmers_count']
          : int.tryParse(json['farmers_count']?.toString() ?? '0') ?? 0,
      tasksCount: json['tasks_count'] is int
          ? json['tasks_count']
          : int.tryParse(json['tasks_count']?.toString() ?? '0') ?? 0,
    );
  }

  /// Builds a FieldBoundaryModel from the location's GeoJSON boundary,
  /// falling back to generating a circular polygon from centroid and geofence radius.
  FieldBoundaryModel get fieldBoundary {
    if (boundary != null) {
      final b = FieldBoundaryModel.fromGeoJson(boundary);
      if (b.isNotEmpty) return b;
    }
    final lat = latitude ?? 24.7471;
    final lng = longitude ?? 90.4203;
    return FieldBoundaryModel.fromCenterAndRadius(
      lat,
      lng,
      geofenceRadiusMeters > 0 ? geofenceRadiusMeters.toDouble() : 30.0,
    );
  }

  String get formattedArea {
    if (area != null) {
      final val = area! % 1 == 0 ? area!.toInt().toString() : area!.toString();
      return '${DateFormatter.toBanglaDigits(val)} $areaUnit';
    }
    return 'অনির্ধারিত';
  }
}
