from collections import defaultdict

from hasher import calculate_sha256


def find_duplicates(files):
    # Group files by size first.
    size_groups = defaultdict(list)

    for file_path in files:
        try:
            size = file_path.stat().st_size
            size_groups[size].append(file_path)
        except (PermissionError, OSError):
            continue

    duplicate_groups = []

    # Only hash files that have the same size.
    for size, same_size_files in size_groups.items():

        if len(same_size_files) < 2:
            continue

        hash_groups = defaultdict(list)

        for file_path in same_size_files:
            try:
                file_hash = calculate_sha256(file_path)
                hash_groups[file_hash].append(file_path)
            except (PermissionError, OSError):
                continue

        # Files with the same size AND same hash are duplicates.
        for file_hash, same_hash_files in hash_groups.items():

            if len(same_hash_files) > 1:
                duplicate_groups.append({
                    "hash": file_hash,
                    "size": size,
                    "files": [str(path) for path in same_hash_files],
                })

    return duplicate_groups