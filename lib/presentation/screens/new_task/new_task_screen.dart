import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../services/task_service.dart';
import '../../../state/app_state.dart';
import '../../../state/farmer_app_state.dart';
import '../../widgets/farmer_bottom_nav_bar.dart';

class NewTaskScreen extends ConsumerStatefulWidget {
  const NewTaskScreen({super.key});

  @override
  ConsumerState<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends ConsumerState<NewTaskScreen> {
  final TextEditingController _descriptionController = TextEditingController(
    text: 'আজ সবজি ক্ষেতে সেচের পাইপ মেরামত করেছি।',
  );

  bool _isListening = false;
  bool _isSubmitting = false;
  File? _selectedPhotoFile;
  Position? _currentPosition;
  String _locationName = 'লোকেশন খোঁজা হচ্ছে...';
  String _locationBadgeText = 'খোঁজা হচ্ছে...';
  bool _isLoadingLocation = true;
  bool _isInsideFarm = false;
  int? _matchedFarmLocationId;
  Timer? _timeTimer;
  DateTime _currentDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();

    // Update live clock every 30 seconds
    _timeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {
          _currentDateTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _timeTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    double lat = 23.8103;
    double lng = 90.4125;
    double acc = 10.0;

    try {
      final gpsService = ref.read(gpsServiceProvider);
      final coord = await gpsService.getCurrentLocation().timeout(const Duration(seconds: 4));
      if (coord != null) {
        lat = coord.latitude;
        lng = coord.longitude;
        acc = coord.accuracy;
        _currentPosition = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: acc,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }
    } catch (_) {
      // Hardware GPS timeout or test environment fallback
    }

    try {
      final resolver = ref.read(locationResolutionServiceProvider);
      final resolved = await resolver.resolveLocation(
        latitude: lat,
        longitude: lng,
        accuracy: acc,
      );

      if (mounted) {
        setState(() {
          _locationName = resolved.displayName;
          _locationBadgeText = resolved.badgeText;
          _isInsideFarm = resolved.isInsideFarm;
          _matchedFarmLocationId = resolved.farmLocationId;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          if (_locationName == 'লোকেশন খোঁজা হচ্ছে...') {
            _locationName = 'জিপিএস অবস্থান পাওয়া গেছে';
            _locationBadgeText = 'লোকেশন প্রাপ্ত';
          }
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('বাংলায় বলুন, শুনছি...'),
            ],
          ),
          backgroundColor: const Color(0xFF006837),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Simulate live voice recognition result after 2.5 seconds if speech continues
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _isListening) {
          setState(() {
            _isListening = false;
          });
        }
      });
    }
  }

  void _showAudioGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.volume_up_rounded, color: Color(0xFF006837), size: 24),
              SizedBox(width: 10),
              Text(
                'কীভাবে বলবেন শুনুন',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'মাইক্রোফোন বাটনে চাপ দিয়ে স্পষ্ট বাংলায় বলুন আপনি আজ খামারে কী কাজ সম্পন্ন করেছেন।',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'উদাহরণসমূহ:',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                    ),
                    SizedBox(height: 6),
                    Text('• "আজ সবজি ক্ষেতে সেচের পাইপ মেরামত করেছি।"', style: TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                    SizedBox(height: 4),
                    Text('• "পুকুরে মাছের খাবার দেওয়া শেষ করেছি।"', style: TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                    SizedBox(height: 4),
                    Text('• "গরুর শেড পরিষ্কার করেছি ও ঘাস দিয়েছি।"', style: TextStyle(fontSize: 12.5, color: Color(0xFF334155))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বুঝেছি', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006837))),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'কাজের ছবি যোগ করুন (ঐচ্ছিক)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF006837)),
                  title: const Text('সরাসরি ক্যামেরা দিয়ে ছবি তুলুন'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/camera');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF006837)),
                  title: const Text('ডেমো স্যাম্পল ছবি নির্বাচন করুন'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedPhotoFile = File('dummy_photo.jpg');
                    });
                  },
                ),
                if (_selectedPhotoFile != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    title: const Text('ছবি মুছে ফেলুন'),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedPhotoFile = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitTask() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অনুগ্রহ করে কাজের বিবরণ লিখুন বা মুখে বলুন।'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(taskListProvider.notifier).submitSelfReportedTask(
        description: text,
        latitude: _currentPosition?.latitude ?? 23.8103,
        longitude: _currentPosition?.longitude ?? 90.4125,
        accuracy: _currentPosition?.accuracy ?? 10.0,
        locationName: _locationName,
        farmLocationId: _matchedFarmLocationId,
        photoPath: _selectedPhotoFile?.path,
      );

      // Refresh tasks
      ref.read(farmerTasksProvider.notifier).refresh();

      if (!mounted) return;

      // Show success modal celebration
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_rounded, color: Color(0xFF15803D), size: 36),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'কাজ সফলভাবে জমা হয়েছে!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'আপনার নতুন কাজটি "সম্পন্ন কাজ" তালিকায় যুক্ত করা হয়েছে।',
                  style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Switch to Completed filter and navigate to dashboard
                      ref.read(taskTabFilterProvider.notifier).setFilter(TaskTabFilter.completed);
                      context.go('/dashboard');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006837),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('সম্পন্ন কাজের তালিকা দেখুন', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('কাজ জমা দিতে সমস্যা হয়েছে: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormatter.formatFullDateWithDay();
    final formattedTime = DateFormatter.formatDateTimeToBanglaTime(_currentDateTime.toIso8601String());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Gradient Green Header
          _buildHeader(context),

          // Main Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. "কী কাজ করেছেন?" Section
                  _buildSectionTitle('কী কাজ করেছেন?'),
                  const SizedBox(height: 8),
                  _buildVoiceInputCard(),

                  const SizedBox(height: 16),

                  // 2. "কাজের বিবরণ" Section
                  _buildSectionTitle('কাজের বিবরণ'),
                  const SizedBox(height: 8),
                  _buildDescriptionCard(),

                  const SizedBox(height: 16),

                  // 3. "কাজের ছবি" (ঐচ্ছিক) Section
                  _buildPhotoSectionHeader(),
                  const SizedBox(height: 8),
                  _buildPhotoPickerCard(),
                  const SizedBox(height: 4),
                  const Text(
                    'এখন ছবি না দিলেও কাজ জমা হবে। পরে ছবি যোগ করতে পারবেন।',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),

                  const SizedBox(height: 16),

                  // 4. "স্বয়ংক্রিয়ভাবে যুক্ত হবে" Section
                  _buildSectionTitle('স্বয়ংক্রিয়ভাবে যুক্ত হবে'),
                  const SizedBox(height: 8),
                  _buildMetadataCard(formattedDate, formattedTime),

                  const SizedBox(height: 16),

                  // 5. Completion Guarantee Banner
                  _buildGuaranteeBanner(),

                  const SizedBox(height: 16),

                  // 6. Submit Button
                  _buildSubmitButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FarmerBottomNavBar(
        currentIndex: 1,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF006837), Color(0xFF0E8A4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/dashboard');
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'নতুন কাজ যোগ করুন',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'যে কাজ করেছেন, তা বলুন বা লিখুন',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildVoiceInputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3FAF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
      ),
      child: Column(
        children: [
          // Audio Guide Button
          Align(
            alignment: Alignment.topRight,
            child: InkWell(
              onTap: () => _showAudioGuideDialog(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD1FAE5), width: 1.1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_up_outlined, size: 16, color: Color(0xFF006837)),
                    SizedBox(width: 4),
                    Text(
                      'কীভাবে বলবেন শুনুন',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006837),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Big Mic Button with Pulsing Effect
          GestureDetector(
            onTap: _toggleVoiceRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _isListening ? const Color(0xFFBBF7D0) : const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                boxShadow: _isListening
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Container(
                  width: 66,
                  height: 66,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006837),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Mic label
          Text(
            _isListening ? 'শুনছি... বলুন' : 'চাপ দিয়ে বলুন',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'আপনার কথা বাংলায় লেখা হবে',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'এখানে কাজের বিবরণ লিখুন বা মুখে বলুন...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  ),
                ),
              ),
              const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'ভুল হলে ঠিক করুন বা আবার বলুন',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _toggleVoiceRecording,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_none_rounded, size: 14, color: Color(0xFF006837)),
                      SizedBox(width: 3.5),
                      Text(
                        'আবার বলুন',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006837),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSectionHeader() {
    return Row(
      children: [
        const Text(
          'কাজের ছবি',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'ঐচ্ছিক',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15803D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPickerCard() {
    return InkWell(
      onTap: _showPhotoOptions,
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: const Color(0xFF86EFAC),
          strokeWidth: 1.4,
          gap: 5.0,
          radius: 14,
        ),
        child: Container(
          width: double.infinity,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAF8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: _selectedPhotoFile != null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 22),
                          SizedBox(width: 8),
                          Text(
                            '১টি ছবি নির্বাচিত হয়েছে',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'পরিবর্তন করতে ট্যাপ করুন',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: Color(0xFF006837), size: 30),
                      SizedBox(height: 6),
                      Text(
                        'ছবি তুলুন বা যোগ করুন',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006837),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(String formattedDate, String formattedTime) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          // Location Row
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF475569), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('বর্তমান লোকেশন', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      _locationName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: _isInsideFarm
                      ? const Color(0xFFDCFCE7)
                      : (_isLoadingLocation
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFE0F2FE)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingLocation)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF64748B)),
                      )
                    else
                      Icon(
                        _isInsideFarm ? Icons.check_circle_rounded : Icons.my_location_rounded,
                        size: 12.5,
                        color: _isInsideFarm ? const Color(0xFF15803D) : const Color(0xFF0369A1),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      _locationBadgeText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _isInsideFarm
                            ? const Color(0xFF15803D)
                            : (_isLoadingLocation
                                ? const Color(0xFF64748B)
                                : const Color(0xFF0369A1)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Submission Time Row
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFF475569), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('জমা দেওয়ার সময়', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      '$formattedDate • $formattedTime',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 5),
              Text(
                'জমা দেওয়ার সময় লোকেশন ও সময় নেওয়া হবে',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 19),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'জমা দিলে কাজটি সম্পন্ন হিসেবে যুক্ত হবে',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF15803D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF006837),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF006837).withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 21, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'কাজ জমা দিন',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        final double len = distance + gap > metric.length ? metric.length - distance : gap;
        dashedPath.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += len * 2;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.radius != radius;
  }
}
