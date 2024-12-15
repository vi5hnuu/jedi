import 'dart:io';

import 'package:flutter/cupertino.dart';

class FileSelectionConfig{
  final String path;
  final List<String> limitToExtensions;//empty means all select allow
  final List<String>? excludeShowingDirsPath;
  final Function(RelativeRect,File)? onFileClick;

  FileSelectionConfig({this.onFileClick,this.excludeShowingDirsPath,required this.path,this.limitToExtensions=const []});
}