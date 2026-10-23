import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/owner_models.dart';
import '../../../models/task_assignment_model.dart';
import '../../../state/owner_state.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import '../../widgets/owner_farm_header.dart';

/// Only shows an actual server assignment. Never supplies demo GPS/photo/status data.
class OwnerPhotoDetailsScreen extends ConsumerWidget {
  final int assignmentId;

  const OwnerPhotoDetailsScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = assignmentId > 0
        ? ref.watch(ownerAssignmentDetailsProvider(assignmentId))
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Column(
        children: [
          OwnerFarmHeaderBackground(
            height: OwnerFarmHeaderBackground.standardHeight,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/owner-tasks'),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('কাজের বিস্তারিত',
                            style: TextStyle(color: Colors.white,
                              fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('প্রমাণ, সময় ও অবস্থান যাচাই',
                            style: TextStyle(color: Color(0xFFE8F5E9), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: detail == null
                ? const Center(child: Text('কাজের সঠিক পরিচিতি পাওয়া যায়নি।'))
                : detail.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                    error: (_, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('সার্ভার থেকে কাজের তথ্য পাওয়া যায়নি।'),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => ref.invalidate(ownerAssignmentDetailsProvider(assignmentId)),
                              child: const Text('আবার চেষ্টা করুন'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (assignment) => RefreshIndicator(
                      color: AppColors.primaryGreen,
                      onRefresh: () async {
                        ref.invalidate(ownerAssignmentDetailsProvider(assignmentId));
                        try {
                          await ref.read(ownerAssignmentDetailsProvider(assignmentId).future);
                        } catch (_) {}
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: _buildDetails(assignment),
                      ),
                    ),
                  ),
          ),
          const OwnerBottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  List<Widget> _buildDetails(TaskAssignmentModel assignment) {
    final submission = assignment.submission;
    final status = OwnerWorkStatus.label(assignment.status);
    final check = submission == null || !assignment.isCompleted
        ? null
        : OwnerWorkStatus.verificationLabel(submission.geofencePassed, submission.isLate);
    final photos = submission?.photoUrls ?? const <String>[];

    return [
      _section(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(assignment.displayTitle,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                _badge(status, assignment.isCompleted),
              ],
            ),
            const SizedBox(height: 8),
            Text(assignment.task?.category ?? '',
              style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            _line(Icons.person_outline, assignment.farmer?['full_name']?.toString() ?? 'কৃষক নেই'),
            _line(Icons.location_on_outlined, assignment.location?.name ?? 'লোকেশন নেই'),
            _line(Icons.event_outlined,
              '${assignment.scheduledDate} • ${assignment.timeFormatted}'),
            if (assignment.notes != null && assignment.notes!.isNotEmpty)
              _line(Icons.notes_rounded, assignment.notes!),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _section(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('কাজের যাচাই',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (submission == null)
              const Text('এখনও কোনো জমা বা যাচাইয়ের তথ্য পাওয়া যায়নি।',
                style: TextStyle(color: Color(0xFF64748B)))
            else ...[
              if (check != null) _badge(check, check == 'সব ঠিক'),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (submission.geofencePassed != null)
                  _badge(submission.geofencePassed! ? 'সঠিক লোকেশনে' : 'লোকেশনের বাইরে',
                      submission.geofencePassed!),
                if (submission.isLate != null)
                  _badge(submission.isLate! ? 'সময় পেরিয়েছে' : 'সময়ের মধ্যে',
                      !submission.isLate!),
                if (submission.verificationStatus != null)
                  _badge(_verificationText(submission.verificationStatus!),
                      submission.verificationStatus == 'verified'),
              ]),
              if (submission.submittedAt != null) ...[
                const SizedBox(height: 10),
                _line(Icons.check_circle_outline,
                    'জমা: ${DateFormatter.formatDateTimeToBanglaTime(submission.submittedAt)}'),
              ],
              if (submission.latitude != null && submission.longitude != null)
                _line(Icons.gps_fixed,
                    '${submission.latitude}, ${submission.longitude}'),
              if (submission.distanceMeters != null)
                _line(Icons.social_distance,
                    'দূরত্ব: ${submission.distanceMeters!.toStringAsFixed(1)} মিটার'),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      _section(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('জমা দেওয়া ছবি (${DateFormatter.toBanglaDigits(photos.length.toString())}টি)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (photos.isEmpty)
              const Text('কোনো ছবি জমা দেওয়া হয়নি।',
                  style: TextStyle(color: Color(0xFF64748B)))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: photos.length,
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(photos[index], fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFFE2E8F0),
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey))),
                ),
              ),
          ],
        ),
      ),
    ];
  }

  String _verificationText(String value) => switch (value) {
    'verified' => 'যাচাইকৃত',
    'pending' => 'যাচাই অপেক্ষমাণ',
    'flagged' => 'যাচাইয়ে সতর্কতা',
    'rejected' => 'যাচাই বাতিল',
    _ => value,
  };

  Widget _section(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: child,
  );

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(children: [
      Icon(icon, size: 17, color: AppColors.primaryGreen),
      const SizedBox(width: 8),
      Expanded(child: Text(text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
    ]),
  );

  Widget _badge(String label, bool positive) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: positive ? const Color(0xFFDCFCE7) : const Color(0xFFFFF1DF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label, style: TextStyle(
      color: positive ? const Color(0xFF15803D) : const Color(0xFF9A4B07),
      fontSize: 11, fontWeight: FontWeight.w700)),
  );
}
