from pathlib import Path


def scan_files(folder_path):
    folder = Path(folder_path)

    if not folder.exists():
        raise FileNotFoundError(f"Folder not found: {folder_path}")

    if not folder.is_dir():
        raise NotADirectoryError(f"Not a directory: {folder_path}")

    files = []

    for path in folder.rglob("*"):
        try:
            if path.is_file():
                files.append(path)
        except (PermissionError, OSError):
            continue

    return files