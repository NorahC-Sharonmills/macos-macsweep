# Entitlements

Required for the sandboxed app target:

- `com.apple.security.app-sandbox`: enable App Sandbox.
- `com.apple.security.files.user-selected.read-write`: user-selected folder access.
- `com.apple.security.files.bookmarks.app-scope`: persist security-scoped bookmarks.
- `com.apple.security.files.downloads.read-write`: Downloads review and Trash workflow.

Not an entitlement:

- Full Disk Access. Users grant it in System Settings > Privacy & Security > Full Disk Access.

Current plist: `MacDeepCleaner.entitlements`.
