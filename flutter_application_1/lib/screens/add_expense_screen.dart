import 'package:flutter/material.dart';
import '../services/sms_parser_service.dart';
import '../models/expense.dart';
import 'add_income_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  _AddExpenseState createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpenseScreen> with TickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': '🍕', 'color': const Color(0xFFF59E0B)},
    {'name': 'Transport', 'icon': '🚗', 'color': const Color(0xFF10B981)},
    {'name': 'Shopping', 'icon': '🛍️', 'color': const Color(0xFF8B5CF6)},
    {'name': 'Entertainment', 'icon': '🎬', 'color': const Color(0xFFEC4899)},
    {'name': 'Education', 'icon': '📚', 'color': const Color(0xFF6366F1)},
    {'name': 'Healthcare', 'icon': '💊', 'color': const Color(0xFFEF4444)},
    {'name': 'Mobile & Bills', 'icon': '📱', 'color': const Color(0xFF3B82F6)},
    {'name': 'Other', 'icon': '📦', 'color': const Color(0xFF6B7280)},
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  Future<void> _addExpense() async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showErrorSnackbar('Please fill all fields! 😅');
      return;
    }

    try {
      double amount = double.parse(_amountController.text);
      print('DEBUG: Adding expense - Amount: $amount, Category: $_selectedCategory, Description: ${_descriptionController.text}');
      
      await ExpenseService.addExpense(
        amount: amount,
        category: _selectedCategory,
        description: _descriptionController.text,
        date: _selectedDate,
      );

      print('DEBUG: Expense added successfully');

      // Clear form
      _amountController.clear();
      _descriptionController.clear();
      _selectedCategory = 'Food';
      _selectedDate = DateTime.now();

      _showSuccessSnackbar('Expense added successfully! 🎉');
      
      // Navigate back to home screen after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      print('DEBUG: Error adding expense: $e');
      _showErrorSnackbar('Error adding expense: $e 😔');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('➕', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 4),
            Text('Add Expense', 
                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 16,
                 )),
          ],
        ),
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddIncomeScreen()),
          );
        },
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Income'),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Animation
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1), // Indigo
                          Color(0xFF8B5CF6), // Purple
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
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '💰 Add New Expense',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your spending habits!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Amount Field
            _buildInputField(
              controller: _amountController,
              label: '💵 Amount (₹)',
              hint: 'Enter amount...',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Description Field
            _buildInputField(
              controller: _descriptionController,
              label: '📝 Description',
              hint: 'What did you spend on?',
              icon: Icons.description_rounded,
            ),
            const SizedBox(height: 20),
            
            // Category Selection
            Text(
              '🏷️ Select Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            
            // Category Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                    _bounceController.forward().then((_) {
                      _bounceController.reverse();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? category['color'] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? category['color'] : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category['icon'],
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Date Selection
            Container(
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📅 Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF6366F1),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Add Button
            GestureDetector(
              onTapDown: (_) => _bounceController.forward(),
              onTapUp: (_) => _bounceController.reverse(),
              onTapCancel: () => _bounceController.reverse(),
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounceAnimation.value,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _addExpense,
                          borderRadius: BorderRadius.circular(16),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_rounded, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Add Expense',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _bounceController.dispose();
    super.dispose();
  }
} 