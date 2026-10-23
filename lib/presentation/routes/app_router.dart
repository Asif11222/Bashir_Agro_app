import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/local_storage_service.dart';
import '../../models/auth_model.dart';
import '../screens/login/login_screen.dart';
import '../screens/dashboard/farmer_dashboard_screen.dart';
import '../screens/task_details/task_details_screen.dart';
import '../screens/camera/live_camera_screen.dart';
import '../screens/photo_review/photo_review_screen.dart';
import '../screens/owner_dashboard/owner_dashboard_screen.dart';
import '../screens/farmers/farmers_list_screen.dart';
import '../screens/owner_tasks/owner_task_planning_screen.dart';
import '../screens/farmers/farmer_activity_screen.dart';
import '../screens/owner_photos/owner_photo_details_screen.dart';
import '../screens/profile/farmer_profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/farm_map/field_boundary_map_screen.dart';
import '../screens/owner_locations/owner_locations_list_screen.dart';
import '../screens/owner_locations/owner_location_map_screen.dart';
import '../screens/new_task/new_task_screen.dart';

String getInitialLocation() {
  final token = LocalStorageService.instance.getString(ApiConstants.tokenKey);
  if (token != null && token.isNotEmpty) {
    final userJson = LocalStorageService.instance.getJson(ApiConstants.userKey);
    if (userJson != null) {
      try {
        final user = AuthUser.fromJson(userJson as Map<String, dynamic>);
        return user.isOwner ? '/owner-dashboard' : '/dashboard';
      } catch (_) {}
    }
    return '/dashboard';
  }
  return '/login';
}

GoRouter createAppRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? getInitialLocation(),
    redirect: (context, state) {
      final token = LocalStorageService.instance.getString(ApiConstants.tokenKey);
      final isAuthenticated = token != null && token.isNotEmpty;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      if (isAuthenticated && isLoggingIn) {
        final userJson = LocalStorageService.instance.getJson(ApiConstants.userKey);
        if (userJson != null) {
          try {
            final user = AuthUser.fromJson(userJson as Map<String, dynamic>);
            return user.isOwner ? '/owner-dashboard' : '/dashboard';
          } catch (_) {}
        }
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Farmer Flow (Screens 1 to 5 + Phase 12B Profile, Notifications & Field Boundary)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const FarmerDashboardScreen(),
    ),
    GoRoute(
      path: '/task-details',
      builder: (context, state) => const TaskDetailsScreen(),
    ),
    GoRoute(
      path: '/field-boundary',
      builder: (context, state) => const FieldBoundaryMapScreen(),
    ),
    GoRoute(
      path: '/farm-map',
      builder: (context, state) => const FieldBoundaryMapScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const LiveCameraScreen(),
    ),
    GoRoute(
      path: '/photo-review',
      builder: (context, state) => const PhotoReviewScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const FarmerProfileScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/new-task',
      builder: (context, state) => const NewTaskScreen(),
    ),

    // Owner Flow (Screens 6 to 10 from Bashir_Agro_Flutter_Prototype_Specification.pdf)
    GoRoute(
      path: '/owner-dashboard',
      builder: (context, state) => const OwnerDashboardScreen(),
    ),
    GoRoute(
      path: '/farmers-list',
      builder: (context, state) => const FarmersListScreen(),
    ),
    GoRoute(
      path: '/owner-tasks',
      builder: (context, state) => const OwnerTaskPlanningScreen(),
    ),
    GoRoute(
      path: '/farmer-activity',
      builder: (context, state) => const FarmerActivityScreen(),
    ),
    GoRoute(
      path: '/owner-photo-details',
      builder: (context, state) => const OwnerPhotoDetailsScreen(),
    ),
    GoRoute(
      path: '/locations-list',
      builder: (context, state) => const OwnerLocationsListScreen(),
    ),
    GoRoute(
      path: '/owner-locations',
      builder: (context, state) => const OwnerLocationsListScreen(),
    ),
    GoRoute(
      path: '/location-map',
      builder: (context, state) => const OwnerLocationMapScreen(),
    ),
  ],
);
}

final appRouter = createAppRouter();


