import 'dart:io';
class DeleteItemResult { final String path; final bool success; final String? error; final int bytes; const DeleteItemResult({required this.path,required this.success,required this.bytes,this.error}); }
class FileDeleteService {
 Future<DeleteItemResult> deleteFile(String path) async { try { final f=File(path); if(!await f.exists()) return DeleteItemResult(path:path,success:false,bytes:0,error:'File no longer exists.'); final b=await f.length(); await f.delete(); return DeleteItemResult(path:path,success:true,bytes:b); } on FileSystemException catch(e){ return DeleteItemResult(path:path,success:false,bytes:0,error:e.message); } catch(e){ return DeleteItemResult(path:path,success:false,bytes:0,error:e.toString()); } }
 Future<List<DeleteItemResult>> deleteFiles(List<String> paths,{void Function(int,int,DeleteItemResult)? onProgress}) async { final out=<DeleteItemResult>[]; for(var i=0;i<paths.length;i++){ final r=await deleteFile(paths[i]); out.add(r); onProgress?.call(i+1,paths.length,r); } return out; }
}
