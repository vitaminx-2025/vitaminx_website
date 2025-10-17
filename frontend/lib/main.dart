import 'dart:developer' as dev;
import 'dart:async';
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
    dev.log('VitaminX demo v0.7 started');

    return MaterialApp(
      title: 'VitaminX',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF111316),
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
  final _scrollCtrl = ScrollController();

  bool busy = false;
  String ping = '…';
  List<Note> notes = [];
  int total = 0;
  int limit = 20;
  int offset = 0;
  String currentQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scrollCtrl.addListener(_maybeLoadMore);
    _searchController.addListener(_debouncedSearch);
  }

  @override
  void dispose() {
    _newController.dispose();
    _searchController.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _debouncedSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      currentQuery = _searchController.text.trim();
      _load(reset: true);
    });
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        busy = true;
        offset = 0;
        notes = [];
      });
    } else {
      setState(() => busy = true);
    }
    try {
      final p = await ApiClient.ping();
      final page = await ApiClient.getNotes(
        q: currentQuery,
        limit: limit,
        offset: offset,
      );
      setState(() {
        ping = p;
        total = page.total;
        offset = page.offset + page.items.length;
        notes.addAll(page.items);
      });
    } catch (e) {
      _toast('$e');
    } finally {
      setState(() => busy = false);
    }
  }

  void _maybeLoadMore() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      if (notes.length < total && !busy) {
        _load(reset: false);
      }
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
      await _load(reset: true);
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
    if (updated == null || updated.isEmpty) return;
    setState(() => busy = true);
    try {
      await ApiClient.updateNote(n.id, updated);
      await _load(reset: true);
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
      await _load(reset: true);
    } catch (e) {
      _toast('$e');
    } finally {
      setState(() => busy = false);
    }
  }

  String _relative(String iso) {
    DateTime dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return iso;
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasMore = notes.length < total;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'VitaminX — Hello 👋',
                  style: TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text('Ping: $ping'),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: busy ? null : () => _load(reset: true),
                      child: const Text('Go'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _load(reset: true),
                    child: ListView.separated(
                      controller: _scrollCtrl,
                      itemCount: notes.length + (hasMore ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        if (i >= notes.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final n = notes[i];
                        return ListTile(
                          title: Text(n.text),
                          subtitle: Text(_relative(n.createdAt)),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: busy ? null : () => _edit(n),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: busy ? null : () => _delete(n),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text('Total: $total  Loaded: ${notes.length}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
