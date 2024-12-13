import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/state/files-state/files_bloc.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/httpStates.dart';
import 'package:jedi/utils/utility.dart';
import 'package:jedi/widgets/FileTile.dart';


class DirectoryFilesListing extends StatefulWidget {
  final String directoryPath;
  final bool? multiSelect;//on null no selection allow
  final List<String> limitSelectionToExtensions;
  final int? minSelection;
  final Function(List<File>)? onDoneSelection;
  final Function(File)? onDelete;
  final List<String>? excludeShowingDirsPath;

  DirectoryFilesListing({super.key, required this.directoryPath,this.multiSelect,this.limitSelectionToExtensions=const [],this.onDoneSelection,this.minSelection,this.onDelete,this.excludeShowingDirsPath}){
    if(multiSelect==null && (onDoneSelection!=null || minSelection!=null)) throw Exception("multiSelect is disabled but onDownSelection/minSelection is not null");
    if(multiSelect!=null && onDoneSelection==null) throw Exception("OnDoneSelection is required");
  }

  @override
  State<DirectoryFilesListing> createState() => _DirectoryFilesListingState();
}

class _DirectoryFilesListingState extends State<DirectoryFilesListing> {
  late final FilesBloc bloc;
  final List<File> selectedFiles=[];
  List<String> pathToDirectory = [];
  List<File> deletedFiles=[];

  @override
  void initState() {
    bloc=BlocProvider.of<FilesBloc>(context);
    pathToDirectory = [widget.directoryPath];
    _loadDirectoryFiles(pathToDirectory.last);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final router=GoRouter.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (pathToDirectory.length <= 1) {
          router.pop();
        } else {
          setState(() {
            pathToDirectory.removeLast();
            _loadDirectoryFiles(pathToDirectory.last);
          });
        }
      },
      child:  BlocConsumer<FilesBloc,FilesState>(listener: (context, state) {
        final error=state.getError(forr: HttpStates.LOAD_DIRECTORY_FILES);
        if(error!=null){
          NotificationService.showSnackbar(text: error,color: Colors.red);
          setState(()=>pathToDirectory.removeLast());
          if(pathToDirectory.isEmpty) router.pop();
        }
      },
        buildWhen: (previous, current) => previous!=current,
        listenWhen: (previous, current) => previous!=current,
        builder: (context, state) {
          return Stack(children: [
            if(!state.isLoading(forr: HttpStates.LOAD_DIRECTORY_FILES))(state.files.isEmpty
                ? const Center(child: Text('No files found'))
                : Flex(
              direction: Axis.vertical,
              children: [
                Flexible(fit: FlexFit.tight,child: ListView.builder(
                    itemCount: state.files.length,
                    itemBuilder: (context, index) {
                      final file = state.files[index];

                      if((file is Directory) && widget.excludeShowingDirsPath?.contains(file.path)==true) return SizedBox.shrink();

                      //on delete we add to deleted files but we are not sure if delete operation was successfull or not
                      //may be user cancelled deletion or it might have failed...
                      //also dont show file if delete or move is in loading
                      if(deletedFiles.contains(file)){
                        if(state.isLoading(forr: HttpStates.DELETE_FILE) || state.isLoading(forr: HttpStates.MOVE_FILE_TO) || !file.existsSync()) return SizedBox.shrink();
                        deletedFiles.remove(file);
                      }
                      return FileTile(file: file,
                          selected:  _isFileSelected(file),
                          onPress: ()=> _onItemClick(file: file),
                          onDelete:widget.onDelete!=null && file is File ?  (){
                            widget.onDelete!(file);
                            deletedFiles.add(file);
                          } : null,
                          enabled: file is Directory || widget.limitSelectionToExtensions.isEmpty || widget.limitSelectionToExtensions.contains(Utility.fileExtension(file as File)));
                    })),
                AnimatedOpacity(opacity:selectedFiles.isNotEmpty ? 1 : 0, duration: Duration(milliseconds: 300),child: selectedFiles.isNotEmpty ? Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.black87),
                  child: FilledButton(onPressed:widget.onDoneSelection==null || (widget.minSelection!=null && selectedFiles.length<widget.minSelection!) ? null : ()=>widget.onDoneSelection!(selectedFiles),
                      child: Text("Complete Selection")),
                ):null)
              ],
            )),
            if (state.isLoading(forr: HttpStates.LOAD_DIRECTORY_FILES))
              Container(
                decoration:BoxDecoration(color: Colors.black.withOpacity(0.8)),
                child: const Align(alignment: Alignment.center, child: SpinKitRipple(size: 72, color: Colors.green)),
              ),
          ]);
        },),
    );
  }

  bool _isFileSelected(FileSystemEntity file){
    if(file is Directory) return false;
    try{
      return selectedFiles.firstWhere((selectedFile)=>selectedFile.path==file.path)!=null;
    }catch(e){
     return false;
    }
  }

  _loadDirectoryFiles(String path){
    if(bloc.state.isLoading(forr: HttpStates.LOAD_DIRECTORY_FILES)) return;
    bloc.add(LoadDirectoryFiles(path: pathToDirectory.last));
  }

  @override
  void dispose() {
    super.dispose();
  }

  _onItemClick({required FileSystemEntity file}) async {
    try{
      if(file is Directory){
        _loadDirectoryFiles((pathToDirectory..add(file.path)).last);
        return;
      }

      if(widget.multiSelect==null){//allow opening file only
        if(Utility.isPdf(file.path)) {
          GoRouter.of(context).pushNamed(AppRoutes.pdfFilePreviewRoute.name,pathParameters: {'pdfFilePath':file.path});
        } else {
          OpenFile.open(file.path,type: Constants.extrnalOpenSupportedFiles[Utility.fileExtension(file as File)] ?? '*/*');
        }
      }else{
        if(_isFileSelected(file)){
         setState(()=>selectedFiles.removeWhere((selectedFile)=>selectedFile.path==file.path));
          return;
        }
        if(widget.multiSelect==false){
          selectedFiles.clear();
        }
        setState(()=>selectedFiles.add(file as File));
      }
    }catch(e){
      NotificationService.showSnackbar(text: "Something went wrong",color: Colors.red,showCloseIcon: true);
    }
  }
}



