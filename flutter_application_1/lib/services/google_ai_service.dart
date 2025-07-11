import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleAIService {
  static const String _baseUrl = 'https://language.googleapis.com/v1/documents:analyzeEntities';
  static String? _apiKey;

  // Initialize with API key
  static void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  // Analyze text using Google Natural Language API
  static Future<Map<String, dynamic>?> analyzeText(String text) async {
    if (_apiKey == null) {
      throw Exception('Google API key not initialized');
    }

    try {
      final url = Uri.parse('$_baseUrl?key=$_apiKey');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'document': {
            'type': 'PLAIN_TEXT',
            'content': text,
          },
          'encodingType': 'UTF8',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        print('Google API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling Google API: $e');
      return null;
    }
  }

  // Smart categorization using AI
  static Future<String> categorizeExpense(String description, String? merchant) async {
    try {
      final textToAnalyze = merchant != null ? '$description $merchant' : description;
      final analysis = await analyzeText(textToAnalyze);
      
      if (analysis != null) {
        return _extractCategoryFromAnalysis(analysis, description);
      }
    } catch (e) {
      print('AI categorization failed: $e');
    }
    
    // Fallback to rule-based categorization
    return _ruleBasedCategorization(description, merchant);
  }

  // Extract category from Google API analysis
  static String _extractCategoryFromAnalysis(Map<String, dynamic> analysis, String description) {
    final entities = analysis['entities'] as List<dynamic>?;
    if (entities == null) return _ruleBasedCategorization(description, null);

    final lowerDescription = description.toLowerCase();
    
    // Look for specific entities that indicate categories
    for (var entity in entities) {
      final name = entity['name']?.toString().toLowerCase() ?? '';
      final type = entity['type']?.toString() ?? '';
      
      // Food-related entities
      if (name.contains('food') || name.contains('restaurant') || 
          name.contains('meal') || name.contains('dinner') ||
          lowerDescription.contains('food') || lowerDescription.contains('restaurant')) {
        return 'Food';
      }
      
      // Transport-related entities
      if (name.contains('transport') || name.contains('uber') || 
          name.contains('ola') || name.contains('bus') ||
          lowerDescription.contains('transport') || lowerDescription.contains('uber')) {
        return 'Transport';
      }
      
      // Shopping-related entities
      if (name.contains('shop') || name.contains('store') || 
          name.contains('mall') || name.contains('amazon') ||
          lowerDescription.contains('shop') || lowerDescription.contains('amazon')) {
        return 'Shopping';
      }
      
      // Entertainment-related entities
      if (name.contains('movie') || name.contains('entertainment') || 
          name.contains('netflix') || name.contains('game') ||
          lowerDescription.contains('movie') || lowerDescription.contains('entertainment')) {
        return 'Entertainment';
      }
      
      // Education-related entities
      if (name.contains('book') || name.contains('course') || 
          name.contains('education') || name.contains('school') ||
          lowerDescription.contains('book') || lowerDescription.contains('course')) {
        return 'Education';
      }
      
      // Healthcare-related entities
      if (name.contains('medical') || name.contains('hospital') || 
          name.contains('pharmacy') || name.contains('doctor') ||
          lowerDescription.contains('medical') || lowerDescription.contains('hospital')) {
        return 'Healthcare';
      }
    }
    
    return _ruleBasedCategorization(description, null);
  }

  // Rule-based categorization as fallback
  static String _ruleBasedCategorization(String description, String? merchant) {
    final lowerDescription = description.toLowerCase();
    final lowerMerchant = merchant?.toLowerCase() ?? '';
    
    // Food & Dining
    if (lowerDescription.contains('food') || lowerDescription.contains('restaurant') ||
        lowerDescription.contains('meal') || lowerDescription.contains('dinner') ||
        lowerMerchant.contains('mcdonalds') || lowerMerchant.contains('kfc') ||
        lowerMerchant.contains('dominos') || lowerMerchant.contains('pizza')) {
      return 'Food';
    }
    
    // Mobile & Bills
    if (lowerDescription.contains('recharge') || lowerDescription.contains('bill') ||
        lowerMerchant.contains('jio') || lowerMerchant.contains('airtel') ||
        lowerMerchant.contains('vodafone') || lowerDescription.contains('mobile')) {
      return 'Mobile & Bills';
    }
    
    // Transport
    if (lowerDescription.contains('transport') || lowerDescription.contains('uber') ||
        lowerDescription.contains('ola') || lowerDescription.contains('bus') ||
        lowerDescription.contains('metro') || lowerDescription.contains('petrol')) {
      return 'Transport';
    }
    
    // Shopping
    if (lowerDescription.contains('shop') || lowerDescription.contains('store') ||
        lowerDescription.contains('amazon') || lowerDescription.contains('flipkart') ||
        lowerDescription.contains('mall') || lowerDescription.contains('buy')) {
      return 'Shopping';
    }
    
    // Entertainment
    if (lowerDescription.contains('movie') || lowerDescription.contains('entertainment') ||
        lowerDescription.contains('netflix') || lowerDescription.contains('game') ||
        lowerDescription.contains('music') || lowerDescription.contains('concert')) {
      return 'Entertainment';
    }
    
    // Education
    if (lowerDescription.contains('book') || lowerDescription.contains('course') ||
        lowerDescription.contains('education') || lowerDescription.contains('school') ||
        lowerDescription.contains('college') || lowerDescription.contains('study')) {
      return 'Education';
    }
    
    // Healthcare
    if (lowerDescription.contains('medical') || lowerDescription.contains('hospital') ||
        lowerDescription.contains('pharmacy') || lowerDescription.contains('doctor') ||
        lowerDescription.contains('medicine') || lowerDescription.contains('health')) {
      return 'Healthcare';
    }
    
    return 'Other';
  }

  // Generate spending insights using AI
  static Future<String> generateInsights(List<Map<String, dynamic>> expenses) async {
    try {
      // Create a summary of expenses for AI analysis
      final summary = _createExpenseSummary(expenses);
      final analysis = await analyzeText(summary);
      
      if (analysis != null) {
        return _extractInsightsFromAnalysis(analysis, expenses);
      }
    } catch (e) {
      print('AI insights generation failed: $e');
    }
    
    return _generateBasicInsights(expenses);
  }

  // Create summary text for AI analysis
  static String _createExpenseSummary(List<Map<String, dynamic>> expenses) {
    final categoryTotals = <String, double>{};
    double totalSpent = 0;
    
    for (var expense in expenses) {
      final category = expense['category'] ?? 'Other';
      final amount = expense['amount'] ?? 0.0;
      
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      totalSpent += amount;
    }
    
    final summary = StringBuffer();
    summary.write('Total spending: ₹$totalSpent. ');
    
    categoryTotals.forEach((category, amount) {
      final percentage = (amount / totalSpent * 100).toStringAsFixed(1);
      summary.write('$category: ₹$amount ($percentage%). ');
    });
    
    return summary.toString();
  }

  // Extract insights from AI analysis
  static String _extractInsightsFromAnalysis(Map<String, dynamic> analysis, List<Map<String, dynamic>> expenses) {
    // This is a placeholder for future AI-powered insights
    // For now, return basic insights
    return _generateBasicInsights(expenses);
  }

  // Generate basic spending insights
  static String _generateBasicInsights(List<Map<String, dynamic>> expenses) {
    if (expenses.isEmpty) {
      return 'No expenses recorded yet. Start tracking your spending!';
    }
    
    final categoryTotals = <String, double>{};
    double totalSpent = 0;
    
    for (var expense in expenses) {
      final category = expense['category'] ?? 'Other';
      final amount = expense['amount'] ?? 0.0;
      
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      totalSpent += amount;
    }
    
    // Find top spending category
    String topCategory = 'Other';
    double topAmount = 0;
    
    categoryTotals.forEach((category, amount) {
      if (amount > topAmount) {
        topAmount = amount;
        topCategory = category;
      }
    });
    
    final topPercentage = (topAmount / totalSpent * 100).toStringAsFixed(1);
    
    return 'You\'ve spent ₹$totalSpent total. Your biggest expense category is $topCategory (₹$topAmount, $topPercentage%).';
  }
} 