import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../models/expense_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../utils/app_constants.dart' hide AppHelpers;

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final expenses = provider.expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              provider.loadExpenses();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Expenses refreshed!'),
                duration: Duration(seconds: 1),
                backgroundColor: AppTheme.successColor,
              ));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: AppTheme.cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Today: ${AppHelpers.formatCurrency(provider.todayExpenses)}", style: const TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w600)),
              Text("This Month: ${AppHelpers.formatCurrency(provider.monthExpenses)}", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ]),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : expenses.isEmpty
              ? const Center(child: Text('No expenses recorded', style: TextStyle(color: AppTheme.textMuted)))
              : RefreshIndicator(
                  color: AppTheme.accentColor,
                  onRefresh: () async {
                    provider.loadExpenses();
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    itemBuilder: (_, i) => _ExpenseTile(expense: expenses[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expenses_fab',
        onPressed: () => _showAddExpenseSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.secondaryColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddExpenseSheet(),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppTheme.errorColor.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
        child: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
      ),
      confirmDismiss: (dir) async => await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.secondaryColor,
          title: const Text('Delete Expense?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
          ],
        ),
      ),
      onDismissed: (_) => context.read<ExpenseProvider>().deleteExpense(expense.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.money_off, color: AppTheme.warningColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(expense.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${expense.category} • ${AppHelpers.formatDate(expense.date)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            if (expense.description != null) Text(expense.description!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ])),
          Text(AppHelpers.formatCurrency(expense.amount), style: const TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();
  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = AppConstants.expenseCategories.first;
  DateTime _date = DateTime.now();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<ExpenseProvider>().addExpense(
      title: _titleCtrl.text.trim(), category: _category,
      amount: double.parse(_amountCtrl.text),
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text.trim(), date: _date,
    );
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense added'), backgroundColor: AppTheme.successColor));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Add Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ]),
          const SizedBox(height: 16),
          TextFormField(controller: _titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Expense Title *', prefixIcon: Icon(Icons.title, color: AppTheme.textMuted)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category, dropdownColor: AppTheme.cardColor,
            decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textMuted)),
            items: AppConstants.expenseCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _amountCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Amount (Rs.) *', prefixIcon: Icon(Icons.attach_money, color: AppTheme.textMuted)), validator: (v) { if (v == null || v.isEmpty) return 'Required'; if (double.tryParse(v) == null) return 'Invalid amount'; return null; }),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined, color: AppTheme.textMuted),
            title: Text(AppHelpers.formatDate(_date), style: const TextStyle(color: Colors.white)),
            subtitle: const Text('Tap to change date', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now(), builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accentColor)), child: child!));
              if (picked != null) setState(() => _date = picked);
            },
          ),
          TextFormField(controller: _descCtrl, style: const TextStyle(color: Colors.white), maxLines: 2, decoration: const InputDecoration(labelText: 'Description (optional)', prefixIcon: Icon(Icons.notes_outlined, color: AppTheme.textMuted))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor), child: const Text('Save Expense'))),
          const SizedBox(height: 10),
        ])),
      ),
    );
  }
}