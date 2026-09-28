import 'duplicate_result.dart';
import 'file_hasher.dart';
class DuplicateDetector {
  final FileHasher _hasher; DuplicateDetector({FileHasher? hasher}):_hasher=hasher??FileHasher();
  Future<List<DuplicateGroup>> findDuplicates(List<DuplicateFile> files,{void Function(String stage,int completed,int total)? onProgress}) async {
    final bySize=<int,List<DuplicateFile>>{};
    for(final f in files){bySize.putIfAbsent(f.size,()=>[]).add(f);}
    final candidates=bySize.values.where((v)=>v.length>1).expand((v)=>v).toList();
    final quick=<String,List<DuplicateFile>>{}; int done=0;
    for(final f in candidates){try{final h=await _hasher.calculateQuickHash(f.path);quick.putIfAbsent(h,()=>[]).add(f);}catch(_){} done++;onProgress?.call('Checking duplicate candidates...',done,candidates.length);}
    final results=<DuplicateGroup>[]; final fullCandidates=quick.values.where((v)=>v.length>1).expand((v)=>v).toList(); done=0;
    final full=<String,List<DuplicateFile>>{};
    for(final f in fullCandidates){try{final h=await _hasher.calculateSha256(f.path);full.putIfAbsent(h,()=>[]).add(f);}catch(_){} done++;onProgress?.call('Verifying exact matches...',done,fullCandidates.length);}
    for(final e in full.entries){if(e.value.length>1)results.add(DuplicateGroup(hash:e.key,size:e.value.first.size,files:List.unmodifiable(e.value)));}
    return List.unmodifiable(results);
  }
}
