# PRODUCTION MEDIA PANEL

**Production Media Panel (PMP)** is an interactive Linux panel for managing video projects, ingesting from a phone, generating proxies, editing, and exporting.

Designed for documentary and creative projects.

## 🔹 Key Features

1. **System Status** – displays GPU, NVENC, available space, and the number of projects.
2. **Create Project** – creates a project in two locations:
- Storage: `/mnt/storage/Videos/projects/ProjectName`
- Shotcut: `/home/vladislav/shotcut/projects/ProjectName`
3. **Footage Ingest from Phone** – import videos from your phone:
- originals in `raw`
- working files in `footage`
4. **Generate Proxy** – creates proxy files in the Shotcut folder with UTF-8 progress and security.
5. **Launch Shotcut** – opens Shotcut (Flatpak).
6. **Export YouTube** – exports the finished video to `exports` with YouTube settings.
7. **Archive Project** – saves the project to a `.tar.gz` archive.
8. **Video / Graphics / Audio Tools** – quick access to Flatpak applications:
- Shotcut, OBS Studio
- GIMP, Krita
- Audacity
9. **Project Info** – shows:
- number of clips in `footage`
- number of proxy files
- folder size
- general project statistics and last modification date

## 🔹 Project Structure

**Storage (originals)**
/mnt/storage/Videos/projects/ProjectName
* footage/
* raw/
* edit/
* export/

**Shotcut (workspace)**
/home/vladislav/shotcut/projects/ProjectName
* proxy/
* project/

## 🔹 Installation

1. Copy the script to `~/bin` and make it executable:

```bash
mv rebk-media-panel.sh pro-media-panel.sh
chmod +x ~/bin/pro-media-panel.sh
```
2. (Optional) Add an alias for convenience:
```bash
alias pro-media-panel='~/bin/pro-media-panel.sh'
```

3. Make sure Flatpak applications are installed:
* Shotcut
* OBS Studio
* GIMP
* Krita
* Audacity

## Usage

Launch the panel:
```bash
pro-media-panel
```

Select the desired menu item for working with projects:
* Create project → ingest from phone → generate proxy → edit → export → archive
* Check Project Info to monitor project status

## Notes

All operations are safe for UTF-8 encoding and spaces in file names.
Proxies are created in a separate working folder on the SSD to speed up editing.
Integration with Shotcut allows you to immediately use proxies for editing large 4K projects.

## License

MIT License © 2026 Vladislav Krashevsky, ChatGPT support