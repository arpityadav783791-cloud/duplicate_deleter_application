import hashlib

def calculate_sha256(file_path, chunk_size=1024*1024):
    sha256 = hashlib.sha256()

    with open(file_path, 'rb') as file:
        while chunk := file.read(chunk_size):
            sha256.update(chunk)

    return sha256.hexdigest()