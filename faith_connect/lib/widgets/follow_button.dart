import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/follow_service.dart';

/// Follow button that is safe by default:
/// - Only renders for worshipper viewers
/// - Only targets leader IDs (leaderId)
///
/// Note: The service layer (FollowService) also enforces that only leaders can
/// be followed.
class FollowButton extends StatefulWidget {
  final String worshipperId;
  final String leaderId;

  /// Optional style overrides.
  final bool compact;
  final double? height;
  final BorderRadiusGeometry borderRadius;

  const FollowButton({
    super.key,
    required this.worshipperId,
    required this.leaderId,
    this.compact = false,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final FollowService _followService = FollowService();
  final AuthService _authService = AuthService();

  StreamSubscription<bool>? _sub;
  bool? _isFollowing;
  bool _isSaving = false;
  bool _canRender = false;

  @override
  void initState() {
    super.initState();
    _initRoleAndStream();
  }

  Future<void> _initRoleAndStream() async {
    final current = _authService.getCurrentUser();
    if (current == null) return;

    final viewer = await _authService.getUserById(current.uid);
    if (!mounted) return;

    // Only worshippers can follow.
    final canRender = viewer != null && viewer.role == UserRole.worshiper;
    setState(() => _canRender = canRender);

    if (!canRender) return;

    _sub?.cancel();
    _sub = _followService
        .isFollowingStream(
          worshipperId: widget.worshipperId,
          leaderId: widget.leaderId,
        )
        .listen(
          (v) {
            if (!mounted) return;
            setState(() => _isFollowing = v);
          },
          onError: (e) {
            // ignore: avoid_print
            print('❌ isFollowingStream error: $e');
          },
        );
  }

  @override
  void didUpdateWidget(covariant FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worshipperId != widget.worshipperId ||
        oldWidget.leaderId != widget.leaderId) {
      _isFollowing = null;
      _initRoleAndStream();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    final current = _isFollowing ?? false;
    final next = !current;

    setState(() {
      _isFollowing = next; // optimistic
      _isSaving = true;
    });

    try {
      await _followService.setFollowing(
        worshipperId: widget.worshipperId,
        leaderId: widget.leaderId,
        follow: next,
      );
    } catch (_) {
      if (!mounted) return;
      // rollback
      setState(() => _isFollowing = current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn\'t update follow status.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRender) return const SizedBox.shrink();

    final isFollowing = _isFollowing ?? false;

    const Color primary = Color(0xFF6366F1);
    const Color border = Color(0xFFE5E7EB);

    final height = widget.height ?? (widget.compact ? 34.0 : 40.0);
    final pad = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 12)
        : const EdgeInsets.symmetric(horizontal: 16);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _toggle,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: pad,
          backgroundColor: isFollowing ? Colors.white : primary,
          foregroundColor: isFollowing ? const Color(0xFF111827) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: widget.borderRadius,
            side: BorderSide(color: isFollowing ? border : primary),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _isSaving
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Center(
                  key: ValueKey(isFollowing ? 'following' : 'follow'),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
        ),
      ),
    );
  }
}
