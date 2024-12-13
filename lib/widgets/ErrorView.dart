import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ErrorView extends StatelessWidget {
  final Widget? subtitle;

  const ErrorView({
    super.key,
    this.subtitle
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 75,vertical: 125),
      child:Column(
        children: [
          LottieBuilder.asset("assets/lottie/error.json",fit: BoxFit.fitWidth,animate: true,backgroundLoading: true,),
          if(subtitle!=null) subtitle!
        ],
      ),
    );
  }
}
