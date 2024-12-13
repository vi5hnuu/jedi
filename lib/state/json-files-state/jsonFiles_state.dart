part of 'jsonFiles_bloc.dart';

@Immutable("cannot modify aarti state")
class JsonFilesState extends Equatable with WithHttpState {
  final List<FileSystemEntity> files;
  final Stream<List<File>>? searchStream;

  JsonFilesState._({
    this.files=const [],
    this.searchStream,
    Map<String,HttpState>? httpStates,
  }){
    this.httpStates.addAll(httpStates ?? {});
  }

  JsonFilesState.initial() : this._(httpStates: const {});

  JsonFilesState copyWith({
    Map<String, HttpState>? httpStates,
  List<FileSystemEntity>? files,
    Stream<List<File>>? searchStream,
  }) {
    return JsonFilesState._(
      files: files ?? this.files,
      searchStream: searchStream ?? this.searchStream,
      httpStates: httpStates ?? this.httpStates,
    );
  }

  @override
  List<Object?> get props => [httpStates,files,searchStream];

}
