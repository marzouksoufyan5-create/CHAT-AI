import 'package:flutter/material.dart';

void main() {
  runApp(const ChatAiApp());
}

class ChatAiApp extends StatefulWidget {
  const ChatAiApp({super.key});

  @override
  State<ChatAiApp> createState() => _ChatAiAppState();
}

class _ChatAiAppState extends State<ChatAiApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6750A4);
    return MaterialApp(
      title: 'CHAT AI',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF8F7FC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: HomePage(onToggleTheme: _toggleTheme),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  static const tools = <(IconData, String)>[
    (Icons.chat_bubble_outline, 'محادثة ذكية'),
    (Icons.edit_note, 'الكتابة والتحرير'),
    (Icons.translate, 'الترجمة'),
    (Icons.summarize_outlined, 'تلخيص الملفات'),
    (Icons.image_outlined, 'إنشاء الصور'),
    (Icons.mic_none, 'الصوت'),
    (Icons.code, 'مساعد البرمجة'),
    (Icons.school_outlined, 'المعلم الذكي'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CHAT AI', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: 'تغيير المظهر',
              onPressed: onToggleTheme,
              icon: const Icon(Icons.brightness_6_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.tertiary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مرحباً بك في CHAT AI',
                        style: TextStyle(color: Colors.white, fontSize: 23,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('مساعدك الذكي لإنجاز المزيد كل يوم',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('اكتشف الأدوات',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tools.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final item = tools[index];
                  return Card(
                    elevation: 0,
                    color: colors.surfaceContainerHighest,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(
                            'سيتم تفعيل أداة "${item.$2}" في مرحلة الربط.',
                          )),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.$1, size: 30, color: colors.primary),
                            const SizedBox(height: 9),
                            Text(item.$2,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                child: ListTile(
                  leading: Icon(Icons.workspace_premium, color: colors.primary),
                  title: const Text('CHAT AI Premium'),
                  subtitle: const Text('مزايا وحدود استخدام أعلى — ستُفعّل لاحقاً'),
                  trailing: const Icon(Icons.arrow_back_ios_new, size: 16),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
            NavigationDestination(icon: Icon(Icons.history), label: 'المحادثات'),
            NavigationDestination(icon: Icon(Icons.apps), label: 'الأدوات'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}
