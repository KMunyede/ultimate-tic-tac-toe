// lib/widgets/profile/profile_header.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final bool isGuest;
  final bool isAdmin;
  final AppTheme theme;
  final bool isEditingName;
  final bool isSavingName;
  final TextEditingController displayNameController;
  final VoidCallback onEditName;
  final VoidCallback onUpdateName;
  final VoidCallback onCancelEdit;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isGuest,
    required this.isAdmin,
    required this.theme,
    required this.isEditingName,
    required this.isSavingName,
    required this.displayNameController,
    required this.onEditName,
    required this.onUpdateName,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.mainColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.mainColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [theme.mainColor, theme.accentGlow],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Center(
                  child: Text(
                    isGuest ? 'G' : (user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : 'U'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              if (isAdmin)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_user_rounded, size: 12, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isEditingName)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: displayNameController,
                            style: TextStyle(color: theme.textColor, fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              isDense: true,
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.mainColor)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      isSavingName
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green), onPressed: onUpdateName),
                      IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.red), onPressed: onCancelEdit),
                    ],
                  )
                else
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isGuest ? 'Guest Player' : (user.displayName ?? 'Registered Gamer'),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isGuest)
                        IconButton(icon: Icon(Icons.edit_rounded, size: 16, color: theme.mainColor), onPressed: onEditName),
                    ],
                  ),
                Row(
                  children: [
                    if (isAdmin) ...[
                      const Icon(Icons.shield_rounded, size: 12, color: Color(0xFFFF8F00)),
                      const SizedBox(width: 4),
                      const Text('SuperAdmin • ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFFF8F00))),
                    ],
                    Expanded(
                      child: Text(
                        isGuest ? 'Temporary Offline Session' : (user.email ?? 'Verified Account'),
                        style: TextStyle(fontSize: 11.5, color: theme.textColor.withValues(alpha: 0.65)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
