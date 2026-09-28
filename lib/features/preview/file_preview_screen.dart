import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/duplicate_file.dart';

class FilePreviewScreen extends StatelessWidget {
  final DuplicateFile file;
  const FilePreviewScreen({super.key,required this.file});
  bool get isImage=>const ['.jpg','.jpeg','.png','.gif','.webp','.bmp'].contains(file.extension);
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('File details')),body:ListView(padding:const EdgeInsets.all(20),children:[Container(height:280,decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(24)),clipBehavior:Clip.antiAlias,child:isImage&&File(file.path).existsSync()?Image.file(File(file.path),fit:BoxFit.contain,errorBuilder:(_,_,_)=>const Icon(Icons.broken_image_rounded,size:80)):Center(child:Icon(isImage?Icons.image_rounded:Icons.insert_drive_file_rounded,size:88))),const SizedBox(height:20),Text(file.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800)),const SizedBox(height:14),_Info('Size',_size(file.size)),_Info('Type',file.extension.isEmpty?'Unknown':file.extension),_Info('Path',file.path),_Info('Modified','${file.modified.day}/${file.modified.month}/${file.modified.year}') ]));
  String _size(int b){if(b<1024)return '$b B';if(b<1024*1024)return '${(b/1024).toStringAsFixed(1)} KB';if(b<1024*1024*1024)return '${(b/(1024*1024)).toStringAsFixed(1)} MB';return '${(b/(1024*1024*1024)).toStringAsFixed(1)} GB';}
}
class _Info extends StatelessWidget { final String label,value; const _Info(this.label,this.value); @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:Colors.black54)),const SizedBox(height:3),Text(value,style:const TextStyle(fontWeight:FontWeight.w600))])); }
