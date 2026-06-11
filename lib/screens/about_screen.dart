import 'package:flutter/material.dart';
import '../utils/contants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.school,
                size: 100,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Student Data App',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 24),
            Text(
              'About',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              'This application is designed to manage student data with CRUD (Create, Read, Update, Delete) functionality using Firebase as the backend service.',
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 24),
            Text(
              'Features',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureItem('Student data management'),
                _buildFeatureItem('Photo upload capability'),
                _buildFeatureItem('Search and filter functionality'),
                _buildFeatureItem('Secure authentication'),
                _buildFeatureItem('Responsive design'),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Developed by:',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              'Your Name',
              style: AppTextStyles.bodyText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyText)),
        ],
      ),
    );
  }
}