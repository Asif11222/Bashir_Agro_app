import '../models/user_model.dart';
import '../models/farm_location_model.dart';
import '../models/task_model.dart';

class MockData {
  static final List<UserModel> demoUsers = [
    const UserModel(
      id: 'farmer_1',
      name: 'আব্দুল রহমান',
      phone: '01700000001',
      password: '123456',
      role: UserRole.farmer,
    ),
    const UserModel(
      id: 'owner_1',
      name: 'মোঃ আরিফ হোসেন',
      phone: '01700000002',
      password: '123456',
      role: UserRole.owner,
    ),
  ];

  static final List<FarmLocationModel> demoLocations = [
    const FarmLocationModel(
      id: 'LOC001',
      ownerId: 'owner_1',
      propertyId: 'PROP01',
      name: 'দক্ষিণ মাঠ, ২ নং ব্লক',
      type: 'Vegetable Field',
      address: 'দক্ষিণ পাড়া, ২ নং ব্লক, শ্যামনগর',
      polygonPoints: [
        GeoPoint(23.7808, 90.4152),
        GeoPoint(23.7815, 90.4160),
        GeoPoint(23.7800, 90.4168),
        GeoPoint(23.7795, 90.4155),
      ],
      toleranceMeters: 20.0,
    ),
    const FarmLocationModel(
      id: 'LOC002',
      ownerId: 'owner_1',
      propertyId: 'PROP01',
      name: 'পশ্চিম পুকুর, বাড়ির পাশে',
      type: 'Fish Pond',
      address: 'পশ্চিম পুকুর, বাড়ির পাশে, সাভার',
      polygonPoints: [
        GeoPoint(23.7900, 90.4200),
        GeoPoint(23.7910, 90.4210),
        GeoPoint(23.7905, 90.4220),
        GeoPoint(23.7895, 90.4210),
      ],
      toleranceMeters: 20.0,
    ),
    const FarmLocationModel(
      id: 'LOC003',
      ownerId: 'owner_1',
      propertyId: 'PROP01',
      name: 'গোয়ালঘর, উত্তর পাশ',
      type: 'Cow Shed',
      address: 'গোয়ালঘর, উত্তর পাশ, সাভার',
      polygonPoints: [
        GeoPoint(23.7750, 90.4100),
        GeoPoint(23.7760, 90.4110),
        GeoPoint(23.7755, 90.4120),
        GeoPoint(23.7745, 90.4110),
      ],
      toleranceMeters: 20.0,
    ),
  ];

  static final List<TaskModel> initialTasks = [
    const TaskModel(
      id: 'TASK_101',
      title: 'সবজি ক্ষেত পরিদর্শন',
      subTitle: 'লাউ ক্ষেত',
      ownerId: 'owner_1',
      ownerName: 'আব্দুল করিম',
      farmName: 'করিম এগ্রো ফার্ম',
      locationId: 'LOC001',
      locationName: 'দক্ষিণ মাঠ, ২ নং ব্লক',
      fullAddress: 'দক্ষিণ পাড়া, ২ নং ব্লক, শ্যামনগর',
      timeRange: 'সকাল ৮:০০ - ১০:০০',
      date: '১২ জুন ২০২৪',
      description: 'ক্ষেতের বর্তমান অবস্থা যাচাই করতে রিয়েল-টাইম ছবি তুলে পাঠাতে হবে।',
      instructions:
          'ক্ষেতে গিয়ে ফসলের বর্তমান অবস্থা, পোকামাকড় বা কোনো সমস্যা আছে কিনা — তা পরিষ্কারভাবে রিয়েল-টাইম ছবি তুলে পাঠান।',
      minPhotos: 1,
      maxPhotos: 5,
      status: TaskStatus.scheduled,
      badgeText: 'আজ করব',
      thumbnailType: 'vegetable',
    ),
    const TaskModel(
      id: 'TASK_102',
      title: 'মাছের খাবার দেওয়া',
      subTitle: 'পুকুর নং ১',
      ownerId: 'owner_1',
      ownerName: 'আব্দুল করিম',
      farmName: 'করিম এগ্রো ফার্ম',
      locationId: 'LOC002',
      locationName: 'পশ্চিম পুকুর, বাড়ির পাশে',
      fullAddress: 'পশ্চিম পাড়া, ১ নং পুকুর, শ্যামনগর',
      timeRange: 'দুপুর ১২:০০ - ১২:৩০',
      date: '১২ জুন ২০২৪',
      description: 'মাছের সুষম খাদ্য নির্ধারিত পরিমাণে পানিতে প্রয়োগ নিশ্চিত করুন।',
      instructions:
          'পুকুর পাড়ে গিয়ে খাদ্য দেওয়ার সময় মাছের চঞ্চলতা ও খাওয়ার স্পষ্ট ছবি তুলে পাঠান।',
      minPhotos: 1,
      maxPhotos: 3,
      status: TaskStatus.inProgress,
      badgeText: 'চলছে',
      thumbnailType: 'fish',
    ),
    const TaskModel(
      id: 'TASK_103',
      title: 'গরুকে খাবার দেওয়া',
      subTitle: 'দেশি গরু (৩টি)',
      ownerId: 'owner_1',
      ownerName: 'আব্দুল করিম',
      farmName: 'করিম এগ্রো ফার্ম',
      locationId: 'LOC003',
      locationName: 'গোয়ালঘর, উত্তর পাশ',
      fullAddress: 'গোয়ালঘর সংলগ্ন চত্বর, শ্যামনগর',
      timeRange: 'বিকাল ৪:০০ - ৫:০০',
      date: '১২ জুন ২০২৪',
      description: 'গরুদের প্রয়োজনীয় সুষম খাদ্য ও পরিচ্ছন্ন পানি সরবরাহ করুন।',
      instructions:
          'গোয়ালঘরের পরিচ্ছন্নতা এবং পাত্রে খাদ্য প্রদানের সময় স্পষ্ট ছবি তুলে পাঠান।',
      minPhotos: 1,
      maxPhotos: 3,
      status: TaskStatus.scheduled,
      badgeText: 'বাকি আছে',
      thumbnailType: 'cow',
    ),
  ];
}
