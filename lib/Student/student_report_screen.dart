import 'package:flutter/material.dart';
import 'student_data.dart';

/// 📈 Attendance Report: overall summary plus a per-subject breakdown
/// with how many classes are needed (or can be skipped) vs the 75% rule.
class StudentReportScreen extends StatelessWidget {
  const StudentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = StudentData.load();
    final overallColor =
    percentColor(d.overallPercent, hasData: d.hasData);

    return Scaffold(
      backgroundColor: AdminUi.bg,
      appBar: studentAppBar('Attendance Report'),
      body: !d.hasData
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.insights_outlined,
          title: 'No report yet',
          message: 'Your report appears once attendance has been taken.',
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: cardDecoration(),
            child: Column(
              children: [
                Text('${d.overallPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: overallColor)),
                const Text('Overall attendance'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat('Classes', '${d.totalClasses}', Colors.black87),
                    _Stat('Present', '${d.totalPresent}',
                        const Color(0xFF10B981)),
                    _Stat('Absent', '${d.totalAbsent}',
                        const Color(0xFFEF4444)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Subject-wise',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final s in d.subjects) _SubjectRow(summary: s),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
    ],
  );
}

class _SubjectRow extends StatelessWidget {
  final SubjectSummary summary;
  const _SubjectRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final color = percentColor(s.percent, hasData: s.hasData);

    String advice;
    if (!s.hasData) {
      advice = 'No classes taken yet.';
    } else if (s.percent >= kMinPercent) {
      advice = s.canSkip > 0
          ? 'On track. You can miss ${s.canSkip} more '
          'class${s.canSkip == 1 ? '' : 'es'} and stay above '
          '${kMinPercent.toStringAsFixed(0)}%.'
          : 'On track, but you cannot afford to miss the next class.';
    } else {
      advice = 'Attend the next ${s.classesNeeded} '
          'class${s.classesNeeded == 1 ? '' : 'es'} in a row to reach '
          '${kMinPercent.toStringAsFixed(0)}%.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Text(s.hasData ? '${s.percent.toStringAsFixed(1)}%' : '--',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s.hasData ? s.percent / 100 : 0,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text('${s.present} present  •  ${s.absent} absent  •  ${s.total} total',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(advice, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
        ],
      ),
    );
  }
}