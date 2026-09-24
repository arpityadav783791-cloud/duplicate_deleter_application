class StorageCategory {
  final String name;
  final int sizeBytes;

  const StorageCategory({
    required this.name,
    required this.sizeBytes,
  });

  double percentageOf(int totalBytes) {
    if (totalBytes == 0) return 0;
    return sizeBytes / totalBytes;
  }
}