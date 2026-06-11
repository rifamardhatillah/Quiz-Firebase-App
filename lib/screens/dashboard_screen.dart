import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart'; // Asumsi Anda memiliki ini
import '../services/database_service.dart';
import '../models/student_model.dart';
import '../screens/add_edit_screen.dart';
import '../screens/detail_screen.dart'; // Jika Anda masih menggunakan ini
import '../widgets/student_card.dart';
import '../utils/contants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  String _selectedHobby = 'All';
  String _sortBy = 'name';
  final List<String> _hobbyOptions = ['All', 'Reading', 'Sports', 'Music', 'Coding', 'Art', 'Traveling']; // Sesuaikan

  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, String studentName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete $studentName?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login'); // Asumsi ada route login
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Search by name or NIM',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedHobby,
                        items: _hobbyOptions.map((hobby) => DropdownMenuItem(value: hobby, child: Text(hobby))).toList(),
                        onChanged: (value) => setState(() => _selectedHobby = value!),
                        decoration: InputDecoration(labelText: 'Filter by hobby', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        items: const [
                           DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                           DropdownMenuItem(value: 'nim', child: Text('Sort by NIM')),
                           DropdownMenuItem(value: 'birthDate', child: Text('Sort by Birth Date')),
                        ],
                        onChanged: (value) => setState(() => _sortBy = value!),
                        decoration: InputDecoration(labelText: 'Sort by', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: databaseService.getStudents(), // Bisa juga pakai searchStudents jika mau realtime search backend
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                List<Student> students = List.from(snapshot.data!);

                // Client-side filtering and sorting
                if (_searchQuery.isNotEmpty) {
                  students = students.where((s) => s.name.toLowerCase().contains(_searchQuery) || s.nim.toLowerCase().contains(_searchQuery)).toList();
                }
                if (_selectedHobby != 'All') {
                  students = students.where((s) => s.hobby == _selectedHobby).toList();
                }
                students.sort((a, b) {
                  if (_sortBy == 'name') return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  if (_sortBy == 'nim') return a.nim.compareTo(b.nim);
                  if (_sortBy == 'birthDate') return a.birthDate.compareTo(b.birthDate); // Asumsi format YYYY-MM-DD
                  return 0;
                });

                if (students.isEmpty) {
                  return const Center(child: Text('No students match your criteria.'));
                }

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return StudentCard(
                      student: student,
                      onTap: () { // Navigasi ke detail atau edit
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(student: student)));
                        // atau Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditScreen(student: student)));
                      },
                      onEdit: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditScreen(student: student)));
                      },
                      onDelete: () async {
                        final confirmed = await _showDeleteConfirmationDialog(context, student.name);
                        if (confirmed == true && student.id != null) {
                          try {
                            await databaseService.deleteStudent(student.id!);
                            // Jika photoUrl adalah path lokal dan perlu dihapus oleh StorageService
                            // final storageService = Provider.of<StorageService>(context, listen: false);
                            // if (student.photoUrl.isNotEmpty) {
                            //    await storageService.deleteImage(student.photoUrl);
                            // }
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${student.name} deleted.')));
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryColor,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditScreen())),
        tooltip: 'Add Student',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}