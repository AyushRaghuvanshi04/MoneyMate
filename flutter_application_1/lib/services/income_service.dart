import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/income.dart';

class IncomeService {
  static const String _storageKey = 'incomes';

  static Future<void> saveIncome(Income income) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> incomes = prefs.getStringList(_storageKey) ?? [];
    
    // Add new income
    incomes.add(jsonEncode(income.toJson()));
    
    await prefs.setStringList(_storageKey, incomes);
    print('DEBUG: Saved income - ${income.description} - ${income.date}: ₹${income.amount}');
    print('DEBUG: Total incomes in storage: ${incomes.length}');
  }

  static Future<List<Income>> getIncomes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> incomes = prefs.getStringList(_storageKey) ?? [];
    
    print('DEBUG: Loading ${incomes.length} incomes from storage');
    
    List<Income> incomeList = [];
    for (String incomeJson in incomes) {
      try {
        Map<String, dynamic> incomeMap = jsonDecode(incomeJson);
        incomeList.add(Income.fromJson(incomeMap));
      } catch (e) {
        print('DEBUG: Error parsing income: $e');
      }
    }
    
    // Sort by date (newest first)
    incomeList.sort((a, b) => b.date.compareTo(a.date));
    
    print('DEBUG: Successfully loaded ${incomeList.length} incomes');
    return incomeList;
  }

  static Future<void> deleteIncome(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> incomes = prefs.getStringList(_storageKey) ?? [];
    
    // Remove income with matching id
    incomes.removeWhere((incomeJson) {
      try {
        Map<String, dynamic> incomeMap = jsonDecode(incomeJson);
        return incomeMap['id'] == id;
      } catch (e) {
        return false;
      }
    });
    
    await prefs.setStringList(_storageKey, incomes);
    print('DEBUG: Deleted income with id: $id');
  }

  static Future<double> getTotalIncome() async {
    List<Income> incomes = await getIncomes();
    double total = 0.0;
    for (Income income in incomes) {
      total += income.amount;
    }
    return total;
  }

  static Future<double> getIncomeForPeriod(DateTime start, DateTime end) async {
    List<Income> incomes = await getIncomes();
    double total = 0.0;
    for (Income income in incomes) {
      if (income.date.isAfter(start.subtract(const Duration(days: 1))) && 
          income.date.isBefore(end.add(const Duration(days: 1)))) {
        total += income.amount;
      }
    }
    return total;
  }
} 