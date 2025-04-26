import 'package:flutter/material.dart';

class BackgroundContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final String backgroundImage;

  const BackgroundContainer({
    Key? key,
    required this.child,
    this.backgroundColor = Colors.white,
    this.backgroundImage = 'assets/bg1.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: backgroundColor.withOpacity(0.0),
        child: child,
      ),
    );
  }
}
