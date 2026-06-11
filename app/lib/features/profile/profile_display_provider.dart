import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDisplayState {
  final String name;
  final String photoPath;

  const ProfileDisplayState({this.name = '', this.photoPath = ''});

  ProfileDisplayState copyWith({String? name, String? photoPath}) {
    return ProfileDisplayState(
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

final profileDisplayProvider =
    StateNotifierProvider<ProfileDisplayNotifier, ProfileDisplayState>(
      (ref) => ProfileDisplayNotifier()..load(),
    );

class ProfileDisplayNotifier extends StateNotifier<ProfileDisplayState> {
  static const String _localNameKey = 'profile_local_name_v1';
  static const String _localPhotoPathKey = 'profile_local_photo_path_v1';

  ProfileDisplayNotifier() : super(const ProfileDisplayState());

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      name: prefs.getString(_localNameKey)?.trim() ?? '',
      photoPath: prefs.getString(_localPhotoPathKey)?.trim() ?? '',
    );
  }

  Future<void> update({String? name, String? photoPath}) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null) {
      final normalizedName = name.trim();
      await prefs.setString(_localNameKey, normalizedName);
      state = state.copyWith(name: normalizedName);
    }

    if (photoPath != null) {
      final normalizedPhotoPath = photoPath.trim();
      if (normalizedPhotoPath.isEmpty) {
        await prefs.remove(_localPhotoPathKey);
      } else {
        await prefs.setString(_localPhotoPathKey, normalizedPhotoPath);
      }
      state = state.copyWith(photoPath: normalizedPhotoPath);
    }
  }
}
