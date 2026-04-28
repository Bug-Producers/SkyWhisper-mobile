/// Centralized color palette for the SkyWhisper application.
///
/// All colors used throughout the app are defined here to maintain
/// consistency and enable easy theming. The palette is derived from
/// the SkyWhisper design system featuring cool blues, teals, and
/// neutral grays on a soft white background.
library;

import 'package:flutter/material.dart';

/// Provides a unified set of [Color] constants used across all
/// SkyWhisper widgets and screens.
abstract final class AppColors {
  // ───────────────────── Brand ─────────────────────

  /// Primary brand blue used for the logo, accents, and active indicators.
  static const Color primary = Color(0xFF1A8CFF);

  /// Darker shade of primary used for emphasized text and headings.
  static const Color primaryDark = Color(0xFF0D6EFD);

  /// Teal accent used for the humidity ring and secondary highlights.
  static const Color teal = Color(0xFF00BFA6);

  /// Lighter teal for gradient fills and decorative arcs.
  static const Color tealLight = Color(0xFF80DFCC);

  // ───────────────────── Backgrounds ─────────────────────

  /// Main scaffold background — a very faint blue-gray.
  static const Color background = Color(0xFFF4F7FB);

  /// Card surface color — pure white for elevated containers.
  static const Color cardSurface = Color(0xFFFFFFFF);

  /// Subtle border color used on cards and dividers.
  static const Color border = Color(0xFFE8EDF3);

  // ───────────────────── Text ─────────────────────

  /// Primary text color for headings and large numbers.
  static const Color textPrimary = Color(0xFF1A1D26);

  /// Secondary text color for labels, subtitles, and metadata.
  static const Color textSecondary = Color(0xFF8E99A8);

  /// Muted text color for hints and disabled states.
  static const Color textMuted = Color(0xFFB0B9C6);

  // ───────────────────── Semantic ─────────────────────

  /// Green used for positive trend indicators (e.g. "+2.4 hPa/h").
  static const Color positive = Color(0xFF00C48C);

  /// Ring track color — the faint background arc behind progress rings.
  static const Color ringTrack = Color(0xFFE8EDF3);

  // ───────────────────── Chart ─────────────────────

  /// Gradient start color for the area fill beneath the climate chart line.
  static const Color chartGradientStart = Color(0x331A8CFF);

  /// Gradient end color (transparent) for the area fill fade-out.
  static const Color chartGradientEnd = Color(0x001A8CFF);

  /// The climate chart line color.
  static const Color chartLine = Color(0xFF1A8CFF);

  // ───────────────────── Live indicator ─────────────────────

  /// Bright green dot indicating live / real-time data.
  static const Color liveGreen = Color(0xFF34D399);
}
