part of 'jsonFiles_bloc.dart';

@immutable
abstract class JsonFilesEvent {
  const JsonFilesEvent();
}

class LoadDirectoryFiles extends JsonFilesEvent{
  final String path;
  const LoadDirectoryFiles({required this.path});
}

class SearchFile extends JsonFilesEvent{
  final String path;
  final String nameLike;
  const SearchFile({required this.path,required this.nameLike});
}

class ResetSearch extends JsonFilesEvent{
  const ResetSearch();
}

class MoveFileTo extends JsonFilesEvent{
  final File file;
  final String to;

  const MoveFileTo({required this.to,required this.file});
}

class CreateMainDirs extends JsonFilesEvent{
  const CreateMainDirs();
}