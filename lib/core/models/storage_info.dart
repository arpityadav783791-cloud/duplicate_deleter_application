class StorageInfo {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;

  const StorageInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
  });
  double get usagePercentage{
    if(totalBytes == 0) return 0;
    return usedBytes/totalBytes;
  }
}