# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A [Calibre](https://calibre-ebook.com/) plugin (Python, PyQt) that fetches or imports ebook annotations/highlights from reader devices and apps, and writes them into a Calibre library's custom columns. It runs inside Calibre's process — there is no standalone entry point, build system, or test suite. `calibre_plugins.annotations` is the package namespace Calibre assigns this plugin at runtime; imports inside the code use that prefix even though the repo root has no such folder.

## Build / package / run

There's no build step for development — Calibre loads the `.py` files directly. Packaging and installing use the Windows batch scripts in `tools/`:

- `tools/run.cmd` — zips the plugin into `Annotations.zip` (via 7-Zip, excluding `readers/_*` private/example files) and installs it into Calibre with `calibre-customize -a`, then relaunches Calibre in debug mode (`calibre-debug -g`).
- `tools/BuildLanguageFiles.cmd` — regenerates the `.po` translation templates in `translations/` via `xgettext`.

To test a change: install into a local Calibre via the zip method above (or Calibre's Preferences → Plugins → Load plugin from file), then run `calibre-debug -g` and watch the console for import errors and diagnostic logging.

There is no automated test suite and no linter config in this repo — verify changes by loading the plugin in Calibre.

## Architecture

Full program-flow documentation already lives in `developer_notes.txt` (and is mirrored in `README.md`) — read that file for the canonical walkthrough. Summary:

**Two ways annotations get into the plugin:**
- **Fetching** — probing a connected USB/MTP device directly (its own sqlite DB, or a proprietary format like Kindle's `My Clippings.txt`).
- **Importing** — parsing a file exported by a reader app (email attachment, iTunes file share, drag-and-drop).

**Reader classes** (`readers/*.py`) implement support for one device or app, subclassing one of three base classes in `reader_app_support.py`:
- `USBReader` — a USB-connected device (Kindle, Sony, Kobo, PocketBook, Tolino, Boox).
- `iOSReaderApp` — an iOS app accessed via device mount (iBooks, Marvin, Kindle for iOS — files prefixed `_` are the built-in/private implementations).
- `ExportingReader` — an app that exports annotation files rather than being probed directly (GoodReader, Bluefire, Stanza).

A class declares `SUPPORTS_FETCHING` (implements `get_installed_books()` / `get_active_annotations()`) and/or `SUPPORTS_EXPORTING` (implements `parse_exported_highlights()`); some classes support both. `readers/SampleFetchingApp.py` and `readers/SampleExportingApp.py` are templates for adding a new device/app. Third-party reader classes can also be registered externally via `additional_readers` in the user's `annotations.json` config, without touching this repo.

**Core flow** (see `action.py`):
- `action.py` — the `InterfaceAction` Calibre entry point. `genesis()` runs at Calibre startup: sets up logging, loads prefs, initializes `annotations.db`, discovers reader classes, builds menus. Listens for device-connect events and library-switch events to keep menus current.
- Both fetching and importing paths converge on `annotations_db.py`, the plugin's own sqlite database (`annotations.db`) that stores annotations in a normalized schema regardless of source.
- After processing, `annotated_books.py` (`AnnotatedBooksDialog`) shows the user a review screen — color-coded by match confidence — where books can be previewed and toggled before import.
- `action.py:process_selected_books()` writes approved annotations into the library's configured custom column; low-confidence metadata matches get a manual confirmation dialog first.

**Other modules:**
- `config.py` — plugin preferences (`annotations.json`) and the `ConfigWidget` shown in Calibre's plugin settings.
- `appearance.py` — `AnnotationsAppearance` dialog controlling how annotations render as HTML in the custom column.
- `find_annotations.py` — `FindAnnotationsDialog`, a library-wide annotation search.
- `common_utils.py` — shared PyQt/Calibre helper code used across dialogs.
- `dialogs/` — additional Qt dialogs (`.ui` files paired with generated/handwritten `.py`), e.g. the custom-column creation wizard (`cc_wizard.*`) and new-destination picker.
- `message_box_ui.py` — shared message box UI.

**Developer mode**: setting `developer_mode: true` in `annotations.json` enables an extra "Remove all annotations" menu command, useful while iterating on a reader class.

## Notes for changes

- This plugin has passed through several maintainers; expect inconsistent style between older reader classes and newer ones — match the style of the file you're editing rather than the newest convention.
- Reader class filenames prefixed with `_` (e.g. `_Marvin.py`, `_iBooks.py`, `_Stanza.py`, `_BluefireReader.py`, `_iOSKindle.py`) are excluded from the release zip by `tools/run.cmd` — treat them as private/internal implementations, not examples to copy for new readers (use the `Sample*.py` files for that instead).
- Version and changelog live in `about.txt` (`Version history`) and the `version` tuple in `__init__.py` — both need updating together for a release.
