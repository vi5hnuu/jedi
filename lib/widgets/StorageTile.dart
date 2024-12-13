import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      padding: padding ?? EdgeInsets.only(left: 16),
      child: ListTile(
        onTap:onTap,
        leading: SvgPicture.asset(leadingIconSvgPath,fit: BoxFit.contain,height: 28,),
        title: Text(title,style: TextStyle(fontSize: 18),),
        trailing: trailing,
      ),
    );
  }
}
