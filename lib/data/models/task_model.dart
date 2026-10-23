import 'task_photo_model.dart';
import '../../models/field_boundary_model.dart';

enum TaskStatus {
  scheduled,
  inProgress,
  submitted,
  completed,
  rejected,
}

enum CompletedSubmissionType {
  allGood, // ১. সময়ের মধ্যে এবং জোনের ভেতরে
  lateOnly, // ২. সময় পার হয়ে গেছে এবং জোনের ভেতরে
  outsideZoneOnly, // ৩. সময়ের মধ্যে কিন্তু জোনের বাইরে
  bothIssues, // ৪. সময় পার হয়ে গেছে এবং জোনের বাইরে
}

class TaskModel {
  final String id;
  final String title;
  final String subTitle;
  final String ownerId;
  final String ownerName;
  final String farmName;
  final String locationId;
  final String locationName;
  final String fullAddress;
  final double? latitude;
  final double? longitude;
  final FieldBoundaryModel? fieldBoundary;
  final int geofenceRadiusMeters;
  final String timeRange;
  final String date;
  final String description;
  final String instructions;
  final int minPhotos;
  final int maxPhotos;
  final TaskStatus status;
  final String badgeText;
  final String thumbnailType; // 'vegetable', 'fish', 'cow', 'fertilizer'
  final String bannerImageUrl;
  final bool isLate;
  final List<TaskPhotoModel> photos;
  final String? startedAt;
  final String? completedAt;
  final bool? geofencePassed;
  final double? distanceMeters;
  final String? submittedAt; // e.g. "সকাল ৯:১৫"
  final List<String> evidencePhotoUrls;

  const TaskModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.ownerId,
    required this.ownerName,
    required this.farmName,
    required this.locationId,
    required this.locationName,
    required this.fullAddress,
    this.latitude,
    this.longitude,
    this.fieldBoundary,
    this.geofenceRadiusMeters = 100,
    required this.timeRange,
    required this.date,
    required this.description,
    required this.instructions,
    this.minPhotos = 1,
    this.maxPhotos = 5,
    this.status = TaskStatus.scheduled,
    required this.badgeText,
    required this.thumbnailType,
    this.bannerImageUrl = '',
    this.isLate = false,
    this.photos = const [],
    this.startedAt,
    this.completedAt,
    this.geofencePassed,
    this.distanceMeters,
    this.submittedAt,
    this.evidencePhotoUrls = const [],
  });

  CompletedSubmissionType get completedSubmissionType {
    final bool geoPassed = geofencePassed ?? true;
    final bool late = isLate;
    if (!late && geoPassed) return CompletedSubmissionType.allGood;
    if (late && geoPassed) return CompletedSubmissionType.lateOnly;
    if (!late && !geoPassed) return CompletedSubmissionType.outsideZoneOnly;
    return CompletedSubmissionType.bothIssues;
  }

  String get cropCategory => subTitle;

  TaskModel copyWith({
    String? id,
    String? title,
    String? subTitle,
    String? ownerId,
    String? ownerName,
    String? farmName,
    String? locationId,
    String? locationName,
    String? fullAddress,
    double? latitude,
    double? longitude,
    FieldBoundaryModel? fieldBoundary,
    int? geofenceRadiusMeters,
    String? timeRange,
    String? date,
    String? description,
    String? instructions,
    int? minPhotos,
    int? maxPhotos,
    TaskStatus? status,
    String? badgeText,
    String? thumbnailType,
    String? bannerImageUrl,
    bool? isLate,
    List<TaskPhotoModel>? photos,
    String? startedAt,
    String? completedAt,
    bool? geofencePassed,
    double? distanceMeters,
    String? submittedAt,
    List<String>? evidencePhotoUrls,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subTitle: subTitle ?? this.subTitle,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      farmName: farmName ?? this.farmName,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      fullAddress: fullAddress ?? this.fullAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      fieldBoundary: fieldBoundary ?? this.fieldBoundary,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      timeRange: timeRange ?? this.timeRange,
      date: date ?? this.date,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      minPhotos: minPhotos ?? this.minPhotos,
      maxPhotos: maxPhotos ?? this.maxPhotos,
      status: status ?? this.status,
      badgeText: badgeText ?? this.badgeText,
      thumbnailType: thumbnailType ?? this.thumbnailType,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      isLate: isLate ?? this.isLate,
      photos: photos ?? this.photos,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      geofencePassed: geofencePassed ?? this.geofencePassed,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      submittedAt: submittedAt ?? this.submittedAt,
      evidencePhotoUrls: evidencePhotoUrls ?? this.evidencePhotoUrls,
    );
  }
}

