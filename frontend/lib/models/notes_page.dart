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

  factory NotesPage.fromJson(Map<String, dynamic> json) {
    return NotesPage(
      items:
          (json['items'] as List)
              .map((e) => Note.fromJson(e as Map<String, dynamic>))
              .toList(),
      total: json['total'] as int,
      limit: json['limit'] as int,
      offset: json['offset'] as int,
      hasMore: json['has_more'] as bool,
    );
  }
}
