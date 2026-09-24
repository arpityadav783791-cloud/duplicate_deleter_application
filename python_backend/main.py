import json
import sys

from scanner import scan_files
from duplicate_detector import find_duplicates


def main():
    if len(sys.argv) != 2:
        print(json.dumps({
            "success": False,
            "error": "Usage: python3 main.py <folder_path>"
        }))
        return

    folder_path = sys.argv[1]

    try:
        files = scan_files(folder_path)
        duplicates = find_duplicates(files)

        wasted_space = sum(
            group["size"] * (len(group["files"]) - 1)
            for group in duplicates
        )

        result = {
            "success": True,
            "scanned_files": len(files),
            "duplicate_groups": len(duplicates),
            "duplicate_files": sum(
                len(group["files"]) for group in duplicates
            ),
            "wasted_space": wasted_space,
            "duplicates": duplicates,
        }

        print(json.dumps(result, indent=2))

    except Exception as error:
        print(json.dumps({
            "success": False,
            "error": str(error)
        }))


if __name__ == "__main__":
    main()
    