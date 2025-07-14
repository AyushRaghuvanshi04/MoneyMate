import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/income_service.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  _AddIncomeScreenState createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Salary';
  bool _isLoading = false;

  late AnimationController _headerController;
  late AnimationController _formController;
  late Animation<double> _headerAnimation;
  late Animation<double> _formAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Salary', 'emoji': '💰', 'color': Color(0xFF10B981)},
    {'name': 'Freelance', 'emoji': '💼', 'color': Color(0xFF3B82F6)},
    {'name': 'Investment', 'emoji': '📈', 'color': Color(0xFF8B5CF6)},
    {'name': 'Gift', 'emoji': '🎁', 'color': Color(0xFFEC4899)},
    {'name': 'Scholarship', 'emoji': '🎓', 'color': Color(0xFF6366F1)},
    {'name': 'Part-time', 'emoji': '⏰', 'color': Color(0xFFF59E0B)},
    {'name': 'Business', 'emoji': '🏢', 'color': Color(0xFFEF4444)},
    {'name': 'Other', 'emoji': '💸', 'color': Color(0xFF6B7280)},
  ];

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _formController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    
    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _formController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _formController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final income = Income(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: _selectedCategory,
      );

      await IncomeService.saveIncome(income);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Income added successfully! 💰'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error saving income: $e 😔'),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💰', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 2),
            Text('Add Income', 
                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                 )),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 16),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(6),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Animated Header
            AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _headerAnimation.value)),
                  child: Opacity(
                    opacity: _headerAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Track Your Income! 💰',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add money you received to keep track of your finances',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Form
            AnimatedBuilder(
              animation: _formAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - _formAnimation.value)),
                  child: Opacity(
                    opacity: _formAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Selection
                            const Text(
                              '🎯 Income Source',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
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
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? category['color'] 
                                          : category['color'].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected 
                                            ? category['color'] 
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          category['emoji'],
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          category['name'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected 
                                                ? Colors.white 
                                                : category['color'],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Description Field
                            const Text(
                              '📝 Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Monthly salary, Freelance project...',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF10B981),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a description';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Amount Field
                            const Text(
                              '💵 Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9FAFB),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF10B981),
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an amount';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid amount';
                                }
                                if (double.parse(value) <= 0) {
                                  return 'Amount must be greater than 0';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Date Field
                            const Text(
                              '📅 Date',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveIncome,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Save Income 💰',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 