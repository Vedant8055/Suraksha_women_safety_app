import 'package:flutter/material.dart';

class PremiumDialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const PremiumDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });
}

class PremiumDialogSurface extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? child;
  final IconData icon;
  final Color accentColor;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const PremiumDialogSurface({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.actions,
    this.message,
    this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 22, 22, 20),
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: isLight
                ? [
                    Colors.white,
                    Color.lerp(Colors.white, accentColor, 0.08)!,
                    Color.lerp(const Color(0xFFF6F8FC), accentColor, 0.12)!,
                  ]
                : [
                    const Color(0xFF121826),
                    Color.lerp(const Color(0xFF121826), accentColor, 0.16)!,
                    const Color(0xFF0C1320),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: isLight ? 0.26 : 0.36),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isLight ? 0.22 : 0.34),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.28),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -26,
              top: -26,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isLight ? 0.08 : 0.14),
                ),
              ),
            ),
            Positioned(
              left: -34,
              bottom: -36,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: isLight ? 0.06 : 0.10),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.95),
                          accentColor.withValues(alpha: 0.68),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(
                            alpha: isLight ? 0.24 : 0.34,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: TextStyle(
                      color: isLight ? const Color(0xFF172235) : Colors.white,
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      message!,
                      style: TextStyle(
                        color: isLight
                            ? const Color(0xFF516078)
                            : Colors.white.withValues(alpha: 0.78),
                        fontSize: 14.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (child != null) ...[const SizedBox(height: 14), child!],
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showPremiumDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required Color accentColor,
  required List<PremiumDialogAction> actions,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final buttons = [
        for (final action in actions)
          action.isPrimary
              ? ElevatedButton(
                  onPressed: () => action.onPressed(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    action.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              : OutlinedButton(
                  onPressed: () => action.onPressed(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(dialogContext).brightness == Brightness.light
                        ? const Color(0xFF172235)
                        : Colors.white,
                    side: BorderSide(
                      color: accentColor.withValues(
                        alpha:
                            Theme.of(dialogContext).brightness ==
                                Brightness.light
                            ? 0.34
                            : 0.42,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    action.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
      ];

      return PremiumDialogSurface(
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
        actions: buttons,
      );
    },
  );
}
