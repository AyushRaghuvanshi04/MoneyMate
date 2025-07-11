import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/sms_parser_service.dart';
import '../services/income_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Expense> _expenses = [];
  bool _isListening = false;
  double _totalSpent = 0.0;
  double _totalIncome = 0.0;
  double _netBalance = 0.0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExpenses();
    _setupSmsListener();
    
    // Setup pulse animation for the main card
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadExpenses();
    }
  }

  Future<void> _loadExpenses() async {
    try {
      List<Expense> expenses = await ExpenseService.getExpenses();
      double totalIncome = await IncomeService.getTotalIncome();
      
      print('DEBUG: Loaded ${expenses.length} expenses');
      for (var expense in expenses) {
        print('DEBUG: Expense - ${expense.description}: ₹${expense.amount}');
      }
      
      setState(() {
        _expenses = expenses;
        _totalSpent = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
        _totalIncome = totalIncome;
        _netBalance = totalIncome - _totalSpent;
      });
    } catch (e) {
      print('DEBUG: Error loading expenses: $e');
    }
  }

  Future<void> _setupSmsListener() async {
    // No longer needed for manual entry
    setState(() {
      _isListening = false;
    });
  }

  // Calculate spending trend (this week vs last week)
  Map<String, dynamic> _calculateTrend() {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    
    double thisWeekTotal = 0.0;
    double lastWeekTotal = 0.0;
    
    for (var expense in _expenses) {
      if (expense.date.isAfter(thisWeekStart.subtract(const Duration(days: 1))) && 
          expense.date.isBefore(thisWeekStart.add(const Duration(days: 7)))) {
        thisWeekTotal += expense.amount;
      } else if (expense.date.isAfter(lastWeekStart.subtract(const Duration(days: 1))) && 
                 expense.date.isBefore(lastWeekStart.add(const Duration(days: 7)))) {
        lastWeekTotal += expense.amount;
      }
    }
    
    if (lastWeekTotal == 0) {
      return {
        'percentage': thisWeekTotal > 0 ? 100.0 : 0.0,
        'isIncrease': thisWeekTotal > 0,
        'thisWeek': thisWeekTotal,
        'lastWeek': lastWeekTotal,
      };
    }
    
    double percentage = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100;
    return {
      'percentage': percentage,
      'isIncrease': percentage > 0,
      'thisWeek': thisWeekTotal,
      'lastWeek': lastWeekTotal,
    };
  }

  // Calculate daily budget based on monthly goal
  Map<String, dynamic> _calculateDailyBudget() {
    const double monthlyGoal = 5000.0; // ₹5000 monthly budget
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyBudget = monthlyGoal / daysInMonth;
    
    // Calculate how much spent today
    final today = DateTime(now.year, now.month, now.day);
    double todaySpent = 0.0;
    
    for (var expense in _expenses) {
      if (expense.date.isAfter(today.subtract(const Duration(days: 1))) && 
          expense.date.isBefore(today.add(const Duration(days: 1)))) {
        todaySpent += expense.amount;
      }
    }
    
    final remaining = dailyBudget - todaySpent;
    final percentageUsed = (todaySpent / dailyBudget) * 100;
    
    return {
      'dailyBudget': dailyBudget,
      'todaySpent': todaySpent,
      'remaining': remaining,
      'percentageUsed': percentageUsed,
    };
  }

  void _showExpenseDetectedSnackbar(Expense expense) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New expense detected: ₹${expense.amount} - ${expense.description}'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SMS integration coming soon! Use manual testing for now.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trend = _calculateTrend();
    final dailyBudget = _calculateDailyBudget();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💰', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 3),
            Text('Money Mate', 
                 style: theme.textTheme.titleLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 15,
                 )),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
            onPressed: _loadExpenses,
            tooltip: 'Refresh',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report_rounded, color: Colors.white, size: 18),
            onPressed: () async {
              // Add a test expense for debugging
              try {
                await ExpenseService.addExpense(
                  amount: 100.0,
                  category: 'Food',
                  description: 'Test Expense - ${DateTime.now().toString()}',
                  date: DateTime.now(),
                );
                _loadExpenses();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test expense added! 🧪'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: const Color(0xFFEF4444),
                  ),
                );
              }
            },
            tooltip: 'Add Test',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isListening ? Icons.auto_awesome : Icons.auto_awesome_outlined, 
                     color: Colors.white, size: 12),
                const SizedBox(width: 1),
                Text(
                  'AI',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Summary Card with Animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1), // Indigo
                          Color(0xFF8B5CF6), // Purple
                          Color(0xFFEC4899), // Pink
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, 
                                                 color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Net Balance',
                                      style: TextStyle(
                                        fontSize: 16, 
                                        color: Colors.white.withOpacity(0.9), 
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Income: ₹${_totalIncome.toStringAsFixed(2)} | Spent: ₹${_totalSpent.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: Colors.white.withOpacity(0.7)
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '₹${_netBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: _netBalance >= 0 ? Colors.white : const Color(0xFFFFB3B3),
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '💸 Live Tracking',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Quick Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickStatCard(
                      icon: '💰',
                      title: 'Income',
                      value: '₹${_totalIncome.toStringAsFixed(0)}',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStatCard(
                      icon: '💸',
                      title: 'Spent',
                      value: '₹${_totalSpent.toStringAsFixed(0)}',
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickStatCard(
                      icon: _netBalance >= 0 ? '📈' : '📉',
                      title: 'Balance',
                      value: '₹${_netBalance.toStringAsFixed(0)}',
                      color: _netBalance >= 0 
                          ? const Color(0xFF10B981) 
                          : const Color(0xFFEF4444),
                      subtitle: _netBalance >= 0 ? 'Positive' : 'Negative',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent Expenses Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('🔥 ', style: TextStyle(fontSize: 20)),
                  Text(
                    'Recent Expenses',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Navigate to expense list
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Recent Expenses List
            _expenses.isEmpty
                ? Container(
                    margin: const EdgeInsets.all(20),
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
                          'No expenses yet!',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start tracking your spending\nby adding your first expense!',
                          style: TextStyle(
                            fontSize: 14, 
                            color: const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: List.generate(
                      _expenses.length > 5 ? 5 : _expenses.length,
                      (index) {
                        Expense expense = _expenses[_expenses.length - 1 - index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: _buildExpenseCard(expense, index),
                        );
                      },
                    ),
                  ),
            
            // Add some bottom padding for better scrolling experience
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard({
    required String icon,
    required String title,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, int index) {
    return AnimatedContainer(
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getCategoryColor(expense.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _getCategoryIcon(expense.category),
              color: _getCategoryColor(expense.category),
              size: 24,
            ),
          ),
          title: Text(
            expense.description,
            style: const TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 16,
              color: Color(0xFF1F2937),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${DateFormat('MMM dd, yyyy').format(expense.date)} • ${expense.category}',
                style: const TextStyle(
                  fontSize: 13, 
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (expense.isAutoDetected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
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
          ),
          trailing: Text(
            '₹${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6366F1),
            ),
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }
} 