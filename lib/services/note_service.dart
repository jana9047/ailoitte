import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class NoteService {

  final notesBox = Hive.box('notes_box');
  final queueBox = Hive.box('queue_box');

  /// CREATE NOTE
  void addNote(String text) {

    final id = const Uuid().v4();

    final note = {
      "id": id,
      "text": text,
      "liked": false,
      "updatedAt": DateTime.now().millisecondsSinceEpoch
    };

    /// Save locally first (Local-first UX)
    notesBox.put(id, note);

    /// Add action to offline queue
    queueBox.add({
      "id": id,
      "type": "add_note",
      "data": note,
      "retryCount": 0
    });

    print("NOTE CREATED");
    print("Queue size: ${queueBox.length}");
  }

  /// UPDATE NOTE (text edit or like change)
  void updateNote(String id, Map note) {

    final updatedNote = {
      ...note,
      "updatedAt": DateTime.now().millisecondsSinceEpoch
    };

    /// Update locally first
    notesBox.put(id, updatedNote);

    /// Add update action to queue
    queueBox.add({
      "id": id,
      "type": "update_note",
      "data": updatedNote,
      "retryCount": 0
    });

    print("NOTE UPDATED");
    print("Queue size: ${queueBox.length}");
  }

  /// DELETE NOTE
  void deleteNote(String id) {

    /// Delete locally
    notesBox.delete(id);

    /// Add delete action to queue
    queueBox.add({
      "id": id,
      "type": "delete_note",
      "retryCount": 0
    });

    print("NOTE DELETED");
    print("Queue size: ${queueBox.length}");
  }

  /// TOGGLE LIKE
  void toggleLike(Map note) {

    final updatedNote = {
      ...note,
      "liked": !(note['liked'] ?? false),
      "updatedAt": DateTime.now().millisecondsSinceEpoch
    };

    updateNote(note['id'], updatedNote);
  }

}