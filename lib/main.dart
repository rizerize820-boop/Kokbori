import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const KokboriApp());

const gold = Color(0xFFE2B85B);
const teal = Color(0xFF35D6C7);
const bg = Color(0xFF070A0B);
const panel = Color(0xFF111819);
const muted = Color(0xFF8D9997);

class KokboriApp extends StatelessWidget {
  const KokboriApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KOKBORI RP',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: bg,
          colorScheme: const ColorScheme.dark(
            primary: gold,
            secondary: teal,
            surface: panel,
          ),
          useMaterial3: true,
          fontFamily: 'Arial',
        ),
        home: const LauncherShell(),
      );
}

class LauncherShell extends StatefulWidget {
  const LauncherShell({super.key});

  @override
  State<LauncherShell> createState() => _LauncherShellState();
}

class _LauncherShellState extends State<LauncherShell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onPlay: _openGame),
      const ServersPage(),
      const MapPage(),
      const ProfilePage(),
      const SettingsPage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Expanded(child: IndexedStack(index: tab, children: pages)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        backgroundColor: const Color(0xFF0D1314),
        indicatorColor: teal.withValues(alpha: .13),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Обзор'),
          NavigationDestination(icon: Icon(Icons.dns_outlined), label: 'Серверы'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Карта'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Профиль'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Опции'),
        ],
      ),
    );
  }

  void _openGame() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameLaunchScreen()),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: gold.withValues(alpha: .65)),
                borderRadius: BorderRadius.circular(13),
                color: gold.withValues(alpha: .08),
              ),
              child: const Icon(Icons.shield_moon_outlined, color: gold, size: 25),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('KOKBORI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3.2, color: gold)),
                Text('ROLEPLAY • MOBILE', style: TextStyle(fontSize: 8, letterSpacing: 2.1, color: muted)),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: teal.withValues(alpha: .35)),
              ),
              child: const Row(children: [
                Icon(Icons.circle, color: teal, size: 7),
                SizedBox(width: 6),
                Text('BETA', style: TextStyle(color: teal, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
              ]),
            ),
          ],
        ),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onPlay});
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            height: 330,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: gold.withValues(alpha: .45)),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF26332F), Color(0xFF111718), Color(0xFF090D0E)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(right: -34, top: 28, child: Icon(Icons.shield_moon, size: 220, color: gold.withValues(alpha: .055))),
                Positioned(right: 18, bottom: 64, child: Icon(Icons.location_city_rounded, size: 118, color: teal.withValues(alpha: .08))),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: teal.withValues(alpha: .1), borderRadius: BorderRadius.circular(6)),
                        child: const Text('SAN ANDREAS • ROLE PLAY', style: TextStyle(color: teal, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.7)),
                      ),
                      const Spacer(),
                      const Text('ТВОЙ ГОРОД.\nТВОИ ПРАВИЛА.', style: TextStyle(fontSize: 30, height: 1.12, fontWeight: FontWeight.w900, letterSpacing: .4)),
                      const SizedBox(height: 10),
                      const Text('Начни свою историю в мире KOKBORI RP.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: onPlay,
                          icon: const Icon(Icons.play_arrow_rounded, size: 25),
                          label: const Text('ИГРАТЬ', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                          style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: const Color(0xFF17130B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                        ),
                      ),
                      const SizedBox(height: 9),
                      const Center(child: Text('ЛАУНЧЕР • BETA BUILD', style: TextStyle(color: muted, fontSize: 8, letterSpacing: 1.5))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle('МИР KOKBORI'),
          const SizedBox(height: 11),
          const Row(children: [
            Expanded(child: StatCard(icon: Icons.public, title: 'SAN ANDREAS', caption: 'Открытый мир')),
            SizedBox(width: 10),
            Expanded(child: StatCard(icon: Icons.groups_2_outlined, title: 'ROLEPLAY', caption: 'Живые истории')),
          ]),
          const SizedBox(height: 22),
          const SectionTitle('СТАТУС ПРОЕКТА'),
          const SizedBox(height: 11),
          const Panel(child: Row(children: [
            Icon(Icons.construction_rounded, color: gold, size: 25),
            SizedBox(width: 12),
            Expanded(child: Text('Лаунчер находится в разработке. Игровой движок пока не подключён.', style: TextStyle(color: Colors.white70, height: 1.4, fontSize: 12))),
          ])),
        ],
      );
}

class ServersPage extends StatelessWidget {
  const ServersPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SectionTitle('ИГРОВЫЕ СЕРВЕРЫ'),
          const SizedBox(height: 8),
          const Text('Выбери мир, в котором начнётся твоя история.', style: TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 16),
          const ServerCard(name: 'KOKBORI ROLEPLAY', number: '01', status: 'СКОРО ОТКРЫТИЕ'),
          const SizedBox(height: 10),
          const ServerCard(name: 'KOKBORI TEST', number: '02', status: 'ТЕСТОВЫЙ СЕРВЕР'),
          const SizedBox(height: 16),
          const Text('Адреса и онлайн появятся после подключения серверной части.', style: TextStyle(color: muted, fontSize: 11)),
        ],
      );
}

class ServerCard extends StatelessWidget {
  const ServerCard({super.key, required this.name, required this.number, required this.status});
  final String name, number, status;

  @override
  Widget build(BuildContext context) => Panel(
        child: Row(children: [
          Text(number, style: const TextStyle(color: gold, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 5),
            Text(status, style: const TextStyle(color: teal, fontSize: 9, letterSpacing: 1.1)),
          ])),
          const Icon(Icons.lock_outline, color: muted, size: 19),
        ]),
      );
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: const [
          SectionTitle('КАРТА SAN ANDREAS'),
          SizedBox(height: 12),
          Panel(child: Column(children: [
            Icon(Icons.map_rounded, color: teal, size: 58),
            SizedBox(height: 14),
            Text('Карта игрового мира', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Text('Здесь появится карта с городами, районами и важными точками.', textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5, fontSize: 12)),
          ])),
        ],
      );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final controller = TextEditingController();
  String nickname = 'Гость';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SectionTitle('ПРОФИЛЬ ИГРОКА'),
          const SizedBox(height: 12),
          Panel(child: Column(children: [
            const CircleAvatar(radius: 39, backgroundColor: Color(0xFF27332F), child: Icon(Icons.person_rounded, color: gold, size: 43)),
            const SizedBox(height: 12),
            Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 22),
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Игровой ник', hintText: 'Например: Player_Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                setState(() => nickname = controller.text.trim());
              },
              child: const Text('СОХРАНИТЬ НИК'),
            )),
            const SizedBox(height: 8),
            const Text('Пока сохраняется только на экране профиля.', style: TextStyle(color: muted, fontSize: 10)),
          ])),
        ],
      );
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;
  bool vibration = true;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SectionTitle('НАСТРОЙКИ'),
          const SizedBox(height: 12),
          Panel(child: Column(children: [
            SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: teal, title: const Text('Уведомления'), value: notifications, onChanged: (v) => setState(() => notifications = v)),
            const Divider(color: Colors.white12),
            SwitchListTile(contentPadding: EdgeInsets.zero, activeThumbColor: teal, title: const Text('Вибрация'), value: vibration, onChanged: (v) => setState(() => vibration = v)),
          ])),
          const SizedBox(height: 12),
          const Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('KOKBORI RP', style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
            SizedBox(height: 6),
            Text('Версия 1.1.0 • Launcher beta', style: TextStyle(color: muted, fontSize: 11)),
          ])),
        ],
      );
}

class GameLaunchScreen extends StatefulWidget {
  const GameLaunchScreen({super.key});

  @override
  State<GameLaunchScreen> createState() => _GameLaunchScreenState();
}

class _GameLaunchScreenState extends State<GameLaunchScreen> {
  @override
  void initState() {
    super.initState();
    _setLandscape();
  }

  Future<void> _setLandscape() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _close() async {
    await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF080C0D),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(children: [
                  const Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('KOKBORI RP', style: TextStyle(color: gold, fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: 3)),
                      SizedBox(height: 12),
                      Text('ИГРОВОЙ КЛИЕНТ НЕ ПОДКЛЮЧЁН', style: TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.3)),
                      SizedBox(height: 8),
                      Text('Экран уже переключён в горизонтальный режим. Для входа в саму игру требуется совместимый SA-MP/CRMP игровой движок и сервер.', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
                    ],
                  )),
                  const SizedBox(width: 24),
                  SizedBox(height: 48, child: FilledButton.icon(
                    onPressed: _close,
                    icon: const Icon(Icons.close),
                    label: const Text('ВЕРНУТЬСЯ'),
                    style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: bg),
                  )),
                ]),
              ),
            ),
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.8));
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.icon, required this.title, required this.caption});
  final IconData icon;
  final String title, caption;

  @override
  Widget build(BuildContext context) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: teal, size: 24),
    const SizedBox(height: 12),
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    const SizedBox(height: 4),
    Text(caption, style: const TextStyle(color: muted, fontSize: 10)),
  ]));
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
        ),
        child: child,
      );
}
