import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_helpers.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Customers (${provider.totalCustomers})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              provider.loadCustomers();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Customers refreshed!'),
                duration: Duration(seconds: 1),
                backgroundColor: AppTheme.successColor,
              ));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Search name, phone, vehicle...', prefixIcon: Icon(Icons.search, color: AppTheme.textMuted)),
              onChanged: provider.setSearchQuery,
            ),
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : provider.customers.isEmpty
              ? const Center(child: Text('No customers found', style: TextStyle(color: AppTheme.textMuted)))
              : RefreshIndicator(
                  color: AppTheme.accentColor,
                  onRefresh: () async {
                    provider.loadCustomers();
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.customers.length,
                    itemBuilder: (_, i) => _CustomerTile(customer: provider.customers[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'customers_fab',
        onPressed: () => _showAddCustomerSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  void _showAddCustomerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.secondaryColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddCustomerSheet(),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.secondaryColor, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.15), shape: BoxShape.circle), child: Center(child: Text(customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700, fontSize: 18)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Text(customer.phone, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          if (customer.vehicleNumber != null) Text('${customer.vehicleType ?? ''} • ${customer.vehicleNumber}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(AppHelpers.formatCurrency(customer.totalPurchases), style: const TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w600, fontSize: 13)),
          Text('${customer.totalVisits} visit(s)', style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ]),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textMuted, size: 18),
          color: AppTheme.cardColor,
          onSelected: (v) async {
            if (v == 'delete') {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.secondaryColor,
                title: const Text('Delete Customer?'),
                content: Text('Delete ${customer.name}?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor))),
                ],
              ));
              if (confirm == true && context.mounted) context.read<CustomerProvider>().deleteCustomer(customer.id);
            }
          },
          itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.white))]))],
        ),
      ]),
    );
  }
}

class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();
  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();
  final _vehicleNumCtrl = TextEditingController();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<CustomerProvider>().addCustomer(name: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim(), email: _emailCtrl.text.isEmpty ? null : _emailCtrl.text.trim(), address: _addressCtrl.text.isEmpty ? null : _addressCtrl.text.trim(), vehicleType: _vehicleTypeCtrl.text.isEmpty ? null : _vehicleTypeCtrl.text.trim(), vehicleNumber: _vehicleNumCtrl.text.isEmpty ? null : _vehicleNumCtrl.text.trim());
    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer added!'), backgroundColor: AppTheme.successColor));
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
            const Text('Add Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted))),
          ]),
          const SizedBox(height: 16),
          TextFormField(controller: _nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone *', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted)), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Email (optional)', prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted))),
          const SizedBox(height: 12),
          TextFormField(controller: _addressCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Address (optional)', prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.textMuted))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _vehicleTypeCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Vehicle Type'))),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _vehicleNumCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Vehicle No.'))),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)), child: const Text('Save Customer'))),
          const SizedBox(height: 10),
        ])),
      ),
    );
  }
}