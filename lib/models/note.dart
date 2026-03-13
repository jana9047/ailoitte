class Note {
  String id;
  String text;
  bool liked;

  Note({
    required this.id,
    required this.text,
    this.liked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'liked': liked,
    };
  }

  factory Note.fromMap(Map map) {
    return Note(
      id: map['id'],
      text: map['text'],
      liked: map['liked'] ?? false,
    );
  }
}