import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import 'package:RXrail/app/utils/app_assets.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AnimatedFancyBackground(),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GlowPulseLogo(),

                SizedBox(height: 20.h),

                Text(
                  'RX RAIL',
                  style: TextStyle(
                    fontSize: 38.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),

                SizedBox(height: 8.h),

                SlideUpText(
                  child: Text(
                    'Railway Proximity IntelAlert',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white70,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: 40.h),

                Container(
                  width: 80.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orangeAccent, Colors.amberAccent],
                    ),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFancyBackground extends StatefulWidget {
  const _AnimatedFancyBackground();

  @override
  State<_AnimatedFancyBackground> createState() => _FancyBGState();
}

class _FancyBGState extends State<_AnimatedFancyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1, _color2;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 5))
      ..repeat(reverse: true);

    _color1 = ColorTween(
      begin: const Color(0xFF0f0f1a),
      end: const Color(0xFF1a1a2e),
    ).animate(_controller);
    _color2 = ColorTween(
      begin: const Color(0xFF1a1a2e),
      end: const Color(0xFF0f0f1a),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_color1.value!, _color2.value!],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
        );
      },
    );
  }
}

class GlowPulseLogo extends StatefulWidget {
  const GlowPulseLogo({super.key});

  @override
  State<GlowPulseLogo> createState() => _GlowPulseLogoState();
}

class _GlowPulseLogoState extends State<GlowPulseLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.97, end: 1.05).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glow = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose(); // <-- Important! This was missing
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withOpacity(_glow.value),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              AppAssets.crossIcon1Img,
              width: 170.w,
              height: 170.w,
            ),
          ),
        );
      },
    );
  }
}

class SlideUpText extends StatefulWidget {
  final Widget child;

  const SlideUpText({super.key, required this.child});

  @override
  State<SlideUpText> createState() => _SlideUpTextState();
}

class _SlideUpTextState extends State<SlideUpText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _offset = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose(); // <-- Important! This was missing
  }




  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: widget.child,
    );
  }
}
