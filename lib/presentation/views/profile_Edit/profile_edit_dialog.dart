import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_wallet/domain/entities/user_entity.dart';
import 'package:app_wallet/presentation/viewmodels/auth_viewmodel.dart';
import 'package:app_wallet/services/image_service.dart';

class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({super.key});

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  File? _selectedImage;
  String? _base64Image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final image = await ImageService.showImageSourceDialog(context);
    if (image != null) {
      final base64 = await ImageService.convertImageToBase64(image);
      setState(() {
        _selectedImage = image;
        _base64Image = base64;
      });
    }
  }

  Future<void> _saveProfileImage() async {
    if (_base64Image == null) return;
    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user != null) {
      // Simulate API call for now to keep functionality without breaking architecture
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isLoading = false);

      final updatedUser = UserEntity(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: _base64Image!,
        balance: user.balance,
      );
      auth.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteProfileImage() async {
    setState(() {
      _isLoading = true;
      _selectedImage = null;
      _base64Image = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user != null) {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isLoading = false);

      final updatedUser = UserEntity(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatar: '',
        balance: user.balance,
      );
      auth.updateUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Profile Image Display
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.purpleAccent, width: 3),
                    ),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : (user != null && user.avatar.isNotEmpty)
                          ? Image.memory(
                              base64Decode(user.avatar),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.purpleAccent,
                                );
                              },
                            )
                          : const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.purpleAccent,
                            ),
                    ),
                  ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
                if ((user != null && user.avatar.isNotEmpty) || _selectedImage != null)
                  ElevatedButton.icon(
                    onPressed: _deleteProfileImage,
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Save and Cancel Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_selectedImage != null && !_isLoading)
                        ? _saveProfileImage
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
