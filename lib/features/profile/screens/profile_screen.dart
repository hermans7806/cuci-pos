import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final _controller = ProfileController();

  bool biometricEnabled = false;
  bool isUploading = false;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    nameController.text = user.displayName ?? '';
    imageUrl = user.photoURL;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _controller.loadProfile();
    if (data != null) {
      setState(() {
        nameController.text = data['displayName'] ?? '';
        nicknameController.text = data['nickname'] ?? '';
        phoneController.text = data['phone'] ?? '';
        imageUrl = data['photoURL'];
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Sumber Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => isUploading = true);
    try {
      final file = File(picked.path);
      final url = await _controller.uploadAvatar(file);
      setState(() => imageUrl = url);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload gagal: $e')));
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> _deleteAvatar() async {
    try {
      await _controller.deleteAvatar();
      setState(() => imageUrl = null);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal hapus foto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (isUploading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else
                ProfileAvatar(
                  imageUrl: imageUrl,
                  isUploading: isUploading,
                  onChangeAvatar: _pickAndUploadAvatar,
                  onDeleteAvatar: _deleteAvatar,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Lengkap",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: "Nama Panggilan",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Nomor HP",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                enabled: false,
                initialValue: user.email,
                decoration: const InputDecoration(
                  labelText: "Email (tidak bisa diubah)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Gunakan Login Biometrik (Coming Soon)"),
                value: biometricEnabled,
                onChanged: (val) {
                  setState(() {
                    biometricEnabled = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
