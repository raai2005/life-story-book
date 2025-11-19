import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Life Storybook Generator'),
        backgroundColor: const Color(0xFF16213E),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 100, color: const Color(0xFF6C63FF)),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Life Storybook',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Start creating your story',
              style: TextStyle(fontSize: 16, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      ),
    );
  }
}
