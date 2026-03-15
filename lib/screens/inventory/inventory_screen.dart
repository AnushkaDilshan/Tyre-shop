import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inventory_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../utils/app_constants.dart' hide AppHelpers;

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
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
    final inv = context.watch<InventoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<InventoryProvider>().loadInventory();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Inventory refreshed!'),
                duration: Duration(seconds: 1),
                backgroundColor: AppTheme.successColor,
              ));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accentColor,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            Tab(text: 'Tyres (${inv.totalTyreStock})'),
            Tab(text: 'Tubes (${inv.totalTubeStock})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search by name, brand, size...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
              ),
              onChanged: inv.setSearchQuery,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _InventoryList(items: inv.tyres, type: 'tyre'),
                _InventoryList(items: inv.tubes, type: 'tube'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_fab',
        onPressed: () => _showAddItemSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  void _showAddItemSheet(BuildContext context) {
    final initialType = _tab.index == 0 ? 'tyre' : 'tube';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.secondaryColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddItemSheet(initialType: initialType),
    );
  }
}

// ─── Inventory List ──────────────────────────────────────────

class _InventoryList extends StatelessWidget {
  final List<InventoryItem> items;
  final String type;
  const _InventoryList({required this.items, required this.type});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type == 'tyre' ? Icons.tire_repair : Icons.circle_outlined,
                size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text('No ${type}s found',
                style: const TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: items.length,
      itemBuilder: (_, i) => _InventoryTile(item: items[i]),
    );
  }
}

// ─── Inventory Tile (FIXED: no more right overflow) ──────────

class _InventoryTile extends StatelessWidget {
  final InventoryItem item;
  const _InventoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final stockColor = item.isOutOfStock
        ? AppTheme.errorColor
        : item.isLowStock
            ? AppTheme.warningColor
            : AppTheme.successColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                item.isLowStock ? stockColor.withOpacity(0.4) : Colors.white10),
      ),
      // ── Outer Column so price badges sit below the main row ──
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon | name+subtitle | stock+actions ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                    item.type == 'tyre'
                        ? Icons.tire_repair
                        : Icons.circle_outlined,
                    color: const Color(0xFF7C4DFF),
                    size: 22),
              ),
              const SizedBox(width: 12),

              // Name + subtitle — Expanded absorbs all spare space
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('${item.brand} • ${item.size} • ${item.category}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right column: stock badge + action icons (fixed width)
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: stockColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.stockQuantity}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: stockColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('in stock',
                        style:
                            TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    const SizedBox(height: 8),
                    // Action icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _showAdjustStock(context, item),
                          child: const Icon(Icons.tune,
                              color: AppTheme.accentColor, size: 18),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _showEditItem(context, item),
                          child: const Icon(Icons.edit_outlined,
                              color: AppTheme.textMuted, size: 18),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _confirmDelete(context, item),
                          child: const Icon(Icons.delete_outline,
                              color: AppTheme.errorColor, size: 18),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Price badges row — full width below, wraps if needed ──
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _Badge(
                  label: 'Buy: ${AppHelpers.formatCurrency(item.buyingPrice)}',
                  color: AppTheme.textMuted),
              _Badge(
                  label:
                      'Sell: ${AppHelpers.formatCurrency(item.sellingPrice)}',
                  color: AppTheme.accentColor),
              _Badge(
                  label: '+${AppHelpers.formatCurrency(item.profitMargin)}',
                  color: AppTheme.successColor),
            ],
          ),
        ],
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────

  void _showAdjustStock(BuildContext context, InventoryItem item) {
    final ctrl = TextEditingController(text: item.stockQuantity.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.secondaryColor,
        title: const Text('Adjust Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.name, style: const TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'New Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(ctrl.text);
              if (qty == null) return;
              await context
                  .read<InventoryProvider>()
                  .adjustStock(item.id, item.type, qty);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditItem(BuildContext context, InventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.secondaryColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddItemSheet(existingItem: item, initialType: item.type),
    );
  }

  void _confirmDelete(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.secondaryColor,
        title: const Text('Delete Item?'),
        content: Text('Delete "${item.name}" from inventory?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await context
                  .read<InventoryProvider>()
                  .deleteItem(item.id, item.type);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

// ─── Badge ───────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10)),
    );
  }
}

// ─── Add / Edit Item Sheet ───────────────────────────────────

class _AddItemSheet extends StatefulWidget {
  final InventoryItem? existingItem;
  final String initialType;
  const _AddItemSheet({this.existingItem, required this.initialType});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type;
  late String _category;
  final _nameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _buyCtrl = TextEditingController();
  final _sellCtrl = TextEditingController();
  final _alertCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == 'tyre'
        ? AppConstants.tyreCategories.first
        : AppConstants.tubeCategories.first;
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _type = item.type;
      _category = item.category;
      _nameCtrl.text = item.name;
      _brandCtrl.text = item.brand;
      _sizeCtrl.text = item.size;
      _stockCtrl.text = item.stockQuantity.toString();
      _buyCtrl.text = item.buyingPrice.toString();
      _sellCtrl.text = item.sellingPrice.toString();
      _alertCtrl.text = item.lowStockAlert.toString();
      _descCtrl.text = item.description ?? '';
    } else {
      _alertCtrl.text = '5';
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _brandCtrl,
      _sizeCtrl,
      _stockCtrl,
      _buyCtrl,
      _sellCtrl,
      _alertCtrl,
      _descCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final inv = context.read<InventoryProvider>();
    bool ok;
    if (widget.existingItem != null) {
      final updated = widget.existingItem!.copyWith(
        stockQuantity: int.parse(_stockCtrl.text),
        buyingPrice: double.parse(_buyCtrl.text),
        sellingPrice: double.parse(_sellCtrl.text),
        updatedAt: DateTime.now(),
      );
      ok = await inv.updateItem(updated);
    } else {
      ok = await inv.addItem(
        name: _nameCtrl.text.trim(),
        type: _type,
        category: _category,
        brand: _brandCtrl.text.trim(),
        size: _sizeCtrl.text.trim(),
        stockQuantity: int.parse(_stockCtrl.text),
        buyingPrice: double.parse(_buyCtrl.text),
        sellingPrice: double.parse(_sellCtrl.text),
        lowStockAlert: int.tryParse(_alertCtrl.text) ?? 5,
        description: _descCtrl.text.isEmpty ? null : _descCtrl.text.trim(),
      );
    }
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.existingItem != null
              ? 'Item updated!'
              : 'Item added to inventory!'),
          backgroundColor: AppTheme.successColor));
    }
  }

  List<String> get _categories => _type == 'tyre'
      ? AppConstants.tyreCategories
      : AppConstants.tubeCategories;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingItem != null
                        ? 'Edit Item'
                        : 'Add Inventory Item',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: const Text('Cancel',
                          style: TextStyle(color: AppTheme.textMuted))),
                ],
              ),
              const SizedBox(height: 16),

              // Type selector (add mode only)
              if (widget.existingItem == null)
                Row(
                  children: [
                    Expanded(
                        child: _TypeBtn(
                            label: 'Tyre',
                            icon: Icons.tire_repair,
                            selected: _type == 'tyre',
                            onTap: () => setState(() {
                                  _type = 'tyre';
                                  _category = AppConstants.tyreCategories.first;
                                }))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _TypeBtn(
                            label: 'Tube',
                            icon: Icons.circle_outlined,
                            selected: _type == 'tube',
                            onTap: () => setState(() {
                                  _type = 'tube';
                                  _category = AppConstants.tubeCategories.first;
                                }))),
                  ],
                ),
              if (widget.existingItem == null) const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _category,
                dropdownColor: AppTheme.cardColor,
                decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined,
                        color: AppTheme.textMuted)),
                items: _categories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c,
                            style: const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: widget.existingItem != null
                    ? null
                    : (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),

              if (widget.existingItem == null) ...[
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Item Name *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Brand *'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _sizeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Size *'),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buyCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          const InputDecoration(labelText: 'Buying Price *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _sellCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          const InputDecoration(labelText: 'Selling Price *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          const InputDecoration(labelText: 'Stock Qty *'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _alertCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration:
                          const InputDecoration(labelText: 'Low Stock Alert'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.existingItem != null
                      ? 'Update Item'
                      : 'Add to Inventory'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Type Button ─────────────────────────────────────────────

class _TypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accentColor.withOpacity(0.15)
              : AppTheme.cardColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppTheme.accentColor : Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppTheme.accentColor : AppTheme.textMuted),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: selected ? AppTheme.accentColor : AppTheme.textMuted,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
