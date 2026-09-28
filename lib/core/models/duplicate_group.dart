import 'duplicate_file.dart';
class DuplicateGroup {
  final String hash; final int size; final List<DuplicateFile> files;
  const DuplicateGroup({required this.hash, required this.size, required this.files});
}
