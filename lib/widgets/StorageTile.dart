import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jedi/utils/Constants.dart';

class StorageTile extends StatelessWidget {
  final String leadingIconSvgPath;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const StorageTile({
    super.key,
    this.onTap,
    this.padding,
    required this.leadingIconSvgPath,
    required this.title,
    required this.trailing
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 12,vertical: 4),
      child: ListTile(
        onTap:onTap,
        shape: OutlineInputBorder(borderRadius: BorderRadius.circular(8),borderSide: BorderSide.none),
        splashColor: Constants.green200,
        tileColor: Colors.white.withOpacity(0.4),
        leading: SvgPicture.asset(leadingIconSvgPath,fit: BoxFit.contain,height: 28,),
        title: Text(title,style: TextStyle(fontWeight: FontWeight.w600,fontSize: 18),),
        trailing: trailing,
      ),
    );
  }
}
