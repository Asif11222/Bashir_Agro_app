import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_router.dart';
import 'state/app_appearance.dart';
import 'state/farmer_app_state.dart';
import 'state/owner_state.dart';

import 'core/storage/local_storage_service.dart';
import 'core/storage/install_security_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.instance.init();
  await InstallSecurityService.instance.verifyInstallation();
  runApp(
    const ProviderScope(
      child: BashirAgroApp(),
    ),
  );
}


class BashirAgroApp extends ConsumerStatefulWidget {
  const BashirAgroApp({super.key});

  @override
  ConsumerState<BashirAgroApp> createState() => _BashirAgroAppState();
}

class _BashirAgroAppState extends ConsumerState<BashirAgroApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(appAppearanceProvider);
      ref.invalidate(ownerFarmersListProvider);
      ref.read(farmerAuthProvider.notifier).refreshIdentity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'আমাদের খামার - Bashir Agro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
