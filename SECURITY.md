# Security

- No private Apple APIs.
- No `sudo`.
- No `rm -rf`.
- No SIP or Gatekeeper bypass.
- No chmod/chown mass changes.
- No automatic deletion.
- `/System` paths are blocked in the Trash service.
- `Do Not Delete` items cannot be cleaned.
- Symbolic links are skipped by default.
- External volumes are skipped by default.
- Network volumes are skipped by default.

macOS sandbox limits:

- Sandboxed apps cannot freely scan all user data.
- User-selected folders require explicit picker access.
- Long-term access needs security-scoped bookmarks.
- Full Disk Access must be granted by the user in System Settings.
- TCC-protected folders may appear missing or unreadable without permission.

Permanent deletion is intentionally disabled in the UI. Trash is the default workflow.
