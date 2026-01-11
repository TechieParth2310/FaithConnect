import '../models/user_model.dart';

/// Centralized, app-wide rules for profile UI/behavior.
///
/// Core product rule:
/// - ONLY leaders can be followed.
/// - Worshippers cannot be followed.
///
/// Keep all role-based rendering decisions here so we don't duplicate
/// logic across screens.
class ProfileCapabilities {
  const ProfileCapabilities._();

  static bool canBeFollowed(UserModel user) =>
      user.role == UserRole.religiousLeader;

  /// Whether a profile should show the "Followers" metric.
  static bool showFollowers(UserModel user) =>
      user.role == UserRole.religiousLeader;

  /// Whether a profile should show the "Following" metric.
  static bool showFollowing(UserModel user) =>
      user.role != UserRole.religiousLeader;

  /// Whether to render Follow/Unfollow controls when viewing [profileUser].
  ///
  /// Only worshippers (or non-leaders) should see a follow button, and only
  /// when the viewed profile is a leader, and it isn't their own profile.
  static bool showFollowButton({
    required UserModel viewer,
    required UserModel profileUser,
  }) {
    if (viewer.id == profileUser.id) return false;
    if (!canBeFollowed(profileUser)) return false;
    // Leaders don't follow leaders in this product.
    if (viewer.role == UserRole.religiousLeader) return false;
    return true;
  }

  /// Leaders can show their bio; worshippers can keep it more minimal.
  static bool showBio(UserModel user) => user.role == UserRole.religiousLeader;

  static String roleLabel(UserModel user) {
    return user.role == UserRole.religiousLeader ? 'Leader' : 'Worshipper';
  }
}
