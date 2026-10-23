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
    this.landArea = 5.0,
    this.farmingCategories = const ['সবজি', 'ধান', 'মাছ', 'গরু'],
  });

  factory FarmerItemModel.fromJson(Map<String, dynamic> json) {
    // 1. Determine isAssigned from API boolean or integer, or fallback
    bool assigned = json['is_assigned'] == true || json['is_assigned'] == 1 || json['is_assigned'] == '1';

    final locations = json['locations'] as List<dynamic>?;
    if (!assigned && json['is_assigned'] == null) {
      if (locations != null && locations.isNotEmpty) {
        assigned = true;
      }
      final totalTasks = int.tryParse(json['total_tasks']?.toString() ?? '0') ?? 0;
      if (totalTasks > 0) {
        assigned = true;
      }
      final activeTasks = int.tryParse(json['active_tasks']?.toString() ?? '0') ?? 0;
      if (activeTasks > 0) {
        assigned = true;
      }
    }

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

    double landArea = (json['land_area'] is num) ? (json['land_area'] as num).toDouble() : 0.0;
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
      farmType: json['farm_type']?.toString() ?? json['primary_activity']?.toString() ?? 'কৃষি চাষ',
      progressPercent: json['progress_percent'] is int
          ? json['progress_percent']
          : int.tryParse(json['progress_percent']?.toString() ?? '0') ?? 0,
      isAssigned: assigned,
      avatarPath: json['profile_photo_url']?.toString() ?? '',
      landArea: landArea,
      farmingCategories: json['farming_categories'] is List
          ? (json['farming_categories'] as List).map((e) => e.toString()).toList()
          : const ['সবজি'],
    );
  }
}

class FarmerActivityItemModel {
  final String id;
  final String title;
  final String description;
  final String time;
  final String location;
  final String photoAsset;
  final bool isCompleted;
  final String status;
  final String statusText;
  final String? scheduledDate;

  const FarmerActivityItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.location,
    required this.photoAsset,
    this.isCompleted = true,
    this.status = 'completed',
    this.statusText = '✓ সম্পন্ন',
    this.scheduledDate,
  });

  factory FarmerActivityItemModel.fromJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final rawStatus = (json['status']?.toString() ?? 'assigned').toLowerCase().trim();
    final isCompleted = rawStatus == 'completed';

    final startTime = json['start_time']?.toString() ?? '';
    final date = json['scheduled_date']?.toString() ?? '';
    final timeStr = startTime.isNotEmpty ? '$date ($startTime)' : date;

    String statusText;
    switch (rawStatus) {
      case 'completed':
        statusText = '✓ সম্পন্ন';
        break;
      case 'in_progress':
        statusText = 'চলমান';
        break;
      case 'submitted':
        statusText = 'রিভিউ অপেক্ষায়';
        break;
      case 'late':
        statusText = 'দেরি হয়েছে';
        break;
      case 'assigned':
      case 'pending':
      default:
        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        if (date.isNotEmpty && date.compareTo(todayStr) < 0) {
          statusText = 'বাকি আছে';
        } else if (date.isNotEmpty && date.compareTo(todayStr) > 0) {
          statusText = 'আসন্ন';
        } else {
          statusText = 'বাকি আছে';
        }
        break;
    }

    return FarmerActivityItemModel(
      id: json['id']?.toString() ?? '',
      title: task?['name']?.toString() ?? 'মাঠ কাজ',
      description: json['notes']?.toString() ?? task?['instructions']?.toString() ?? 'কাজের বিবরণ সম্পন্ন হয়েছে।',
      time: timeStr,
      location: location?['name']?.toString() ?? 'মাঠ',
      photoAsset: 'assets/images/vegetable_field.jpg',
      isCompleted: isCompleted,
      status: rawStatus,
      statusText: statusText,
      scheduledDate: date.isNotEmpty ? date : null,
    );
  }
}

class OwnerTaskPlanModel {
  final String id;
  final String title;
  final String timeRange;
  final String farmerName;
  final String location;
  final String statusText; // নির্ধারিত, চলমান, বাকি
  final String photoAsset;

  final String? scheduledDate;

  const OwnerTaskPlanModel({
    required this.id,
    required this.title,
    required this.timeRange,
    required this.farmerName,
    required this.location,
    required this.statusText,
    required this.photoAsset,
    this.scheduledDate,
  });

  factory OwnerTaskPlanModel.fromJson(Map<String, dynamic> json) {
    final task = json['task'] as Map<String, dynamic>?;
    final farmer = json['farmer'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;

    final startTime = json['start_time']?.toString() ?? '';
    final endTime = json['end_time']?.toString() ?? '';
    final timeRange = (startTime.isNotEmpty && endTime.isNotEmpty)
        ? '$startTime – $endTime'
        : (startTime.isNotEmpty ? startTime : 'সকাল ৮:০০ – বিকাল ৫:০০');

    final status = json['status']?.toString() ?? 'assigned';
    String statusText;
    switch (status) {
      case 'completed':
        statusText = 'সম্পন্ন';
        break;
      case 'in_progress':
        statusText = 'চলমান';
        break;
      case 'late':
        statusText = 'বাকি';
        break;
      default:
        statusText = 'নির্ধারিত';
    }

    return OwnerTaskPlanModel(
      id: json['id']?.toString() ?? '',
      title: task?['name']?.toString() ?? 'কৃষি কাজ',
      timeRange: timeRange,
      farmerName: '${farmer?['full_name'] ?? 'চাষী'} (চাষী)',
      location: location?['name']?.toString() ?? 'খামার মাঠ',
      statusText: statusText,
      photoAsset: 'assets/images/vegetable_field.jpg',
      scheduledDate: json['scheduled_date']?.toString(),
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
          : int.tryParse(json['new_farmers_this_month']?.toString() ?? '0') ?? 0,
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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
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
          : int.tryParse(json['geofence_radius_meters']?.toString() ?? '20') ?? 20,
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
