import 'note.dart';

class NotesPage {
  final List<Note> items;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  NotesPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory NotesPage.fromJson(Map<String, dynamic> j) => NotesPage(
    items:
        (j['items'] as List)
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList(),
    total: j['total'] as int,
    limit: j['limit'] as int,
    offset: j['offset'] as int,
    hasMore: j['has_more'] as bool,
  );
}
