import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:jedi/utils/httpStates.dart';
import 'package:jedi/utils/utility.dart';
import 'package:meta/meta.dart';
import 'package:jedi/extensions/map-entensions.dart';
import 'package:jedi/models/WithHttpState.dart';
import 'package:jedi/singletons/LoggerSingleton.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/StoragePermissions.dart';
import '../../models/HttpState.dart';

part 'jsonFiles_event.dart';
part 'jsonFiles_state.dart';

class JsonFilesBloc extends Bloc<JsonFilesEvent, JsonFilesState> {
  StreamSubscription<File>? _searchSubscription;
  StreamController<List<File>>? _searchController;

  JsonFilesBloc() : super(JsonFilesState.initial()) {
    on<LoadDirectoryFiles>((event, emit) async {
      emit(state.copyWith(httpStates: state.httpStates.clone()
        ..put(HttpStates.LOAD_DIRECTORY_FILES, const HttpState.loading())));
      // await Future.delayed(Duration(seconds: 20));
      try {
        final files = await _loadDirectoryFiles(event.path);
        files.sort((fileA, fileB){
          if((fileA is Directory && fileB is Directory)) {
            return fileA.path.compareTo(fileB.path);
          } else if(fileA is Directory && fileB is File){
            return -1;
          }
          return 1;
        });
        emit(state.copyWith(files: files, httpStates: state.httpStates.clone()
          ..put(HttpStates.LOAD_DIRECTORY_FILES,const HttpState.done())));
      } catch (e) {
        emit(state.copyWith(httpStates: state.httpStates.clone()
          ..put(HttpStates.LOAD_DIRECTORY_FILES,
              HttpState.error(error: e.toString()))));
      }
    });

    on<SearchFile>((event, emit) async {
      if (_searchSubscription != null) await _searchSubscription?.cancel();
      if (_searchController == null) _searchController=StreamController<List<File>>.broadcast();

      List<File> files = [];
      _searchSubscription = searchFiles(event.path, event.nameLike).listen((data) {
          files.add(data);
          _searchController!.add(files);
        },
        onError: _searchController!.addError,
      );
      emit(state.copyWith(searchStream: _searchController!.stream));
    });

    on<ResetSearch>((event, emit) async {
      if (_searchSubscription != null) await _searchSubscription!.cancel();
      if (_searchController != null) await _searchController!.close();
      _searchController=null;
      _searchSubscription=null;
      emit(state.copyWith(searchStream: null));
    });

    on<MoveFileTo>((event, emit) async {
      emit(state.copyWith(httpStates: state.httpStates.clone()..put(HttpStates.MOVE_FILE_TO, const HttpState.loading())));
      try{
        await _moveFile(file:event.file,toDirectoryPath:event.to);
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(HttpStates.MOVE_FILE_TO, const HttpState.done())));
      }catch(e){
        emit(state.copyWith(httpStates: state.httpStates.clone()..put(HttpStates.MOVE_FILE_TO, HttpState.error(error: e.toString()))));
      }
    });
  }

  Future<List<FileSystemEntity>> _loadDirectoryFiles(String path) async {
    try {
      if (!await StoragePermissions.requestStoragePermissions()) {
        throw Exception("Permission denied");
      }
      if (Constants.isHiddenFileOrDir(path)) {
        throw Exception("Permission denied");
      }

      Directory directory = Directory(path);
      if (directory.existsSync() == false) {
        throw Exception("Invalid directory path");
      }
      return directory.listSync(followLinks: false)..removeWhere((fileEntity)=>(fileEntity is File) && !Utility.isJsonFile(fileEntity));
    } catch (e) {
      throw Exception("Failed to load directory files");
    }
  }

  Stream<File> searchFiles(String directoryPath, String userInput) async* {
    if (!await StoragePermissions.requestStoragePermissions()) {
      return;
    }
    if (Constants.isHiddenFileOrDir(directoryPath)) {
      return;
    }

    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      await for (var entity in directory.list(recursive: false, followLinks: false)) {
        try {
          if (entity is File) {
            final fileName = entity.path.split('/').last.toLowerCase();
            if (!Utility.isJsonFile(entity) || !fileName.startsWith(userInput.toLowerCase())) continue;
            yield entity;
          } else if (entity is Directory) {
            yield* searchFiles(entity.path, userInput);
          }
        } on FileSystemException catch (e) {
          LoggerSingleton().logger.w("Failed to access ${entity.path}: $e");
          return;
        }
      }
    } else {
      LoggerSingleton().logger.w("Directory does not exist: $directoryPath");
    }
  }

  _moveFile({required File file, required String toDirectoryPath}) {
    Directory directoryTo=Directory(toDirectoryPath);

    if(!directoryTo.existsSync()){
      throw Exception("No such directory exists");
    }

    if (!file.existsSync()) {
      throw Exception("File does not exist in the source directory");
    }

    // Construct the new file path
    String newFilePath = "${directoryTo.path}/${file.path.split('/').last}";

    // Move the file
    try {
      file.renameSync(newFilePath);
    } catch (e) {
      throw Exception("Failed to move file: $e");
    }
  }
}
