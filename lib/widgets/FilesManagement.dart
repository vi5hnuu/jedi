import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jedi/models/file-selection-config.dart';
import 'package:jedi/widgets/DirectoryFilesListing.dart';

class FilesManagement extends StatefulWidget {
  final FileSelectionConfig config;

  const FilesManagement({super.key, required this.config});

  @override
  State<FilesManagement> createState() => _FilesManagementState();
}

class _FilesManagementState extends State<FilesManagement> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final router=GoRouter.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("File Management"),
      ),
      body: SafeArea(
        child: DirectoryFilesListing(minSelection: widget.config.minSelection,onDoneSelection: widget.config.multiSelect==null ? null : (files){
          final result={'files':files};
          if(widget.config.redirectPath==null) {
            router.pop(result);
          } else {
            router.push(widget.config.redirectPath!,extra: result);
          }
        } ,directoryPath: widget.config.path,multiSelect: widget.config.multiSelect,limitSelectionToExtensions: widget.config.limitToExtensions),
      ),
    );
  }
}
