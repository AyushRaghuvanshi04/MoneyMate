import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import 'google_ai_service.dart';

class ExpenseService {
  static const String _expensesKey = 'expenses';

  // Save expense to local storage
  static Future<void> saveExpense(Expense expense) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> expensesJson = prefs.getStringList(_expensesKey) ?? [];
      
      expensesJson.add(jsonEncode(expense.toJson()));
      await prefs.setStringList(_expensesKey, expensesJson);
      
      print('DEBUG: Saved expense - ${expense.description}: ₹${expense.amount}');
      print('DEBUG: Total expenses in storage: ${expensesJson.length}');
    } catch (e) {
      print('DEBUG: Error saving expense: $e');
      rethrow;
    }
  }

  // Get all expenses from local storage
  static Future<List<Expense>> getExpenses() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> expensesJson = prefs.getStringList(_expensesKey) ?? [];
      
      print('DEBUG: Loading ${expensesJson.length} expenses from storage');
      
      List<Expense> expenses = expensesJson
          .map((json) => Expense.fromJson(jsonDecode(json)))
          .toList();
      
      print('DEBUG: Successfully loaded ${expenses.length} expenses');
      return expenses;
    } catch (e) {
      print('DEBUG: Error loading expenses: $e');
      rethrow;
    }
  }

  // Delete expense by ID
  static Future<void> deleteExpense(String expenseId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> expensesJson = prefs.getStringList(_expensesKey) ?? [];
    
    // Remove the expense with matching ID
    expensesJson.removeWhere((json) {
      try {
        Map<String, dynamic> expenseData = jsonDecode(json);
        return expenseData['id'] == expenseId;
      } catch (e) {
        return false;
      }
    });
    
    await prefs.setStringList(_expensesKey, expensesJson);
  }

  // Add new expense manually with AI categorization
  static Future<Expense> addExpense({
    required double amount,
    String? category,
    required String description,
    DateTime? date,
  }) async {
    // Use AI categorization if category is not provided
    String finalCategory = category ?? 'Other';
    if (category == null) {
      try {
        finalCategory = await GoogleAIService.categorizeExpense(description, null);
      } catch (e) {
        print('AI categorization failed, using default: $e');
        finalCategory = 'Other';
      }
    }

    Expense expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      category: finalCategory,
      description: description,
      date: date ?? DateTime.now(),
      isAutoDetected: false,
    );

    await saveExpense(expense);
    return expense;
  }

  // Simple categorization based on recipient name
  static String _categorizeTransaction(String recipient) {
    String lowerRecipient = recipient.toLowerCase().trim();
    
    // Food & Dining
    if (lowerRecipient.contains('swiggy') || lowerRecipient.contains('zomato') || 
        lowerRecipient.contains('restaurant') || lowerRecipient.contains('food') ||
        lowerRecipient.contains('mcdonalds') || lowerRecipient.contains('kfc') ||
        lowerRecipient.contains('dominos') || lowerRecipient.contains('pizza')) {
      return 'Food';
    } 
    // Mobile Recharge & Bills
    else if (lowerRecipient.contains('jio') || lowerRecipient.contains('airtel') || 
             lowerRecipient.contains('vodafone') || lowerRecipient.contains('recharge') ||
             lowerRecipient.contains('prepaid') || lowerRecipient.contains('postpaid')) {
      return 'Mobile & Bills';
    }
    // Transport
    else if (lowerRecipient.contains('uber') || lowerRecipient.contains('ola') || 
             lowerRecipient.contains('metro') || lowerRecipient.contains('bus') ||
             lowerRecipient.contains('railway') || lowerRecipient.contains('petrol')) {
      return 'Transport';
    } 
    // Shopping
    else if (lowerRecipient.contains('amazon') || lowerRecipient.contains('flipkart') || 
             lowerRecipient.contains('shop') || lowerRecipient.contains('mall')) {
      return 'Shopping';
    } 
    // Entertainment
    else if (lowerRecipient.contains('movie') || lowerRecipient.contains('netflix') || 
             lowerRecipient.contains('entertainment') || lowerRecipient.contains('hotstar')) {
      return 'Entertainment';
    } 
    // Education
    else if (lowerRecipient.contains('book') || lowerRecipient.contains('course') || 
             lowerRecipient.contains('education') || lowerRecipient.contains('college')) {
      return 'Education';
    } 
    // Healthcare
    else if (lowerRecipient.contains('pharmacy') || lowerRecipient.contains('medical') ||
             lowerRecipient.contains('hospital') || lowerRecipient.contains('doctor')) {
      return 'Healthcare';
    }
    else {
      return 'Other';
    }
  }
} 