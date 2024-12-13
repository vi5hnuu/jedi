import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jedi/models/file-selection-config.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/StoragePermissions.dart';
import 'package:jedi/widgets/StorageTile.dart';
import 'package:rxdart/rxdart.dart';

class StorageStats{
  final int totalItemsInRoot;
  final int totalItemsInDownloads;
  final int totalItemsInDocuments;
  final int totalProcessedFiles;
  final int totalFileInBin;
  final bool isLoading;

  StorageStats({required this.totalItemsInRoot,required this.totalItemsInDownloads,
    this.isLoading=false,
    required this.totalItemsInDocuments, required this.totalProcessedFiles, required this.totalFileInBin});

  StorageStats copyWith({
    int? totalItemsInRoot,
    int? totalItemsInDownloads,
    int? totalItemsInDocuments,
    int? totalProcessedFiles,
    int? totalFileInBin,
    bool? isLoading,
}){
    return StorageStats(totalItemsInRoot: totalItemsInRoot ?? this.totalItemsInRoot,
        totalItemsInDownloads: totalItemsInDownloads ?? this.totalItemsInDownloads,
        isLoading: isLoading ?? this.isLoading,
        totalItemsInDocuments: totalItemsInDocuments ?? this.totalItemsInDocuments,
        totalProcessedFiles: totalProcessedFiles ?? this.totalProcessedFiles,
        totalFileInBin: totalFileInBin ?? this.totalFileInBin);
  }

  static zero(){
    return StorageStats(isLoading: true,totalItemsInRoot: 0, totalItemsInDownloads: 0, totalItemsInDocuments: 0, totalProcessedFiles: 0, totalFileInBin: 0);
  }
}

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  BehaviorSubject<StorageStats> storageStats=BehaviorSubject.seeded(StorageStats.zero());

  @override
  void initState() {
    _loadStats();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final router=GoRouter.of(context);

    return SafeArea(
      child: Column(
        children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 18.0,top: 24.0),
                child: Row(children: [
                  Text("My Storage",style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),),
                ],),
              ),
              StreamBuilder<StorageStats>(stream: storageStats.stream, builder: (context, snapshot) {
                final stats=snapshot.data;
                return Column(
                  children: [
                    StorageTile(onTap: () => router.pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(excludeShowingDirsPath: [Constants.binDirPath],path: Constants.rootStoragePath)).then((value) => _loadStats()),trailing: stats==null || stats.isLoading ? SizedBox(width: 16,child: SpinKitThreeBounce(color: Colors.white,size: 8,),) : Text(stats.totalItemsInRoot.toString(),style: const TextStyle(fontSize: 16),),leadingIconSvgPath: "assets/icons/hard-disk.svg",title: "Internal Storage",),
                    StorageTile(onTap: () => router.pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(excludeShowingDirsPath: [Constants.binDirPath],path: Constants.downloadsStoragePath)).then((value) => _loadStats()),trailing: stats==null || stats.isLoading ? SizedBox(width: 16,child: SpinKitThreeBounce(color: Colors.white,size: 8,),) : Text(stats.totalItemsInDownloads.toString(),style: const TextStyle(fontSize: 16),),leadingIconSvgPath: "assets/icons/downloads.svg",title: "Downloads",),
                    StorageTile(onTap: () => router.pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(excludeShowingDirsPath: [Constants.binDirPath],path: Constants.documentsStoragePath)).then((value) => _loadStats()),trailing: stats==null || stats.isLoading ? SizedBox(width: 16,child: SpinKitThreeBounce(color: Colors.white,size: 8,),) : Text(stats.totalItemsInDocuments.toString(),style: const TextStyle(fontSize: 16),),leadingIconSvgPath: "assets/icons/documents.svg",title: "Documents",),
                    StorageTile(onTap: () => router.pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(path: Constants.processedDirPath)).then((value) => _loadStats()),trailing: stats==null || stats.isLoading ? SizedBox(width: 16,child: SpinKitThreeBounce(color: Colors.white,size: 8,),) : Text(stats.totalProcessedFiles.toString(),style: const TextStyle(fontSize: 16),),leadingIconSvgPath: "assets/icons/folder-management.svg",title: "Processed Files",),
                  ],
                );
              },)
            ],
          ),
        ],
      ),
  );
  }

  _loadStats() async{
    try{
      if(await StoragePermissions.requestStoragePermissions()){
        await _createMainDirs();
        storageStats.sink.add(storageStats.value.copyWith(isLoading: true));
        // await Future.delayed(Duration(minutes: 5));
        final stats=await Future.wait([Directory(Constants.rootStoragePath).list(followLinks: false).length,Directory(Constants.downloadsStoragePath).list(followLinks: false).length,Directory(Constants.documentsStoragePath).list(followLinks: false).length,Directory(Constants.processedDirPath).list(followLinks: false).length,Directory(Constants.binDirPath).list(followLinks: false).length]);
        storageStats.sink.add(StorageStats(totalItemsInRoot: stats[0], totalItemsInDownloads: stats[1], totalItemsInDocuments: stats[2], totalProcessedFiles: stats[3], totalFileInBin: stats[4]));
      }else{
        NotificationService.showSnackbar(text: "Storage permission denied",color: Colors.red);
      }
    }catch(e){
      NotificationService.showSnackbar(text: "Something went wrong",color: Colors.red);
    }
  }

  Future<void> _createMainDirs() async {
    final mainDirs=[Constants.downloadsStoragePath,Constants.documentsStoragePath,Constants.processedDirPath,Constants.binDirPath];
    for (var dirPath in mainDirs) {
      final dir=Directory(dirPath);
      if(!(await dir.exists())){
        dir.create(recursive: true);
      }
    }
  }

  void _goToBin() {
    GoRouter.of(context)
        .pushNamed(AppRoutes.filesListingRoute.name,extra: FileSelectionConfig(path: Constants.binDirPath))
        .then((value)=>_loadStats());
  }
}

