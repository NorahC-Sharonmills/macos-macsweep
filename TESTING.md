# Testing

Run on macOS:

```sh
swift test
```

Current test coverage:

- Exclusion rules.
- Duplicate detection with Unicode filenames.
- File scanner symlink skip.
- Deleted-during-scan tolerance.
- Unreadable file tolerance on macOS.
- Trash workflow with mock performer.
- System path block.
- Permission settings URL.

Tests use temporary directories only. They do not scan real user folders.

Manual checks:

- Launch app from Xcode.
- Scan dashboard without Full Disk Access; verify limited-access banner.
- Grant Full Disk Access, relaunch, rescan.
- Quick Look a result.
- Reveal a result in Finder.
- Select safe cache item, confirm Trash workflow.
