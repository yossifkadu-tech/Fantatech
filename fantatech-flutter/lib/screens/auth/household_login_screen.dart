// ─────────────────────────────────────────────────────────────────────────────
// HouseholdLoginScreen
//
// Shows existing member profiles so a household member can enter without auth.
// If no home manager exists yet, shows an info message.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/app_state.dart';
import '../../services/auth/user_service.dart';
import '../../widgets/app_background.dart';

class HouseholdLoginScreen extends StatelessWidget {
  final void Function(AppUser user) onLogin;
  const HouseholdLoginScreen({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final manager = UserService.homeManager;
    final members = UserService.members;
    final s = context.watch<AppState>().strings;

    return Scaffold(
      backgroundColor: const Color(0xFF1D75BD),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.loginHousehold,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: manager == null
                ? _NoManagerState()
                : _MemberPicker(
                    manager: manager,
                    members: members,
                    onLogin: onLogin,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── No manager yet ─────────────────────────────────────────────────────────

class _NoManagerState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.people_outline, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'עדיין אין מנהל בית',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'כניסה כחבר בית זמינה לאחר שמנהל הבית\nנרשם עם Google או Apple.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3C4043),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'חזור למסך הכניסה',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Member picker ──────────────────────────────────────────────────────────

class _MemberPicker extends StatelessWidget {
  final AppUser manager;
  final List<AppUser> members;
  final void Function(AppUser) onLogin;

  const _MemberPicker({
    required this.manager,
    required this.members,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Manager info banner — white card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                child: Text(
                  manager.name.isNotEmpty ? manager.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'מנהל הבית',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Section title
        Text(
          members.isEmpty ? 'אין חברי בית עדיין' : 'בחר פרופיל',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),

        const SizedBox(height: 12),

        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'מנהל הבית יכול להוסיף חברי בית\nבאזור הפרופיל ← ניהול בית.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final member = members[i];
                return _MemberTile(
                  member: member,
                  onTap: () async {
                    await UserService.signInAsMember(member);
                    if (ctx.mounted) onLogin(member);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final AppUser member;
  final VoidCallback onTap;

  const _MemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF1D75BD).withValues(alpha: 0.15),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF1D75BD),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: Color(0xFF3C4043),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (member.phone.isNotEmpty)
                    Text(
                      member.phone,
                      style: TextStyle(
                        color: const Color(0xFF3C4043).withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1D75BD).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.login, color: Color(0xFF1D75BD), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
