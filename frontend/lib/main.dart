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
  final _controller = TextEditingController();
  bool busy = false;
  List<Map<String, dynamic>> notes = [];
  String ping = '…';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => busy = true);
    try {
      final p = await ApiClient.ping();
      final list = await ApiClient.getNotes();
      setState(() {
        ping = p;
        notes = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => busy = true);
    try {
      await ApiClient.addNote(text);
      _controller.clear();
      await _loadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => busy = false);
    }
  }

  Future<void> _delete(int id) async {
    setState(() => busy = true);
    try {
      await ApiClient.deleteNote(id);
      await _loadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'VitaminX — Hello 👋',
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text('Ping: $ping'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a note',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: busy ? null : _add,
                      child: Text(busy ? '...' : 'Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child:
                      notes.isEmpty
                          ? const Text('No notes yet')
                          : ListView.separated(
                            shrinkWrap: true,
                            itemCount: notes.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final n = notes[i];
                              final id = n['id'] as int;
                              final text = n['text'] as String;
                              final ts = (n['created_at'] as String?) ?? '';
                              return ListTile(
                                dense: true,
                                title: Text(text),
                                subtitle: Text(ts),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: busy ? null : () => _delete(id),
                                ),
                              );
                            },
                          ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: busy ? null : _loadAll,
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
