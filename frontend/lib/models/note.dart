class Note {
  final int id;
  final String text;
  final String createdAt;

  Note({required this.id, required this.text, required this.createdAt});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as int,
      text: json['text'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}
