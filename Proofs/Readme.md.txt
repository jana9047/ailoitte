Offline Notes App (Flutter + Firebase)
Overview

This project implements an offline-first notes application using Flutter.
Users can create, update, like, and delete notes even when the device is offline.

All user actions are stored locally and added to a sync queue. When internet connectivity becomes available, the queued actions are automatically synchronized with the backend database.

The goal of this project is to demonstrate offline-first architecture, reliable synchronization, and resilient mobile app design.

Tech Stack

Flutter – UI framework
Hive – Local database
Firebase Firestore – Backend database
Connectivity Plus – Internet detection

Local storage is handled using
Hive

Backend storage uses
Cloud Firestore

Network status detection uses
connectivity_plus

Architecture

The application follows an offline-first architecture.

Flutter UI
     ↓
Hive Local Database
     ↓
Offline Action Queue
     ↓
Connectivity Listener
     ↓
Sync Service
     ↓
Firebase Firestore
Flow

User performs an action (add/edit/delete note)

Action is saved locally in Hive

Action is added to a sync queue

If internet is available → sync immediately

If offline → wait until connectivity returns

Sync service processes queued actions sequentially

Features
Notes Management

• Create note
• Edit note
• Delete note
• Like/unlike note

Offline Support

• Works completely without internet
• Local-first data storage
• Queue-based write synchronization

Sync System

• Automatic sync when internet returns
• Retry mechanism for failed operations
• Prevents duplicate sync operations

UI

• Card-style notes layout
• Online/offline indicator
• Floating action button for note creation

Folder Structure
lib
│
├── models
│   ├── note.dart
│   └── queue_action.dart
│
├── services
│   ├── note_service.dart
│   └── sync_service.dart
│
├── screens
│   └── notes_screen.dart
│
└── main.dart
How To Run
1 Clone the repository
git clone <repository-url>
2 Navigate to project
cd offline-notes-app
3 Install dependencies
flutter pub get
4 Configure Firebase

Add the Firebase configuration file:

android/app/google-services.json
5 Run the application
flutter run
Sync Mechanism

Each offline action is stored in a queue box.

Example queued action:

{
  "id": "note_id",
  "type": "add_note",
  "data": {...},
  "retryCount": 0
}

The SyncService processes actions sequentially.

Supported actions:

add_note
update_note
delete_note
Retry Strategy

If synchronization fails:

Retry count is increased

Retry attempted later

After 3 failures, the action is removed from queue

This prevents infinite retry loops.

Tradeoffs

Hive was selected instead of SQLite for simplicity and performance.

Firestore was chosen as the backend due to its easy Flutter integration and scalability.

The queue-based sync design ensures reliability but increases implementation complexity.

Limitations

The current implementation has some limitations:

• No real-time pull synchronization from Firebase
• No multi-device conflict resolution
• Basic UI design

Future Improvements

Possible enhancements include:

• Search functionality
• Note categories or tags
• Grid layout similar to Google Keep
• Pull sync from Firebase
• Multi-device conflict resolution
• Dark mode