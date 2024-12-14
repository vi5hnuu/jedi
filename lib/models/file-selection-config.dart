import 'dart:io';

class FileSelectionConfig{
  final String path;
  final List<String> limitToExtensions;//empty means all select allow
  final List<String>? excludeShowingDirsPath;
  final Function(File)? onFileClick;

  FileSelectionConfig({this.onFileClick,this.excludeShowingDirsPath,required this.path,this.limitToExtensions=const []});
}