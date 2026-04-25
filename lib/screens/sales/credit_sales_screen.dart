import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/credit_sale_model.dart';
import '../../models/sale_model.dart';
import '../../models/inventory_model.dart';
import '../../providers/credit_sales_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/customer_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../utils/app_constants.dart' hide AppHelpers;

// ─────────────────────────────────────────────────────────────────────────────
//  CREDIT SALES SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CreditSalesScreen extends StatefulWidget {
  const CreditSalesScreen({super.key});

  @override
  State<CreditSalesScreen> createState() => _CreditSalesScreenState();
}

class _CreditSalesScreenState extends State<CreditSalesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreditSalesProvider>().loadCreditSales();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreditSalesProvider>();
    final sales = provider.filteredSales;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: _buildAppBar(provider),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: provider.isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE67E22)))
            : Column(
                children: [
                  _SummaryCards(provider: provider),
                  Expanded(
                    child: sales.isEmpty
                        ? _EmptyState(
                            message: provider.showUnpaidOnly
                                ? 'No unpaid credit sales'
                                : 'No credit sales yet',
                          )
                        : RefreshIndicator(
                            color: const Color(0xFFE67E22),
                            onRefresh: () async => provider.loadCreditSales(),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: sales.length,
                              itemBuilder: (ctx, i) => _CreditSaleTile(
                                creditSale: sales[i],
                                index: i,
                                onPayment: () =>
                                    _showPaymentSheet(context, sales[i]),
                                onDelete: () =>
                                    _confirmDelete(context, sales[i]),
                                onViewDetails: () =>
                                    _showDetailSheet(context, sales[i]),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'credit_fab',
        onPressed: () => _showAddCreditSheet(context),
        backgroundColor: const Color(0xFFE67E22),
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Credit Sale',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(CreditSalesProvider provider) {
    return AppBar(
      title: const Text('Credit Sales',
          style: TextStyle(fontWeight: FontWeight.w700)),
      actions: [
        IconButton(
          icon: Icon(
            provider.showUnpaidOnly
                ? Icons.filter_alt_rounded
                : Icons.filter_alt_outlined,
            color: provider.showUnpaidOnly
                ? const Color(0xFFE67E22)
                : Colors.white70,
          ),
          tooltip: provider.showUnpaidOnly ? 'Show All' : 'Unpaid Only',
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.toggleUnpaidFilter();
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            provider.loadCreditSales();
          },
        ),
      ],
    );
  }

  void _showAddCreditSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CreditSalesProvider>(),
        child: const _BottomSheetWrapper(child: AddCreditSaleSheet()),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, CreditSale cs) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CreditSalesProvider>(),
        child:
            _BottomSheetWrapper(child: RecordPaymentSheet(creditSaleId: cs.id)),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, CreditSale cs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _BottomSheetWrapper(child: CreditDetailSheet(creditSale: cs)),
    );
  }

  void _confirmDelete(BuildContext context, CreditSale cs) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.secondaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.errorColor, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Delete Credit Sale',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete credit sale for ${cs.customerName}?',
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.warningColor.withOpacity(0.2)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppTheme.warningColor),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Choose whether to restore stock back to inventory.',
                    style:
                        TextStyle(color: AppTheme.warningColor, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<CreditSalesProvider>()
                  .deleteCreditSale(cs, restoreStock: false);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Credit sale deleted'),
                  backgroundColor: AppTheme.errorColor,
                ));
              }
            },
            child: const Text('Delete Only',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<CreditSalesProvider>()
                  .deleteCreditSale(cs, restoreStock: true);
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Deleted & stock restored'),
                  backgroundColor: AppTheme.successColor,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22)),
            child: const Text('Delete & Restore'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BOTTOM SHEET WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final Widget child;
  const _BottomSheetWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUMMARY CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final CreditSalesProvider provider;
  const _SummaryCards({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _SummaryCard(
            label: 'Outstanding',
            value: AppHelpers.formatCurrency(provider.totalOutstanding),
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFFE67E22),
            flex: 2,
          ),
          const SizedBox(width: 10),
          _SummaryCard(
            label: 'Unpaid',
            value: '${provider.unpaidCount}',
            icon: Icons.pending_outlined,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: 10),
          _SummaryCard(
            label: 'Overdue',
            value: '${provider.overdueCount}',
            icon: Icons.warning_amber_rounded,
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int flex;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(label,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CREDIT SALE TILE
// ─────────────────────────────────────────────────────────────────────────────

class _CreditSaleTile extends StatelessWidget {
  final CreditSale creditSale;
  final int index;
  final VoidCallback onPayment;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const _CreditSaleTile({
    required this.creditSale,
    required this.index,
    required this.onPayment,
    required this.onDelete,
    required this.onViewDetails,
  });

  Color get _statusColor {
    switch (creditSale.status) {
      case CreditStatus.paid:
        return AppTheme.successColor;
      case CreditStatus.partial:
        return AppTheme.warningColor;
      case CreditStatus.pending:
        return AppTheme.errorColor;
    }
  }

  IconData get _statusIcon {
    switch (creditSale.status) {
      case CreditStatus.paid:
        return Icons.check_circle_rounded;
      case CreditStatus.partial:
        return Icons.timelapse_rounded;
      case CreditStatus.pending:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = creditSale;
    final isOverdue = cs.isOverdue;
    final progress =
        cs.netAmount > 0 ? (cs.paidAmount / cs.netAmount).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: onViewDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOverdue
                ? AppTheme.errorColor.withOpacity(0.4)
                : cs.isFullyPaid
                    ? AppTheme.successColor.withOpacity(0.2)
                    : Colors.white.withOpacity(0.07),
            width: isOverdue ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            // ── Top section ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(children: [
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          cs.customerName.isNotEmpty
                              ? cs.customerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Color(0xFFE67E22),
                              fontWeight: FontWeight.w800,
                              fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name & phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cs.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white)),
                          if (cs.customerPhone != null)
                            Row(children: [
                              const Icon(Icons.phone_outlined,
                                  size: 11, color: AppTheme.textMuted),
                              const SizedBox(width: 3),
                              Text(cs.customerPhone!,
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 11)),
                            ]),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon, color: _statusColor, size: 11),
                          const SizedBox(width: 4),
                          Text(cs.status.label,
                              style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ]),

                  const SizedBox(height: 14),

                  // Amount row
                  Row(children: [
                    _AmountChip(
                      label: 'Total',
                      value: AppHelpers.formatCurrency(cs.netAmount),
                      valueColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    _AmountChip(
                      label: 'Paid',
                      value: AppHelpers.formatCurrency(cs.paidAmount),
                      valueColor: AppTheme.successColor,
                    ),
                    const SizedBox(width: 8),
                    _AmountChip(
                      label: 'Remaining',
                      value: AppHelpers.formatCurrency(cs.remainingAmount),
                      valueColor: cs.remainingAmount > 0
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                      highlighted: cs.remainingAmount > 0,
                    ),
                  ]),

                  // Progress bar
                  if (!cs.isFullyPaid) ...[
                    const SizedBox(height: 10),
                    Stack(children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: cs.paidAmount > 0
                                ? AppTheme.warningColor
                                : AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% paid',
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 10),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Meta row
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 11, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(AppHelpers.formatDate(cs.date),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.inventory_2_outlined,
                        size: 11, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('${cs.items.length} item(s)',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                    if (cs.payments.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.payments_outlined,
                          size: 11, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text('${cs.payments.length} payment(s)',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                    ],
                    if (cs.dueDate != null) ...[
                      const Spacer(),
                      Icon(Icons.event_rounded,
                          size: 11,
                          color: isOverdue
                              ? AppTheme.errorColor
                              : AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        'Due ${AppHelpers.formatDate(cs.dueDate!)}',
                        style: TextStyle(
                            color: isOverdue
                                ? AppTheme.errorColor
                                : AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: isOverdue
                                ? FontWeight.w700
                                : FontWeight.normal),
                      ),
                    ],
                  ]),

                  if (isOverdue) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppTheme.errorColor),
                          SizedBox(width: 4),
                          Text('OVERDUE',
                              style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Action bar ───────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(children: [
                // Delete
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: AppTheme.textMuted,
                  onTap: onDelete,
                ),
                const Spacer(),
                // View details
                _ActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Details',
                  color: AppTheme.textMuted,
                  onTap: onViewDetails,
                ),
                if (!cs.isFullyPaid) ...[
                  const SizedBox(width: 8),
                  // Record payment
                  GestureDetector(
                    onTap: onPayment,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text('Pay',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool highlighted;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.valueColor,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: highlighted
              ? AppTheme.errorColor.withOpacity(0.07)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlighted
                ? AppTheme.errorColor.withOpacity(0.2)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: valueColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RECORD PAYMENT SHEET
// ─────────────────────────────────────────────────────────────────────────────

class RecordPaymentSheet extends StatefulWidget {
  final String creditSaleId;
  const RecordPaymentSheet({super.key, required this.creditSaleId});

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(CreditSale cs) async {
    if (_isSubmitting) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    final remaining = cs.remainingAmount;

    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount');
      return;
    }
    if (amount > remaining + 0.01) {
      _showError('Exceeds remaining ${AppHelpers.formatCurrency(remaining)}');
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await context.read<CreditSalesProvider>().recordPayment(
          creditSale: cs,
          amount: amount,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      Navigator.pop(context);
      final isFullyPaid = amount >= remaining - 0.01;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isFullyPaid
            ? '✅ Fully paid! Credit cleared.'
            : 'Payment of ${AppHelpers.formatCurrency(amount)} recorded.'),
        backgroundColor:
            isFullyPaid ? AppTheme.successColor : const Color(0xFFE67E22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      _showError('Failed to save payment. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.errorColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CreditSalesProvider>();
    final cs = provider.creditSales.firstWhere(
      (s) => s.id == widget.creditSaleId,
      orElse: () => provider.creditSales.first,
    );

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),

            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Record Payment',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Customer info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE67E22).withOpacity(0.15),
                    const Color(0xFFE67E22).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFFE67E22).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        cs.customerName.isNotEmpty
                            ? cs.customerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            color: Color(0xFFE67E22),
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cs.customerName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text('Borrowed ${AppHelpers.formatDate(cs.date)}',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppHelpers.formatCurrency(cs.remainingAmount),
                        style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 20),
                      ),
                      const Text('remaining',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Progress
            if (cs.paidAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid so far: ${AppHelpers.formatCurrency(cs.paidAmount)}',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                  Text(
                    '${((cs.paidAmount / cs.netAmount) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: cs.netAmount > 0
                      ? (cs.paidAmount / cs.netAmount).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: Colors.white12,
                  color: AppTheme.warningColor,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Quick amount buttons
            const Text('Quick select',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              _QuickBtn(
                label: 'Full',
                sublabel: AppHelpers.formatCurrency(cs.remainingAmount),
                onTap: () => setState(() =>
                    _amountCtrl.text = cs.remainingAmount.toStringAsFixed(2)),
              ),
              const SizedBox(width: 8),
              _QuickBtn(
                label: '½',
                sublabel: AppHelpers.formatCurrency(cs.remainingAmount / 2),
                onTap: () => setState(() => _amountCtrl.text =
                    (cs.remainingAmount / 2).toStringAsFixed(2)),
              ),
              const SizedBox(width: 8),
              _QuickBtn(
                label: '¼',
                sublabel: AppHelpers.formatCurrency(cs.remainingAmount / 4),
                onTap: () => setState(() => _amountCtrl.text =
                    (cs.remainingAmount / 4).toStringAsFixed(2)),
              ),
            ]),
            const SizedBox(height: 16),

            // Amount field
            TextFormField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                prefixIcon: const Icon(Icons.payments_outlined,
                    color: AppTheme.textMuted),
                suffixText: _amountCtrl.text.isNotEmpty
                    ? (double.tryParse(_amountCtrl.text) != null
                        ? '${((double.parse(_amountCtrl.text) / cs.netAmount) * 100).toStringAsFixed(0)}%'
                        : null)
                    : null,
                suffixStyle: const TextStyle(
                    color: Color(0xFFE67E22), fontWeight: FontWeight.w600),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            // Notes field
            TextFormField(
              controller: _notesCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon:
                    Icon(Icons.notes_outlined, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submit(cs),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  disabledBackgroundColor:
                      const Color(0xFFE67E22).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Payment',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final String sublabel;
  final VoidCallback onTap;
  const _QuickBtn(
      {required this.label, required this.sublabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE67E22).withOpacity(0.4)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFE67E22).withOpacity(0.05),
          ),
          child: Column(children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFFE67E22),
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 2),
            Text(sublabel,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CREDIT DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────────

class CreditDetailSheet extends StatelessWidget {
  final CreditSale creditSale;
  const CreditDetailSheet({super.key, required this.creditSale});

  @override
  Widget build(BuildContext context) {
    final cs = creditSale;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          // Handle + title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cs.customerName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  Text(cs.status.label,
                      style: TextStyle(
                          color: _statusColor(cs),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textMuted),
                ),
              ]),
            ]),
          ),

          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                // ── Info cards ──────────────────────────────
                _InfoCard(children: [
                  _DetailRow(
                      label: 'Date Borrowed',
                      value: AppHelpers.formatDateTime(cs.date)),
                  if (cs.customerPhone != null)
                    _DetailRow(label: 'Phone', value: cs.customerPhone!),
                  if (cs.dueDate != null)
                    _DetailRow(
                      label: 'Due Date',
                      value: AppHelpers.formatDate(cs.dueDate!),
                      valueColor: cs.isOverdue ? AppTheme.errorColor : null,
                    ),
                  if (cs.notes != null)
                    _DetailRow(label: 'Notes', value: cs.notes!),
                ]),

                const SizedBox(height: 16),

                // ── Items ────────────────────────────────────
                _SectionLabel(
                    label: 'Items Borrowed', icon: Icons.inventory_2_outlined),
                const SizedBox(height: 8),
                ...cs.items.map((item) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.07))),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item.itemType == 'tyre'
                                ? Icons.tire_repair_rounded
                                : Icons.circle_outlined,
                            color: const Color(0xFFE67E22),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.itemName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                Text('${item.brand} • ${item.size}',
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 11)),
                              ]),
                        ),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                  '${item.quantity} × ${AppHelpers.formatCurrency(item.sellingPrice)}',
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 11)),
                              Text(AppHelpers.formatCurrency(item.totalSelling),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ]),
                      ]),
                    )),

                const SizedBox(height: 16),

                // ── Financials ───────────────────────────────
                _SectionLabel(
                    label: 'Financial Summary', icon: Icons.summarize_outlined),
                const SizedBox(height: 8),
                _InfoCard(children: [
                  _DetailRow(
                      label: 'Subtotal',
                      value: AppHelpers.formatCurrency(cs.totalAmount)),
                  if (cs.discountAmount > 0)
                    _DetailRow(
                      label: 'Discount',
                      value:
                          '- ${AppHelpers.formatCurrency(cs.discountAmount)}',
                      valueColor: AppTheme.warningColor,
                    ),
                  if (cs.serviceCharge > 0)
                    _DetailRow(
                        label: 'Service Charge',
                        value: AppHelpers.formatCurrency(cs.serviceCharge)),
                  const Divider(color: Colors.white12, height: 20),
                  _DetailRow(
                      label: 'Net Total',
                      value: AppHelpers.formatCurrency(cs.netAmount),
                      bold: true),
                  _DetailRow(
                      label: 'Paid',
                      value: AppHelpers.formatCurrency(cs.paidAmount),
                      valueColor: AppTheme.successColor),
                  _DetailRow(
                      label: 'Remaining',
                      value: AppHelpers.formatCurrency(cs.remainingAmount),
                      valueColor: cs.remainingAmount > 0
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                      bold: true),
                ]),

                // ── Payment History ──────────────────────────
                if (cs.payments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionLabel(
                      label: 'Payment History', icon: Icons.history_rounded),
                  const SizedBox(height: 8),
                  ...cs.payments.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.2)),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: AppTheme.successColor, size: 14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppHelpers.formatDateTime(p.date),
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 11)),
                              if (p.notes != null)
                                Text(p.notes!,
                                    style: const TextStyle(fontSize: 12)),
                            ],
                          )),
                          Text(AppHelpers.formatCurrency(p.amount),
                              style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ]),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(CreditSale cs) {
    switch (cs.status) {
      case CreditStatus.paid:
        return AppTheme.successColor;
      case CreditStatus.partial:
        return AppTheme.warningColor;
      case CreditStatus.pending:
        return AppTheme.errorColor;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(children: children),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 13, color: AppTheme.textMuted),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
    ]);
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _DetailRow(
      {required this.label,
      required this.value,
      this.valueColor,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD CREDIT SALE SHEET
// ─────────────────────────────────────────────────────────────────────────────

class AddCreditSaleSheet extends StatefulWidget {
  const AddCreditSaleSheet({super.key});

  @override
  State<AddCreditSaleSheet> createState() => _AddCreditSaleSheetState();
}

class _AddCreditSaleSheetState extends State<AddCreditSaleSheet> {
  final List<SaleItem> _cartItems = [];
  String? _customerId;
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _serviceChargeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _isSaving = false;

  double get _subtotal =>
      _cartItems.fold(0.0, (sum, i) => sum + i.totalSelling);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0.0;
  double get _serviceCharge => double.tryParse(_serviceChargeCtrl.text) ?? 0.0;
  double get _total => _subtotal - _discount + _serviceCharge;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _discountCtrl.dispose();
    _serviceChargeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _addItemFromInventory(InventoryItem inv, int qty) {
    final existing = _cartItems.indexWhere((i) => i.itemId == inv.id);
    if (existing >= 0) {
      final old = _cartItems[existing];
      _cartItems[existing] = SaleItem(
          itemId: old.itemId,
          itemName: old.itemName,
          itemType: old.itemType,
          category: old.category,
          brand: old.brand,
          size: old.size,
          quantity: old.quantity + qty,
          buyingPrice: old.buyingPrice,
          sellingPrice: old.sellingPrice,
          profit: old.sellingPrice - old.buyingPrice);
    } else {
      _cartItems.add(SaleItem(
          itemId: inv.id,
          itemName: inv.name,
          itemType: inv.type,
          category: inv.category,
          brand: inv.brand,
          size: inv.size,
          quantity: qty,
          buyingPrice: inv.buyingPrice,
          sellingPrice: inv.sellingPrice,
          profit: inv.sellingPrice - inv.buyingPrice));
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_cartItems.isEmpty) {
      _showSnack('Add at least one item', AppTheme.errorColor);
      return;
    }

    final name = _customerId != null
        ? context.read<CustomerProvider>().findById(_customerId!)?.name ??
            _customerNameCtrl.text.trim()
        : _customerNameCtrl.text.trim();

    if (name.isEmpty) {
      _showSnack(
          'Customer name is required for credit sales', AppTheme.errorColor);
      return;
    }

    setState(() => _isSaving = true);

    final ok = await context.read<CreditSalesProvider>().addCreditSale(
          items: _cartItems,
          customerId: _customerId,
          customerName: name,
          customerPhone: _customerPhoneCtrl.text.trim().isEmpty
              ? null
              : _customerPhoneCtrl.text.trim(),
          discountAmount: _discount,
          serviceCharge: _serviceCharge,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          dueDate: _dueDate,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.pop(context);
      _showSnack('Credit sale recorded!', const Color(0xFFE67E22));
    } else {
      _showSnack('Failed to save. Try again.', AppTheme.errorColor);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final customers = context.watch<CustomerProvider>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      builder: (_, ctrl) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.credit_card_rounded,
                        color: Color(0xFFE67E22), size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text('New Credit Sale',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ]),
          ),

          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                // ── Customer ──────────────────────────────────
                _SectionLabel(
                    label: 'Customer Info', icon: Icons.person_outline_rounded),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _customerId,
                  dropdownColor: AppTheme.cardColor,
                  decoration: const InputDecoration(
                      labelText: 'Existing Customer (optional)',
                      prefixIcon: Icon(Icons.person_search_outlined,
                          color: AppTheme.textMuted)),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('New / Unnamed')),
                    ...customers.customers.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name,
                            style: const TextStyle(color: Colors.white)))),
                  ],
                  onChanged: (v) => setState(() {
                    _customerId = v;
                    if (v != null) {
                      final c = customers.findById(v);
                      if (c != null) {
                        _customerNameCtrl.text = c.name;
                        _customerPhoneCtrl.text = c.phone;
                      }
                    }
                  }),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customerNameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    prefixIcon:
                        Icon(Icons.badge_outlined, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customerPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    prefixIcon:
                        Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 10),

                // Due date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFE67E22)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(
                        Icons.event_rounded,
                        color: _dueDate != null
                            ? const Color(0xFFE67E22)
                            : AppTheme.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dueDate == null
                              ? 'Set due date (optional)'
                              : 'Due: ${AppHelpers.formatDate(_dueDate!)}',
                          style: TextStyle(
                              color: _dueDate == null
                                  ? AppTheme.textMuted
                                  : Colors.white,
                              fontSize: 14),
                        ),
                      ),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppTheme.textMuted, size: 16),
                        ),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Items ─────────────────────────────────────
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel(
                          label: 'Items', icon: Icons.inventory_2_outlined),
                      GestureDetector(
                        onTap: () => _showItemPicker(context, inventory),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE67E22).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    const Color(0xFFE67E22).withOpacity(0.4)),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: Color(0xFFE67E22), size: 14),
                                SizedBox(width: 4),
                                Text('Add Item',
                                    style: TextStyle(
                                        color: Color(0xFFE67E22),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ]),
                        ),
                      ),
                    ]),
                const SizedBox(height: 8),

                if (_cartItems.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.07),
                          style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Text('No items added yet',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 13)),
                    ),
                  )
                else
                  ..._cartItems.map((item) => _CartItemTile(
                      item: item,
                      onRemove: () => setState(() => _cartItems
                          .removeWhere((i) => i.itemId == item.itemId)),
                      onQtyChange: (qty) {
                        final idx = _cartItems
                            .indexWhere((i) => i.itemId == item.itemId);
                        if (idx >= 0) {
                          final old = _cartItems[idx];
                          _cartItems[idx] = SaleItem(
                              itemId: old.itemId,
                              itemName: old.itemName,
                              itemType: old.itemType,
                              category: old.category,
                              brand: old.brand,
                              size: old.size,
                              quantity: qty,
                              buyingPrice: old.buyingPrice,
                              sellingPrice: old.sellingPrice,
                              profit: old.sellingPrice - old.buyingPrice);
                          setState(() {});
                        }
                      })),

                const SizedBox(height: 16),

                // ── Discount & Service ────────────────────────
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _discountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Discount',
                          prefixIcon: Icon(Icons.discount_outlined,
                              color: AppTheme.textMuted)),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _serviceChargeCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          labelText: 'Service Charge',
                          prefixIcon: Icon(Icons.build_circle_outlined,
                              color: AppTheme.textMuted)),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _notesCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.notes_outlined,
                          color: AppTheme.textMuted)),
                ),
                const SizedBox(height: 20),

                // ── Total summary ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        const Color(0xFFE67E22).withOpacity(0.15),
                        const Color(0xFFE67E22).withOpacity(0.05),
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFE67E22).withOpacity(0.3))),
                  child: Column(children: [
                    if (_cartItems.isNotEmpty) ...[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13)),
                            Text(AppHelpers.formatCurrency(_subtotal),
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500)),
                          ]),
                      if (_discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 13)),
                              Text('- ${AppHelpers.formatCurrency(_discount)}',
                                  style: const TextStyle(
                                      color: AppTheme.warningColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ]),
                      ],
                      if (_serviceCharge > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Service Charge',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 13)),
                              Text(AppHelpers.formatCurrency(_serviceCharge),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ]),
                      ],
                      const Divider(color: Colors.white12, height: 16),
                    ],
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Amount to Credit',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(AppHelpers.formatCurrency(_total),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE67E22))),
                        ]),
                  ]),
                ),
                const SizedBox(height: 14),

                // ── Save button ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE67E22),
                      disabledBackgroundColor:
                          const Color(0xFFE67E22).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Record Credit Sale',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _showItemPicker(BuildContext context, InventoryProvider inventory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => _ItemPickerSheet(
          inventory: inventory,
          onItemSelected: (item, qty) {
            _addItemFromInventory(item, qty);
            Navigator.pop(context);
          }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CART ITEM TILE (with qty stepper)
// ─────────────────────────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final SaleItem item;
  final VoidCallback onRemove;
  final void Function(int) onQtyChange;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Row(children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.itemName,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('${AppHelpers.formatCurrency(item.sellingPrice)} each',
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ]),
        ),
        // Qty stepper
        Row(children: [
          GestureDetector(
            onTap: () {
              if (item.quantity > 1) onQtyChange(item.quantity - 1);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.remove_rounded,
                  size: 14, color: Colors.white70),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('${item.quantity}',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          GestureDetector(
            onTap: () => onQtyChange(item.quantity + 1),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE67E22).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 14, color: Color(0xFFE67E22)),
            ),
          ),
        ]),
        const SizedBox(width: 10),
        Text(AppHelpers.formatCurrency(item.totalSelling),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(width: 8),
        GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                color: AppTheme.errorColor, size: 16)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ITEM PICKER SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _ItemPickerSheet extends StatefulWidget {
  final InventoryProvider inventory;
  final void Function(InventoryItem, int) onItemSelected;
  const _ItemPickerSheet(
      {required this.inventory, required this.onItemSelected});

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(children: [
        Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white30, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        const Text('Select Item',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                hintText: 'Search by name, brand, size...',
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppTheme.textMuted)),
            onChanged: (v) {
              widget.inventory.setSearchQuery(v);
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
            controller: _tab,
            indicatorColor: const Color(0xFFE67E22),
            labelColor: const Color(0xFFE67E22),
            unselectedLabelColor: AppTheme.textMuted,
            tabs: const [Tab(text: 'Tyres'), Tab(text: 'Tubes')]),
        Expanded(
            child: TabBarView(controller: _tab, children: [
          _ItemList(
              items: widget.inventory.tyres, onSelect: widget.onItemSelected),
          _ItemList(
              items: widget.inventory.tubes, onSelect: widget.onItemSelected),
        ])),
      ]),
    );
  }
}

class _ItemList extends StatelessWidget {
  final List<InventoryItem> items;
  final void Function(InventoryItem, int) onSelect;
  const _ItemList({required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
          child: Text('No items found',
              style: TextStyle(color: AppTheme.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = items[i];
        final isOutOfStock = item.isOutOfStock;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isOutOfStock ? null : () => _pickQty(context, item),
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: isOutOfStock ? 0.45 : 1.0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOutOfStock
                        ? AppTheme.errorColor.withOpacity(0.25)
                        : Colors.white12,
                  ),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE67E22).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.type == 'tyre'
                          ? Icons.tire_repair_rounded
                          : Icons.circle_outlined,
                      color: const Color(0xFFE67E22),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                              '${item.brand} • ${item.size} • Stock: ${item.stockQuantity}',
                              style: const TextStyle(
                                  color: AppTheme.textMuted, fontSize: 11)),
                          if (isOutOfStock)
                            const Text('Out of stock',
                                style: TextStyle(
                                    color: AppTheme.errorColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                        ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(AppHelpers.formatCurrency(item.sellingPrice),
                        style: const TextStyle(
                            color: Color(0xFFE67E22),
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(
                        'Profit: ${AppHelpers.formatCurrency(item.profitMargin)}',
                        style: TextStyle(
                            color: item.profitMargin >= 0
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            fontSize: 10)),
                  ]),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  void _pickQty(BuildContext context, InventoryItem item) {
    int qty = 1;
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setS) => AlertDialog(
                  backgroundColor: AppTheme.secondaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('${item.brand} • ${item.size}',
                            style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.normal)),
                      ]),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Stock available: ${item.stockQuantity}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      IconButton(
                          onPressed: () =>
                              setS(() => qty = (qty - 1).clamp(1, 999)),
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Color(0xFFE67E22))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE67E22).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$qty',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                          onPressed: () => setS(() =>
                              qty = (qty + 1).clamp(1, item.stockQuantity)),
                          icon: const Icon(Icons.add_circle_outline,
                              color: Color(0xFFE67E22))),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                        'Total: ${AppHelpers.formatCurrency(item.sellingPrice * qty)}',
                        style: const TextStyle(
                            color: Color(0xFFE67E22),
                            fontWeight: FontWeight.w700)),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel',
                            style: TextStyle(color: AppTheme.textMuted))),
                    ElevatedButton(
                        onPressed: () {
                          onSelect(item, qty);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE67E22),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text('Add')),
                  ],
                )));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFE67E22).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.credit_card_off_outlined,
            size: 48, color: Color(0xFFE67E22)),
      ),
      const SizedBox(height: 20),
      Text(message,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Tap + Credit Sale to add one',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
    ]));
  }
}
