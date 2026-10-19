import 'package:flutter/material.dart';

/// Shared look for all admin screens (colors + small reusable widgets).
class AdminUi {
  static const navy = Color(0xFF0F1F3D);
  static const blue = Color(0xFF2563EB);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const bg = Color(0xFFF3F5F9);
  static const line = Color(0xFFE5E7EB);
  static const danger = Color(0xFFDC2626);
}

/// White app bar with a thin divider, used on every admin screen.
AppBar adminAppBar(String title, {List<Widget>? actions}) => AppBar(
  backgroundColor: Colors.white,
  surfaceTintColor: Colors.white,
  elevation: 0,
  foregroundColor: AdminUi.ink,
  title: Text(title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
  actions: actions,
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(height: 1, color: AdminUi.line),
  ),
);

/// Search box used above the lists.
class AdminSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AdminSearchField({required this.hint, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14.5),
        prefixIcon: const Icon(Icons.search_rounded, color: AdminUi.muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border(AdminUi.line),
        enabledBorder: border(AdminUi.line),
        focusedBorder: border(AdminUi.blue, 1.8),
      ),
    );
  }
}

/// Bordered white card (optionally tappable).
class AdminCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const AdminCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminUi.line),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Rounded square avatar with a letter.
class AdminAvatar extends StatelessWidget {
  final String text;
  final List<Color> colors;

  const AdminAvatar({required this.text, required this.colors, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        text.isEmpty ? '?' : text[0].toUpperCase(),
        style: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Small grey label such as "12 faculty".
class AdminListHeader extends StatelessWidget {
  final String text;
  const AdminListHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AdminUi.muted,
      ),
    ),
  );
}

/// Centered "nothing here" message.
class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const AdminEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AdminUi.blue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: AdminUi.blue),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AdminUi.ink)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, height: 1.4, color: AdminUi.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Text field look used inside admin dialogs.
InputDecoration adminInputDecoration(String label, IconData icon,
    {Widget? suffix}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AdminUi.muted),
    floatingLabelStyle: const TextStyle(color: AdminUi.blue),
    prefixIcon: Icon(icon, size: 20, color: AdminUi.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: border(AdminUi.line),
    enabledBorder: border(AdminUi.line),
    focusedBorder: border(AdminUi.blue, 1.8),
    errorBorder: border(AdminUi.danger),
    focusedErrorBorder: border(AdminUi.danger, 1.8),
  );
}

/// Header shown at the top of admin dialogs: icon + title (+ subtitle).
class AdminDialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;

  const AdminDialogHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = AdminUi.blue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AdminUi.ink)),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 12.5, color: AdminUi.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rounded confirmation dialog. Returns true when the user confirms.
Future<bool> showAdminConfirm(
    BuildContext context, {
      required String title,
      required String message,
      String confirmLabel = 'Delete',
      bool destructive = true,
    }) async {
  final color = destructive ? AdminUi.danger : AdminUi.blue;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          destructive
              ? Icons.delete_outline_rounded
              : Icons.help_outline_rounded,
          color: color,
          size: 28,
        ),
      ),
      title: Text(title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 14, height: 1.45, color: AdminUi.muted)),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: OutlinedButton.styleFrom(
            foregroundColor: AdminUi.ink,
            side: const BorderSide(color: AdminUi.line),
            minimumSize: const Size(110, 44),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(110, 44),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

/// Big colorful tile used on the home grids (admin and faculty).
class AppTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final String? caption;
  final List<Color> colors;
  final VoidCallback onTap;

  const AppTile({
    required this.icon,
    required this.title,
    required this.colors,
    required this.onTap,
    this.count,
    this.caption,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                Positioned(
                  right: -26,
                  top: -26,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: -34,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: Colors.white, size: 28),
                      ),
                      const Spacer(),
                      if (count != null) ...[
                        Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 34,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (caption != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          caption!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
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

/// Gradient welcome banner shown at the top of the home screens.
class AppBanner extends StatelessWidget {
  final IconData icon;
  final String greeting;
  final String name;
  final String? line;
  final String? chip;

  const AppBanner({
    required this.icon,
    required this.greeting,
    required this.name,
    this.line,
    this.chip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F1F3D), Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: const TextStyle(
                        fontSize: 13.5, color: Color(0xFFBFDBFE))),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                if (line != null && line!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    line!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFDBEAFE)),
                  ),
                ],
                if (chip != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(chip!,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Good morning / afternoon / evening" for the home banners.
String greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}