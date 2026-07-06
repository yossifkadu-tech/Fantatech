import 'package:material_symbols_icons/symbols.dart';
// ─────────────────────────────────────────────────────────────────────────────
// HouseholdLoginScreen
//
// Shows existing member profiles so a household member can enter without auth.
// If no home manager exists yet, shows an info message.
// ─────────────────────────────────────────────────────────────────────────────
import '../../theme/app_theme.dart';
import '../../widgets/ft_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/app_state.dart';
import '../../services/auth/user_service.dart';
import '../../widgets/app_background.dart';

class HouseholdLoginScreen extends StatelessWidget {
  final void Function(AppUser user) onLogin;
  const HouseholdLoginScreen({super.key, required this.onLogin});

  // Bridge a household HomeUser (profile → home management) to an AppUser the
  // login flow understands.
  static AppUser _toAppUser(HomeUser h) => AppUser(
        id:           h.id,
        name:         h.name,
        email:        '',
        role:         h.isManager ? UserRole.homeManager : UserRole.member,
        authProvider: AuthProvider.member,
        photoUrl:     h.imagePath,
        registeredAt: DateTime.now(),
        isApproved:   true,
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    // Read from the household list the user actually manages in the app.
    final homeUsers = state.homeUsers;
    final manager = homeUsers.where((u) => u.isManager).map(_toAppUser).firstOrNull;
    final members = homeUsers.where((u) => !u.isManager).map(_toAppUser).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1D75BD),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Symbols.arrow_back_ios_new, color: context.tText2(0.7), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          s.loginHousehold,
          style: TextStyle(color: context.tText, fontSize: 17, fontWeight: FontWeight.bold),
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
    final s = context.select((AppState st) => st.strings);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.tText2(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: context.tText2(0.3)),
            ),
            child: Icon(Symbols.people, color: context.tText, size: 36),
          ),
          const SizedBox(height: 20),
          Text(
            s.householdNoAdmin,
            style: TextStyle(
              color: context.tText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.householdMemberNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.tText2(0.75),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          FtButton(
            label: s.backToLogin,
            variant: FtButtonVariant.neutral,
            expand: true,
            onTap: () => Navigator.pop(context),
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
    final s = context.select((AppState st) => st.strings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),

        // Manager info banner — white card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.tText2(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.tText2(0.3)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.tText2(0.25),
                child: Text(
                  manager.name.isNotEmpty ? manager.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: context.tText,
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
                      style: TextStyle(
                        color: context.tText,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Symbols.verified, color: context.tText2(0.7), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          s.householdAdmin,
                          style: TextStyle(
                            color: context.tText2(0.7),
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
          members.isEmpty ? s.noMembersYet : s.selectProfile,
          style: TextStyle(
            color: context.tText2(0.75),
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
                s.addMembersHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.tText2(0.6),
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
          color: context.tText,
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
                style: TextStyle(
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
                    style: TextStyle(
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
              child: Icon(Symbols.login, color: Color(0xFF1D75BD), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
