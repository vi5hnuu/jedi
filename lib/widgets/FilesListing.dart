import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jedi/models/file-selection-config.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/state/files-state/files_bloc.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/httpStates.dart';
import 'package:jedi/widgets/DirectoryFilesListing.dart';

class FilesListing extends StatelessWidget {
  final FileSelectionConfig config;

  const FilesListing({super.key,required this.config});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FilesBloc,FilesState>(
        listenWhen: (previous, current) => previous.httpStates[HttpStates.MOVE_FILE_TO]!=current.httpStates[HttpStates.MOVE_FILE_TO],
        listener: (context, state) {
          final httpState=state.httpStates[HttpStates.PAGE_NUMBERS];
          if(httpState?.done==true){
            NotificationService.showSnackbar(text: "File Delete Success.",color: Colors.green);
          }else if(httpState?.error!=null){
            NotificationService.showSnackbar(text: httpState!.error!,color: Colors.red);
          }else if(httpState?.loading==true){
            NotificationService.showSnackbar(text: "Deleting file...",color: Colors.lightBlue);
          }
        },child:DirectoryFilesListing(excludeShowingDirsPath: config.excludeShowingDirsPath,directoryPath: config.path,onDelete: (file)=> _onDeleteFile(context,file))
    );
  }

  _onDeleteFile(BuildContext context,File file) async {
    //-1 -> bin
    // 0 | null -> cancel
    // 1 -> permanent delete
    int? deleteApproved=await showDialog(context: context, builder: (context) {
      return SimpleDialog(
        contentPadding: EdgeInsets.all(16),
        children: [
          RichText(text: TextSpan(children: [
            TextSpan(text: "File "),
            TextSpan(text: file.path.split('/').last,style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: " will be deleted."),
          ]),),
          SizedBox(height: 5,),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisSize: MainAxisSize.max,
              children: [
                if(!file.path.startsWith(Constants.binDirPath)) ...[Expanded(child: FilledButton(onPressed: ()=>Navigator.of(context).pop(-1), child: Text("Move to bin",style: TextStyle(color: Colors.black),),style: FilledButton.styleFrom(backgroundColor: Colors.yellow),)),
                SizedBox(width: 12,)],
                Expanded(child: FilledButton(onPressed: ()=>Navigator.of(context).pop(0), child: Text("Cancel",style: TextStyle(color: Colors.white)),style: FilledButton.styleFrom(backgroundColor: Colors.green)))
              ],
            ),
          ),
          SizedBox(width: 12,),
          Container(width: double.infinity,child: FilledButton(onPressed: ()=>Navigator.of(context).pop(1), child: Text("Permanent Delete",style: TextStyle(color: Colors.white)),style: FilledButton.styleFrom(backgroundColor: Colors.red)))
        ],
      );
    });
    if(deleteApproved==-1) BlocProvider.of<FilesBloc>(context).add(MoveFileTo(to: Constants.binDirPath, file: file));
    if(deleteApproved==1) BlocProvider.of<FilesBloc>(context).add(DeleteFile(file: file));
  }
}
