import 'package:flutter/material.dart';
import '../admin/admin_ui.dart';
import '../models/class_room.dart';

String classLabel(ClassRoom c) =>
    [c.subject.isEmpty ? c.name : c.subject, c.divisionLabel]
        .where((e) => e.isNotEmpty)
        .join(' \u2022 ');

/// Bottom-sheet list used to choose a subject/class.
Future<ClassRoom?> pickClass(
    BuildContext context, List<ClassRoom> classes, String? selectedId) {
  return showModalBottomSheet<ClassRoom>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Text('Select subject',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AdminUi.ink)),
          ),
          for (final c in classes)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: c.id == selectedId
                    ? AdminUi.blue.withValues(alpha: 0.07)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: c.id == selectedId ? AdminUi.blue : AdminUi.line,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminUi.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.menu_book_rounded,
                      color: AdminUi.blue, size: 21),
                ),
                title: Text(classLabel(c),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14.5)),
                subtitle: Text(c.name,
                    style: const TextStyle(
                        fontSize: 12.5, color: AdminUi.muted)),
                trailing: c.id == selectedId
                    ? const Icon(Icons.check_circle_rounded,
                    color: AdminUi.blue)
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              ),
            ),
        ],
      ),
    ),
  );
}

/// A tappable, dropdown-looking field.
class PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: InputDecorator(
        decoration: adminInputDecoration(label, icon,
            suffix: const Icon(Icons.keyboard_arrow_down_rounded))
            .copyWith(fillColor: Colors.white),
        child: Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: AdminUi.ink)),
      ),
    );
  }
}