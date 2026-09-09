import 'dart:ui';
import 'package:flutter/material.dart';

// ------------------------------------------------------------
// NO STRECH BEHAVIOUR
// ------------------------------------------------------------
class NoStretchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

// ------------------------------------------------------------
// GLASS THEME COLORS & CONSTANTS
// ------------------------------------------------------------
class GlassTheme {
  static const Color background = Color(0xFF060910);
  static const Color backgroundTop = Color.fromARGB(255, 19, 18, 56);
  static const Color cyan = Color(0xFF39D9FF);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFFF4FD8);
  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFF9AA8BA);
}

// ------------------------------------------------------------
// BACKGROUND & NEON GLOW EFFECTS
// ------------------------------------------------------------
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  Widget _buildGlowOrb(Color color, double size) {
    return IgnorePointer(
      child: 
        
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: .55),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      );
    
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [GlassTheme.backgroundTop, GlassTheme.background],
              ),
            ),
          ),
        ),
        // Neon Orbs
        Positioned(top: -90, left: -70, child: _buildGlowOrb(GlassTheme.cyan, 260)),
        Positioned(top: 140, right: -120, child: _buildGlowOrb(GlassTheme.purple, 300)),
        Positioned(bottom: -100, left: 80, child: _buildGlowOrb(GlassTheme.pink, 220)),
        Positioned(bottom: 60, right: 40, child: _buildGlowOrb(GlassTheme.cyan, 180)),
        
        child,
      ],
    );
  }
}

// ------------------------------------------------------------
// GLASS PANEL (Kapsayıcı Konteyner)
// ------------------------------------------------------------
class GlassPanel extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  const GlassPanel({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        // boxShadow: [
        //   BoxShadow(
        //     color: GlassTheme.cyan.withValues(alpha: .1),
        //     blurRadius: 40,
        //     spreadRadius: -6,
        //   ),
        //   BoxShadow(
        //     color: Colors.black.withValues(alpha: .25),
        //     blurRadius: 24,
        //     offset: const Offset(0, 12),
        //   ),
        // ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.045),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: .09),
                  Colors.white.withValues(alpha: .025),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: .14),
                width: 1.1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Row(
                    children: [
                      if (icon != null) ...[
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                GlassTheme.cyan.withValues(alpha: .22),
                                GlassTheme.purple.withValues(alpha: .14),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: GlassTheme.cyan.withValues(alpha: .25)),
                          ),
                          child: Icon(icon, size: 16, color: GlassTheme.cyan),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: const TextStyle(
                                  color: Color(0xFF8997AA),
                                  fontSize: 9,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// INTERACTIVE ACTION TILE
// ------------------------------------------------------------
class GlassActionTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const GlassActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<GlassActionTile> createState() => _GlassActionTileState();
}

class _GlassActionTileState extends State<GlassActionTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: GlassTheme.cyan.withValues(alpha: .28),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _hovering
                    ? [
                        GlassTheme.cyan.withValues(alpha: .14),
                        GlassTheme.purple.withValues(alpha: .1),
                      ]
                    : [
                        Colors.white.withValues(alpha: .035),
                        Colors.white.withValues(alpha: .02),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovering
                    ? GlassTheme.cyan.withValues(alpha: .35)
                    : Colors.white.withValues(alpha: .07),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              splashColor: GlassTheme.cyan.withValues(alpha: .15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [GlassTheme.cyan, GlassTheme.purple]),
                        borderRadius: BorderRadius.circular(8),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: GlassTheme.cyan.withValues(alpha: _hovering ? .55 : .25),
                        //     blurRadius: _hovering ? 14 : 8,
                        //   ),
                        // ],
                      ),
                      child: Icon(widget.icon, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        widget.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE9EEF5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// STAT & GROUP CARD WIDGETS
// ------------------------------------------------------------
class GlassStat extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;

  const GlassStat({
    super.key,
    required this.value,
    required this.label,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent ? GlassTheme.cyan : Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            shadows: accent
                ? [Shadow(color: GlassTheme.cyan.withValues(alpha: .7), blurRadius: 20)]
                : null,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8997AA), fontSize: 9),
        ),
      ],
    );
  }
}

class GlassGroupCard extends StatelessWidget {
  final String group;
  final int count;
  final VoidCallback onTap;

  const GlassGroupCard({
    super.key,
    required this.group,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = count > 0;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        splashColor: GlassTheme.cyan.withValues(alpha: .15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? GlassTheme.cyan.withValues(alpha: .07) : Colors.white.withValues(alpha: .025),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: active ? GlassTheme.cyan.withValues(alpha: .28) : Colors.white.withValues(alpha: .06),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: GlassTheme.cyan.withValues(alpha: .18),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  group,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? GlassTheme.cyan.withValues(alpha: .14) : Colors.white.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: active ? GlassTheme.cyan : const Color(0xFF8997AA),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}