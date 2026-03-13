
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class SyncService {

  bool isSyncing = false;

  Future<void> syncQueue() async {

    if (isSyncing) {
      print("Sync already running");
      return;
    }

    isSyncing = true;

    final queueBox = Hive.box('queue_box');

    print("Starting sync...");
    print("Queue size: ${queueBox.length}");

    try {
      final keys = queueBox.keys.toList();

      for (final key in keys) {
        final action = queueBox.get(key);

        final type = action['type'];
        final id = action['id'];
        final data = action['data'];

        print("Processing action: $type");

        try {
          if (type == "add_note") {
            print("Adding note to Firebase: $id");
            await FirebaseFirestore.instance
                .collection("notes")
                .doc(id)
                .set(Map<String, dynamic>.from(data));
            print("Note added to Firebase: $id");
          } else if (type == "update_note") {
            print("Updating note in Firebase: $id");
            await FirebaseFirestore.instance
                .collection("notes")
                .doc(id)
                .update(Map<String, dynamic>.from(data));
            print("Note updated in Firebase: $id");
          } else if (type == "delete_note") {
            print("Deleting note from Firebase: $id");
            await FirebaseFirestore.instance
                .collection("notes")
                .doc(id)
                .delete();
            print("Note deleted from Firebase: $id");
          }

          print("SYNC SUCCESS");

          await queueBox.delete(key);
        } catch (e) {
          print("SYNC FAILED for $id: $e");

          // Increment retry count
          action['retryCount'] = (action['retryCount'] ?? 0) + 1;

await Future.delayed(
  Duration(seconds: action['retryCount'] * 2),
);

          // If too many retries, remove from queue
          if (action['retryCount'] > 3) {
            print("Max retries reached, removing from queue: $id");
            await queueBox.delete(key);
          } else {
            // Update the action with new retry count
            await queueBox.put(key, action);
            break; // Stop processing on failure
          }
        }
      }
    } catch (e) {
      print("SYNC FAILED: $e");
    }

    print("Sync finished");

    isSyncing = false;
  }
}

