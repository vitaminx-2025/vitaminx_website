import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'models/note.dart';

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
  final _newController = TextEditingController();
  final _searchController = TextEditingController();
  bool busy = false;
  String ping = '…';
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({String? q}) async {
    setState(() => busy = true);
    try {
      final p = await ApiClient.ping();
      final list = await ApiClient.getNotes(q: q);
      setState(() {
        ping = p;
        notes = list;
      });
    } catch (e) {
      _toast('$e');
    } finally {
      setState(() => busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _add() async {
    final text = _newController.text.trim();
    if (text.isEmpty) return;
    setState(() => busy = true);
    try {
      await ApiClient.addNote(text);
      _newController.clear();
      await _loadAll(q: _searchController.text.trim());
    } catch (e) {
      _toast('$e');
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _edit(Note n) async {
    final ctrl = TextEditingController(text: n.text);
    final updated = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit note'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onSubmitted: (_) => Navigator.of(context).pop(ctrl.text.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (updated == null) return;
    if (updated.isEmpty) {
      _toast('Text required');
      return;
    }
    setState(() => busy = true);
    try {
      await ApiClient.updateNote(n.id, updated);
      await _loadAll(q: _searchController.text.trim());
    } catch (e) {
      _toast('$e');
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _delete(Note n) async {
    setState(() => busy = true);
    try {
      await ApiClient.deleteNote(n.id);
      await _loadAll(q: _searchController.text.trim());
    } catch (e) {
      _toast('$e');
    } finally {
      setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'VitaminX — Hello 👋',
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text('Ping: $ping'),
                const SizedBox(height: 16),

                // Search
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search notes...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (v) => _loadAll(q: v.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed:
                          busy
                              ? null
                              : () =>
                                  _loadAll(q: _searchController.text.trim()),
                      child: const Text('Go'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Add
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newController,
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

                // List
                Flexible(
                  child:
                      notes.isEmpty
                          ? const Text('No notes')
                          : ListView.separated(
                            shrinkWrap: true,
                            itemCount: notes.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final n = notes[i];
                              return ListTile(
                                title: Text(n.text),
                                subtitle: Text(n.createdAt),
                                trailing: Wrap(
                                  spacing: 4,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: busy ? null : () => _edit(n),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: busy ? null : () => _delete(n),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                ),

                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed:
                      busy
                          ? null
                          : () => _loadAll(q: _searchController.text.trim()),
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
