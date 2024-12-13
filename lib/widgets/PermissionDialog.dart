import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jedi/utils/StoragePermissions.dart';

class PermissionInfoDialog extends StatelessWidget {
  final Function(bool) onAction;

  PermissionInfoDialog({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Permission Request",textAlign: TextAlign.center,style: TextStyle(fontWeight: FontWeight.bold),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.security,
            size: 48,
            color: Colors.blueAccent,
          ),
          SizedBox(height: 16),
          Text(
            "This app requires certain permissions to function properly.",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "We need access to files and media to provide features like organizing your documents. "
                "We do not read, delete, or harm your files without your explicit permission.",
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 8),
          Text(
            "Your privacy is our priority. We do not collect, store, or share any of your personal information.",
            textAlign: TextAlign.justify,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: ()=>onAction(false),
          child: Text("Decline"),
        ),
        ElevatedButton(
          onPressed: () async =>onAction(await StoragePermissions.requestStoragePermissions()),
          child: Text("Grant Permission"),
        ),
      ],
    );
  }
}
