import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/utils/StoragePermissions.dart';
import 'package:jedi/widgets/ErrorView.dart';

enum ErrorReason{
  STORAGE_PERMISSION_DENIED
}

class Errorpage extends StatefulWidget {
  final ErrorReason? reason;

  const Errorpage({super.key,this.reason});

  @override
  State<Errorpage> createState() => _ErrorpageState();
}

class _ErrorpageState extends State<Errorpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black26,
      appBar: AppBar(title: ErrorReason.STORAGE_PERMISSION_DENIED==widget.reason ? Text("No Storage permission") : Text("Something went wrong"),backgroundColor: Colors.red,elevation: 10,),
      body: ErrorView(subtitle: getSubTitle()),
    );
  }

  Widget? getSubTitle(){
    switch(widget.reason){
      case ErrorReason.STORAGE_PERMISSION_DENIED:{
        return Column(
          children: [
            Text("We need storage permision to operate.",textAlign: TextAlign.center,style: TextStyle(color: Colors.grey,fontWeight: FontWeight.bold,fontSize: 16),),
            Container(padding: EdgeInsets.symmetric(vertical: 12),width: double.infinity,child: OutlinedButton(onPressed: () async{
              final granted=await StoragePermissions.requestStoragePermissions();
              if(granted) GoRouter.of(context).goNamed(AppRoutes.filesRoute.name);
              else {
                NotificationService.showSnackbar(text: "Permission denied",color: Colors.red);
              }
            }, child: Text("Allow Permission",style: TextStyle(color: Colors.white),)))
          ],
        );
      }
      default: return null;
    }
  }
}


