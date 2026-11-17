import 'package:flutter/material.dart';

void main() {
  runApp(const KokboriApp());
}

const Color gold = Color(0xFFD8AD52);
const Color turquoise = Color(0xFF31D4C5);
const Color background = Color(0xFF090C0D);
const Color surface = Color(0xFF151B1C);

class KokboriApp extends StatelessWidget {
  const KokboriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KOKBORI RP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: turquoise,
          surface: surface,
        ),
        useMaterial3: true,
        fontFamily: 'Arial',
      ),
      home: const LauncherShell(),
    );
  }
}

class LauncherShell extends StatefulWidget {
  const LauncherShell({super.key});

  @override
  State<LauncherShell> createState() => _LauncherShellState();
}

class _LauncherShellState extends State<LauncherShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onPlay: _showNotConnected),
      const MapPage(),
      const ProfilePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        backgroundColor: const Color(0xFF111617),
        indicatorColor: turquoise.withValues(alpha: 0.14),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Карта',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }

  void _showNotConnected() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Игровой клиент ещё не подключён. Сейчас это лаунчер-прототип.',
        ),
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: gold, size: 29),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'KOKBORI',
              style: TextStyle(
                color: gold,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: turquoise.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: turquoise, size: 7),
                SizedBox(width: 7),
                Text(
                  'MOBILE',
                  style: TextStyle(
                    color: turquoise,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onPlay});

  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: gold.withValues(alpha: 0.45)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF27302B), Color(0xFF111617)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ROLE PLAY • SAN ANDREAS',
                style: TextStyle(
                  color: turquoise,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'ТВОЯ ИСТОРИЯ\nНАЧИНАЕТСЯ ЗДЕСЬ',
                style: TextStyle(
                  fontSize: 27,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Добро пожаловать в KOKBORI RP. '
                'Твой мобильный игровой портал.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('ВОЙТИ В ИГРУ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: const Color(0xFF17130C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'ДЕМО-ВЕРСИЯ • ИГРОВОЙ ДВИЖОК НЕ ПОДКЛЮЧЁН',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 9),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle(title: 'ПРОЕКТ'),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: InfoTile(
                icon: Icons.public,
                title: 'San Andreas',
                subtitle: 'Игровой мир',
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InfoTile(
                icon: Icons.groups_outlined,
                title: 'Role Play',
                subtitle: 'Игровой режим',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SectionTitle(title: 'ПОСЛЕДНИЕ НОВОСТИ'),
        const SizedBox(height: 10),
        const CardPanel(
          child: Row(
            children: [
              Icon(Icons.campaign_outlined, color: gold, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Лаунчер KOKBORI RP находится в разработке.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: const [
        SectionTitle(title: 'КАРТА SAN ANDREAS'),
        SizedBox(height: 12),
        CardPanel(
          child: Column(
            children: [
              Icon(Icons.map_outlined, color: turquoise, size: 54),
              SizedBox(height: 14),
              Text(
                'Карта появится позже',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Здесь можно будет разместить карту игрового мира '
                'и отметки важных мест.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final controller = TextEditingController();
  String nickname = 'Игрок';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SectionTitle(title: 'ПРОФИЛЬ ИГРОКА'),
        const SizedBox(height: 12),
        CardPanel(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFF29332F),
                child: Icon(Icons.person, color: gold, size: 42),
              ),
              const SizedBox(height: 12),
              Text(
                nickname,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Игровой ник',
                  hintText: 'Например, Kokbori_Player',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) return;
                    setState(() => nickname = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ник обновлён в текущем сеансе.'),
                      ),
                    );
                  },
                  child: const Text('СОХРАНИТЬ НИК'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool highGraphics = true;
  bool vibration = true;
  bool notifications = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SectionTitle(title: 'НАСТРОЙКИ'),
        const SizedBox(height: 12),
        CardPanel(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: turquoise,
                title: const Text('Высокая графика'),
                subtitle: const Text('Настройка интерфейса-прототипа'),
                value: highGraphics,
                onChanged: (value) => setState(() => highGraphics = value),
              ),
              const Divider(color: Colors.white12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: turquoise,
                title: const Text('Вибрация'),
                value: vibration,
                onChanged: (value) => setState(() => vibration = value),
              ),
              const Divider(color: Colors.white12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: turquoise,
                title: const Text('Уведомления'),
                value: notifications,
                onChanged: (value) => setState(() => notifications = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KOKBORI RP',
                style: TextStyle(
                  color: gold,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Версия 1.0.0 • Демонстрационная сборка',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: gold,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return CardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: turquoise, size: 25),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CardPanel extends StatelessWidget {
  const CardPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}
