import 'package:flutter/material.dart';
import 'package:reelscholar/core/constants/app_colors.dart';

/// Splash-style logo badge — white rounded box with bold "R"
class AppLogoBadge extends StatelessWidget {
  final double size;
  const AppLogoBadge({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'R',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: size * 0.48,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Error banner
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success banner
class AuthSuccessBanner extends StatelessWidget {
  final String message;
  const AuthSuccessBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF15803D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Field label with optional required asterisk
class FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const FieldLabel(this.text, {super.key, this.required = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }
}

/// Returns a theme-aware InputDecoration for auth screens
InputDecoration authInputDecoration({
  required bool isDark,
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final fillColor =
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  final borderColor =
      isDark ? Colors.white12 : const Color(0xFFE2E8F0);
  final hintColor =
      isDark ? Colors.white30 : const Color(0xFF94A3B8);
  final radius = BorderRadius.circular(14.0);

  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 14,
      color: hintColor,
    ),
    filled: true,
    fillColor: fillColor,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor)),
    enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error, width: 2)),
    errorStyle: const TextStyle(fontFamily: 'DM Sans', fontSize: 11),
  );
}

/// Text style for text typed inside auth fields
TextStyle authInputTextStyle(bool isDark) => TextStyle(
      fontFamily: 'DM Sans',
      fontSize: 14,
      color: isDark ? Colors.white : const Color(0xFF1E293B),
    );

/// Loading state for primary button
class PrimaryButtonChild extends StatelessWidget {
  final String label;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButtonChild({
    super.key,
    required this.label,
    required this.isLoading,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(width: 6),
          Icon(icon, size: 18, color: Colors.white),
        ],
      );
    }
    return Text(
      label,
      style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white),
    );
  }
}

/// Divider with centred "or" label
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor =
        isDark ? Colors.white12 : AppColors.border;
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: lineColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontSize: 12,
              color: isDark ? Colors.white38 : AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: lineColor)),
      ],
    );
  }
}
