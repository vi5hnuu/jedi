import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/utility.dart';

class FileTile extends StatelessWidget {
  final FileSystemEntity file;
  final bool enabled;
  final bool selected;
  final Function(Offset)? onPress;
  const FileTile({super.key,required this.file,this.enabled=true,this.selected=false,this.onPress});

  @override
  Widget build(BuildContext context) {
    final fileIcon=Constants.fileIcons[file is Directory ? 'folder' : file.path.split('.').last];

    return GestureDetector(
      onTapUp:onPress!=null ? (details) => onPress!(details.globalPosition):null,
      child: ListTile(
          enabled: enabled,
          selected: selected,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          splashColor: Constants.green300,
          tileColor: Constants.green500.withOpacity(0.1),
          selectedTileColor: Colors.green.withOpacity(0.15),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12,vertical: 0),
          selectedColor: Colors.green,
          leading: file is Directory
              ? fileIcon!=null ? Image.asset(fileIcon,width: 32,fit: BoxFit.fitWidth,) : const Icon(FontAwesomeIcons.solidFolder, color: Colors.yellowAccent)
              : fileIcon!=null ? Image.asset(fileIcon,width: 32,fit: BoxFit.fitWidth,) : const Icon(FontAwesomeIcons.file,
              color: Colors.orange),
          title: Text(file.path.split('/').last),
          subtitle: (file is! Directory) ? Text(Utility.bytesToSize(File(file.path).lengthSync())) : null,
      ),
    );
  }
}