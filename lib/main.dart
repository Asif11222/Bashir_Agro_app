import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_router.dart';

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


class BashirAgroApp extends StatelessWidget {
  const BashirAgroApp({super.key});

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
