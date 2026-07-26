import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/medication_reminder.dart';
import '../providers/reminder_provider.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// "Reminder" screen: a horizontal day strip for the current week and
/// a checklist of pills due that day, matching the reference design.
/// Reminders repeat daily until removed; "taken" is tracked per date
/// so a missed dose yesterday doesn't uncheck today's.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    final weekday = today.weekday % 7; // Sunday -> 0
    final sunday = _selectedDate.subtract(Duration(days: weekday));
    _weekDates = List.generate(7, (i) => sunday.add(Duration(days: i)));
  }

  Future<void> _showAddReminderSheet() async {
    final drugController = TextEditingController();
    final dosageController = TextEditingController(text: '1 per intake');
    TimeOfDay pickedTime = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('New Reminder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: drugController,
                    decoration: const InputDecoration(labelText: 'Medicine name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosageController,
                    decoration: const InputDecoration(labelText: 'Dosage (e.g. 2 per intake)'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: AppTheme.primaryNavy),
                    title: const Text('Time'),
                    trailing: Text(pickedTime.format(sheetContext), style: const TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () async {
                      final result = await showTimePicker(context: sheetContext, initialTime: pickedTime);
                      if (result != null) setSheetState(() => pickedTime = result);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (drugController.text.trim().isEmpty) return;
                      await context.read<ReminderProvider>().addReminder(
                            drugName: drugController.text.trim(),
                            dosage: dosageController.text.trim().isEmpty ? '1 per intake' : dosageController.text.trim(),
                            hour: pickedTime.hour,
                            minute: pickedTime.minute,
                          );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Reminder'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminderProvider = context.watch<ReminderProvider>();
    final reminders = reminderProvider.remindersFor(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryNavy,
        onPressed: _showAddReminderSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                _monthNames[_selectedDate.month - 1],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _weekDates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final date = _weekDates[i];
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  return InkWell(
                    onTap: () => setState(() => _selectedDate = date),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.inStockGreen.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.inStockGreen : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dayNames[date.weekday % 7],
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppTheme.inStockGreen : Colors.grey.shade500,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Your today pills', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: reminderProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : reminders.isEmpty
                      ? Center(
                          child: Text('No reminders yet — tap + to add one', style: TextStyle(color: Colors.grey.shade500)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: reminders.length,
                          itemBuilder: (context, i) => _ReminderTile(
                            reminder: reminders[i],
                            date: _selectedDate,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final MedicationReminder reminder;
  final DateTime date;

  const _ReminderTile({required this.reminder, required this.date});

  @override
  Widget build(BuildContext context) {
    final isTaken = reminder.isTakenOn(date);
    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        await context.read<ReminderProvider>().deleteReminder(reminder.id);
        return true;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isTaken ? AppTheme.inStockGreen.withValues(alpha: 0.4) : AppTheme.borderGrey),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              child: Text(reminder.formattedTime, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            Container(width: 1, height: 32, color: AppTheme.borderGrey),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.drugName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(reminder.dosage, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            InkWell(
              onTap: () => context.read<ReminderProvider>().toggleTaken(reminder, date),
              borderRadius: BorderRadius.circular(20),
              child: Icon(
                isTaken ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isTaken ? AppTheme.inStockGreen : Colors.grey.shade400,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}