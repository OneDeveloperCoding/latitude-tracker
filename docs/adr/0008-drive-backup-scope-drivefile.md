# Drive backup uses `driveFileScope`, not `driveAppDataScope`

DriveBackup stores JSON export files in `Latitude Tracker Backup/data/` in the seller's Google Drive. The OAuth scope used is `DriveApi.driveFileScope` (`https://www.googleapis.com/auth/drive.file`), which grants access only to files created by this app.

## Considered options

**`driveAppDataScope` (hidden app-data folder):** Google Drive exposes a special hidden `appDataFolder` that is invisible to the user in the Drive UI and cannot be browsed, shared, or downloaded manually. Scope is narrower and the consent dialog is less alarming.

**`driveFileScope` (chosen):** Grants read/write access only to files this app creates. The `Latitude Tracker Backup/` folder is visible in the seller's Drive — she can browse it, verify the backups exist, share it, or download files manually. The consent dialog explicitly names the scope, but it is scoped to app-created files only, not the full Drive.

## Why `driveFileScope`

The primary purpose of DriveBackup is to be a recoverable safety copy the seller can trust. If the backup is hidden in `appDataFolder`, she has no way to verify it exists, inspect its contents, or recover data outside the app (e.g. if the app itself is broken). Visibility in Drive is the feature — hiding the backup defeats the point.

`driveAppDataScope` would also complicate BackupRestore: the restore flow would need to go through the app API, with no manual fallback if the app is unavailable. With `driveFileScope`, the seller can always open Drive, find the JSON files, and recover data manually if needed.

## Trade-offs to watch

- If the seller links her Google account (ADR-0007) before the Drive scope is requested, her stored token will lack `driveFileScope`. The first "Back up now" tap calls `GoogleSignIn.requestScopes([driveFileScope])` to add it incrementally — no re-link required.
- `driveFileScope` only covers files this app created. If the seller moves or renames the `Latitude Tracker Backup/` folder manually in Drive, the app will create a second folder on the next backup run rather than finding the renamed one. The folder name is the lookup key.
