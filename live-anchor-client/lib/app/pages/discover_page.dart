import 'package:flutter/material.dart';

/// 发现/广场页面
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Discover',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Coming soon', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
