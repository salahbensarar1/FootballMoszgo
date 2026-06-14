import 'package:flutter/material.dart';
import 'package:footballtraining/core/widgets/gradient_widgets.dart';

class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingStateWidget({
    super.key,
    this.message,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingSpinner(
        size: size,
        message: message ?? 'Loading...',
      ),
    );
  }
}
