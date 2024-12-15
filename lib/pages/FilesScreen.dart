import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jedi/models/file-selection-config.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/StoragePermissions.dart';
import 'package:jedi/utils/utility.dart';
import 'package:jedi/widgets/CustomAppBar.dart';
import 'package:jedi/widgets/StorageTile.dart';
import 'package:rxdart/rxdart.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  late final router=GoRouter.of(context);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Center(child: Text("Json Editor",style: TextStyle(color: Constants.green100,fontFamily: "bangers",letterSpacing: 2,fontSize: 28,fontWeight: FontWeight.bold),softWrap: false,overflow: TextOverflow.visible,)),
        ),
        actions: [
          IconButton(onPressed: () => GoRouter.of(context).pushNamed(AppRoutes.searchRoute.name), icon: const Icon(Icons.search,color: Constants.green100,)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 12.0,top: 24.0),
                  child: Row(children: [
                    Text("Json Storage",style: TextStyle(color: Constants.green600,fontSize: 26,fontWeight: FontWeight.w800),),
                  ],),
                ),
                Column(
                  children: [
                    StorageTile(onTap: () => router.pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(onFileClick:_onFileClick ,limitToExtensions: ['.json'],path: Constants.rootStoragePath)),leadingIconSvgPath: "assets/icons/hard-disk.svg",title: "Internal Storage",),
                    StorageTile(onTap: () => router.pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(onFileClick:_onFileClick ,limitToExtensions: ['.json'],path: Constants.downloadsStoragePath)),leadingIconSvgPath: "assets/icons/downloads.svg",title: "Downloads",),
                    StorageTile(onTap: () => router.pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(onFileClick:_onFileClick ,limitToExtensions: ['.json'],path: Constants.documentsStoragePath)),leadingIconSvgPath: "assets/icons/documents.svg",title: "Documents",),
                    StorageTile(onTap: () => router.pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(onFileClick:_onFileClick ,limitToExtensions: ['.json'],path: Constants.processedDirPath)),leadingIconSvgPath: "assets/icons/folder-management.svg",title: "Processed Json Files",),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  _onFileClick(RelativeRect position,File file){
    if(!Utility.isJsonFile(file)){
      throw Exception("Dev error, file must be json");
    }
    showMenu(context: context, position: position, items: [PopupMenuItem(child: Text("Json Viewer"),onTap: () => GoRouter.of(context).pushNamed(AppRoutes.jsonViewer.name,extra: {'file':file}),),
      PopupMenuItem(child: Text("Json Editor"),onTap: () => GoRouter.of(context).pushNamed(AppRoutes.jsonEditor.name,extra: {'file':file}),)]);
  }
}


