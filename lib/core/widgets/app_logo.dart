import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSubtitle;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.showSubtitle = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[600]!, Colors.blue[700]!],
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // House Icon (Top Left)
              Positioned(
                top: size * 0.15,
                left: size * 0.15,
                child: Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: size * 0.3,
                ),
              ),
              // Document Icon (Right)
              Positioned(
                top: size * 0.25,
                right: size * 0.15,
                child: Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: size * 0.25,
                ),
              ),
              // BM Text (Bottom Center)
              Positioned(
                bottom: size * 0.15,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'BM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.225,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // App Name
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
            'BariManager',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
        ],

        // Subtitle
        if (showSubtitle && subtitle != null) ...[
          SizedBox(height: size * 0.05),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: size * 0.175,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
