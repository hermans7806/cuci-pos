import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onChangeAvatar;
  final VoidCallback onDeleteAvatar;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.isUploading,
    required this.onChangeAvatar,
    required this.onDeleteAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: imageUrl != null
              ? NetworkImage(imageUrl!)
              : const AssetImage('lib/assets/default_avatar.png')
                    as ImageProvider,
          child: isUploading
              ? const CircularProgressIndicator(color: Colors.blue)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: PopupMenuButton<String>(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
            onSelected: (value) {
              if (value == 'change') onChangeAvatar();
              if (value == 'delete') onDeleteAvatar();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change',
                child: Row(
                  children: [
                    Icon(Icons.photo_library, size: 18),
                    SizedBox(width: 8),
                    Text('Ganti Foto'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18),
                    SizedBox(width: 8),
                    Text('Hapus Foto'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
