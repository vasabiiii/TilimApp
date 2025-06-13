import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../profile/services/profile_service.dart';
import '../../auth/services/auth_service.dart';
import '../../profile/models/profile_model.dart';

class ChangeAvatarScreen extends StatefulWidget {
  const ChangeAvatarScreen({Key? key}) : super(key: key);

  @override
  State<ChangeAvatarScreen> createState() => _ChangeAvatarScreenState();
}

class _ChangeAvatarScreenState extends State<ChangeAvatarScreen> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _currentAvatarUrl;
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final result = await _authService.getProfile();
      
      if (result['success']) {
        setState(() {
          _profile = ProfileModel.fromJson(result['data']);
          _currentAvatarUrl = _profile?.image;
          _isLoadingProfile = false;
        });
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isLoading = true);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null) {
        final imageUrl = await _cloudinaryService.uploadImageForAvatar(image);
        
        if (imageUrl != null) {
          final success = await _profileService.updateAvatar(imageUrl);
          
          if (success) {
            setState(() => _currentAvatarUrl = imageUrl);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Аватарка успешно обновлена!'),
                  backgroundColor: Colors.green,
                ),
              );
              
              Navigator.pop(context, true);
            }
          } else {
            throw Exception('Не удалось обновить аватар на сервере');
          }
        } else {
          throw Exception('Не удалось загрузить изображение');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Изменить аватарку'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            _isLoadingProfile
              ? Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty
                    ? NetworkImage(_currentAvatarUrl!) 
                    : null,
                  child: _currentAvatarUrl == null || _currentAvatarUrl!.isEmpty
                    ? Icon(
                        Icons.person, 
                        size: 60, 
                        color: Colors.grey[600],
                      )
                    : null,
                ),
            const SizedBox(height: 20),
            if (_profile != null) ...[
              Text(
                _profile!.username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _pickAndUploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Загрузить новую аватарку',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Выберите изображение из галереи',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 