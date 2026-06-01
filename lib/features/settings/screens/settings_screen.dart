import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../sales/repositories/sale_repository.dart';
import '../services/archive_service.dart';
import 'archive_import_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        children: [
          _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Signed in as'),
            subtitle: Text(user?.email ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _confirmSignOut(context),
          ),
          const Divider(),
          _SectionHeader('Archive'),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export year'),
            subtitle: const Text('Save a backup of all sales data'),
            onTap: () => _exportYear(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import archive'),
            subtitle: const Text('Browse a previously exported backup'),
            onTap: () => _importArchive(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever,
                color: Colors.red),
            title: const Text('Delete archived year',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text(
                'Removes a year\'s sales — photos are kept for archive viewing'),
            onTap: () => _deleteYear(context),
          ),
          const Divider(),
          _SectionHeader('App'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '—';
              final build = snapshot.data?.buildNumber ?? '';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: Text('$version ($build)'),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _exportYear(BuildContext context) async {
    final year = await _pickYear(context, title: 'Export which year?');
    if (year == null || !context.mounted) return;

    final service = ArchiveService();
    File? file;

    try {
      await _runWithProgress(context, 'Exporting $year...', () async {
        file = await service.exportYear(year);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
      return;
    }

    if (file == null || !context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file!.path)],
        subject: 'Latitude Tracker — $year archive',
      ),
    );
  }

  Future<void> _importArchive(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    final content = await File(path).readAsString();
    final archive = ArchiveService.parseArchive(content);

    if (!context.mounted) return;

    if (archive == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid archive file')),
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
    final year = await _pickYear(context, title: 'Delete which year?');
    if (year == null || !context.mounted) return;

    // Returns null = cancelled, false = keep photos, true = delete photos too
    final deletePhotos = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteYearDialog(year: year),
    );
    if (deletePhotos == null || !context.mounted) return;

    final progressLabel = deletePhotos
        ? 'Deleting $year data and photos...'
        : 'Deleting $year data...';

    try {
      await _runWithProgress(
        context,
        progressLabel,
        () => SaleRepository()
            .deleteAllSalesForYear(year, deletePhotos: deletePhotos),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$year data deleted')),
      );
    }
  }

  Future<int?> _pickYear(BuildContext context, {required String title}) {
    final currentYear = DateTime.now().year;
    final years =
        List.generate(5, (i) => currentYear - i);

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
    return AlertDialog(
      title: Text('Delete all ${widget.year} data?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This permanently removes all sales from ${widget.year}. '
            'Make sure you have exported a backup first.',
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Also delete photos'),
            subtitle: const Text(
              'Removes photos from Storage — archive photo previews will no longer work',
            ),
            value: _deletePhotos,
            onChanged: (v) => setState(() => _deletePhotos = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, _deletePhotos),
          child: const Text('Delete permanently'),
        ),
      ],
    );
  }
}
