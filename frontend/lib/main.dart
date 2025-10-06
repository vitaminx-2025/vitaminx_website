import 'package:flutter/material.dart';
import 'api/api_client.dart';

void main() {
  runApp(const VitaminXApp());
}

class VitaminXApp extends StatelessWidget {
  const VitaminXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VitaminX',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF111316),
          background: Color(0xFF0E0F12),
          primary: Color(0xFF7C9EFF),
        ),
        scaffoldBackgroundColor: const Color(0xFF0E0F12),
        useMaterial3: true,
      ),
      home: const _Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  String ping = '…';
  String idea = '…';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ApiClient.ping();
      final i = await ApiClient.aiMock(['humans', 'reading']);
      setState(() {
        ping = p;
        idea = i;
      });
    } catch (e) {
      setState(() {
        ping = 'error';
        idea = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VitaminX — Hello 👋',
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 16),
                Text('Ping: $ping'),
                const SizedBox(height: 8),
                Text('AI mock: $idea'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed:
                      busy
                          ? null
                          : () async {
                            setState(() => busy = true);
                            await _load();
                            setState(() => busy = false);
                          },
                  child: Text(busy ? 'Loading…' : 'Refresh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
