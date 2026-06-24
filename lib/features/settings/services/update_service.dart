import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

sealed class UpdateState {
  const UpdateState();
}

final class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

final class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

final class UpdateAvailable extends UpdateState {
  const UpdateAvailable({required this.version, required this.downloadUrl});
  final String version;
  final String downloadUrl;
}

final class UpdateDownloading extends UpdateState {
  const UpdateDownloading({required this.progress});
  final double progress;
}

final class UpdateError extends UpdateState {
  const UpdateError(this.message, {this.retryDownload});
  final String message;
  // Non-null when the error came from a download — carries the version and
  // URL so retry() can re-attempt the download without a fresh API check.
  final ({String version, String downloadUrl})? retryDownload;
}

enum UpdateInstallResult { success, permissionDenied }

class UpdateService {
  UpdateService._();
  static final instance = UpdateService._();

  static const _apiUrl =
      'https://api.github.com/repos/OneDeveloperCoding/latitude-tracker/releases/latest';

  final state = ValueNotifier<UpdateState>(const UpdateIdle());

  Future<void> checkForUpdate() async {
    if (state.value is UpdateChecking ||
        state.value is UpdateDownloading ||
        state.value is UpdateAvailable) {
      return;
    }
    state.value = const UpdateChecking();

    try {
      final info = await PackageInfo.fromPlatform();
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      );

      if (response.statusCode != 200) {
        state.value = UpdateError('HTTP ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = data['tag_name'] as String;
      final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;

      if (!_isNewer(latestVersion, info.version)) {
        state.value = const UpdateIdle();
        return;
      }

      final assets = (data['assets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final apkAsset = assets.firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => {},
      );

      if (apkAsset.isEmpty) {
        state.value = const UpdateError('No APK found in latest release');
        return;
      }

      final downloadUrl = apkAsset['browser_download_url'] as String?;
      if (downloadUrl == null) {
        state.value = const UpdateError(
          'No APK download URL in latest release',
        );
        return;
      }

      state.value = UpdateAvailable(
        version: latestVersion,
        downloadUrl: downloadUrl,
      );
    } on Object catch (e, st) {
      logError(e, st);
      state.value = UpdateError(e.toString());
    }
  }

  Future<UpdateInstallResult> downloadAndInstall() async {
    final s = state.value;
    if (s is! UpdateAvailable) return UpdateInstallResult.success;
    return _doDownloadAndInstall(s.version, s.downloadUrl);
  }

  Future<UpdateInstallResult> retry() async {
    final s = state.value;
    if (s is UpdateError && s.retryDownload != null) {
      final r = s.retryDownload!;
      return _doDownloadAndInstall(r.version, r.downloadUrl);
    }
    await checkForUpdate();
    return UpdateInstallResult.success;
  }

  Future<UpdateInstallResult> _doDownloadAndInstall(
    String version,
    String downloadUrl,
  ) async {
    state.value = const UpdateDownloading(progress: 0);

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/latitude_tracker_$version.apk';

      final client = http.Client();
      try {
        final response = await client.send(
          http.Request('GET', Uri.parse(downloadUrl)),
        );
        final total = response.contentLength ?? 0;
        var received = 0;

        final sink = File(filePath).openWrite();
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            received += chunk.length;
            if (total > 0) {
              state.value = UpdateDownloading(progress: received / total);
            }
          }
        } finally {
          await sink.close();
        }
      } finally {
        client.close();
      }

      final result = await OpenFile.open(filePath);
      if (result.type == ResultType.permissionDenied) {
        state.value =
            UpdateAvailable(version: version, downloadUrl: downloadUrl);
        return UpdateInstallResult.permissionDenied;
      }
      if (result.type != ResultType.done) {
        state.value = UpdateError(
          result.message,
          retryDownload: (version: version, downloadUrl: downloadUrl),
        );
        return UpdateInstallResult.success;
      }
      // Stay on updateAvailable — intent fired but user hasn't installed yet
      state.value =
          UpdateAvailable(version: version, downloadUrl: downloadUrl);
      return UpdateInstallResult.success;
    } on Object catch (e, st) {
      logError(e, st);
      state.value = UpdateError(
        e.toString(),
        retryDownload: (version: version, downloadUrl: downloadUrl),
      );
      return UpdateInstallResult.success;
    }
  }

  bool _isNewer(String latest, String installed) {
    final l = _parseSemver(latest);
    final i = _parseSemver(installed);
    for (var idx = 0; idx < 3; idx++) {
      if (l[idx] > i[idx]) return true;
      if (l[idx] < i[idx]) return false;
    }
    return false;
  }

  List<int> _parseSemver(String v) {
    final parts = v.split('.');
    return List.generate(
      3,
      (i) => int.tryParse(i < parts.length ? parts[i] : '') ?? 0,
    );
  }
}
