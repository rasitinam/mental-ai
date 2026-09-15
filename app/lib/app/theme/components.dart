import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'glass.dart';

/// A 44-tall ink-outlined pill with an icon and a label — the header actions
/// ("Destek", "Tercihler", "Mesajlar"). [count] shows a badge after the
/// label; [iconOnly] keeps the tooltip for narrow screens.
class PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final int count;
  final bool iconOnly;

  const PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.count = 0,
    this.iconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: count > 0 ? '$label, $count' : label,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          shape: StadiumBorder(side: BorderSide(color: palette.textPrimary, width: 1.5)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 44,
              width: iconOnly ? 44 : null,
              child: Padding(
                padding: iconOnly ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 0, 14, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20, color: palette.textPrimary),
                    if (!iconOnly) ...[
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: AppTypography.label.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    if (count > 0) ...[const SizedBox(width: 7), CountBadge(count: count, size: 22)],
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

/// A red count bubble — unread messages.
class CountBadge extends StatelessWidget {
  final int count;
  final double size;
  final Color? ring;

  const CountBadge({super.key, required this.count, this.size = 18, this.ring});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: EdgeInsets.symmetric(horizontal: size > 20 ? 6 : 5),
      decoration: BoxDecoration(
        color: palette.badge,
        borderRadius: BorderRadius.circular(size / 2),
        border: ring == null ? null : Border.all(color: ring!, width: 2),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            fontFamily: AppTypography.bodyFamily,
            fontSize: size > 20 ? 12 : 11,
            height: 1,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// "Destek": always one tap away on Bugün and Sohbet, not only when the
/// app happens to notice hard language.
class SupportPill extends StatelessWidget {
  final bool iconOnly;
  const SupportPill({super.key, this.iconOnly = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PillButton(
      icon: Icons.support_rounded,
      label: l10n.supportPill,
      iconOnly: iconOnly,
      onTap: () => showSupportSheet(context),
    );
  }
}

/// Turkey's single emergency number — not configurable per user, since
/// there's no reliable, low-risk way to infer someone's actual country.
const emergencyNumber = '112';

Future<void> showSupportSheet(BuildContext context) {
  final router = GoRouter.maybeOf(context);

  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final palette = AppPalette.of(sheetContext);
      final l10n = AppLocalizations.of(sheetContext)!;

      return SheetFrame(
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: palette.warningSoft, shape: BoxShape.circle),
              child: Icon(Icons.support_rounded, size: 28, color: palette.warning),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.chatCrisisTitle, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
          const SizedBox(height: 8),
          Text(l10n.supportSheetBody, style: AppTypography.body.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: Material(
              color: palette.warning,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => launchUrl(Uri(scheme: 'tel', path: emergencyNumber)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_rounded, size: 20, color: palette.warningSoft),
                    const SizedBox(width: 9),
                    Text(
                      l10n.chatCallEmergency,
                      style: AppTypography.label.copyWith(
                        color: palette.warningSoft,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlineBlockButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: l10n.supportWriteInChat,
            onTap: () {
              Navigator.of(sheetContext).pop();
              router?.go('/chat');
            },
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: () => Navigator.of(sheetContext).pop(), child: Text(l10n.commonClose)),
        ],
      );
    },
  );
}

/// The ink-outlined sibling of [AppPrimaryButton].
class OutlineBlockButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final double height;
  final double radius;

  const OutlineBlockButton({
    super.key,
    this.icon,
    required this.label,
    required this.onTap,
    this.height = 52,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: palette.textPrimary, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: palette.textPrimary), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 44-tall stadium chip: ink when selected, [fill] otherwise.
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? fill;
  final bool outlined;

  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.fill,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final background = selected ? palette.accent : (outlined ? Colors.transparent : (fill ?? palette.glassFill));

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: background,
        shape: StadiumBorder(
          side: outlined && !selected
              ? BorderSide(color: palette.textPrimary.withValues(alpha: 0.3), width: 1.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 17, color: palette.onAccent),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: AppTypography.label.copyWith(color: selected ? palette.onAccent : palette.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A small colored label: a discovery's kind, a story's diagnosis, a band.
class TintTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final double height;

  const TintTag({super.key, required this.label, required this.color, this.outlined = false, this.height = 26});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final foreground = outlined ? palette.textPrimary : AppPalette.inkOn(color);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        borderRadius: BorderRadius.circular(height > 26 ? 10 : 8),
        border: outlined ? Border.all(color: palette.textPrimary, width: 1.5) : null,
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: foreground,
            fontSize: height > 26 ? 13.5 : 12.5,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// A 54×32 switch in ink.
class AppToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  const AppToggle({super.key, required this.value, required this.onChanged, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final enabled = onChanged != null;

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 54,
              height: 32,
              padding: const EdgeInsets.all(4),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: value ? palette.accent : palette.separator,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? palette.canvasTop : Colors.white,
                  boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The body of every bottom sheet: card fill, 32px top corners, a handle,
/// and bottom padding that clears the system inset.
class SheetFrame extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  const SheetFrame({super.key, required this.children, this.crossAxisAlignment = CrossAxisAlignment.stretch});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: palette.glassFill,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(22, 12, 22, 30 + MediaQuery.paddingOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: palette.separator, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A section heading on a tab page: a title, and on the right either an
/// underlined action or a quiet note.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? trailingNote;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.action, this.onAction, this.trailingNote, this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(title, style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 19)),
          ),
          if (trailingNote != null)
            Text(
              trailingNote!,
              style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 14.5),
            ),
          ?trailing,
          if (action != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    widthFactor: 1,
                    child: Text(
                      action!,
                      style: AppTypography.label.copyWith(
                        color: palette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A card of rows separated by hairlines.
class ListGroup extends StatelessWidget {
  final List<Widget> children;
  const ListGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GlassSurface(
      radius: 24,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) Divider(height: 1, thickness: 1, color: palette.separator, indent: 16),
          ],
        ],
      ),
    );
  }
}

/// One row: a tinted icon square, a label with an optional line under it,
/// and a trailing widget or a chevron.
class ListRow extends StatelessWidget {
  final IconData? icon;
  final Color? tint;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;
  final bool showChevron;

  const ListRow({
    super.key,
    this.icon,
    this.tint,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.labelColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final iconBackground = tint ?? palette.canvasTop;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  icon,
                  size: 21,
                  color: tint == null ? palette.textPrimary : AppPalette.inkOn(iconBackground),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color: labelColor ?? palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 14.5),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            if (trailing == null && onTap != null && showChevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 22, color: palette.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

/// A standalone outlined row — the way into Rehber.
class OutlinedLinkRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const OutlinedLinkRow({
    super.key,
    required this.icon,
    required this.tint,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: palette.separator, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 21, color: AppPalette.inkOn(tint)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.label.copyWith(
                        color: palette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 22, color: palette.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

/// A back button plus a pushed-screen title, the header most sub-pages use.
class BackTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  const BackTitle({super.key, required this.title, this.onBack, this.trailing});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Row(
      children: [
        SquareIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(title, style: AppTypography.title3.copyWith(color: palette.textPrimary)),
        ),
        ?trailing,
      ],
    );
  }
}
