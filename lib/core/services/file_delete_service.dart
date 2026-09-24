import 'dart:io';
class FileDeleteService {
  Future<bool> deleteFile(String path) async{
    try{
      final file = File(path);
      if(!await file.exists()){
        return false;
      }
      await file.delete();
      return true;
    }on FileSystemException{
      return false;
    }
  }
}