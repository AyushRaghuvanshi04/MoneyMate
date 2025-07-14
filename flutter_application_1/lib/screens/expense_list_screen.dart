import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/sms_parser_service.dart';
import 'package:intl/intl.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> with TickerProviderStateMixin {
  List<Expense> _expenses = [];
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'This Week', 'This Month', 'This Year'];

  @override
  void initState() {
    super.initState();
    
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut),
    );
    
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    _refreshController.forward().then((_) {
      _refreshController.reset();
    });
    
    List<Expense> expenses = await ExpenseService.getExpenses();
    setState(() {
      _expenses = expenses;
    });
  }

  Future<void> _deleteExpense(Expense expense) async {
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 28),
              const SizedBox(width: 8),
              const Text('Delete Expense?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this expense?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)} • ${expense.category}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone! 😱',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await ExpenseService.deleteExpense(expense.id);
        await _loadExpenses(); // Reload the list
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Expense deleted successfully! 🗑️'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Error deleting expense: $e 😔'),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  List<Expense> _getFilteredExpenses() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return _expenses.where((expense) => 
          expense.date.isAfter(weekStart.subtract(const Duration(days: 1)))
        ).toList();
      case 'This Month':
        return _expenses.where((expense) => 
          expense.date.month == now.month && expense.date.year == now.year
        ).toList();
      case 'This Year':
        return _expenses.where((expense) => 
          expense.date.year == now.year
        ).toList();
      default:
        return _expenses;
    }
  }

  double _getTotalForFilteredExpenses() {
    return _getFilteredExpenses().fold(0.0, (sum, expense) => sum + expense.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredExpenses = _getFilteredExpenses();
    final totalAmount = _getTotalForFilteredExpenses();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 2),
            Text('All Expenses', 
                 style: theme.textTheme.titleLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                 )),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2 * 3.14159,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                  onPressed: _loadExpenses,
                  tooltip: 'Refresh',
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💰 Total Spent',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Color(0xFF6366F1),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${filteredExpenses.length} transactions',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('🔍 ', style: TextStyle(fontSize: 16)),
                Text(
                  'Filter by:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Expenses List
          Expanded(
            child: filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text('📱', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                'No expenses found!',
                                style: TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try changing the filter or\nadd some expenses first!',
                                style: TextStyle(
                                  fontSize: 14, 
                                  color: const Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: filteredExpenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      Expense expense = filteredExpenses[filteredExpenses.length - 1 - index];
                      return _buildExpenseCard(expense, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, int index) {
    return Dismissible(
      key: Key(expense.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        await _deleteExpense(expense);
        return true;
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400 + (index * 100)),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _getCategoryColor(expense.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: _getCategoryColor(expense.category),
                size: 28,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    expense.description,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCategoryEmoji(expense.category),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      DateFormat('MMM dd').format(expense.date),
                      style: const TextStyle(
                        fontSize: 11, 
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.category_rounded,
                      size: 12,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        expense.category,
                        style: const TextStyle(
                          fontSize: 11, 
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (expense.isAutoDetected) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🤖 Auto-detected',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Spent',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              // Show delete confirmation dialog
              _deleteExpense(expense);
            },
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return const Color(0xFFF59E0B);
      case 'mobile & bills':
        return const Color(0xFF3B82F6);
      case 'transport':
        return const Color(0xFF10B981);
      case 'shopping':
        return const Color(0xFF8B5CF6);
      case 'entertainment':
        return const Color(0xFFEC4899);
      case 'education':
        return const Color(0xFF6366F1);
      case 'healthcare':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood_rounded;
      case 'mobile & bills':
        return Icons.phone_android_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'healthcare':
        return Icons.local_hospital_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return '🍕';
      case 'mobile & bills':
        return '📱';
      case 'transport':
        return '🚗';
      case 'shopping':
        return '🛍️';
      case 'entertainment':
        return '🎬';
      case 'education':
        return '📚';
      case 'healthcare':
        return '💊';
      default:
        return '📦';
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
} 