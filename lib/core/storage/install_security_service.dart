import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/api_constants.dart';
import 'local_storage_service.dart';

/// Service that verifies app installation integrity and prevents restored
/// cloud backup data (e.g. from Android Auto Backup) from resurrecting previous
/// sessions on a fresh install after an app uninstallation.
class InstallSecurityService {
  static InstallSecurityService? _instance;
  static bool testMode = false;
  File? _customMarkerFileForTest;

  InstallSecurityService._();

  static InstallSecurityService get instance {
    _instance ??= InstallSecurityService._();
    return _instance!;
  }

  @visibleForTesting
  void setCustomMarkerFileForTest(File? file) {
    _customMarkerFileForTest = file;
  }

  /// Verifies that the app is running on an active, existing installation.
  /// If a fresh install is detected with restored backup data (e.g., from Android Auto Backup),
  /// the stale cache and session are purged to guarantee a clean first run.
  /// Returns `true` if this was an existing install, or `false` if it was a fresh install.
  Future<bool> verifyInstallation({LocalStorageService? storage}) async {
    if (testMode) return true;

    final localStorage = storage ?? LocalStorageService.instance;

    try {
      final markerFile = _customMarkerFileForTest ?? await _getInstallMarkerFile();
      if (markerFile == null) {
        // In environments without filesystem access (e.g. web or mocked unit tests)
        return true;
      }

      final markerExists = await markerFile.exists();

      if (!markerExists) {
        // Marker file does NOT exist -> Fresh app install or reinstall!
        final existingToken = localStorage.getString(ApiConstants.tokenKey);
        final existingUser = localStorage.getString(ApiConstants.userKey);

        if ((existingToken != null && existingToken.isNotEmpty) || existingUser != null) {
          debugPrint(
            '[InstallSecurity] Fresh install detected with restored cloud backup cache. Purging stale session.',
          );
          await localStorage.clearAll();
        }

        // Write marker file for future launches
        await _createInstallMarker(markerFile);
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[InstallSecurity] Error verifying installation marker: $e');
      return true;
    }
  }

  Future<File?> _getInstallMarkerFile() async {
    try {
      if (kIsWeb) return null;

      if (Platform.isAndroid) {
        // On Android, use the official no_backup directory which is NEVER backed up by Auto Backup
        final supportDir = await getApplicationSupportDirectory();
        final noBackupDir = Directory('${supportDir.parent.path}/no_backup');
        if (!await noBackupDir.exists()) {
          try {
            await noBackupDir.create(recursive: true);
          } catch (_) {}
        }
        if (await noBackupDir.exists()) {
          return File('${noBackupDir.path}/.bashir_agro_install_marker');
        }
      }

      final supportDir = await getApplicationSupportDirectory();
      return File('${supportDir.path}/.bashir_agro_install_marker');
    } catch (_) {
      return null;
    }
  }

  Future<void> _createInstallMarker(File markerFile) async {
    try {
      final parent = markerFile.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
      final payload = {
        'installed_at': DateTime.now().toIso8601String(),
        'install_id': '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}',
      };
      await markerFile.writeAsString(jsonEncode(payload));
    } catch (e) {
      debugPrint('[InstallSecurity] Failed to write install marker: $e');
    }
  }
}
