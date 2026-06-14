import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:footballtraining/core/theme/app_theme.dart';

// ===============================
// GRADIENT BUTTON
// ===============================
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final bool isLoading;
  final double height;
  final bool compact;
  final IconData? icon;
  final bool expanded;
  final String? subtitle;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.isLoading = false,
    this.height = 54,
    this.compact = false,
    this.icon,
    this.expanded = false,
    this.subtitle,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.compact
            ? ScreenConfig.buttonHeightSmall
            : ScreenConfig.buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppTheme.primaryShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              splashColor: AppTheme.background.withValues(alpha:0.2),
              highlightColor: AppTheme.background.withValues(alpha:0.1),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.background,
                          strokeWidth: 3,
                        ),
                      )
                    : widget.expanded
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null || widget.leadingIcon != null) ...[
                              Icon(
                                widget.icon ?? widget.leadingIcon,
                                color: AppTheme.background,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.label,
                                  style: AppTheme.buttonText.copyWith(
                                    color: AppTheme.background,
                                  ),
                                ),
                                if (widget.subtitle != null)
                                  Text(
                                    widget.subtitle!,
                                    style: AppTheme.caption.copyWith(
                                      color: AppTheme.background.withValues(alpha: 0.8),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.leadingIcon != null) ...[
                              Icon(
                                widget.leadingIcon,
                                color: AppTheme.background,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: AppTheme.buttonText.copyWith(
                                color: AppTheme.background,
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

// ===============================
// OUTLINED PRIMARY BUTTON
// ===============================
class OutlinedPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final double height;
  final bool compact;

  const OutlinedPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.height = 54,
    this.compact = false,
  });

  @override
  State<OutlinedPrimaryButton> createState() => _OutlinedPrimaryButtonState();
}

class _OutlinedPrimaryButtonState extends State<OutlinedPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: widget.compact
            ? ScreenConfig.buttonHeightSmall
            : ScreenConfig.buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(14),
              splashColor: AppTheme.primary.withValues(alpha:0.1),
              highlightColor: AppTheme.primary.withValues(alpha:0.05),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.leadingIcon != null) ...[
                      Icon(
                        widget.leadingIcon,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: AppTheme.buttonText.copyWith(
                        color: AppTheme.primary,
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

// ===============================
// APP CARD
// ===============================
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? ScreenConfig.cardPadding;
    Widget cardWidget = Container(
      margin: margin,
      decoration: AppTheme.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ScreenConfig.radiusL),
        child: Padding(padding: effectivePadding, child: child),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ScreenConfig.radiusL),
          splashColor: AppTheme.primary.withValues(alpha:0.08),
          highlightColor: AppTheme.primary.withValues(alpha:0.04),
          child: cardWidget,
        ),
      );
    }

    return cardWidget;
  }
}

// ===============================
// GRADIENT AVATAR
// ===============================
class GradientAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Gradient? gradient;
  final String? defaultAsset;
  final Color? borderColor;
  final IconData? icon;
  final bool compact;

  const GradientAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 48,
    this.gradient,
    this.defaultAsset,
    this.borderColor,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = compact ? size * 0.75 : size;

    Widget content;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: effectiveSize,
          height: effectiveSize,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(
              color: AppTheme.background,
              strokeWidth: 2,
            ),
          ),
          errorWidget: (context, url, error) => _buildFallback(effectiveSize),
        ),
      );
    } else if (icon != null) {
      content = Icon(icon!, color: Colors.white, size: effectiveSize * 0.45);
    } else if (defaultAsset != null) {
      content = ClipOval(
        child: Image.asset(
          defaultAsset!,
          width: effectiveSize,
          height: effectiveSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(effectiveSize),
        ),
      );
    } else {
      content = _buildFallback(effectiveSize);
    }

    Widget avatar = Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient ?? AppTheme.primaryGradient,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha:0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(child: Center(child: content)),
    );

    return avatar;
  }

  Widget _buildFallback(double effectiveSize) {
    return Container(
      width: effectiveSize,
      height: effectiveSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient ?? AppTheme.primaryGradient,
      ),
      child: Center(
        child: Text(
          initials != null && initials!.isNotEmpty
              ? initials![0].toUpperCase()
              : 'U',
          style: GoogleFonts.syne(
            fontSize: effectiveSize * 0.4,
            fontWeight: FontWeight.w800,
            color: AppTheme.background,
          ),
        ),
      ),
    );
  }
}

// ===============================
// STATUS BADGE
// ===============================
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        borderRadius: BorderRadius.circular(ScreenConfig.radiusL),
        border: Border.all(color: color.withValues(alpha:0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: compact ? 12 : 14,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: AppTheme.label.copyWith(
              color: color,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// GRADIENT ICON
// ===============================
class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Gradient? gradient;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 20,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.primaryShadow,
      ),
      child: Center(
        child: Icon(
          icon,
          color: AppTheme.background,
          size: iconSize,
        ),
      ),
    );
  }
}

// ===============================
// STAT CARD
// ===============================
class StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final double? progress;
  final Color? progressColor;

  const StatCard({
    super.key,
    required this.number,
    required this.label,
    required this.icon,
    this.progress,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIcon(icon: icon, size: 40, iconSize: 18),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedCounter(
            target: int.tryParse(number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
            style: AppTheme.statNumber,
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: AppTheme.overline,
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress! / 100,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? AppTheme.primary,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ],
      ),
    );
  }
}

// ===============================
// SECTION HEADER
// ===============================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTheme.heading3),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// ===============================
// ANIMATED COUNTER
// ===============================
class AnimatedCounter extends StatelessWidget {
  final int target;
  final TextStyle style;

  const AnimatedCounter({
    super.key,
    required this.target,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          value.toInt().toString(),
          style: style,
        );
      },
    );
  }
}

// ===============================
// PREMIUM TEXT FIELD
// ===============================
class PremiumTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final IconData? leadingIcon;
  final Widget? trailingWidget;
  final TextEditingController? controller;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;

  const PremiumTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.leadingIcon,
    this.trailingWidget,
    this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      style: AppTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: leadingIcon != null
            ? Icon(leadingIcon, color: AppTheme.primary)
            : null,
        suffixIcon: trailingWidget,
        filled: true,
        fillColor: enabled
            ? AppTheme.surface2
            : AppTheme.surface2.withValues(alpha: 0.5),
      ),
    );
  }
}

// ===============================
// SHIMMER CARD
// ===============================
class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const ShimmerCard({
    super.key,
    this.height = 80,
    this.width,
    this.margin,
  });

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ScreenConfig.radiusL),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _controller.value * 2, 0),
              end: Alignment(1.0 + _controller.value * 2, 0),
              colors: const [
                AppTheme.surface2,
                AppTheme.surfaceHigh,
                AppTheme.surface2,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===============================
// PREMIUM APP BAR
// ===============================
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading != null
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: leading,
            )
          : null,
      title: subtitle != null
          ? Column(
              children: [
                Text(title, style: AppTheme.heading2),
                Text(subtitle!, style: AppTheme.caption),
              ],
            )
          : Text(title, style: AppTheme.heading2),
      actions: actions
          ?.map((action) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: action,
              ))
          .toList(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ===============================
// STAGGERED LIST
// ===============================
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final int staggerMs;

  const StaggeredList({
    super.key,
    required this.children,
    this.staggerMs = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (entry.key * staggerMs)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: entry.value,
        );
      }).toList(),
    );
  }
}

// ===============================
// PREMIUM DRAWER HEADER
// ===============================
class PremiumDrawerHeader extends StatelessWidget {
  final String name;
  final String role;
  final String? imageUrl;

  const PremiumDrawerHeader({
    super.key,
    required this.name,
    required this.role,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: CustomPaint(
        painter: _PitchLinePainter(),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientAvatar(
                  imageUrl: imageUrl,
                  initials: name.isNotEmpty ? name[0] : 'U',
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(name, style: AppTheme.heading3),
                const SizedBox(height: 4),
                Text(role, style: AppTheme.caption),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PitchLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textPrimary.withValues(alpha:0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double i = 0; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ===============================
// ROLE CHIP
// ===============================
class RoleChip extends StatelessWidget {
  final String role;

  const RoleChip({super.key, required this.role});

  Color get roleColor {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.primary;
      case 'coach':
        return const Color(0xFF4A9EFF);
      case 'receptionist':
        return AppTheme.success;
      default:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: role, color: roleColor);
  }
}

// ===============================
// PREMIUM FAB
// ===============================
class PremiumFAB extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const PremiumFAB({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.primaryShadow,
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: Icon(icon, color: AppTheme.background),
        label: Text(
          label,
          style: AppTheme.buttonText.copyWith(color: AppTheme.background),
        ),
      ),
    );
  }
}