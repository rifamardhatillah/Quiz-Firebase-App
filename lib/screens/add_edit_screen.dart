import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/student_model.dart';
import '../utils/contants.dart'; // Pastikan AppColors dan AppTextStyles ada
import '../widgets/custom_texfield.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Impor untuk kompresi
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io; // Alias untuk io.File

class AddEditScreen extends StatefulWidget {
  final Student? student;

  const AddEditScreen({super.key, this.student});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  XFile? _pickedImageXFile;
  String? _currentPhotoUrl;

  bool _isLoading = false;
  bool get _isEditMode => widget.student != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode && widget.student != null) {
      _nameController.text = widget.student!.name;
      _nimController.text = widget.student!.nim;
      _birthDateController.text = widget.student!.birthDate;
      _hobbyController.text = widget.student!.hobby;
      _phoneController.text = widget.student!.phoneNumber;
      _addressController.text = widget.student!.address;
      _currentPhotoUrl = widget.student!.photoUrl;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImageXFile = pickedFile;
      });
    }
  }

  // --- FUNGSI KOMPRESI GAMBAR ---
  Future<XFile?> _compressImage(XFile file) async {
    // Kompresi mungkin tidak selalu diperlukan atau efektif di Web dengan cara ini
    // Atau mungkin perlu pustaka JS khusus untuk web jika flutter_image_compress tidak optimal
    if (kIsWeb) {
      print("AddEditScreen: Skipping image compression on Web for now.");
      return file; // Kembalikan file asli untuk Web
    }

    try {
      print("AddEditScreen: Attempting to compress image...");
      // Dapatkan temporary path untuk menyimpan hasil kompresi
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg'; // Selalu kompres ke jpg untuk ukuran lebih kecil

      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        minWidth: 1024,  // Batasi lebar maksimum
        minHeight: 1024, // Batasi tinggi maksimum
        quality: 80,     // Kualitas JPEG (0-100)
        format: CompressFormat.jpeg, // Paksa ke JPEG untuk foto
      );

      if (result != null) {
        final originalSize = io.File(file.path).lengthSync();
        final compressedSize = io.File(result.path).lengthSync();
        print("AddEditScreen: Image compressed. Original: $originalSize bytes, Compressed: $compressedSize bytes. Path: ${result.path}");
        return result;
      } else {
        print("AddEditScreen: Compression failed or returned null, using original image.");
        return file; // Kembalikan file asli jika kompresi gagal
      }
    } catch (e) {
      print("AddEditScreen: Error during image compression: $e. Using original image.");
      return file; // Kembalikan file asli jika ada error
    }
  }
  // --- AKHIR FUNGSI KOMPRESI GAMBAR ---


  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    String finalPhotoUrl = _currentPhotoUrl ?? '';

    try {
      XFile? imageToUpload = _pickedImageXFile; // Default ke gambar yang dipilih

      if (_pickedImageXFile != null) {
        print("AddEditScreen: New image file selected.");
        // Kompres gambar sebelum diunggah
        XFile? compressedImage = await _compressImage(_pickedImageXFile!);
        if (compressedImage != null) {
          imageToUpload = compressedImage;
        }
        // Jika kompresi gagal, imageToUpload tetap _pickedImageXFile

        print("AddEditScreen: Attempting to upload ${kIsWeb ? 'original (Web)' : 'processed'} image.");
        String? uploadedImageUrl = await storageService.uploadImage(
          imageXFile: imageToUpload!, // Gunakan gambar yang mungkin sudah dikompres
          folderName: 'student_photos',
          oldImageUrl: _isEditMode && _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty ? _currentPhotoUrl : null,
        );

        if (uploadedImageUrl != null) {
          finalPhotoUrl = uploadedImageUrl;
          print("AddEditScreen: Image uploaded, new URL: $finalPhotoUrl");
        } else {
          print("AddEditScreen: Image upload failed.");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image. Please try again.')),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      } else {
         print("AddEditScreen: No new image file selected. Using current URL: $finalPhotoUrl");
      }

      final studentData = Student(
        id: _isEditMode ? widget.student!.id : null,
        name: _nameController.text.trim(),
        nim: _nimController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        hobby: _hobbyController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        photoUrl: finalPhotoUrl,
      );

      if (_isEditMode) {
        await databaseService.updateStudent(studentData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated!')));
      } else {
        await databaseService.addStudent(studentData);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student added!')));
      }
      if (mounted) Navigator.pop(context);

    } catch (e, s) {
      print("AddEditScreen: Error during submit: $e");
      print("AddEditScreen: Stacktrace: $s");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteStudent() async {
    if (!_isEditMode || widget.student?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${widget.student!.name}?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final databaseService = Provider.of<DatabaseService>(context, listen: false);
        final storageService = Provider.of<StorageService>(context, listen: false);

        if (widget.student!.photoUrl.isNotEmpty) {
          await storageService.deleteImage(widget.student!.photoUrl);
        }
        
        await databaseService.deleteStudent(widget.student!.id!);
        
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.student!.name} deleted.')));
            Navigator.pop(context); 
            // Jika ini satu-satunya halaman, dan Anda ingin kembali ke dashboard utama,
            // Anda mungkin perlu menggunakan Navigator.popUntil atau Navigator.pushReplacementNamed
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting: ${e.toString()}')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (_pickedImageXFile != null) {
      if (kIsWeb) {
        imageWidget = Image.network(_pickedImageXFile!.path, fit: BoxFit.cover);
      } else {
        imageWidget = Image.file(io.File(_pickedImageXFile!.path), fit: BoxFit.cover);
      }
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: _currentPhotoUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    } else {
      imageWidget = const Icon(Icons.add_a_photo, size: 40, color: Colors.grey);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Student' : 'Add Student'),
        actions: _isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _isLoading ? null : _deleteStudent,
                  tooltip: 'Delete Student',
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: imageWidget,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(controller: _nameController, labelText: 'Name', validator: (v) => v!.isEmpty ? 'Name is required' : null),
              const SizedBox(height: 16),
              CustomTextField(controller: _nimController, labelText: 'NIM', keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'NIM is required' : null),
              const SizedBox(height: 16),
              CustomTextField(controller: _birthDateController, labelText: 'Birth Date (YYYY-MM-DD)', validator: (v) => v!.isEmpty ? 'Birth Date is required' : null),
              const SizedBox(height: 16),
              CustomTextField(controller: _hobbyController, labelText: 'Hobby', validator: (v) => v!.isEmpty ? 'Hobby is required' : null),
              const SizedBox(height: 16),
              CustomTextField(controller: _phoneController, labelText: 'Phone Number', keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Phone Number is required' : null),
              const SizedBox(height: 16),
              CustomTextField(controller: _addressController, labelText: 'Address', maxLines: 3, validator: (v) => v!.isEmpty ? 'Address is required' : null),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor, // Pastikan AppColors.primaryColor didefinisikan
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(_isEditMode ? 'Update Student' : 'Add Student', style: AppTextStyles.buttonText), // Pastikan AppTextStyles.buttonText didefinisikan
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _birthDateController.dispose();
    _hobbyController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}