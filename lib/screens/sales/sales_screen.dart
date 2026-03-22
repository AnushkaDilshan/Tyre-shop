import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/sale_model.dart';
import '../../models/inventory_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../utils/app_constants.dart' hide AppHelpers;

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final sales = salesProvider.filteredSales;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              salesProvider.loadSales();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Sales refreshed!'),
                duration: Duration(seconds: 1),
                backgroundColor: AppTheme.successColor,
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: salesProvider.selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: AppTheme.accentColor)),
                  child: child!,
                ),
              );
              if (picked != null) salesProvider.setSelectedDate(picked);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
                color: AppTheme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppHelpers.formatDate(salesProvider.selectedDate),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500)),
                  Text(
                      'Total: ${AppHelpers.formatCurrency(sales.fold(0.0, (s, e) => s + e.netAmount))}',
                      style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w600)),
                ]),
          ),
        ),
      ),
      body: salesProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor))
          : sales.isEmpty
              ? _EmptyState(
                  message:
                      'No sales for ${AppHelpers.formatDate(salesProvider.selectedDate)}',
                  icon: Icons.point_of_sale_outlined)
              : RefreshIndicator(
                  color: AppTheme.accentColor,
                  onRefresh: () async {
                    salesProvider.loadSales();
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sales.length,
                    itemBuilder: (ctx, i) => _SaleTile(sale: sales[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_fab',
        onPressed: () => _showAddSaleSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
      ),
    );
  }

  void _showAddSaleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.secondaryColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const AddSaleSheet(),
    );
  }
}

// ─── Sale Tile ────────────────────────────────────────────────

class _SaleTile extends StatelessWidget {
  final sale;
  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(sale.customerName ?? 'Walk-in Customer',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(AppHelpers.formatCurrency(sale.netAmount),
              style: const TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.access_time, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(AppHelpers.formatDateTime(sale.date),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6)),
            child: Text(sale.paymentMethod,
                style:
                    const TextStyle(color: AppTheme.accentColor, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
            '${sale.items.length} item(s) • Profit: ${AppHelpers.formatCurrency(sale.totalProfit)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        if (sale.discountAmount > 0)
          Text('Discount: ${AppHelpers.formatCurrency(sale.discountAmount)}',
              style:
                  const TextStyle(color: AppTheme.warningColor, fontSize: 12)),
        if (sale.serviceCharge > 0)
          Text('Service: ${AppHelpers.formatCurrency(sale.serviceCharge)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ]),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _EmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: AppTheme.textMuted),
      const SizedBox(height: 16),
      Text(message,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
    ]));
  }
}

// ─── Add Sale Sheet ───────────────────────────────────────────

class AddSaleSheet extends StatefulWidget {
  const AddSaleSheet({super.key});
  @override
  State<AddSaleSheet> createState() => _AddSaleSheetState();
}

class _AddSaleSheetState extends State<AddSaleSheet> {
  final List<SaleItem> _cartItems = [];
  String _paymentMethod = 'Cash';
  String? _customerId;
  String? _customerName;
  final _discountCtrl = TextEditingController();
  final _serviceChargeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  double get _subtotal =>
      _cartItems.fold(0.0, (sum, i) => sum + i.totalSelling);
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0.0;
  double get _serviceCharge => double.tryParse(_serviceChargeCtrl.text) ?? 0.0;
  double get _total => _subtotal - _discount + _serviceCharge;
  double get _profit =>
      _cartItems.fold(0.0, (sum, i) => sum + i.totalProfit) + _serviceCharge;

  @override
  void dispose() {
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

  Future<void> _saveSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one item'),
          backgroundColor: AppTheme.errorColor));
      return;
    }
    final ok = await context.read<SalesProvider>().addSale(
        items: _cartItems,
        customerId: _customerId,
        customerName: _customerName,
        discountAmount: _discount,
        serviceCharge: _serviceCharge,
        paymentMethod: _paymentMethod,
        notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text);
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sale recorded successfully!'),
          backgroundColor: AppTheme.successColor));
    }
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
          Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Sale',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: const Text('Cancel',
                          style: TextStyle(color: AppTheme.textMuted))),
                ]),
          ),
          Expanded(
              child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                // ── Customer ──────────────────────────────────
                DropdownButtonFormField<String>(
                  value: _customerId,
                  dropdownColor: AppTheme.cardColor,
                  decoration: const InputDecoration(
                      labelText: 'Customer (optional)',
                      prefixIcon: Icon(Icons.person_outline,
                          color: AppTheme.textMuted)),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Walk-in Customer')),
                    ...customers.customers.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name,
                            style: const TextStyle(color: Colors.white))))
                  ],
                  onChanged: (v) => setState(() {
                    _customerId = v;
                    _customerName =
                        v == null ? null : customers.findById(v)?.name;
                  }),
                ),
                const SizedBox(height: 16),

                // ── Add Items ─────────────────────────────────
                const Text('Add Items',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showItemPicker(context, inventory),
                  icon: const Icon(Icons.add, color: AppTheme.accentColor),
                  label: const Text('Pick from Inventory',
                      style: TextStyle(color: AppTheme.accentColor)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.accentColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 10),
                ..._cartItems.map((item) => _CartItemTile(
                    item: item,
                    onRemove: () => setState(() => _cartItems
                        .removeWhere((i) => i.itemId == item.itemId)))),

                // ── Subtotal ──────────────────────────────────
                if (_cartItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:',
                            style: TextStyle(color: AppTheme.textMuted)),
                        Text(AppHelpers.formatCurrency(_subtotal),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                ],
                const SizedBox(height: 12),

                // ── Discount ──────────────────────────────────
                TextFormField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Discount Amount',
                        prefixIcon: Icon(Icons.discount_outlined,
                            color: AppTheme.textMuted)),
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),

                // ── Service Charge ────────────────────────────
                TextFormField(
                    controller: _serviceChargeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: 'Service Charge',
                        prefixIcon: Icon(Icons.build_circle_outlined,
                            color: AppTheme.textMuted)),
                    onChanged: (_) => setState(() {})),
                const SizedBox(height: 12),

                // ── Payment Method ────────────────────────────
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  dropdownColor: AppTheme.cardColor,
                  decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.payment_outlined,
                          color: AppTheme.textMuted)),
                  items: AppConstants.paymentMethods
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m,
                              style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 12),

                // ── Notes ─────────────────────────────────────
                TextFormField(
                    controller: _notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        prefixIcon: Icon(Icons.notes_outlined,
                            color: AppTheme.textMuted))),
                const SizedBox(height: 20),

                // ── Summary Card ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.accentColor.withOpacity(0.3))),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:',
                              style: TextStyle(fontSize: 15)),
                          Text(AppHelpers.formatCurrency(_total),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.accentColor)),
                        ]),
                    if (_cartItems.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Est. Profit:',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 12)),
                            Text(AppHelpers.formatCurrency(_profit),
                                style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ],
                    if (_serviceCharge > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Service charge:',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 12)),
                            Text(AppHelpers.formatCurrency(_serviceCharge),
                                style: const TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ]),
                    ],
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Record Button ─────────────────────────────
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _saveSale,
                        child: const Text('Record Sale'))),
                const SizedBox(height: 20),
              ])),
        ]),
      ),
    );
  }

  void _showItemPicker(BuildContext context, InventoryProvider inventory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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

// ─── Item Picker Sheet ────────────────────────────────────────

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
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white30, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 12),
        const Text('Select Item',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                hintText: 'Search by name, brand, size...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted)),
            onChanged: (v) {
              widget.inventory.setSearchQuery(v);
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
            controller: _tab,
            indicatorColor: AppTheme.accentColor,
            labelColor: AppTheme.accentColor,
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

// ─── Item List ────────────────────────────────────────────────

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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.type == 'tyre'
                            ? Icons.tire_repair
                            : Icons.circle_outlined,
                        color: const Color(0xFF7C4DFF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.brand} • ${item.size} • Stock: ${item.stockQuantity}',
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 11),
                          ),
                          if (isOutOfStock)
                            const Text(
                              'Out of stock',
                              style: TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppHelpers.formatCurrency(item.sellingPrice),
                          style: const TextStyle(
                              color: AppTheme.accentColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Profit: ${AppHelpers.formatCurrency(item.profitMargin)}',
                          style: TextStyle(
                              color: item.profitMargin >= 0
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  title: Text(item.name, style: const TextStyle(fontSize: 15)),
                  content: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            onPressed: () =>
                                setS(() => qty = (qty - 1).clamp(1, 999)),
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppTheme.accentColor)),
                        Text('$qty',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        IconButton(
                            onPressed: () => setS(() =>
                                qty = (qty + 1).clamp(1, item.stockQuantity)),
                            icon: const Icon(Icons.add_circle_outline,
                                color: AppTheme.accentColor)),
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
                        child: const Text('Add to Cart')),
                  ],
                )));
  }
}

// ─── Cart Item Tile ───────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final SaleItem item;
  final VoidCallback onRemove;
  const _CartItemTile({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppTheme.cardColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12)),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.itemName,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
              '${item.quantity} × ${AppHelpers.formatCurrency(item.sellingPrice)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ])),
        Text(AppHelpers.formatCurrency(item.totalSelling),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(width: 8),
        GestureDetector(
            onTap: onRemove,
            child:
                const Icon(Icons.close, color: AppTheme.errorColor, size: 18)),
      ]),
    );
  }
}
