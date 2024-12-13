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
  final VoidCallback? onPress;
  final VoidCallback? onDelete;
  const FileTile({super.key,required this.file,this.enabled=true,this.selected=false,this.onPress,this.onDelete});

  @override
  Widget build(BuildContext context) {
    final fileIcon=Constants.fileIcons[file is Directory ? 'folder' : file.path.split('.').last];

    return ListTile(
        enabled: enabled,
        selected: selected,
        selectedTileColor: Colors.green.withOpacity(0.15),
        selectedColor: Colors.green,
        leading: file is Directory
            ? fileIcon!=null ? Image.asset(fileIcon,width: 24,fit: BoxFit.fitWidth,) : const Icon(FontAwesomeIcons.solidFolder,
            color: Colors.yellowAccent)
            : fileIcon!=null ? Image.asset(fileIcon,width: 24,fit: BoxFit.fitWidth,) : const Icon(FontAwesomeIcons.file,
            color: Colors.orange),
        title: Text(file.path.split('/').last),
        trailing: file is File ? IconButton(onPressed: onDelete, icon: Icon(Icons.delete,color: onDelete!=null? Colors.red:Colors.grey)) : null,
        subtitle: (file is! Directory) ? Text(Utility.bytesToSize(File(file.path).lengthSync())) : null,
        onTap:onPress
    );
  }
}