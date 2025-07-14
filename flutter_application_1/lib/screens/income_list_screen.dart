import 'package:flutter/material.dart';
import '../models/income.dart';
import '../services/income_service.dart';
import 'package:intl/intl.dart';

class IncomeListScreen extends StatefulWidget {
  const IncomeListScreen({super.key});

  @override
  _IncomeListScreenState createState() => _IncomeListScreenState();
}

class _IncomeListScreenState extends State<IncomeListScreen> with TickerProviderStateMixin {
  List<Income> _incomes = [];
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
    
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    _refreshController.forward().then((_) {
      _refreshController.reset();
    });
    
    List<Income> incomes = await IncomeService.getIncomes();
    setState(() {
      _incomes = incomes;
    });
  }

  Future<void> _deleteIncome(Income income) async {
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
              const Text('Delete Income?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete this income?',
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
                      income.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${income.amount.toStringAsFixed(2)} • ${income.category}',
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
        await IncomeService.deleteIncome(income.id);
        await _loadIncomes(); // Reload the list
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Income deleted successfully! 🗑️'),
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
                  Text('Error deleting income: $e 😔'),
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

  List<Income> _getFilteredIncomes() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return _incomes.where((income) => 
          income.date.isAfter(weekStart.subtract(const Duration(days: 1)))
        ).toList();
      case 'This Month':
        return _incomes.where((income) => 
          income.date.month == now.month && income.date.year == now.year
        ).toList();
      case 'This Year':
        return _incomes.where((income) => 
          income.date.year == now.year
        ).toList();
      default:
        return _incomes;
    }
  }

  double _getTotalForFilteredIncomes() {
    List<Income> filteredIncomes = _getFilteredIncomes();
    double total = 0.0;
    for (Income income in filteredIncomes) {
      total += income.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredIncomes = _getFilteredIncomes();
    final totalAmount = _getTotalForFilteredIncomes();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💰', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 2),
            Text('All Income', 
                 style: theme.textTheme.titleLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                 )),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2 * 3.14159,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                  onPressed: _loadIncomes,
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
                          '💰 Total Earned',
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
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${filteredIncomes.length} transactions',
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
                              color: isSelected ? const Color(0xFF10B981) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
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

          // Incomes List
          Expanded(
            child: filteredIncomes.isEmpty
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
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: Color(0xFF9CA3AF),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Income Yet! 💸',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Start tracking your income\nby adding your first entry!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadIncomes,
                    color: const Color(0xFF10B981),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredIncomes.length,
                      itemBuilder: (context, index) {
                        final income = filteredIncomes[index];
                        return _buildIncomeCard(income);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(Income income) {
    return Dismissible(
      key: Key(income.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete_forever_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        await _deleteIncome(income);
        return true;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCategoryColor(income.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getCategoryIcon(income.category),
              color: _getCategoryColor(income.category),
              size: 28,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  income.description,
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
                  color: _getCategoryColor(income.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCategoryEmoji(income.category),
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
                    DateFormat('MMM dd').format(income.date),
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
                      income.category,
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
              if (income.isAutoDetected) ...[
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
                '₹${income.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Earned',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          onTap: () {
            // Show delete confirmation dialog
            _deleteIncome(income);
          },
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return const Color(0xFF10B981);
      case 'freelance':
        return const Color(0xFF3B82F6);
      case 'investment':
        return const Color(0xFF8B5CF6);
      case 'gift':
        return const Color(0xFFEC4899);
      case 'scholarship':
        return const Color(0xFF6366F1);
      case 'part-time':
        return const Color(0xFFF59E0B);
      case 'business':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return Icons.account_balance_wallet_rounded;
      case 'freelance':
        return Icons.work_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'scholarship':
        return Icons.school_rounded;
      case 'part-time':
        return Icons.access_time_rounded;
      case 'business':
        return Icons.business_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'salary':
        return '💰';
      case 'freelance':
        return '💼';
      case 'investment':
        return '📈';
      case 'gift':
        return '🎁';
      case 'scholarship':
        return '🎓';
      case 'part-time':
        return '⏰';
      case 'business':
        return '🏢';
      default:
        return '💸';
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
} 