import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Model/user_profile.dart';

// Provider for managing user profile state
final setProfileProvider = StateNotifierProvider<SetProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return SetProfileNotifier();
});

class SetProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  SetProfileNotifier() : super(const AsyncValue.data(null));

  final SupabaseClient _supabase = Supabase.instance.client;

  // Create or update user profile
  Future<void> saveProfile({
    required String userid,
    required String username,
    String? email,
    String? role,
    String? profilePic,
    String? bio,
    String? study,
    String? location,
    int? streakCount,
    int? followersCount,
    int? followingCount,
    bool? isVerified,
  }) async {
    state = const AsyncValue.loading();

    try {
      // Check if user_profiles table exists, create if not
      await _ensureTableExists();

      // Create UserProfile object
      final userProfile = UserProfile(
        userid: userid,
        username: username,
        email: email,
        role: role,
        profilePic: profilePic,
        bio: bio,
        study: study,
        location: location,
        streakCount: streakCount ?? 0,
        followersCount: followersCount ?? 0,
        followingCount: followingCount ?? 0,
        createdAt: DateTime.now(),
        isVerified: isVerified ?? false,
      );

      // Check if profile exists
      final existingProfile = await _supabase
          .from('user_profiles')
          .select()
          .eq('userid', userid)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile
        await _supabase.from('user_profiles').insert({
          'userid': userProfile.userid,
          'username': userProfile.username,
          'email': userProfile.email,
          'role': userProfile.role,
          'profile_pic': userProfile.profilePic,
          'bio': userProfile.bio,
          'study': userProfile.study,
          'location': userProfile.location,
          'streak_count': userProfile.streakCount,
          'followers_count': userProfile.followersCount,
          'following_count': userProfile.followingCount,
          'created_at': userProfile.createdAt?.toIso8601String(),
          'is_verified': userProfile.isVerified,
        });
      } else {
        // Update existing profile
        await _supabase.from('user_profiles').update({
          'username': userProfile.username,
          'email': userProfile.email,
          'role': userProfile.role,
          'profile_pic': userProfile.profilePic,
          'bio': userProfile.bio,
          'study': userProfile.study,
          'location': userProfile.location,
          'streak_count': userProfile.streakCount,
          'followers_count': userProfile.followersCount,
          'following_count': userProfile.followingCount,
          'is_verified': userProfile.isVerified,
        }).eq('userid', userid);
      }

      state = AsyncValue.data(userProfile);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
      rethrow;
    }
  }

  // Get user profile
  Future<void> getUserProfile(String userid) async {
    state = const AsyncValue.loading();

    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('userid', userid)
          .maybeSingle();

      if (response != null) {
        final userProfile = UserProfile(
          userid: response['userid'],
          username: response['username'],
          email: response['email'],
          role: response['role'],
          profilePic: response['profile_pic'],
          bio: response['bio'],
          study: response['study'],
          location: response['location'],
          streakCount: response['streak_count'],
          followersCount: response['followers_count'],
          followingCount: response['following_count'],
          createdAt: response['created_at'] != null
              ? DateTime.parse(response['created_at'])
              : null,
          isVerified: response['is_verified'],
        );
        state = AsyncValue.data(userProfile);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }

  // Ensure the user_profiles table exists
  Future<void> _ensureTableExists() async {
    try {
      // Try to query the table to check if it exists
      await _supabase.from('user_profiles').select('userid').limit(1);
    } catch (error) {
      // If table doesn't exist, create it
      // Note: In production, you should create tables through Supabase dashboard
      // or migration scripts. This is just for development purposes.
      throw Exception('user_profiles table does not exist. Please create it in Supabase dashboard with the following columns:\n'
          '- userid (text, primary key)\n'
          '- username (text, not null)\n'
          '- email (text)\n'
          '- role (text)\n'
          '- profile_pic (text)\n'
          '- bio (text)\n'
          '- study (text)\n'
          '- location (text)\n'
          '- streak_count (integer, default 0)\n'
          '- followers_count (integer, default 0)\n'
          '- following_count (integer, default 0)\n'
          '- created_at (timestamp with time zone, default now())\n'
          '- is_verified (boolean, default false)');
    }
  }

  // Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}