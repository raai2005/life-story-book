import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'new_chapter_screen.dart';
import 'chapter_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalChapters = 0;
  int _totalWords = 0;
  int _totalImages = 0;

  Stream<QuerySnapshot> _getChaptersStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('chapters')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'My Story',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getChaptersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading chapters: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          final chapters = snapshot.data?.docs ?? [];

          // Calculate totals
          _totalChapters = chapters.length;
          _totalWords = 0;
          _totalImages = 0;
          for (var doc in chapters) {
            final data = doc.data() as Map<String, dynamic>;
            _totalWords += (data['wordCount'] as num?)?.toInt() ?? 0;
            _totalImages += (data['attachments'] as List?)?.length ?? 0;
          }

          return SafeArea(
            child: Column(
              children: [
                // Welcome back header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF16213E),
                        const Color(0xFF1A1A2E),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back! 👋',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Continue writing your life story',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats row
                      Row(
                        children: [
                          _buildStatCard(
                            'Chapters',
                            _totalChapters.toString(),
                            Icons.book,
                          ),
                          const SizedBox(width: 15),
                          _buildStatCard(
                            'Words',
                            _totalWords.toString(),
                            Icons.text_fields,
                          ),
                          const SizedBox(width: 15),
                          _buildStatCard(
                            'Images',
                            _totalImages.toString(),
                            Icons.image,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Chapters list
                Expanded(
                  child: chapters.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: chapters.length,
                          itemBuilder: (context, index) {
                            final doc = chapters[index];
                            final data = doc.data() as Map<String, dynamic>;
                            data['id'] = doc.id;
                            return _buildChapterCard(data, index);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewChapterScreen()),
          );
        },
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Chapter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C63FF), size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterCard(Map<String, dynamic> chapter, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            // Open chapter detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChapterDetailScreen(
                  chapterData: chapter,
                  chapterId: chapter['id'],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6C63FF),
                            const Color(0xFF4834DF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(chapter['createdAt']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: const Color(0xFF6C63FF),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  chapter['enhancedText'] ?? chapter['rawText'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 15),
                // Word count and attachments
                Row(
                  children: [
                    Icon(Icons.text_fields, size: 16, color: Color(0xFF6C63FF)),
                    SizedBox(width: 5),
                    Text(
                      '${chapter['wordCount'] ?? 0} words',
                      style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                    ),
                    if ((chapter['attachments'] as List?)?.isNotEmpty ??
                        false) ...[
                      SizedBox(width: 15),
                      Icon(Icons.image, size: 16, color: Color(0xFF6C63FF)),
                      SizedBox(width: 5),
                      Text(
                        '${(chapter['attachments'] as List).length} images',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 100,
            color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'No chapters yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start writing your first chapter',
            style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';

    try {
      final DateTime date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return 'Recently';
    }
  }
}
