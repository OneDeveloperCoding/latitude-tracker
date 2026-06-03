import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/l10n/locale_settings.dart' show AppLocaleScope, LocaleSettings;
import '../../demo/demo_mode.dart';
import '../../demo/demo_tutorial_sheet.dart';
import '../../sales/repositories/sale_repository.dart';
import '../services/archive_service.dart';
import '../services/reset_app_service.dart';
import 'archive_import_screen.dart';

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
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        children: [
          _SectionHeader(s.account),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(s.signedInAs),
            subtitle: Text(isDemo ? s.demoUser : (user?.email ?? '')),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(s.signOut),
            onTap: () => isDemo ? DemoMode.exit() : _confirmSignOut(context),
          ),
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
            title: Text(s.deleteArchivedYear,
                style: const TextStyle(color: Colors.red)),
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
          if (!isDemo) ...[
            const Divider(),
            _SectionHeader(s.dangerZone),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: Text(s.resetApp,
                  style: const TextStyle(color: Colors.red)),
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
      } catch (_) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (_) {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArchiveImportScreen(archive: archive),
      ),
    );
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

    try {
      await _runWithProgress(
        context,
        s.deletingYear(year, deletePhotos),
        () => SaleRepository()
            .deleteAllSalesForYear(year, deletePhotos: deletePhotos),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.deleteFailed(e))),
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
            .map((y) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, y),
                  child: Text('$y'),
                ))
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
    showDialog(
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
    );
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
        onSelectionChanged: (v) =>
            LocaleSettings.setLocale(Locale(v.first)),
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

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
  final int year;

  const _DeleteYearDialog({required this.year});

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
