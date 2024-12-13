part of 'files_bloc.dart';

@Immutable("cannot modify aarti state")
class FilesState extends Equatable with WithHttpState {
  final List<FileSystemEntity> files;
  final Stream<List<File>>? searchStream;

  FilesState._({
    this.files=const [],
    this.searchStream,
    Map<String,HttpState>? httpStates,
  }){
    this.httpStates.addAll(httpStates ?? {});
  }

  FilesState.initial() : this._(httpStates: const {});

  FilesState copyWith({
    Map<String, HttpState>? httpStates,
  List<FileSystemEntity>? files,
    Stream<List<File>>? searchStream,
  }) {
    return FilesState._(
      files: files ?? this.files,
      searchStream: searchStream ?? this.searchStream,
      httpStates: httpStates ?? this.httpStates,
    );
  }

  @override
  List<Object?> get props => [httpStates,files,searchStream];

}
