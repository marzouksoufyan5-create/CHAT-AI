import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const ChatAiApp());
}

class ChatAiApp extends StatelessWidget {
  const ChatAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CHAT AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF03040B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6557FF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocus = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — سيتم تفعيله عند ربط خدمات التطبيق.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF24243A),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _messageFocus.requestFocus();
      return;
    }
    _messageController.clear();
    _messageFocus.unfocus();
    _showComingSoon('واجهة المحادثة جاهزة، وسيتم ربط الذكاء الاصطناعي في المرحلة التالية');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            const _AmbientBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 12),
                                AnimatedStarLogo(),
                                SizedBox(height: 34),
                                Text(
                                  'مرحباً بك',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 39,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                    foreground: Paint()
                                      ..shader = LinearGradient(
                                        colors: [
                                          Color(0xFF37D8FF),
                                          Color(0xFF8580FF),
                                          Color(0xFFC46BFF),
                                        ],
                                      ).createShader(const Rect.fromLTWH(0, 0, 260, 60)),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24),
                                  child: Text(
                                    'كيف يمكنني مساعدتك اليوم؟',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFE7E7F0),
                                      fontSize: 21,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 36),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildComposer(),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 8),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              tooltip: 'القائمة',
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 29),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'CHAT AI',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7357FF).withValues(alpha: 0.30),
                  blurRadius: 16,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'S',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: const Color(0xD91A1C31),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFF6153E8), width: 1.25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4736E8).withValues(alpha: 0.20),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'إضافة',
              onPressed: () => _showComingSoon('إرفاق ملف'),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 31),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocus,
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'اسألني أي شيء...',
                  hintStyle: TextStyle(color: Color(0xFF9696AA), fontSize: 16),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 18),
                ),
              ),
            ),
            IconButton(
              tooltip: 'الميكروفون',
              onPressed: () => _showComingSoon('الإدخال الصوتي'),
              icon: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 27),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 7),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _sendMessage,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF25C7FF), Color(0xFF7655FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF101222),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Text(
                'CHAT AI',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(color: Color(0xFF292B42)),
            ListTile(
              leading: const Icon(Icons.add_comment_outlined),
              title: const Text('محادثة جديدة'),
              onTap: () {
                Navigator.pop(context);
                _messageController.clear();
                _messageFocus.requestFocus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('المحادثات السابقة'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('المحادثات السابقة');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded),
              title: const Text('الأدوات'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('الأدوات الذكية');
              },
            ),
            const Spacer(),
            const Divider(color: Color(0xFF292B42)),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('الإعدادات'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('الإعدادات');
              },
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'مساعدك الذكي في كل وقت',
                style: TextStyle(color: Color(0xFF85869D), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF020308),
              Color(0xFF050817),
              Color(0xFF07143B),
            ],
            stops: [0.0, 0.62, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -130,
              bottom: -170,
              child: _GlowOrb(color: Color(0xFF4714B8), size: 310),
            ),
            Positioned(
              right: -160,
              bottom: -150,
              child: _GlowOrb(color: Color(0xFF064FCB), size: 340),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 100, spreadRadius: 35)],
      ),
    );
  }
}

class AnimatedStarLogo extends StatefulWidget {
  const AnimatedStarLogo({super.key});

  @override
  State<AnimatedStarLogo> createState() => _AnimatedStarLogoState();
}

class _AnimatedStarLogoState extends State<AnimatedStarLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 235,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 2 * math.pi;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: 218,
                  height: 112,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(110, 56)),
                    border: Border.all(color: const Color(0xFF456DFF).withValues(alpha: 0.65), width: 2),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF176CFF).withValues(alpha: 0.20), blurRadius: 18),
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: -angle * 0.72,
                child: Container(
                  width: 190,
                  height: 88,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.elliptical(100, 50)),
                    border: Border.all(color: const Color(0xFFB34DFF).withValues(alpha: 0.38), width: 1.5),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(math.cos(angle) * 105, math.sin(angle) * 53),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF38D8FF),
                    boxShadow: [BoxShadow(color: Color(0xFF38D8FF), blurRadius: 12, spreadRadius: 2)],
                  ),
                ),
              ),
              const CustomPaint(
                size: Size(142, 142),
                painter: _StarPainter(),
              ),
              Positioned(
                bottom: 5,
                child: Container(
                  width: 110,
                  height: 9,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF168BFF).withValues(alpha: 0.75), blurRadius: 20, spreadRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.58, h * 0.34, w * 0.66, h * 0.42, w, h * 0.5)
      ..cubicTo(w * 0.66, h * 0.58, w * 0.58, h * 0.66, w * 0.5, h)
      ..cubicTo(w * 0.42, h * 0.66, w * 0.34, h * 0.58, 0, h * 0.5)
      ..cubicTo(w * 0.34, h * 0.42, w * 0.42, h * 0.34, w * 0.5, 0)
      ..close();

    final rect = Offset.zero & size;
    final glow = Paint()
      ..color = const Color(0xFF6C55FF).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawPath(path, glow);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF4FA8),
          Color(0xFF8B5CFF),
          Color(0xFF12CFFF),
          Color(0xFFFFD23F),
        ],
        stops: [0.0, 0.34, 0.68, 1.0],
      ).createShader(rect);
    canvas.drawPath(path, fill);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.72);
    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
