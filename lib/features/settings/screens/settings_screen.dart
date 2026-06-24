import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:latitude_tracker/core/l10n/app_strings.dart';
import 'package:latitude_tracker/core/l10n/locale_settings.dart'
    show AppLocaleScope, LocaleSettings;
import 'package:latitude_tracker/core/services/error_reporter.dart';
import 'package:latitude_tracker/core/theme/app_theme.dart';
import 'package:latitude_tracker/core/theme/theme_settings.dart';
import 'package:latitude_tracker/features/auth/services/google_auth_service.dart';
import 'package:latitude_tracker/features/demo/demo_mode.dart';
import 'package:latitude_tracker/features/demo/demo_tutorial_sheet.dart';
import 'package:latitude_tracker/features/repairs/repositories/repair_repository.dart';
import 'package:latitude_tracker/features/sales/repositories/sale_repository.dart';
import 'package:latitude_tracker/features/settings/screens/archive_import_screen.dart';
import 'package:latitude_tracker/features/settings/screens/category_maintenance_screen.dart';
import 'package:latitude_tracker/features/settings/services/archive_service.dart';
import 'package:latitude_tracker/features/settings/services/reset_app_service.dart';
import 'package:latitude_tracker/features/settings/services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final isDemo = DemoMode.active.value;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _SectionHeader(s.account),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(s.signedInAs),
              subtitle: Text(isDemo ? s.demoUser : (user?.email ?? '')),
            ),
            if (!isDemo) const _GoogleAccountTile(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(s.signOut),
              onTap: () => isDemo ? DemoMode.exit() : _confirmSignOut(context),
            ),
            const Divider(),
            _SectionHeader(s.catalogueSection),
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(s.categoriesTitle),
              subtitle: Text(s.categoriesSubtitle),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const CategoryMaintenanceScreen(),
                ),
              ),
            ),
            const Divider(),
            _SectionHeader(s.appearance),
            const _ThemePresetTile(),
            const _ThemeBrightnessTile(),
            const Divider(),
            _SectionHeader(s.archive),
            ListTile(
              leading: const Icon(Icons.upload),
              title: Text(s.exportYear),
              subtitle: Text(s.exportYearSubtitle),
              onTap: () => _exportYear(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: Text(s.importArchive),
              subtitle: Text(s.importArchiveSubtitle),
              onTap: () => _importArchive(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(
                s.deleteArchivedYear,
                style: const TextStyle(color: Colors.red),
              ),
              subtitle: Text(s.deleteArchivedYearSubtitle),
              onTap: () => _deleteYear(context),
            ),
            const Divider(),
            _SectionHeader(s.app),
            ListTile(
              leading: const Icon(Icons.explore_outlined),
              title: Text(s.appTour),
              onTap: () => DemoTutorialSheet.show(context),
            ),
            _LanguageTile(),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '—';
                final build = snapshot.data?.buildNumber ?? '';
                return ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(s.version),
                  trailing: Text('$version ($build)'),
                );
              },
            ),
            const _UpdateTile(),
            if (!isDemo) ...[
              const Divider(),
              _SectionHeader(s.dangerZone),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: Text(
                  s.resetApp,
                  style: const TextStyle(color: Colors.red),
                ),
                subtitle: Text(s.resetAppSubtitle),
                onTap: () => _resetApp(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final s = context.s;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.signOut),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } on Object catch (e, st) {
        logError(e, st);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.s.errGeneric)),
          );
        }
      }
    }
  }

  Future<void> _resetApp(BuildContext context) async {
    final s = context.s;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.resetAppConfirmTitle),
        content: Text(s.resetAppConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.continueAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final deletePhotos = await showDialog<bool>(
      context: context,
      builder: (_) => _ResetAppDialog(),
    );
    if (deletePhotos == null || !context.mounted) return;

    try {
      await _runWithProgress(
        context,
        s.resettingApp,
        () => ResetAppService().resetApp(deletePhotos: deletePhotos),
      );
    } on Object catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.resetAppFailed}: $e')),
        );
      }
    }
  }

  Future<void> _exportYear(BuildContext context) async {
    final s = context.s;
    final year = await _pickYear(context, title: s.exportWhichYear);
    if (year == null || !context.mounted) return;

    final service = ArchiveService();
    File? file;

    try {
      await _runWithProgress(context, s.exportingYear(year), () async {
        file = await service.exportYear(year);
      });
    } on Object catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.exportFailed(e))),
        );
      }
      return;
    }

    if (file == null || !context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file!.path)],
        subject: s.exportSubject(year),
      ),
    );
  }

  Future<void> _importArchive(BuildContext context) async {
    final s = context.s;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    final String content;
    try {
      content = await File(path).readAsString();
    } on Object catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.invalidArchive)),
        );
      }
      return;
    }
    final archive = ArchiveService.parseArchive(content);

    if (!context.mounted) return;

    if (archive == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.invalidArchive)),
      );
      return;
    }

    unawaited(Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ArchiveImportScreen(archive: archive),
      ),
    ));
  }

  Future<void> _deleteYear(BuildContext context) async {
    final s = context.s;
    final year = await _pickYear(context, title: s.deleteWhichYear);
    if (year == null || !context.mounted) return;

    final deletePhotos = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteYearDialog(year: year),
    );
    if (deletePhotos == null || !context.mounted) return;

    var salesDeleted = false;
    try {
      await _runWithProgress(
        context,
        s.deletingYear(year, deletePhotos: deletePhotos),
        () async {
          await SaleRepository().deleteAllSalesForYear(
            year,
            deletePhotos: deletePhotos,
          );
          salesDeleted = true;
          await RepairRepository().deleteAllRepairsForYear(
            year,
            deletePhotos: deletePhotos,
          );
        },
      );
    } on Object catch (e, st) {
      logError(e, st);
      if (context.mounted) {
        final message = salesDeleted
            ? s.deleteYearPartialFailed(year, e)
            : s.deleteFailed(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.yearDataDeleted(year))),
      );
    }
  }

  Future<int?> _pickYear(BuildContext context, {required String title}) {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);

    return showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(title),
        children: years
            .map(
              (y) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, y),
                child: Text('$y'),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _runWithProgress(
    BuildContext context,
    String message,
    Future<void> Function() action,
  ) async {
    if (!context.mounted) return;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    ));
    try {
      await action();
    } finally {
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final currentCode = AppLocaleScope.of(context).languageCode;

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(s.language),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'pt', label: Text('PT')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {currentCode},
        onSelectionChanged: (v) => LocaleSettings.setLocale(Locale(v.first)),
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _ThemePresetTile extends StatelessWidget {
  const _ThemePresetTile();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(s.themePreset),
      subtitle: ValueListenableBuilder<Brightness>(
        valueListenable: ThemeSettings.brightness,
        builder: (context, activeBrightness, _) =>
            ValueListenableBuilder<ThemePreset>(
          valueListenable: ThemeSettings.preset,
          builder: (context, activePreset, _) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: ThemePreset.values.map((preset) {
                final scheme = AppTheme.colorSchemeForPreset(
                  preset,
                  activeBrightness,
                );
                final isSelected = preset == activePreset;
                final label = switch (preset) {
                  ThemePreset.terracotta => s.presetTerracotta,
                  ThemePreset.ocean => s.presetOcean,
                  ThemePreset.forest => s.presetForest,
                  ThemePreset.slate => s.presetSlate,
                  ThemePreset.fuchsia => s.presetFuchsia,
                  ThemePreset.indigo => s.presetIndigo,
                };
                return InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => ThemeSettings.setPreset(preset),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: onSurface, width: 2.5)
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: scheme.onPrimary,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(label, style: labelStyle),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeBrightnessTile extends StatelessWidget {
  const _ThemeBrightnessTile();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListTile(
      leading: const Icon(Icons.contrast),
      title: Text(s.themeBrightness),
      trailing: ValueListenableBuilder<Brightness>(
        valueListenable: ThemeSettings.brightness,
        builder: (context, activeBrightness, _) =>
            SegmentedButton<Brightness>(
          segments: const [
            ButtonSegment(
              value: Brightness.light,
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: Brightness.dark,
              icon: Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: {activeBrightness},
          onSelectionChanged: (v) => ThemeSettings.setBrightness(v.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }
}

class _UpdateTile extends StatelessWidget {
  const _UpdateTile();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ValueListenableBuilder<UpdateState>(
      valueListenable: UpdateService.instance.state,
      builder: (context, state, _) => switch (state) {
        UpdateIdle() => ListTile(
          leading: const Icon(Icons.system_update_outlined),
          title: Text(s.checkForUpdates),
          onTap: UpdateService.instance.checkForUpdate,
        ),
        UpdateChecking() => ListTile(
          leading: const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text(s.updateChecking),
        ),
        UpdateAvailable(:final version) => ListTile(
          leading: const Icon(Icons.system_update_outlined),
          title: Text(s.updateAvailableTile(version)),
          trailing: const Icon(Icons.download_outlined),
          onTap: () => _startDownload(context),
        ),
        UpdateDownloading(:final progress) => ListTile(
          leading: const Icon(Icons.downloading_outlined),
          title: Text(s.updateDownloading),
          subtitle: LinearProgressIndicator(
            value: progress > 0 ? progress : null,
          ),
          enabled: false,
        ),
        UpdateError(:final retryDownload) => ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text(
            retryDownload != null
                ? s.updateDownloadFailed
                : s.updateCheckFailed,
          ),
          onTap: () => _handleRetry(context),
        ),
      },
    );
  }

  Future<void> _startDownload(BuildContext context) async {
    final result = await UpdateService.instance.downloadAndInstall();
    if (result == UpdateInstallResult.permissionDenied && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.updateInstallBlocked)),
      );
    }
  }

  Future<void> _handleRetry(BuildContext context) async {
    final result = await UpdateService.instance.retry();
    if (result == UpdateInstallResult.permissionDenied && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.s.updateInstallBlocked)),
      );
    }
  }
}

class _GoogleAccountTile extends StatefulWidget {
  const _GoogleAccountTile();

  @override
  State<_GoogleAccountTile> createState() => _GoogleAccountTileState();
}

class _GoogleAccountTileState extends State<_GoogleAccountTile> {
  bool _isLinking = false;

  bool get _isGoogleLinked =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((p) => p.providerId == 'google.com') ??
      false;

  Future<void> _linkGoogle() async {
    setState(() => _isLinking = true);
    try {
      final result = await GoogleAuthService().linkGoogleAccount();
      if (!mounted) return;

      final message = switch (result) {
        GoogleAuthSuccess() => null,
        GoogleAuthCancelled() => null,
        GoogleAuthCredentialAlreadyInUse() =>
          context.s.errGoogleCredentialInUse,
        // Unreachable from linkGoogleAccount() but required for exhaustive
        // matching on the sealed class.
        GoogleAuthNoExistingData() => context.s.errGeneric,
        GoogleAuthNetworkError() => context.s.errNoInternet,
        GoogleAuthUnknown() => context.s.errGeneric,
      };

      if (message != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      // The finally rebuild also re-reads _isGoogleLinked, so no
      // intermediate setState() is needed on the success path.
      if (mounted) setState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    if (_isGoogleLinked) {
      return ListTile(
        leading: const Icon(Icons.check_circle_outline, color: Colors.green),
        title: Text(s.googleConnected),
      );
    }

    return ListTile(
      leading: _isLinking
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_link),
      title: Text(s.connectGoogle),
      onTap: _isLinking ? null : _linkGoogle,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DeleteYearDialog extends StatefulWidget {
  const _DeleteYearDialog({required this.year});
  final int year;

  @override
  State<_DeleteYearDialog> createState() => _DeleteYearDialogState();
}

class _DeleteYearDialogState extends State<_DeleteYearDialog> {
  bool _deletePhotos = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.deleteAllYearTitle(widget.year)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.deleteAllYearBody(widget.year)),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(s.alsoDeletePhotos),
            subtitle: Text(s.alsoDeletePhotosSubtitle),
            value: _deletePhotos,
            onChanged: (v) => setState(() => _deletePhotos = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, _deletePhotos),
          child: Text(s.deletePermanently),
        ),
      ],
    );
  }
}

class _ResetAppDialog extends StatefulWidget {
  @override
  State<_ResetAppDialog> createState() => _ResetAppDialogState();
}

class _ResetAppDialogState extends State<_ResetAppDialog> {
  bool _deletePhotos = false;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.resetAppFinalTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.resetAppFinalBody),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(s.alsoDeletePhotos),
            subtitle: Text(s.alsoDeletePhotosSubtitle),
            value: _deletePhotos,
            onChanged: (v) => setState(() => _deletePhotos = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, _deletePhotos),
          child: Text(s.resetEverything),
        ),
      ],
    );
  }
}
