import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../state/app_state.dart';
import '../../widgets/farm_graphics.dart';

import '../../../state/farmer_app_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(farmerAuthProvider);
      if (auth.isAuthenticated && auth.user != null && mounted) {
        if (auth.user?.isOwner == true) {
          context.go('/owner-dashboard');
        } else {
          context.go('/dashboard');
        }
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _normalizeDigits(String input) {
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var result = input;
    for (var i = 0; i < bn.length; i++) {
      result = result.replaceAll(bn[i], en[i]);
    }
    return result;
  }

  Future<void> _handleLogin() async {
    final phone = _normalizeDigits(_phoneController.text.trim());
    final password = _normalizeDigits(_passwordController.text.trim());

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('মোবাইল নাম্বার এবং পাসওয়ার্ড লিখুন'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Try Laravel API Sanctum login
    final success = await ref.read(farmerAuthProvider.notifier).login(phone, password);
    setState(() => _isLoading = false);

    if (success) {
      final authState = ref.read(farmerAuthProvider);
      if (authState.user != null) {
        ref.read(currentUserProvider.notifier).setUser(
          UserModel(
            id: authState.user!.id.toString(),
            name: authState.profile?.fullName ?? authState.user!.name,
            phone: authState.user!.phone.isNotEmpty ? authState.user!.phone : phone,
            password: password,
            role: authState.user!.isOwner ? UserRole.owner : UserRole.farmer,
          ),
        );
      }
      ref.read(taskListProvider.notifier).refresh();
      if (mounted) {
        if (authState.user?.isOwner == true) {
          context.go('/owner-dashboard');
        } else {
          context.go('/dashboard');
        }
      }
      return;
    }

    if (mounted) {
      var errorMsg = ref.read(farmerAuthProvider).errorMessage ?? 'ভুল মোবাইল নাম্বার বা পাসওয়ার্ড!';
      errorMsg = errorMsg.replaceAll(RegExp(r'^ApiException:\s*\d+\s*-\s*'), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Farm Landscape (Top 55%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.54,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Farmland background image with fallback
                Image.asset(
                  'assets/images/vegetable_field.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF64B5F6),
                                Color(0xFF90CAF9),
                                Color(0xFF81C784),
                                Color(0xFF2E7D32),
                              ],
                              stops: [0.0, 0.35, 0.6, 1.0],
                            ),
                          ),
                        ),
                        CustomPaint(
                          painter: _FarmLandscapePainter(),
                        ),
                      ],
                    );
                  },
                ),
                // Subtle darkening overlay for readability
                Container(
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                // Header Content: Logo + Bangla Title
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        const SproutLogoBadge(size: 96),
                        const SizedBox(height: 14),
                        const Text(
                          'আমাদের খামার',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'কৃষকের জন্য সহজ ও বিশ্বস্ত সহায়ক',
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom White Sheet with Inputs & Login Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.50,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phone input
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.phone_android_rounded,
                          color: Color(0xFF64748B),
                        ),
                        hintText: 'মোবাইল নাম্বার',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password input
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF64748B),
                        ),
                        hintText: 'পাসওয়ার্ড',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF64748B),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login CTA button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'লগইন',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Forgot password link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('পাসওয়ার্ড রিসেট করতে অনুগ্রহ করে খামার সুপারভাইজার বা অ্যাডমিনের সাথে যোগাযোগ করুন।'),
                            ),
                          );
                        },
                        child: const Text(
                          'পাসওয়ার্ড ভুলে গেছেন?',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLinkBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final horizonPaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..style = PaintingStyle.fill;

    // Distant trees/hills
    final path = Path()
      ..moveTo(0, size.height * 0.48)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.44, size.width * 0.5, size.height * 0.47)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.50, size.width, size.height * 0.46)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, horizonPaint);

    // Green row crop ridges
    final ridgePaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 9; i++) {
      final startX = size.width * (0.35 + i * 0.04);
      final endX = size.width * (0.1 + i * 0.1);
      canvas.drawLine(
        Offset(startX, size.height * 0.52),
        Offset(endX, size.height),
        ridgePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
