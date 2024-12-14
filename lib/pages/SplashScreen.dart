import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jedi/state/json-files-state/jsonFiles_bloc.dart';
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
      goToHome();
    });
    timer=Timer(const Duration(seconds: 3),(){
      if(!mounted) return;
      if(adsInitilized) goToHome();
    });
    BlocProvider.of<JsonFilesBloc>(context).add(const CreateMainDirs());
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

  goToHome(){
    GoRouter.of(context).goNamed(AppRoutes.filesRoute.name);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
