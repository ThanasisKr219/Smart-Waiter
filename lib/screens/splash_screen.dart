import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _entranceFade;
  late final Animation<double> _entranceScale;
  late final Animation<double> _snapGap;
  late final Animation<double> _unfoldFactor;
  late final Animation<double> _monogramScale;
  late final Animation<double> _dashesSlide;
  late final Animation<double> _lineExpand;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _entranceFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
    );
    _entranceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.26),
      ),
    );
    _snapGap = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 28.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 28.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 65,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.28, 0.70),
      ),
    );
    _unfoldFactor = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.72, curve: Curves.easeInOutCubic),
    );
    _monogramScale = Tween<double>(begin: 1.42, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.72, curve: Curves.easeInOutCubic),
      ),
    );
    _dashesSlide = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.35, curve: Curves.easeOutBack),
      ),
    );
    _lineExpand = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.88, curve: Curves.easeOutExpo),
    );
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.68, 0.95, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.95, curve: Curves.easeOutCubic),
      ),
    );
  }

  Future<void> _startInitialization() async {
    final dataFuture = StorageService.loadData();
    final animationFuture = _controller.forward();
    final minimumDurationFuture =
        Future<void>.delayed(const Duration(milliseconds: 2800));
    final results = await Future.wait<Object?>([
      dataFuture,
      animationFuture,
      minimumDurationFuture,
    ]);

    if (!mounted) return;
    final data = results.first as AppStorageData?;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainScreen(initialData: data),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101B2A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final baseFontSize =
              (constraints.maxWidth * 0.11).clamp(44.0, 96.0);
          final dashHeight = (baseFontSize * 0.11).clamp(5.0, 10.0);
          final topDashWidth = baseFontSize * 0.38;
          final bottomDashWidth = baseFontSize * 0.58;
          final maxLineWidth =
              (constraints.maxWidth * 0.65).clamp(240.0, 520.0);
          final taglineFontSize = (baseFontSize * 0.19).clamp(11.0, 18.0);

          const whiteStyle = TextStyle(
            color: Color(0xFFEAF4F5),
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -1.5,
          );
          const cyanStyle = TextStyle(
            color: Color(0xFF50D6D1),
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -1.5,
          );

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final scale = _entranceScale.value * _monogramScale.value;

                  return Opacity(
                    opacity: _entranceFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Transform.scale(
                            scale: scale,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: Offset(_dashesSlide.value, 0),
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: baseFontSize * 0.18,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        _buildDash(topDashWidth, dashHeight),
                                        SizedBox(height: dashHeight * 1.1),
                                        _buildDash(
                                          bottomDashWidth,
                                          dashHeight,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(
                                  'S',
                                  style: whiteStyle.copyWith(
                                    fontSize: baseFontSize,
                                  ),
                                ),
                                _buildUnfoldingText(
                                  'WIFT ',
                                  whiteStyle.copyWith(fontSize: baseFontSize),
                                ),
                                SizedBox(width: _snapGap.value),
                                Text(
                                  'D',
                                  style: cyanStyle.copyWith(
                                    fontSize: baseFontSize,
                                  ),
                                ),
                                _buildUnfoldingText(
                                  'ASH',
                                  cyanStyle.copyWith(fontSize: baseFontSize),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: baseFontSize * 0.22),
                        Container(
                          width: maxLineWidth * _lineExpand.value,
                          height: 2.5,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF50D6D1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: baseFontSize * 0.20),
                        SlideTransition(
                          position: _taglineSlide,
                          child: Opacity(
                            opacity: _taglineFade.value,
                            child: Text(
                              'EFFORTLESS TABLESIDE ORDERING',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF8296A5),
                                fontSize: taglineFontSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnfoldingText(String text, TextStyle style) {
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: _unfoldFactor.value,
        child: Opacity(
          opacity: _unfoldFactor.value,
          child: Text(text, style: style),
        ),
      ),
    );
  }

  Widget _buildDash(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF50D6D1),
        borderRadius: BorderRadius.circular(height),
      ),
    );
  }
}
