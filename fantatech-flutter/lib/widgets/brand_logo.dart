import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Accent gradient: purple → magenta ───────────────────────────────────────

const _kAccentColors = [Color(0xFF7B2FFF), Color(0xFFFF2D8A)];

const _kAccentGradient = LinearGradient(
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
  colors: _kAccentColors,
);

// ─── BrandLogo ────────────────────────────────────────────────────────────────
//
// size:
//   BrandLogoSize.large   — login / splash  (big, with divider + subtitle)
//   BrandLogoSize.medium  — dashboard header (compact inline)
//   BrandLogoSize.small   — drawer / profile tiles (minimal)

enum BrandLogoSize { large, medium, small }

class BrandLogo extends StatelessWidget {
  final BrandLogoSize size;
  const BrandLogo({super.key, this.size = BrandLogoSize.large});

  @override
  Widget build(BuildContext context) {
    switch (size) {
      case BrandLogoSize.large:
        return _LargeLogo();
      case BrandLogoSize.medium:
        return _MediumLogo();
      case BrandLogoSize.small:
        return _SmallLogo();
    }
  }
}

// ── Large (login / splash) ────────────────────────────────────────────────────

class _LargeLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main title row: "Fanta" light + accent dot + "Tech" bold-gradient
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          textDirection: TextDirection.ltr,
          children: [
            // "Fanta" — ultra light white
            Text(
              'Fanta',
              style: GoogleFonts.outfit(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: -1,
                height: 1.0,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            // Accent dot
            Padding(
              padding: const EdgeInsets.only(bottom: 18, left: 3, right: 2),
              child: ShaderMask(
                shaderCallback: (b) => _kAccentGradient.createShader(b),
                blendMode: BlendMode.srcIn,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // "Tech" — heavy bold gradient
            ShaderMask(
              shaderCallback: (b) => _kAccentGradient.createShader(b),
              blendMode: BlendMode.srcIn,
              child: Text(
                'Tech',
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Thin gradient divider
        _AccentRule(width: 220),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'SMART HOME & SECURITY',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 3.5,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Medium (dashboard header) ─────────────────────────────────────────────────

class _MediumLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      textDirection: TextDirection.ltr,
      children: [
        Text(
          'Fanta',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2, right: 1),
          child: ShaderMask(
            shaderCallback: (b) => _kAccentGradient.createShader(b),
            blendMode: BlendMode.srcIn,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (b) => _kAccentGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Tech',
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Small (drawer / profile) ──────────────────────────────────────────────────

class _SmallLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      textDirection: TextDirection.ltr,
      children: [
        Text(
          'Fanta',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: -0.3,
            height: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 1, right: 1),
          child: ShaderMask(
            shaderCallback: (b) => _kAccentGradient.createShader(b),
            blendMode: BlendMode.srcIn,
            child: Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
        ShaderMask(
          shaderCallback: (b) => _kAccentGradient.createShader(b),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Tech',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Accent rule line ──────────────────────────────────────────────────────────

class _AccentRule extends StatelessWidget {
  final double width;
  const _AccentRule({required this.width});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (b) => LinearGradient(
        colors: [
          const Color(0x007B2FFF),
          const Color(0xFF7B2FFF),
          const Color(0xFFFF2D8A),
          const Color(0x00FF2D8A),
        ],
      ).createShader(b),
      blendMode: BlendMode.srcIn,
      child: Container(width: width, height: 1.5, color: Colors.white),
    );
  }
}
