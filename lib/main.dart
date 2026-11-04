import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
  );
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
        fontFamily: 'sans-serif',
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
  final AudioRecorder _audioRecorder = AudioRecorder();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<PlatformFile> _attachments = [];
  final List<Map<String, String>> _messages = [];
  late final GenerativeModel _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-3.8-flash');
  bool _isSending = false;
  bool _isRecording = false;
  bool _isDictating = false;
  bool get _hasMessage => _messageController.text.trim().isNotEmpty || _attachments.isNotEmpty;

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocus.dispose();
    _audioRecorder.dispose();
    _speech.stop();
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _attachments.isEmpty) {
      _messageFocus.requestFocus();
      return;
    }
    if (_attachments.isNotEmpty) {
      _showComingSoon('تم استلام النص. تحليل الصور والملفات سيضاف في المرحلة التالية.');
      if (message.isEmpty) return;
    }
    _messageController.clear();
    _messageFocus.unfocus();
    setState(() {
      _messages.add({'role': 'user', 'text': message});
      _isSending = true;
    });
    try {
      final response = await _model.generateContent([Content.text(message)]);
      final answer = response.text?.trim();
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': (answer == null || answer.isEmpty) ? 'لم يصل رد نصي. حاول مرة أخرى.' : answer});
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'تعذر الاتصال بخدمة Gemini. تحقق من تفعيل Firebase AI Logic وإعداد App Check والاتصال بالإنترنت.\n\nالتفاصيل: $error'});
        _isSending = false;
      });
    }
  }

  Future<void> _pickMedia() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: true);
      if (picked == null || !mounted) return;
      setState(() => _attachments.addAll(picked.files));
      _showComingSoon('تم اختيار الملفات. إرسالها وتحليلها يحتاج ربط الخادم.');
    } catch (error) {
      _showComingSoon('تعذر فتح ملفات الهاتف: ' + error.toString());
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        final path = await _audioRecorder.stop();
        if (!mounted) return;
        setState(() => _isRecording = false);
        if (path != null) {
          final name = path.split('/').last;
          setState(() => _attachments.add(PlatformFile(name: name, path: path, size: 0)));
          _showComingSoon('تم حفظ التسجيل وإرفاقه. تفريغه وفهمه والرد عليه يتطلب ربط خدمة الذكاء الاصطناعي.');
        }
      } catch (error) {
        if (mounted) setState(() => _isRecording = false);
        _showComingSoon('تعذر إيقاف التسجيل: ' + error.toString());
      }
      return;
    }
    try {
      if (!await _audioRecorder.hasPermission()) {
        _showComingSoon('يرجى السماح باستخدام الميكروفون');
        return;
      }
      final directory = await getTemporaryDirectory();
      final path = directory.path + '/chat_ai_' + DateTime.now().millisecondsSinceEpoch.toString() + '.m4a';
      await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
      if (mounted) setState(() => _isRecording = true);
    } catch (error) {
      _showComingSoon('تعذر بدء التسجيل: ' + error.toString());
    }
  }

  Future<void> _toggleDictation() async {
    if (_isDictating) {
      await _speech.stop();
      if (mounted) setState(() => _isDictating = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) setState(() => _isDictating = false);
        },
        onError: (error) {
          if (mounted) {
            setState(() => _isDictating = false);
            _showComingSoon('تعذر التعرف على الكلام: ' + error.errorMsg);
          }
        },
      );
      if (!available) {
        _showComingSoon('خدمة تحويل الكلام إلى نص غير متاحة على هذا الجهاز');
        return;
      }
      if (mounted) setState(() => _isDictating = true);
      await _speech.listen(onResult: (speechResult) {
        _messageController.text = speechResult.recognizedWords;
        _messageController.selection = TextSelection.collapsed(offset: _messageController.text.length);
      });
    } catch (error) {
      if (mounted) setState(() => _isDictating = false);
      _showComingSoon('تعذر تشغيل الإملاء الصوتي: ' + error.toString());
    }
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
                    child: _messages.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 12),
                                      const AnimatedStarLogo(),
                                      const SizedBox(height: 34),
                                      ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          colors: [Color(0xFF42E8FF), Color(0xFF9B75FF), Color(0xFFFF72D2)],
                                        ).createShader(bounds),
                                        child: const Text('مرحباً بك في CHAT AI', textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white, fontSize: 31, height: 1.35, fontWeight: FontWeight.w900)),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text('رفيقك الذكي للإجابة والإبداع والإنجاز', textAlign: TextAlign.center,
                                        style: TextStyle(color: Color(0xFFBFC8E8), fontSize: 16)),
                                      const SizedBox(height: 7),
                                      const Text('كيف يمكنني مساعدتك اليوم؟', textAlign: TextAlign.center,
                                        style: TextStyle(color: Color(0xFFF4F4FF), fontSize: 21, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 36),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            itemCount: _messages.length + (_isSending ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isSending && index == _messages.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Align(alignment: Alignment.centerRight, child: CircularProgressIndicator()),
                                );
                              }
                              final item = _messages[index];
                              final isUser = item['role'] == 'user';
                              return Align(
                                alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 330),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isUser ? const Color(0xFF37306F) : const Color(0xFF171A35),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: const Color(0xFF6153E8).withValues(alpha: 0.5)),
                                  ),
                                  child: SelectableText(item['text'] ?? '', textDirection: TextDirection.rtl,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
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
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF45E7FF), Color(0xFF9C68FF), Color(0xFFFF67D4)],
            ).createShader(bounds),
            child: const Text(
              'CHAT AI',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'sans-serif-black',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.3,
              ),
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

  Widget _buildAiTools() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'أدوات الذكاء الاصطناعي',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFE9E7FF),
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 2.35,
            children: [
              _toolCard('محادثة ذكية', Icons.chat_bubble_outline_rounded, const Color(0xFF39D5FF)),
              _toolCard('إنشاء الصور', Icons.auto_awesome_rounded, const Color(0xFFB77BFF)),
              _toolCard('كتابة المحتوى', Icons.edit_note_rounded, const Color(0xFFFF79C8)),
              _toolCard('الترجمة', Icons.translate_rounded, const Color(0xFF51DDBB)),
              _toolCard('تلخيص النصوص', Icons.summarize_rounded, const Color(0xFFFFC45C)),
              _toolCard('مساعدة برمجية', Icons.code_rounded, const Color(0xFF7D9CFF)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolCard(String title, IconData icon, Color accent) {
    return Material(
      color: const Color(0xCC171A35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showComingSoon(title),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 25),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF1F1FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_attachments.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: const Color(0xCC171A35), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF6153E8))),
            child: Wrap(spacing: 6, runSpacing: 6, children: List.generate(_attachments.length, (index) {
              final file = _attachments[index];
              return Chip(
                avatar: const Icon(Icons.attach_file_rounded, size: 16),
                label: SizedBox(width: 105, child: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                onDeleted: () => setState(() => _attachments.removeAt(index)),
              );
            })),
          ),
        if (_isDictating) const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('أستمع إليك... تحدث الآن', style: TextStyle(color: Color(0xFF55DFFF)))),
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(color: const Color(0xD91A1C31), borderRadius: BorderRadius.circular(40), border: Border.all(color: const Color(0xFF6153E8), width: 1.25), boxShadow: [BoxShadow(color: const Color(0xFF4736E8).withValues(alpha: 0.20), blurRadius: 24, spreadRadius: 1)]),
          child: Row(children: [
            IconButton(tooltip: 'إرفاق صورة أو فيديو', onPressed: _pickMedia, icon: const Icon(Icons.add_rounded, color: Colors.white, size: 31)),
            Expanded(child: TextField(controller: _messageController, focusNode: _messageFocus, textDirection: TextDirection.rtl, textInputAction: TextInputAction.send, onChanged: (_) => setState(() {}), onSubmitted: (_) => _sendMessage(), style: const TextStyle(color: Colors.white, fontSize: 16), decoration: const InputDecoration(hintText: 'اسألني أي شيء...', hintStyle: TextStyle(color: Color(0xFF9696AA), fontSize: 16), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 18)))),
            IconButton(tooltip: _isDictating ? 'إيقاف الإملاء' : 'تحويل الكلام إلى نص', onPressed: _toggleDictation, icon: Icon(_isDictating ? Icons.mic_rounded : Icons.mic_none_rounded, color: _isDictating ? const Color(0xFFFF668E) : Colors.white, size: 27)),
            Padding(padding: const EdgeInsetsDirectional.only(end: 7), child: Material(color: Colors.transparent, child: InkWell(onTap: _hasMessage ? _sendMessage : _toggleRecording, customBorder: const CircleBorder(), child: Ink(width: 54, height: 54, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: _isRecording ? const [Color(0xFFFF477E), Color(0xFFFF8A55)] : const [Color(0xFF25C7FF), Color(0xFF7655FF)])), child: Icon(_isRecording ? Icons.stop_rounded : (_hasMessage ? Icons.send_rounded : Icons.graphic_eq_rounded), color: Colors.white, size: 27))))),
          ]),
        ),
        const SizedBox(height: 5),
        const Text('أرفق الصور والفيديوهات أو اكتب رسالتك أو سجّل صوتك', style: TextStyle(color: Color(0xFF85869D), fontSize: 11)),
      ]),
    );
  }

  void _openAiTools() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (pageContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFF03040B),
            appBar: AppBar(
              title: const Text(
                'أدوات الذكاء الاصطناعي',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              backgroundColor: const Color(0xFF080B1B),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Stack(
              children: [
                const _AmbientBackground(),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 28, bottom: 30),
                    child: _buildAiTools(),
                  ),
                ),
              ],
            ),
          ),
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
              title: const Text('أدوات الذكاء الاصطناعي'),
              subtitle: const Text(
                'الصور والكتابة والترجمة والبرمجة',
                style: TextStyle(color: Color(0xFF85869D), fontSize: 11),
              ),
              onTap: _openAiTools,
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
