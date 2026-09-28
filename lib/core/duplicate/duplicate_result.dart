class DuplicateFile {
  final String path; final String name; final int size; final String extension; final DateTime modified;
  const DuplicateFile({required this.path,required this.name,required this.size,required this.extension,required this.modified});
}
class DuplicateGroup {
  final String hash; final int size; final List<DuplicateFile> files;
  const DuplicateGroup({required this.hash,required this.size,required this.files});
}
