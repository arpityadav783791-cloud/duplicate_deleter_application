import '../models/duplicate_group.dart';

class CategoryClassifier {
  static const images = {'.jpg','.jpeg','.png','.gif','.webp','.bmp','.svg'};
  static const videos = {'.mp4','.mkv','.avi','.mov','.webm','.flv'};
  static const audio = {'.mp3','.wav','.aac','.flac','.ogg','.m4a'};
  static const documents = {'.pdf','.doc','.docx','.txt','.xls','.xlsx','.ppt','.pptx','.csv'};

  static String classify(String extension) {
    final ext = extension.toLowerCase();
    if (images.contains(ext)) return 'Images';
    if (videos.contains(ext)) return 'Videos';
    if (audio.contains(ext)) return 'Audio';
    if (documents.contains(ext)) return 'Documents';
    return 'Other Files';
  }

  static Map<String, List<DuplicateGroup>> groupByCategory(
    List<DuplicateGroup> groups,
  ) {
    final result = <String, List<DuplicateGroup>>{};
    for (final group in groups) {
      final categories = group.files.map((f) => classify(f.extension)).toSet();
      final category = categories.length == 1 ? categories.first : 'Other Files';
      result.putIfAbsent(category, () => []).add(group);
    }
    return result;
  }
}
