import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/owner_models.dart';
import '../models/task_assignment_model.dart';
import 'farmer_app_state.dart';

// Dashboard State Model
class OwnerDashboardState {
  final bool isLoading;
  final OwnerDashboardKpis kpis;
  final List<FarmerItemModel> farmers;
  final List<OwnerLocationItem> locations;
  final String? errorMessage;
  final DateTime selectedDate;
  final OwnerLocationItem? selectedLocation;

  const OwnerDashboardState({
    this.isLoading = false,
    this.kpis = const OwnerDashboardKpis(),
    this.farmers = const [],
    this.locations = const [],
    this.errorMessage,
    required this.selectedDate,
    this.selectedLocation,
  });

  OwnerDashboardState copyWith({
    bool? isLoading,
    OwnerDashboardKpis? kpis,
    List<FarmerItemModel>? farmers,
    List<OwnerLocationItem>? locations,
    String? errorMessage,
    DateTime? selectedDate,
    OwnerLocationItem? selectedLocation,
    bool clearLocation = false,
  }) {
    return OwnerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      kpis: kpis ?? this.kpis,
      farmers: farmers ?? this.farmers,
      locations: locations ?? this.locations,
      errorMessage: errorMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedLocation: clearLocation ? null : (selectedLocation ?? this.selectedLocation),
    );
  }
}

class OwnerDashboardNotifier extends Notifier<OwnerDashboardState> {
  int _loadVersion = 0;
  @override
  OwnerDashboardState build() {
    final now = DateTime.now();
    Future.microtask(() => loadDashboard());
    return OwnerDashboardState(selectedDate: now, isLoading: true);
  }

  Future<void> loadDashboard({DateTime? date, OwnerLocationItem? location, bool clearLocation = false}) async {
    final version = ++_loadVersion;
    final targetDate = date ?? state.selectedDate;
    final targetLoc = clearLocation ? null : (location ?? state.selectedLocation);

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedDate: targetDate,
      selectedLocation: targetLoc,
      clearLocation: clearLocation,
    );

    try {
      final apiService = ref.read(apiServiceProvider);
      final dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
      final data = await apiService.getOwnerDashboard(
        date: dateStr,
        locationId: targetLoc?.id,
      );

      final kpisJson = data['kpis'] as Map<String, dynamic>? ?? {};
      final farmersList = (data['farmers'] as List<dynamic>? ?? [])
          .map((e) => FarmerItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final locationsList = (data['locations'] as List<dynamic>? ?? [])
          .map((e) => OwnerLocationItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (version != _loadVersion) return;
      state = state.copyWith(
        isLoading: false,
        kpis: OwnerDashboardKpis.fromJson(kpisJson),
        farmers: farmersList,
        locations: locationsList,
      );
    } catch (e) {
      if (version != _loadVersion) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final ownerDashboardProvider =
    NotifierProvider<OwnerDashboardNotifier, OwnerDashboardState>(OwnerDashboardNotifier.new);

// Selected farmer ID for farmer activity details
class SelectedFarmerIdNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setFarmerId(String id) => state = id;
}

final selectedFarmerIdProvider =
    NotifierProvider<SelectedFarmerIdNotifier, String>(SelectedFarmerIdNotifier.new);

// Search query for Farmers List screen
class FarmerSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

final farmerSearchQueryProvider =
    NotifierProvider<FarmerSearchQueryNotifier, String>(FarmerSearchQueryNotifier.new);

// Filter status for Farmers List screen (all, assigned, unassigned)
enum FarmerFilterStatus { all, assigned, unassigned }

class FarmerFilterStatusNotifier extends Notifier<FarmerFilterStatus> {
  @override
  FarmerFilterStatus build() => FarmerFilterStatus.all;

  void setFilter(FarmerFilterStatus filter) => state = filter;
}

final farmerFilterStatusProvider =
    NotifierProvider<FarmerFilterStatusNotifier, FarmerFilterStatus>(
        FarmerFilterStatusNotifier.new);

// Sort order for Farmers List
enum FarmerSortOrder { newest, oldest, name }

class FarmerSortOrderNotifier extends Notifier<FarmerSortOrder> {
  @override
  FarmerSortOrder build() => FarmerSortOrder.newest;

  void setSort(FarmerSortOrder sort) => state = sort;
}

final farmerSortOrderProvider =
    NotifierProvider<FarmerSortOrderNotifier, FarmerSortOrder>(
        FarmerSortOrderNotifier.new);

class OwnerFarmersSyncErrorNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void setError(bool error) => state = error;
}

final ownerFarmersSyncErrorProvider =
    NotifierProvider<OwnerFarmersSyncErrorNotifier, bool>(OwnerFarmersSyncErrorNotifier.new);

// Real Farmers List Notifier from API
class OwnerFarmersListNotifier extends Notifier<List<FarmerItemModel>> {
  int _loadVersion = 0;

  @override
  List<FarmerItemModel> build() {
    // Recalculate when the dashboard's selected date changes.
    ref.watch(ownerDashboardProvider.select((dashboard) => dashboard.selectedDate));
    Future.microtask(() => loadFarmers());
    return [];
  }

  Future<void> loadFarmers({String? search, String? status}) async {
    final version = ++_loadVersion;
    try {
      final apiService = ref.read(apiServiceProvider);
      final selectedDate = ref.read(ownerDashboardProvider).selectedDate;
      final dateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final list = await apiService.getFarmersList(search: search, status: status, date: dateStr);
      if (version != _loadVersion) return;
      state = list.map((e) => FarmerItemModel.fromJson(e)).toList();
      ref.read(ownerFarmersSyncErrorProvider.notifier).setError(false);
    } catch (_) {
      if (version != _loadVersion) return;
      ref.read(ownerFarmersSyncErrorProvider.notifier).setError(true);
      final dashFarmers = ref.read(ownerDashboardProvider).farmers;
      if (dashFarmers.isNotEmpty) {
        state = dashFarmers;
      }
    }
  }
}

final ownerFarmersListProvider =
    NotifierProvider<OwnerFarmersListNotifier, List<FarmerItemModel>>(OwnerFarmersListNotifier.new);

// Filtered and sorted farmers list
final filteredFarmersProvider = Provider<List<FarmerItemModel>>((ref) {
  final query = ref.watch(farmerSearchQueryProvider).toLowerCase().trim();
  final filter = ref.watch(farmerFilterStatusProvider);
  final sort = ref.watch(farmerSortOrderProvider);

  var list = ref.watch(ownerFarmersListProvider);
  if (list.isEmpty) {
    list = ref.watch(ownerDashboardProvider).farmers;
  }

  var result = List<FarmerItemModel>.from(list);

  // Filter by assignment
  if (filter == FarmerFilterStatus.assigned) {
    result = result.where((f) => f.isAssigned).toList();
  } else if (filter == FarmerFilterStatus.unassigned) {
    result = result.where((f) => !f.isAssigned).toList();
  }

  // Filter by query
  if (query.isNotEmpty) {
    result = result.where((f) {
      return f.name.toLowerCase().contains(query) ||
          f.phone.contains(query) ||
          f.region.toLowerCase().contains(query) ||
          f.farmType.toLowerCase().contains(query);
    }).toList();
  }

  // Sort
  if (sort == FarmerSortOrder.oldest) {
    result = result.reversed.toList();
  } else if (sort == FarmerSortOrder.name) {
    result.sort((a, b) => a.name.compareTo(b.name));
  }

  return result;
});

// Currently selected farmer
final currentSelectedFarmerProvider = Provider<FarmerItemModel?>((ref) {
  final id = ref.watch(selectedFarmerIdProvider);
  final allFarmers = ref.watch(ownerFarmersListProvider);
  final fallbackFarmers = ref.watch(ownerDashboardProvider).farmers;
  final pool = allFarmers.isNotEmpty ? allFarmers : fallbackFarmers;

  if (pool.isEmpty || id.isEmpty) return null;

  try {
    return pool.firstWhere((f) => f.id == id);
  } catch (_) {
    return null;
  }
});

// Activity filter for Farmer Activity Timeline (আজকের, ৭ দিন, ৩০ দিন)
class ActivityFilterTimeNotifier extends Notifier<String> {
  @override
  String build() => 'আজকের';

  void setFilter(String val) => state = val;
}

final activityFilterTimeProvider =
    NotifierProvider<ActivityFilterTimeNotifier, String>(ActivityFilterTimeNotifier.new);

// Owner Task Planning Time Filter (আজ, ১ সপ্তাহ, ১ মাস)
enum OwnerTaskTimeFilter {
  today,
  oneWeek,
  oneMonth;

  String get label {
    switch (this) {
      case OwnerTaskTimeFilter.today:
        return 'আজ';
      case OwnerTaskTimeFilter.oneWeek:
        return '১ সপ্তাহ';
      case OwnerTaskTimeFilter.oneMonth:
        return '১ মাস';
    }
  }
}

class OwnerTaskTimeFilterNotifier extends Notifier<OwnerTaskTimeFilter> {
  @override
  OwnerTaskTimeFilter build() => OwnerTaskTimeFilter.today;

  void setFilter(OwnerTaskTimeFilter filter) => state = filter;
}

final ownerTaskTimeFilterProvider =
    NotifierProvider<OwnerTaskTimeFilterNotifier, OwnerTaskTimeFilter>(
        OwnerTaskTimeFilterNotifier.new);

// Planned tasks provider (Real assignments from API)
class OwnerTaskLoadInfo {
  final bool loading;
  final String? error;
  const OwnerTaskLoadInfo({this.loading = false, this.error});
}

class OwnerTaskLoadInfoNotifier extends Notifier<OwnerTaskLoadInfo> {
  @override
  OwnerTaskLoadInfo build() => const OwnerTaskLoadInfo();
  void update({bool loading = false, String? error}) =>
      state = OwnerTaskLoadInfo(loading: loading, error: error);
}

final ownerTaskLoadInfoProvider =
    NotifierProvider<OwnerTaskLoadInfoNotifier, OwnerTaskLoadInfo>(OwnerTaskLoadInfoNotifier.new);

class OwnerPlannedTasksNotifier extends Notifier<List<OwnerTaskPlanModel>> {
  int _loadVersion = 0;
  @override
  List<OwnerTaskPlanModel> build() => [];

  Future<void> loadTasks({
    DateTime? date,
    OwnerTaskTimeFilter? filter,
  }) async {
    final version = ++_loadVersion;
    ref.read(ownerTaskLoadInfoProvider.notifier).update(loading: true);
    state = [];
    try {
      final OwnerTaskTimeFilter activeFilter =
          filter ?? ref.read(ownerTaskTimeFilterProvider);
      final apiService = ref.read(apiServiceProvider);
      final targetDate = date ?? DateTime.now();

      String? dateStr;
      String? startDate;
      String? endDate;

      switch (activeFilter) {
        case OwnerTaskTimeFilter.today:
          dateStr = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
          break;
        case OwnerTaskTimeFilter.oneWeek:
          final startOfWeek = targetDate.subtract(Duration(days: targetDate.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          startDate = '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
          endDate = '${endOfWeek.year}-${endOfWeek.month.toString().padLeft(2, '0')}-${endOfWeek.day.toString().padLeft(2, '0')}';
          break;
        case OwnerTaskTimeFilter.oneMonth:
          final startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
          final endOfMonth = DateTime(targetDate.year, targetDate.month + 1, 0);
          startDate = '${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-${startOfMonth.day.toString().padLeft(2, '0')}';
          endDate = '${endOfMonth.year}-${endOfMonth.month.toString().padLeft(2, '0')}-${endOfMonth.day.toString().padLeft(2, '0')}';
          break;
      }

      final raw = await apiService.getRawAssignments(
        date: dateStr,
        startDate: startDate,
        endDate: endDate,
      );
      if (version != _loadVersion) return;
      state = raw.map((e) => OwnerTaskPlanModel.fromJson(e)).toList();
      ref.read(ownerTaskLoadInfoProvider.notifier).update();
    } catch (_) {
      if (version != _loadVersion) return;
      state = [];
      ref.read(ownerTaskLoadInfoProvider.notifier).update(
        error: 'সার্ভারের সর্বশেষ কাজের অবস্থা পাওয়া যায়নি। আবার চেষ্টা করুন।',
      );
    }
  }

  void addTask(OwnerTaskPlanModel task) {
    state = [...state, task];
  }
}

final ownerPlannedTasksProvider =
    NotifierProvider<OwnerPlannedTasksNotifier, List<OwnerTaskPlanModel>>(
        OwnerPlannedTasksNotifier.new);

final ownerAssignmentDetailsProvider = FutureProvider.autoDispose.family<TaskAssignmentModel, int>((ref, assignmentId) async {
  return ref.read(apiServiceProvider).getAssignmentDetails(assignmentId);
});

// Real Farmer activities provider from API assignments
final farmerActivitiesProvider = FutureProvider.autoDispose.family<List<FarmerActivityItemModel>, String>((ref, farmerId) async {
  final id = int.tryParse(farmerId);
  if (id == null || id <= 0) return [];
  final raw = await ref.read(apiServiceProvider).getRawAssignments(farmerId: id);
  return raw.map((e) => FarmerActivityItemModel.fromJson(e)).toList();
});

// Owner Bottom Navigation Index (0: ড্যাশবোর্ড, 1: কাজসমূহ, 2: কৃষকরা, 3: লোকেশন, 4: সেটিংস)
class OwnerNavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final ownerNavIndexProvider =
    NotifierProvider<OwnerNavIndexNotifier, int>(OwnerNavIndexNotifier.new);

// ==========================================
// Farm Locations Management (From Admin Panel)
// ==========================================

class OwnerLocationsListNotifier extends AsyncNotifier<List<OwnerLocationItem>> {
  @override
  Future<List<OwnerLocationItem>> build() async {
    return _fetchLocations();
  }

  Future<List<OwnerLocationItem>> _fetchLocations() async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final list = await apiService.getFarmLocations();
      return list;
    } catch (_) {
      // Return empty list on network error gracefully
      return [];
    }
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchLocations());
  }
}

final ownerLocationsListProvider =
    AsyncNotifierProvider<OwnerLocationsListNotifier, List<OwnerLocationItem>>(
        OwnerLocationsListNotifier.new);

// Search Query for Locations Screen
class LocationSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final locationSearchQueryProvider =
    NotifierProvider<LocationSearchQueryNotifier, String>(
        LocationSearchQueryNotifier.new);

// Filtered Locations List based on Search Query
final filteredOwnerLocationsProvider = Provider<List<OwnerLocationItem>>((ref) {
  final asyncLocations = ref.watch(ownerLocationsListProvider);
  final query = ref.watch(locationSearchQueryProvider).trim().toLowerCase();

  final locations = asyncLocations.value ?? [];
  if (query.isEmpty) return locations;

  return locations.where((loc) {
    return loc.name.toLowerCase().contains(query) ||
        loc.locationCode.toLowerCase().contains(query) ||
        loc.type.toLowerCase().contains(query) ||
        loc.address.toLowerCase().contains(query);
  }).toList();
});

// Currently Selected Location for Map View
class SelectedLocationForMapNotifier extends Notifier<OwnerLocationItem?> {
  @override
  OwnerLocationItem? build() => null;

  void setLocation(OwnerLocationItem? loc) => state = loc;
}

final selectedLocationForMapProvider =
    NotifierProvider<SelectedLocationForMapNotifier, OwnerLocationItem?>(
        SelectedLocationForMapNotifier.new);
