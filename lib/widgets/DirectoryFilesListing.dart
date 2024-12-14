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
import 'package:jedi/state/json-files-state/jsonFiles_bloc.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/httpStates.dart';
import 'package:jedi/utils/utility.dart';
import 'package:jedi/widgets/FileTile.dart';


class DirectoryFilesListing extends StatefulWidget {
  final String directoryPath;
  final List<String> limitSelectionToExtensions;
  final Function(File)? onFileClick;
  final List<String>? excludeShowingDirsPath;

  const DirectoryFilesListing({super.key, required this.directoryPath,this.limitSelectionToExtensions=const [],this.onFileClick,this.excludeShowingDirsPath});

  @override
  State<DirectoryFilesListing> createState() => _DirectoryFilesListingState();
}

class _DirectoryFilesListingState extends State<DirectoryFilesListing> {
  late final JsonFilesBloc bloc;
  final List<File> selectedFiles=[];
  List<String> pathToDirectory = [];
  List<File> deletedFiles=[];

  @override
  void initState() {
    bloc=BlocProvider.of<JsonFilesBloc>(context);
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
      child:  BlocConsumer<JsonFilesBloc,JsonFilesState>(listener: (context, state) {
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
                ? const Center(child: Text('No Json files found'))
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
                          onPress: ()=> _onItemClick(file: file),
                          enabled: file is Directory || widget.limitSelectionToExtensions.isEmpty || widget.limitSelectionToExtensions.contains(Utility.fileExtension(file as File)));
                    })),
              ],
            )),
            if (state.isLoading(forr: HttpStates.LOAD_DIRECTORY_FILES))
              const Align(alignment: Alignment.center, child: SpinKitRipple(size: 72, color: Colors.green)),
          ]);
        },),
    );
  }

  _loadDirectoryFiles(String path){
    if(bloc.state.isLoading(forr: HttpStates.LOAD_DIRECTORY_FILES)) return;
    bloc.add(LoadDirectoryFiles(path: pathToDirectory.last));
  }

  _onItemClick({required FileSystemEntity file}) async {
    try{
      if(file is Directory){
        _loadDirectoryFiles((pathToDirectory..add(file.path)).last);
        return;
      }
      if(widget.onFileClick!=null) widget.onFileClick!(file as File);
    }catch(e){
      NotificationService.showSnackbar(text: "Something went wrong",color: Colors.red,showCloseIcon: true);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}



