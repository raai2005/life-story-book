import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class NewChapterScreen extends StatefulWidget {
  final Map<String, dynamic>? chapterData;
  final String? chapterId;

  const NewChapterScreen({super.key, this.chapterData, this.chapterId});

  @override
  State<NewChapterScreen> createState() => _NewChapterScreenState();
}

class _NewChapterScreenState extends State<NewChapterScreen> {
  final TextEditingController _chapterController = TextEditingController();
  bool _isListening = false;
  bool _isEnhancing = false;
  String _selectedInputMode = 'write'; // 'write', 'attach', or 'voice'
  List<String> _attachedImages = []; // Store attached image paths

  @override
  void initState() {
    super.initState();
    // Load existing chapter data if editing
    if (widget.chapterData != null) {
      _chapterController.text = widget.chapterData!['rawText'] ?? '';
      _attachedImages = List<String>.from(
        widget.chapterData!['attachments'] ?? [],
      );
    }
  }

  @override
  void dispose() {
    _chapterController.dispose();
    super.dispose();
  }

  void _handleAttachment() async {
    // Show dialog to choose camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Choose Image Source',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6C63FF)),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF6C63FF),
              ),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Request permission
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final status = await permission.request();

    if (status.isGranted) {
      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedInputMode = 'attach';
          _attachedImages.add(image.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image attached successfully')),
          );
        }
      }
    } else if (status.isDenied || status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status.isPermanentlyDenied
                  ? 'Permission denied. Please enable in app settings.'
                  : 'Permission denied. Cannot access ${source == ImageSource.camera ? "camera" : "gallery"}.',
            ),
            action: status.isPermanentlyDenied
                ? SnackBarAction(
                    label: 'Settings',
                    onPressed: () => openAppSettings(),
                  )
                : null,
          ),
        );
      }
    }
  }

  void _handleVoiceInput() {
    setState(() {
      _isListening = !_isListening;
      _selectedInputMode = 'voice';
    });
    // TODO: Implement speech-to-text
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isListening ? 'Listening...' : 'Voice input stopped'),
        backgroundColor: _isListening ? Colors.red : Colors.grey,
      ),
    );
  }

  Future<void> _enhanceWithAI() async {
    if (_chapterController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    setState(() {
      _isEnhancing = true;
    });

    try {
      // Call both AI services in parallel for better performance
      final results = await Future.wait([
        AIService.enhanceStory(_chapterController.text),
        AIService.generateTitle(_chapterController.text),
      ]);

      final enhancedText = results[0];
      var suggestedTitle = results[1];

      // Remove surrounding quotation marks from title if present
      suggestedTitle = suggestedTitle.trim();
      if ((suggestedTitle.startsWith('"') && suggestedTitle.endsWith('"')) ||
          (suggestedTitle.startsWith("'") && suggestedTitle.endsWith("'"))) {
        suggestedTitle = suggestedTitle.substring(1, suggestedTitle.length - 1);
      }

      setState(() {
        _isEnhancing = false;
      });

      // Show preview dialog with enhanced content and suggested title
      if (mounted) {
        _showEnhancedPreview(enhancedText, suggestedTitle);
      }
    } catch (e) {
      setState(() {
        _isEnhancing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _saveChapterToFirebase(
    String enhancedText,
    String suggestedTitle,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final chapterData = {
        'userId': user.uid,
        'title': suggestedTitle,
        'rawText': _chapterController.text,
        'enhancedText': enhancedText,
        'attachments': _attachedImages,
        'updatedAt': FieldValue.serverTimestamp(),
        'wordCount': enhancedText.split(' ').length,
      };

      final firestore = FirebaseFirestore.instance;

      if (widget.chapterId != null) {
        // Update existing chapter
        final docRef = firestore.collection('chapters').doc(widget.chapterId);

        // Store edit history
        final editHistory = {
          'rawText': widget.chapterData!['rawText'],
          'enhancedText': widget.chapterData!['enhancedText'],
          'attachments': widget.chapterData!['attachments'],
          'editedAt': FieldValue.serverTimestamp(),
        };

        await firestore.runTransaction((transaction) async {
          // Add to edit history subcollection
          final historyRef = docRef.collection('editHistory').doc();
          transaction.set(historyRef, editHistory);

          // Update main chapter document
          transaction.update(docRef, chapterData);
        });
      } else {
        // Create new chapter
        chapterData['createdAt'] = FieldValue.serverTimestamp();
        await firestore.collection('chapters').add(chapterData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  void _showEnhancedPreview(String enhancedText, String suggestedTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'AI Enhanced Chapter',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Suggested Title:',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                suggestedTitle,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                'Enhanced Content:',
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                enhancedText,
                style: const TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Edit More',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveChapterToFirebase(enhancedText, suggestedTitle);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chapter saved successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Save Chapter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'New Chapter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Mode Selector
                Row(
                  children: [
                    _buildInputModeButton(
                      icon: Icons.edit,
                      label: 'Write',
                      mode: 'write',
                      onTap: () {
                        setState(() {
                          _selectedInputMode = 'write';
                          _isListening = false;
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildInputModeButton(
                      icon: Icons.attach_file,
                      label: 'Attach',
                      mode: 'attach',
                      onTap: _handleAttachment,
                    ),
                    const SizedBox(width: 12),
                    _buildInputModeButton(
                      icon: _isListening ? Icons.mic : Icons.mic_none,
                      label: 'Voice',
                      mode: 'voice',
                      onTap: _handleVoiceInput,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Text Area
                Container(
                  constraints: const BoxConstraints(minHeight: 400),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isListening
                          ? Colors.red.withValues(alpha: 0.5)
                          : Colors.white12,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _chapterController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? 'Listening... Speak your story'
                          : 'Write your story here...\n\nShare your memories, experiences, and moments that matter.',
                      hintStyle: TextStyle(
                        color: _isListening
                            ? Colors.red.withValues(alpha: 0.7)
                            : Colors.white38,
                        fontSize: 16,
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Attached images preview
                if (_attachedImages.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attached Images:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _attachedImages
                            .map(
                              (img) => Chip(
                                backgroundColor: const Color(0xFF16213E),
                                label: Text(
                                  img,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _attachedImages.remove(img);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // Character count
                Text(
                  '${_chapterController.text.length} characters',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 30),

                // AI Enhance Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isEnhancing ? null : _enhanceWithAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      disabledBackgroundColor: const Color(
                        0xFF6C63FF,
                      ).withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isEnhancing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_awesome, color: Colors.white),
                    label: Text(
                      _isEnhancing ? 'Enhancing...' : 'AI Enhance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputModeButton({
    required IconData icon,
    required String label,
    required String mode,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedInputMode == mode;
    final isVoiceActive = mode == 'voice' && _isListening;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected || isVoiceActive
              ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
              : const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVoiceActive
                ? Colors.red
                : isSelected
                ? const Color(0xFF6C63FF)
                : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isVoiceActive
                  ? Colors.red
                  : isSelected
                  ? const Color(0xFF6C63FF)
                  : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isVoiceActive
                    ? Colors.red
                    : isSelected
                    ? const Color(0xFF6C63FF)
                    : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
