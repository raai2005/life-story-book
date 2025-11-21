import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ChapterDetailScreen extends StatefulWidget {
  final Map<String, dynamic> chapterData;
  final String chapterId;

  const ChapterDetailScreen({
    super.key,
    required this.chapterData,
    required this.chapterId,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _storyController;
  bool _isEditMode = false;
  bool _isSaving = false;
  List<String> _attachedImages = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.chapterData['title'] ?? 'Untitled',
    );
    _storyController = TextEditingController(
      text:
          widget.chapterData['enhancedText'] ??
          widget.chapterData['rawText'] ??
          '',
    );
    _attachedImages = List<String>.from(
      widget.chapterData['attachments'] ?? [],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updatedData = {
        'title': _titleController.text,
        'enhancedText': _storyController.text,
        'attachments': _attachedImages,
        'updatedAt': FieldValue.serverTimestamp(),
        'wordCount': _storyController.text.split(' ').length,
      };

      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('chapters').doc(widget.chapterId);

      // Store edit history
      final editHistory = {
        'title': widget.chapterData['title'],
        'enhancedText': widget.chapterData['enhancedText'],
        'attachments': widget.chapterData['attachments'],
        'editedAt': FieldValue.serverTimestamp(),
      };

      await firestore.runTransaction((transaction) async {
        // Add to edit history subcollection
        final historyRef = docRef.collection('editHistory').doc();
        transaction.set(historyRef, editHistory);

        // Update main chapter document
        transaction.update(docRef, updatedData);
      });

      // Update local data
      widget.chapterData['title'] = _titleController.text;
      widget.chapterData['enhancedText'] = _storyController.text;
      widget.chapterData['attachments'] = _attachedImages;

      setState(() {
        _isEditMode = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
    }
  }

  void _shareChapter() {
    final title = _titleController.text;
    final story = _storyController.text;
    Share.share('$title\n\n$story', subject: title);
  }

  void _deleteImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Delete Story',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this story? This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'NO',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'YES',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteChapter();
    }
  }

  Future<void> _deleteChapter() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Delete the chapter from Firestore
      await FirebaseFirestore.instance
          .collection('chapters')
          .doc(widget.chapterId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story deleted successfully')),
        );
        // Go back to dashboard
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareChapter,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title section
              Row(
                children: [
                  Expanded(
                    child: _isEditMode
                        ? TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Chapter Title',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                  width: 2,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            _titleController.text,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Attached images
              if (_attachedImages.isNotEmpty) ...[
                const Text(
                  'Attached Images:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFF6C63FF,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: File(_attachedImages[index]).existsSync()
                                  ? Image.file(
                                      File(_attachedImages[index]),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      color: const Color(0xFF16213E),
                                      child: const Icon(
                                        Icons.image,
                                        color: Color(0xFF6C63FF),
                                        size: 40,
                                      ),
                                    ),
                            ),
                            if (_isEditMode)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () => _deleteImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Story text section
              const Text(
                'Your Story:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(
                  minHeight: 300,
                  maxHeight: 400,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isEditMode
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: _isEditMode
                    ? TextField(
                        controller: _storyController,
                        maxLines: null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.6,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Write your story here...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _storyController.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 30),

              // Action buttons
              if (_isEditMode)
                // Save button in edit mode
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      disabledBackgroundColor: const Color(
                        0xFF6C63FF,
                      ).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                )
              else
                // Edit and Delete buttons side by side
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditMode = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Edit Your Story',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _showDeleteConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Delete Your Story',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              // Cancel button in edit mode
              if (_isEditMode) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _titleController.text =
                            widget.chapterData['title'] ?? 'Untitled';
                        _storyController.text =
                            widget.chapterData['enhancedText'] ??
                            widget.chapterData['rawText'] ??
                            '';
                        _attachedImages = List<String>.from(
                          widget.chapterData['attachments'] ?? [],
                        );
                        _isEditMode = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6C63FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
