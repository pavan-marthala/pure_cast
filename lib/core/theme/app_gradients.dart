import 'package:material_ui/material_ui.dart';

@immutable
class AppGradients extends ThemeExtension<AppGradients> {
  // ── Core ──
  final LinearGradient primary;
  final LinearGradient primaryReverse;
  final LinearGradient primaryVertical;
  final LinearGradient secondary;
  final LinearGradient secondaryReverse;

  // ── Glass / Brand blend ──
  final LinearGradient glass;
  final LinearGradient glassReverse;
  final LinearGradient glassVertical;

  // ── Signature combos ──
  final LinearGradient purpleRose;
  final LinearGradient rosePurple;
  final LinearGradient purpleIndigo;
  final LinearGradient roseDeep;

  // ── Backgrounds ──
  final LinearGradient backgroundDark;
  final LinearGradient backgroundLight;
  final LinearGradient surface;

  // ── Overlays ──
  final LinearGradient glassOverlay;
  final LinearGradient glassOverlaySubtle;
  final LinearGradient overlayBottom;
  final LinearGradient overlayTop;

  // ── Utility ──
  final LinearGradient shimmer;
  final LinearGradient welcomeBox;

  // ── Password strength ──
  final LinearGradient passwordWeak;
  final LinearGradient passwordMedium;
  final LinearGradient passwordStrong;

  const AppGradients({
    required this.primary,
    required this.primaryReverse,
    required this.primaryVertical,
    required this.secondary,
    required this.secondaryReverse,
    required this.glass,
    required this.glassReverse,
    required this.glassVertical,
    required this.purpleRose,
    required this.rosePurple,
    required this.purpleIndigo,
    required this.roseDeep,
    required this.backgroundDark,
    required this.backgroundLight,
    required this.surface,
    required this.glassOverlay,
    required this.glassOverlaySubtle,
    required this.overlayBottom,
    required this.overlayTop,
    required this.shimmer,
    required this.welcomeBox,
    required this.passwordWeak,
    required this.passwordMedium,
    required this.passwordStrong,
  });

  // ── Dark Preset ──────────────────────────────────────────────
  static final dark = AppGradients(
    primary: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFFFA94D), Color(0xFFF97316)],
    ),
    primaryReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFFFFA94D), Color(0xFFF97316)],
    ),
    primaryVertical: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFA94D), Color(0xFFF97316)],
    ),

    // Secondary — lighter maroon/red (dark mode)
    secondary: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFC23B4A), Color(0xFFE05252)],
    ),
    secondaryReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFFC23B4A), Color(0xFFE05252)],
    ),

    // Glass — orange → gold diagonal blend (matches prototype --grad-glass)
    glass: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFFFA94D), Color(0xFFE8C868)],
    ),
    glassReverse: const LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [Color(0xFFFFA94D), Color(0xFFE8C868)],
    ),
    glassVertical: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFA94D), Color(0xFFE8C868)],
    ),

    // Signature combos
    purpleRose: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFA94D), Color(0xFFC23B4A)], // orange → maroon
    ),
    rosePurple: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFC23B4A), Color(0xFFFFA94D)], // maroon → orange
    ),
    purpleIndigo: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE8C868), Color(0xFFFFA94D)], // gold → orange
    ),
    roseDeep: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE05252), Color(0xFFC23B4A)], // red → deep maroon
    ),

    // Backgrounds
    backgroundDark: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF15120F), Color(0xFF211D19)], // bg → surface
    ),
    backgroundLight: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF211D19),
        Color(0xFF2D2925),
      ], // surface → surface-secondary
    ),
    surface: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF2D2925),
        Color(0xFF3B342F),
      ], // surface-secondary → border
    ),

    // Overlays
    glassOverlay: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF97316).withValues(alpha: 0.15),
        const Color(0xFF8B1E2D).withValues(alpha: 0.15),
      ],
    ),
    glassOverlaySubtle: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF97316).withValues(alpha: 0.08),
        const Color(0xFF8B1E2D).withValues(alpha: 0.08),
      ],
    ),
    overlayBottom: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        const Color(0xFF000000).withValues(alpha: 0.8),
      ],
    ),
    overlayTop: LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        Colors.transparent,
        const Color(0xFF000000).withValues(alpha: 0.8),
      ],
    ),

    // Shimmer — subtle white flash for skeleton loaders
    shimmer: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Colors.transparent,
        Colors.white.withValues(alpha: 0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    ),

    // Welcome box tint
    welcomeBox: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF97316).withValues(alpha: 0.10),
        const Color(0xFF8B1E2D).withValues(alpha: 0.10),
      ],
    ),

    // Password strength indicators (shared across presets)
    passwordWeak: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFF87171), Color(0xFFDC2626)],
    ),
    passwordMedium: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    ),
    passwordStrong: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF34D399), Color(0xFF16A34A)],
    ),
  );

  @override
  AppGradients copyWith({
    LinearGradient? primary,
    LinearGradient? primaryReverse,
    LinearGradient? primaryVertical,
    LinearGradient? secondary,
    LinearGradient? secondaryReverse,
    LinearGradient? glass,
    LinearGradient? glassReverse,
    LinearGradient? glassVertical,
    LinearGradient? purpleRose,
    LinearGradient? rosePurple,
    LinearGradient? purpleIndigo,
    LinearGradient? roseDeep,
    LinearGradient? backgroundDark,
    LinearGradient? backgroundLight,
    LinearGradient? surface,
    LinearGradient? glassOverlay,
    LinearGradient? glassOverlaySubtle,
    LinearGradient? overlayBottom,
    LinearGradient? overlayTop,
    LinearGradient? shimmer,
    LinearGradient? welcomeBox,
    LinearGradient? passwordWeak,
    LinearGradient? passwordMedium,
    LinearGradient? passwordStrong,
  }) {
    return AppGradients(
      primary: primary ?? this.primary,
      primaryReverse: primaryReverse ?? this.primaryReverse,
      primaryVertical: primaryVertical ?? this.primaryVertical,
      secondary: secondary ?? this.secondary,
      secondaryReverse: secondaryReverse ?? this.secondaryReverse,
      glass: glass ?? this.glass,
      glassReverse: glassReverse ?? this.glassReverse,
      glassVertical: glassVertical ?? this.glassVertical,
      purpleRose: purpleRose ?? this.purpleRose,
      rosePurple: rosePurple ?? this.rosePurple,
      purpleIndigo: purpleIndigo ?? this.purpleIndigo,
      roseDeep: roseDeep ?? this.roseDeep,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      surface: surface ?? this.surface,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      glassOverlaySubtle: glassOverlaySubtle ?? this.glassOverlaySubtle,
      overlayBottom: overlayBottom ?? this.overlayBottom,
      overlayTop: overlayTop ?? this.overlayTop,
      shimmer: shimmer ?? this.shimmer,
      welcomeBox: welcomeBox ?? this.welcomeBox,
      passwordWeak: passwordWeak ?? this.passwordWeak,
      passwordMedium: passwordMedium ?? this.passwordMedium,
      passwordStrong: passwordStrong ?? this.passwordStrong,
    );
  }

  // ── lerp ─────────────────────────────────────────────────────
  @override
  AppGradients lerp(covariant ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      primary: LinearGradient.lerp(primary, other.primary, t)!,
      primaryReverse: LinearGradient.lerp(
        primaryReverse,
        other.primaryReverse,
        t,
      )!,
      primaryVertical: LinearGradient.lerp(
        primaryVertical,
        other.primaryVertical,
        t,
      )!,
      secondary: LinearGradient.lerp(secondary, other.secondary, t)!,
      secondaryReverse: LinearGradient.lerp(
        secondaryReverse,
        other.secondaryReverse,
        t,
      )!,
      glass: LinearGradient.lerp(glass, other.glass, t)!,
      glassReverse: LinearGradient.lerp(glassReverse, other.glassReverse, t)!,
      glassVertical: LinearGradient.lerp(
        glassVertical,
        other.glassVertical,
        t,
      )!,
      purpleRose: LinearGradient.lerp(purpleRose, other.purpleRose, t)!,
      rosePurple: LinearGradient.lerp(rosePurple, other.rosePurple, t)!,
      purpleIndigo: LinearGradient.lerp(purpleIndigo, other.purpleIndigo, t)!,
      roseDeep: LinearGradient.lerp(roseDeep, other.roseDeep, t)!,
      backgroundDark: LinearGradient.lerp(
        backgroundDark,
        other.backgroundDark,
        t,
      )!,
      backgroundLight: LinearGradient.lerp(
        backgroundLight,
        other.backgroundLight,
        t,
      )!,
      surface: LinearGradient.lerp(surface, other.surface, t)!,
      glassOverlay: LinearGradient.lerp(glassOverlay, other.glassOverlay, t)!,
      glassOverlaySubtle: LinearGradient.lerp(
        glassOverlaySubtle,
        other.glassOverlaySubtle,
        t,
      )!,
      overlayBottom: LinearGradient.lerp(
        overlayBottom,
        other.overlayBottom,
        t,
      )!,
      overlayTop: LinearGradient.lerp(overlayTop, other.overlayTop, t)!,
      shimmer: LinearGradient.lerp(shimmer, other.shimmer, t)!,
      welcomeBox: LinearGradient.lerp(welcomeBox, other.welcomeBox, t)!,
      passwordWeak: LinearGradient.lerp(passwordWeak, other.passwordWeak, t)!,
      passwordMedium: LinearGradient.lerp(
        passwordMedium,
        other.passwordMedium,
        t,
      )!,
      passwordStrong: LinearGradient.lerp(
        passwordStrong,
        other.passwordStrong,
        t,
      )!,
    );
  }
}
