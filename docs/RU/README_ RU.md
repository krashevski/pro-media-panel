# PRODUCTION MEDIA PANEL

**Languages:** [🇬🇧 English](../../README.md) | [🇷🇺 Русский](README_RU.md)

**Production Media Panel (PMP)** — интерактивная Linux-панель для управления видео-проектами, ingest с телефона, генерации прокси, монтажа и экспорта. 
Разработано для документальных и творческих проектов.

## 🔹 Основные возможности

1. **System Status** – отображает GPU, NVENC, доступное пространство и количество проектов. 
2. **Create Project** – создаёт проект в двух местах:
   - Storage: `/mnt/storage/Videos/projects/ProjectName`
   - Shotcut: `/home/vladislav/shotcut/projects/ProjectName`
3. **Footage Ingest from Phone** – импорт видео с телефона:
   - оригиналы в `raw` 
   - рабочие файлы в `footage`
4. **Generate Proxy** – создаёт прокси-файлы в папке Shotcut с прогрессом и безопасностью UTF-8.
5. **Launch Shotcut** – открывает Shotcut (Flatpak). 
6. **Export YouTube** – экспорт готового видео в `exports` с настройками для YouTube. 
7. **Archive Project** – сохраняет проект в `.tar.gz` архив. 
8. **Video / Graphics / Audio Tools** – быстрый доступ к Flatpak-приложениям:
   - Shotcut, OBS Studio 
   - GIMP, Krita 
   - Audacity
9. **Project Info** – показывает:
   - количество клипов в `footage` 
   - количество прокси-файлов 
   - размер папок 
   - общую статистику проекта и дату последнего изменения 

## 🔹 Структура проекта

**Storage (оригиналы)** 
/mnt/storage/Videos/projects/ProjectName
* footage/
* raw/
* edit/
* export/


**Shotcut (рабочая среда)** 
/home/vladislav/shotcut/projects/ProjectName
* proxy/
* project/

## 🔹 Установка

1. Скопируйте скрипт в `~/bin` и сделайте его исполняемым:

```bash
mv rebk-media-panel.sh pro-media-panel.sh
chmod +x ~/bin/pro-media-panel.sh
```
2. (Опционально) добавьте alias для удобства:
```bash
alias pro-media-panel='~/bin/pro-media-panel.sh'
```

3. Убедитесь, что Flatpak приложения установлены:
* Shotcut
* OBS Studio
* GIMP
* Krita
* Audacity

## Использование

Запуск панели:
```bash
pro-media-panel
```

Выберите нужный пункт меню для работы с проектами:
* Создание проекта → ingest с телефона → генерация прокси → монтаж → экспорт → архив
* Проверка Project Info для мониторинга состояния проекта

## Примечания

Все операции безопасны для UTF-8 и пробелов в названиях файлов.
Proxy создаются в отдельной рабочей папке на SSD для ускорения монтажа.
Интеграция с Shotcut позволяет сразу использовать прокси для монтажа больших 4K проектов.

## Лицензия

MIT License © 2026 Владислав Крашевский, ChatGPT поддержка