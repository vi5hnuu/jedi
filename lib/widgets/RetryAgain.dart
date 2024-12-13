import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RetryAgain extends StatelessWidget {
  final Function()? onRetry;
  final String error;

  const RetryAgain({
    super.key,
    required this.onRetry,
    required this.error
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.refresh,color: Colors.red,size: 55),
          Text(error,style: const TextStyle(color: Colors.red,fontSize: 16))
        ],
      ),
    );
  }
}
