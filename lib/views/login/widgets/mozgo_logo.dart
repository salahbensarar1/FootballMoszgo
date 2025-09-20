import 'package:flutter/material.dart';

class MozGoLogo extends StatelessWidget {
  final bool isSmallScreen;

  const MozGoLogo({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSmallScreen ? 300 : 340,
      height: isSmallScreen ? 160 : 180,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _buildBackgroundShapes(),
          _buildMainContent(),
          _buildDecorativeElements(),
        ],
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -20,
          left: -15,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
        Positioned(
          bottom: -25,
          right: -20,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 20,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogoRow(),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildClubInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -0.3,
          child: Container(
            width: 4,
            height: isSmallScreen ? 16 : 20,
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'moz',
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 32,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2D3748),
            letterSpacing: -1,
            height: 1.0,
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: isSmallScreen ? 44 : 50,
                height: isSmallScreen ? 44 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE31E24),
                      Color(0xFFC41E3A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE31E24).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              Text(
                'GO',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        Transform.rotate(
          angle: 0.2,
          child: Icon(
            Icons.sports_soccer,
            size: isSmallScreen ? 18 : 22,
            color: const Color(0xFF2D3748).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Transform.rotate(
          angle: 0.4,
          child: Container(
            width: 4,
            height: isSmallScreen ? 12 : 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClubInfo() {
    return Column(
      children: [
        Container(
          width: isSmallScreen ? 60 : 80,
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFFE31E24),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          'NAGYKŐRÖS',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D3748),
            letterSpacing: 1.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'LABDARÚGÓ KLUB',
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF718096),
            letterSpacing: 1.2,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildDecorativeElements() {
    return Stack(
      children: [
        Positioned(
          bottom: 15,
          left: 20,
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
        Positioned(
          top: 25,
          left: 60,
          child: Transform.rotate(
            angle: 0.5,
            child: Container(
              width: 2,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFFE31E24).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}