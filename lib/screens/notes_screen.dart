import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/note_service.dart';
import '../services/sync_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final noteService = NoteService();
  final syncService = SyncService();
  final notesBox = Hive.box('notes_box');
  bool isOnline = true;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _subscribeToConnectivity();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final results = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return results.isNotEmpty && results.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _hasNetworkInterface(dynamic connectivityResult) {
    // connectivity_plus versions differ:
    // - older: ConnectivityResult
    // - newer: List<ConnectivityResult>
    if (connectivityResult is List<ConnectivityResult>) {
      return connectivityResult.isNotEmpty &&
          !connectivityResult.contains(ConnectivityResult.none);
    }
    if (connectivityResult is ConnectivityResult) {
      return connectivityResult != ConnectivityResult.none;
    }
    return true; // fallback: attempt internet check
  }

  Future<void> _refreshOnlineStatus({bool syncIfOnline = true}) async {
    final networkUp = _hasNetworkInterface(await Connectivity().checkConnectivity());
    final online = networkUp ? await _hasInternetAccess() : false;

    if (!mounted) return;
    if (online != isOnline) {
      setState(() {
        isOnline = online;
      });
    }
    if (online && syncIfOnline) {
      syncService.syncQueue();
    }
  }

  void _checkInitialConnectivity() async {
    await _refreshOnlineStatus(syncIfOnline: true);
  }

  void _subscribeToConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) async {
      final networkUp = _hasNetworkInterface(result);
      final online = networkUp ? await _hasInternetAccess() : false;

      if (!mounted) return;
      if (online != isOnline) {
        setState(() {
          isOnline = online;
        });
      }
      if (online) syncService.syncQueue();
    });
  }

  // --- UI Components ---

  void showAddNoteDialog() {
    _showStyledDialog(
      title: "New Note",
      hint: "What's on your mind?",
      buttonLabel: "Create",
      onConfirm: (val) => noteService.addNote(val),
    );
  }

  void showEditDialog(Map note) {
    _showStyledDialog(
      title: "Edit Note",
      hint: "Update your thoughts...",
      initialValue: note['text'],
      buttonLabel: "Update",
      onConfirm: (val) {
        final updatedNote = {...note, "text": val};
        noteService.updateNote(note['id'], updatedNote);
      },
    );
  }

  void _showStyledDialog({
    required String title,
    required String hint,
    required String buttonLabel,
    required Function(String) onConfirm,
    String initialValue = "",
  }) {
    TextEditingController controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) onConfirm(controller.text);
              Navigator.pop(context);
            },
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FE),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildNotesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddNoteDialog,
        backgroundColor: Colors.indigoAccent,
        label: const Text("Add Note", style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xffF8F9FE),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
        title: Text(
          "My Notes",
          style: TextStyle(
            color: Colors.grey[900],
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      actions: [
        _ConnectivityBadge(isOnline: isOnline),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildNotesList() {
    return ValueListenableBuilder(
      valueListenable: notesBox.listenable(),
      builder: (context, Box box, _) {
        final notes = box.values.toList();

        if (notes.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: Icon(Icons.description_outlined, size: 100, color: Colors.indigo),
                  ),
                  SizedBox(height: 16),
                  Text("Your workspace is empty", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          );
        }

        return AnimationLimiter(
          child: SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final note = notes[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: _NoteCard(
                          note: note,
                          onEdit: () => showEditDialog(note),
                          onDelete: () => noteService.deleteNote(note['id']),
                          onLike: () {
                            final updatedNote = {
                              ...note,
                              "liked": !(note['liked'] ?? false)
                            };
                            noteService.updateNote(note['id'], updatedNote);
                          },
                        ),
                      ),
                    ),
                  );
                },
                childCount: notes.length,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Map note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLike;

  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    bool isLiked = note['liked'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: isLiked ? Colors.redAccent : Colors.indigoAccent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note['text'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _ActionButton(
                            icon: isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            onTap: onLike,
                          ),
                          _ActionButton(
                            icon: Icons.edit_note_rounded,
                            color: Colors.blueAccent,
                            onTap: onEdit,
                          ),
                          _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            color: Colors.grey,
                            onTap: onDelete,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _ConnectivityBadge extends StatelessWidget {
  final bool isOnline;
  const _ConnectivityBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? "Online" : "Offline",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOnline ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}