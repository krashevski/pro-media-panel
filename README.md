# 🧰 Media Panel Template

This template is free to use and modify.

A simple panel template for launching media programs from a single text menu on Ubuntu.
Suitable for Flatpak, system, and user applications.

## Installation

Copy `bin/media-panel.sh` to `~/bin/` and make it executable:
```bash
chmod +x ~/bin/media-panel.sh

```

Copy .desktop/media-panel.desktop to:
```bash
cp desktop/media-panel.desktop ~/.local/share/applications/
```

The panel will appear in the application menu as "Media Panel."

## The script is extensible:

- Add your own Flatpak applications
- Add custom ffmpeg pipelines
- Connect Resolve and automation
