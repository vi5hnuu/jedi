import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jedi/state/json-files-state/jsonFiles_bloc.dart';
import 'package:jedi/utils/StoragePermissions.dart';
import 'package:lottie/lottie.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/LoggerSingleton.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? timer;
  var adsInitilized=false;

  @override
  void initState() {
    handleFileOpen().then((file) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        ),
      );

      MobileAds.instance.initialize().then((value) {
        if(!mounted) return;
        setState(()=>adsInitilized=true);
        if(timer!.isActive) return;
        LoggerSingleton().logger.i('Ads ${value.adapterStatuses.keys.join(',')} : ${value.adapterStatuses.values.join(',')}');
        goToDestination(file);
      });
      timer=Timer(const Duration(seconds: 3),(){
        if(!mounted) return;
        if(adsInitilized) goToDestination(file);
        timer?.cancel();
      });
      BlocProvider.of<JsonFilesBloc>(context).add(const CreateMainDirs());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 75,vertical: 125),
              child:LottieBuilder.asset("assets/lottie/document_loading.json",fit: BoxFit.fitWidth,animate: true,backgroundLoading: true,),
            ),
            Column(
              children: [
                SpinKitPulse(color: theme.primaryColor)
              ],
            ),
          ],
        ));
  }

  goToDestination(File? file)async{
    if(file!=null){
      if(await StoragePermissions.isStoragePermissionGranted() || await StoragePermissions.requestStoragePermissions()){
        GoRouter.of(context).goNamed(AppRoutes.jsonViewer.name,extra: {'file':file});
      }else{
        GoRouter.of(context).goNamed(AppRoutes.filesRoute.name);
      }
    }else{
      GoRouter.of(context).goNamed(AppRoutes.filesRoute.name);
    }
  }

  Future<File?> handleFileOpen() async {
    try {
      // Check for intent data
      if (!Platform.isAndroid) return null;

      // Capture intent data passed when the app is opened via a JSON file
      final intent = await const MethodChannel('app.channel.shared.data')
          .invokeMethod<String>('getSharedFile');

      if (intent != null) {
        return File(intent.startsWith("/root") ? intent.substring(5) : intent);
      }
    } catch (e) {
      LoggerSingleton().logger.e('Error in handleFileOpen: $e');
    }
    return null;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
