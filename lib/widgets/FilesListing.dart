import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jedi/models/file-selection-config.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/state/json-files-state/jsonFiles_bloc.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/httpStates.dart';
import 'package:jedi/widgets/BannerAdd.dart';
import 'package:jedi/widgets/DirectoryFilesListing.dart';

class FilesListing extends StatelessWidget {
  final FileSelectionConfig config;

  const FilesListing({super.key,required this.config});

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
      body: Flex(direction: Axis.vertical,children: [
        Expanded(child: DirectoryFilesListing(onFileClick: config.onFileClick,excludeShowingDirsPath: config.excludeShowingDirsPath,directoryPath: config.path)),
        const BannerAdd()
      ],),
    );
  }
}
