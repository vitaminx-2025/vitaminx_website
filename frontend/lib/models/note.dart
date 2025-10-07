class Note {
  final int id;
  final String text;
  final String createdAt;

  Note({required this.id, required this.text, required this.createdAt});

  factory Note.fromJson(Map<String, dynamic> j) => Note(
    id: j['id'] as int,
    text: j['text'] as String,
    createdAt: j['created_at'] as String,
  );
}
