import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/credit_sales_provider.dart'; // ← ADD
import '../../utils/app_theme.dart';
import '../../utils/app_helpers.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/alert_banner.dart';
import '../sales/sales_screen.dart';
import '../sales/credit_sales_screen.dart'; // ← ADD
import '../expenses/expenses_screen.dart';
import '../inventory/inventory_screen.dart';
import '../reports/reports_screen.dart';
import '../customers/customers_screen.dart';
import '../auth/login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [
    _DashboardHome(),
    SalesScreen(),
    CreditSalesScreen(), // ← ADD
    InventoryScreen(),
    ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().clearData();
      context.read<ExpenseProvider>().clearData();
      context.read<InventoryProvider>().clearData();
      context.read<CustomerProvider>().clearData();
      context.read<CreditSalesProvider>().clearData(); // ← ADD
      _loadAll();
    });
  }

  void _loadAll() {
    context.read<SalesProvider>().loadSales();
    context.read<ExpenseProvider>().loadExpenses();
    context.read<InventoryProvider>().loadInventory();
    context.read<CustomerProvider>().loadCustomers();
    context.read<CreditSalesProvider>().loadCreditSales(); // ← ADD
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_outlined),
              activeIcon: Icon(Icons.point_of_sale),
              label: 'Sales'),
          BottomNavigationBarItem(
              // ← ADD
              icon: Icon(Icons.credit_card_outlined),
              activeIcon: Icon(Icons.credit_card),
              label: 'Credit'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Inventory'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reports'),
        ],
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome();

  void _refreshAll(BuildContext context) {
    context.read<SalesProvider>().loadSales();
    context.read<ExpenseProvider>().loadExpenses();
    context.read<InventoryProvider>().loadInventory();
    context.read<CustomerProvider>().loadCustomers();
    context.read<CreditSalesProvider>().loadCreditSales(); // ← ADD
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Data refreshed!'),
      duration: Duration(seconds: 1),
      backgroundColor: AppTheme.successColor,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final expenses = context.watch<ExpenseProvider>();
    final inventory = context.watch<InventoryProvider>();
    final customers = context.watch<CustomerProvider>();
    final credit = context.watch<CreditSalesProvider>(); // ← ADD
    final netProfit = sales.todayProfit - expenses.todayExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tyre Shop Manager'),
          Text(AppHelpers.formatDate(DateTime.now()),
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _refreshAll(context)),
          IconButton(
              icon: const Icon(Icons.people_outline),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CustomersScreen()))),
          IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ExpensesScreen()))),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: AppTheme.secondaryColor,
            onSelected: (v) async {
              if (v == 'logout') {
                context.read<SalesProvider>().clearData();
                context.read<ExpenseProvider>().clearData();
                context.read<InventoryProvider>().clearData();
                context.read<CustomerProvider>().clearData();
                context.read<CreditSalesProvider>().clearData(); // ← ADD

                await context.read<AuthProvider>().signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false);
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [
                    Icon(Icons.logout, color: AppTheme.accentColor, size: 18),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.white))
                  ]))
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accentColor,
        onRefresh: () async {
          _refreshAll(context);
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (inventory.lowStockItems.isNotEmpty)
            AlertBanner(
                icon: Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
                title:
                    '${inventory.lowStockItems.length} item(s) running low on stock',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const InventoryScreen()))),
          if (inventory.outOfStockItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            AlertBanner(
                icon: Icons.error_outline,
                color: AppTheme.errorColor,
                title:
                    '${inventory.outOfStockItems.length} item(s) out of stock!',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const InventoryScreen())))
          ],
          // ── Credit overdue alert ──────────────────────────────── ← ADD
          if (credit.overdueCount > 0) ...[
            const SizedBox(height: 8),
            AlertBanner(
                icon: Icons.credit_card_off_outlined,
                color: const Color(0xFFE67E22),
                title:
                    '${credit.overdueCount} credit sale(s) overdue! Total: ${AppHelpers.formatCurrency(credit.totalOutstanding)}',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreditSalesScreen()))),
          ],
          const SizedBox(height: 16),
          _sectionHeader('Today\'s Summary'),
          const SizedBox(height: 14),
          GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                StatCard(
                    title: 'Revenue',
                    value: AppHelpers.formatCurrency(sales.todayRevenue),
                    icon: Icons.attach_money,
                    color: AppTheme.successColor,
                    subtitle: '${sales.todaySalesCount} sales'),
                StatCard(
                    title: 'Gross Profit',
                    value: AppHelpers.formatCurrency(sales.todayProfit),
                    icon: Icons.trending_up,
                    color: AppTheme.accentColor),
                StatCard(
                    title: 'Expenses',
                    value: AppHelpers.formatCurrency(expenses.todayExpenses),
                    icon: Icons.money_off,
                    color: AppTheme.warningColor),
                StatCard(
                    title: 'Net Profit',
                    value: AppHelpers.formatCurrency(netProfit),
                    icon: netProfit >= 0
                        ? Icons.sentiment_satisfied
                        : Icons.sentiment_dissatisfied,
                    color: netProfit >= 0
                        ? AppTheme.successColor
                        : AppTheme.errorColor),
              ]),
          const SizedBox(height: 24),
          _sectionHeader('Inventory'),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: StatCard(
                    title: 'Tyres in Stock',
                    value: inventory.totalTyreStock.toString(),
                    icon: Icons.tire_repair,
                    color: const Color(0xFF7C4DFF))),
            const SizedBox(width: 12),
            Expanded(
                child: StatCard(
                    title: 'Tubes in Stock',
                    value: inventory.totalTubeStock.toString(),
                    icon: Icons.circle_outlined,
                    color: const Color(0xFF00BCD4))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: StatCard(
                    title: 'Customers',
                    value: customers.totalCustomers.toString(),
                    icon: Icons.people,
                    color: const Color(0xFF4CAF50))),
            const SizedBox(width: 12),
            Expanded(
                child: StatCard(
                    title: 'Credit Due', // ← CHANGED
                    value: AppHelpers.formatCurrency(credit.totalOutstanding),
                    icon: Icons.credit_card_outlined,
                    color: const Color(0xFFE67E22))),
          ]),
          const SizedBox(height: 24),
          _sectionHeader('Quick Actions'),
          const SizedBox(height: 14),
          Row(children: [
            _QuickAction(
                icon: Icons.add_shopping_cart,
                label: 'New Sale',
                color: AppTheme.accentColor,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SalesScreen()))),
            const SizedBox(width: 12),
            _QuickAction(
                icon: Icons.money_off,
                label: 'Add Expense',
                color: AppTheme.warningColor,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExpensesScreen()))),
            const SizedBox(width: 12),
            _QuickAction(
                icon: Icons.credit_card_outlined, // ← CHANGED
                label: 'Credit Sale',
                color: const Color(0xFFE67E22),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreditSalesScreen()))),
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(children: [
      Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
