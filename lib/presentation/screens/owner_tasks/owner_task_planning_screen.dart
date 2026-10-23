import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/owner_models.dart';
import '../../../state/owner_state.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import '../../widgets/owner_farm_header.dart';

class OwnerTaskPlanningScreen extends ConsumerStatefulWidget {
  const OwnerTaskPlanningScreen({super.key});

  @override
  ConsumerState<OwnerTaskPlanningScreen> createState() => _OwnerTaskPlanningScreenState();
}

class _OwnerTaskPlanningScreenState extends ConsumerState<OwnerTaskPlanningScreen>
    with WidgetsBindingObserver {
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      final filter = ref.read(ownerTaskTimeFilterProvider);
      ref.read(ownerPlannedTasksProvider.notifier).loadTasks(
            date: _currentDate,
            filter: filter,
          );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(ownerPlannedTasksProvider.notifier).loadTasks(
        date: _currentDate,
        filter: ref.read(ownerTaskTimeFilterProvider),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _currentDate) {
      setState(() {
        _currentDate = picked;
      });
      final filter = ref.read(ownerTaskTimeFilterProvider);
      ref.read(ownerPlannedTasksProvider.notifier).loadTasks(
            date: _currentDate,
            filter: filter,
          );
    }
  }

  void _previousDateRange() {
    final filter = ref.read(ownerTaskTimeFilterProvider);
    setState(() {
      switch (filter) {
        case OwnerTaskTimeFilter.today:
          _currentDate = _currentDate.subtract(const Duration(days: 1));
          break;
        case OwnerTaskTimeFilter.oneWeek:
          _currentDate = _currentDate.subtract(const Duration(days: 7));
          break;
        case OwnerTaskTimeFilter.oneMonth:
          _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, _currentDate.day);
          break;
      }
    });
    ref.read(ownerPlannedTasksProvider.notifier).loadTasks(
          date: _currentDate,
          filter: filter,
        );
  }

  void _nextDateRange() {
    final filter = ref.read(ownerTaskTimeFilterProvider);
    setState(() {
      switch (filter) {
        case OwnerTaskTimeFilter.today:
          _currentDate = _currentDate.add(const Duration(days: 1));
          break;
        case OwnerTaskTimeFilter.oneWeek:
          _currentDate = _currentDate.add(const Duration(days: 7));
          break;
        case OwnerTaskTimeFilter.oneMonth:
          _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, _currentDate.day);
          break;
      }
    });
    ref.read(ownerPlannedTasksProvider.notifier).loadTasks(
          date: _currentDate,
          filter: filter,
        );
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(ownerTaskTimeFilterProvider);
    final tasks = ref.watch(ownerPlannedTasksProvider);
    final loadInfo = ref.watch(ownerTaskLoadInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Column(
        children: [
          // 1. Lush Green Curved Header
          _buildHeader(context),

          // 2. Main Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(ownerPlannedTasksProvider.notifier).loadTasks(
                      date: _currentDate,
                      filter: selectedFilter,
                    );
              },
              color: AppColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    // Filter Bar: আজ | ১ সপ্তাহ | ১ মাস
                    _buildFilterTabs(selectedFilter),
                    const SizedBox(height: 12),

                    // Date / Range Picker Card
                    _buildDatePickerBar(context, selectedFilter),
                    const SizedBox(height: 12),

                    // Total Tasks Summary Banner
                    if (!loadInfo.loading && loadInfo.error == null)
                      _buildTotalTasksBanner(tasks.length, selectedFilter),
                    const SizedBox(height: 14),

                    if (loadInfo.loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(color: AppColors.primaryGreen),
                      )
                    else if (loadInfo.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(loadInfo.error!,
                          style: const TextStyle(color: AppColors.errorRed)),
                      ),
                    // Task Cards List or Empty State
                    if (!loadInfo.loading && loadInfo.error == null && tasks.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8ECE8)),
                        ),
                        child: Center(
                          child: Text(
                            selectedFilter == OwnerTaskTimeFilter.today
                                ? 'এই তারিখে কোনো কাজের পরিকল্পনা নেই।'
                                : (selectedFilter == OwnerTaskTimeFilter.oneWeek
                                    ? 'এই সপ্তাহে কোনো কাজের পরিকল্পনা নেই।'
                                    : 'এই মাসে কোনো কাজের পরিকল্পনা নেই।'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    else if (!loadInfo.loading && loadInfo.error == null)
                      ...tasks.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTaskPlanCard(
                              context,
                              task,
                              showDateBadge: selectedFilter != OwnerTaskTimeFilter.today,
                            ),
                          )),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Navigation Bar (Tab 1: কাজসমূহ active)
          const OwnerBottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(OwnerTaskTimeFilter selectedFilter) {
    const filters = OwnerTaskTimeFilter.values;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1E9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (filter != selectedFilter) {
                  ref.read(ownerTaskTimeFilterProvider.notifier).setFilter(filter);
                  ref.read(ownerPlannedTasksProvider.notifier).loadTasks(
                        date: _currentDate,
                        filter: filter,
                      );
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.22),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return OwnerFarmPageHeader(
      screenKey: 'owner_tasks',
      title: 'আজকের কাজের পরিকল্পনা',
      subtitle: 'খামারের সব কাজ এক নজরে',
      onBack: () => context.go('/owner-dashboard'),
      actionIcon: Icons.calendar_month_rounded,
      onAction: () => _pickDate(context),
    );
  }

  Widget _buildDatePickerBar(BuildContext context, OwnerTaskTimeFilter filter) {
    String dateLabel;
    switch (filter) {
      case OwnerTaskTimeFilter.today:
        dateLabel = DateFormatter.formatFullDateWithDay(date: _currentDate);
        break;
      case OwnerTaskTimeFilter.oneWeek:
        final startOfWeek = _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final startDay = DateFormatter.toBanglaDigits(startOfWeek.day);
        final startMonth = DateFormatter.banglaShortMonths[startOfWeek.month];
        final endDay = DateFormatter.toBanglaDigits(endOfWeek.day);
        final endMonth = DateFormatter.banglaShortMonths[endOfWeek.month];
        final endYear = DateFormatter.toBanglaDigits(endOfWeek.year);
        dateLabel = '$startDay $startMonth – $endDay $endMonth $endYear';
        break;
      case OwnerTaskTimeFilter.oneMonth:
        final monthName = DateFormatter.banglaMonths[_currentDate.month];
        final yearBn = DateFormatter.toBanglaDigits(_currentDate.year);
        dateLabel = '$monthName $yearBn';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EBE5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _previousDateRange,
            icon: const Icon(Icons.chevron_left_rounded, size: 26, color: Color(0xFF475569)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          InkWell(
            onTap: () => _pickDate(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 17, color: Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _nextDateRange,
            icon: const Icon(Icons.chevron_right_rounded, size: 26, color: Color(0xFF475569)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalTasksBanner(int count, OwnerTaskTimeFilter filter) {
    final now = DateTime.now();
    final isToday = _currentDate.year == now.year &&
        _currentDate.month == now.month &&
        _currentDate.day == now.day;

    String titleText;
    final countBn = DateFormatter.toBanglaDigits(count.toString());

    switch (filter) {
      case OwnerTaskTimeFilter.today:
        titleText = isToday
            ? 'আজ মোট কাজ $countBnটি'
            : 'নির্ধারিত মোট কাজ $countBnটি';
        break;
      case OwnerTaskTimeFilter.oneWeek:
        titleText = 'এই সপ্তাহে মোট কাজ $countBnটি';
        break;
      case OwnerTaskTimeFilter.oneMonth:
        titleText = 'এই মাসে মোট কাজ $countBnটি';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1EED8)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFC8E6C9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'সময়মতো সম্পন্ন করুন',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskPlanCard(
    BuildContext context,
    OwnerTaskPlanModel task, {
    bool showDateBadge = false,
  }) {
    return InkWell(
      onTap: () => context.push('/owner-photo-details/${task.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECE8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 82,
                    height: 82,
                    child: task.photoUrls.isNotEmpty
                        ? Image.network(
                            task.photoUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
                          )
                        : Container(
                            color: const Color(0xFFE9F5ED),
                            child: const Icon(Icons.grass_rounded, color: AppColors.primaryGreen, size: 32),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Task Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusPill(task.statusText),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Time Range & Optional Date Badge
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              task.timeRange,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showDateBadge && task.scheduledDate != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFC8E6C9)),
                              ),
                              child: Text(
                                DateFormatter.formatShortDate(task.scheduledDate),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Farmer Name
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              task.farmerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              task.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
            if (task.isPastDeadline && !task.isCompleted && task.statusText != 'বাতিল')
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildVerificationBadge('সময়সীমা পেরিয়েছে', false),
                ),
              ),
            if (task.isCompleted && task.hasSubmission) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                  if (task.completionIssueLabel != null)
                    _buildVerificationBadge(
                      task.completionIssueLabel!,
                      task.geofencePassed != false && task.isLate != true,
                    ),
                  if (task.geofencePassed != null)
                    _buildVerificationBadge(
                      task.geofencePassed! ? 'সঠিক লোকেশনে' : 'লোকেশনের বাইরে',
                      task.geofencePassed!,
                    ),
                  if (task.isLate != null)
                    _buildVerificationBadge(
                      task.isLate! ? 'সময় পেরিয়েছে' : 'সময়ের মধ্যে',
                      !task.isLate!,
                    ),
                  if (task.submittedAt != null)
                    _buildVerificationBadge('জমা: ${DateFormatter.formatDateTimeToBanglaTime(task.submittedAt)}', true),
                  _buildVerificationBadge('${DateFormatter.toBanglaDigits(task.photoUrls.length.toString())}টি ছবি', true),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(String label, bool positive) {
    final critical = label == 'লোকেশনের বাইরে' || label == 'সময় পেরিয়েছে' || label == 'সময়সীমা পেরিয়েছে';
    final bg = positive ? const Color(0xFFDCFCE7)
        : (critical ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));
    final fg = positive ? const Color(0xFF15803D)
        : (critical ? const Color(0xFFB91C1C) : const Color(0xFFB45309));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.check_circle_rounded : Icons.error_rounded, size: 12, color: fg),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    Color border;

    if (status == 'নির্ধারিত' || status == 'সম্পন্ন') {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
      border = const Color(0xFFC8E6C9);
    } else if (status == 'বাতিল' || status == 'দেরি') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
      border = const Color(0xFFFECACA);
    } else if (status == 'চলমান') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
      border = const Color(0xFFFDE68A);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
      border = const Color(0xFFE2E8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
