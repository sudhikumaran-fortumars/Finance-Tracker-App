import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/address.dart';
import '../models/transaction.dart';
import '../models/user_scheme.dart';
import '../models/scheme_type.dart';
import '../utils/calculations.dart';
import '../widgets/common/card_widget.dart';
import '../widgets/common/button_widget.dart';
import '../providers/data_provider.dart';
import '../services/storage_service.dart';

class DailyEntryScreen extends StatefulWidget {
  const DailyEntryScreen({super.key});

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  User? _selectedUser;
  PaymentMode _paymentMode = PaymentMode.offline;
  DateTime _selectedDate = DateTime.now();
  
  final StorageService _storageService = StorageService.instance;
  List<UserScheme> _userSchemes = [];
  final Map<String, double> _userBonuses = {};
  final Map<String, double> _userPendingAmounts = {};
  final Map<String, double> _userPaidAmounts = {};
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredUsers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<DataProvider>().initializeData();
        _loadUserData();
      } catch (e) {
        // Handle initialization error silently
        // The app will continue with default state
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Get data from DataProvider instead of directly from storage
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final userSchemes = dataProvider.userSchemes;
      final transactions = dataProvider.transactions;
      
      if (mounted) {
        setState(() {
          _userSchemes = userSchemes;
          _calculateUserAmounts(transactions);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = [];
      } else {
        final dataProvider = context.read<DataProvider>();
        if (dataProvider.users.isNotEmpty) {
          _filteredUsers = dataProvider.users.where((user) {
            return user.name.toLowerCase().contains(query.toLowerCase()) ||
                user.mobileNumber.contains(query) ||
                user.serialNumber.toLowerCase().contains(query.toLowerCase()) ||
                user.permanentAddress.city.toLowerCase().contains(query.toLowerCase());
          }).toList();
        } else {
          _filteredUsers = [];
        }
      }
    });
  }

  void _calculateUserAmounts(List<Transaction> transactions) {
    _userBonuses.clear();
    _userPendingAmounts.clear();
    _userPaidAmounts.clear();

    for (var scheme in _userSchemes) {
      final userId = scheme.userId;
      final totalAmount = scheme.totalAmount;
      
      // Calculate paid amount from transactions
      final userTransactions = transactions.where((t) => t.userId == userId).toList();
      final paidAmount = userTransactions.fold(0.0, (sum, t) => sum + t.amount);
      
      // Calculate bonus from actual transaction bonus amounts
      final bonus = userTransactions.fold(0.0, (sum, t) => sum + t.interest);
      
      _userPaidAmounts[userId] = paidAmount;
      _userPendingAmounts[userId] = totalAmount - paidAmount;
      _userBonuses[userId] = bonus;
    }
  }

  void _autoFillWeeklyAmount(User user) {
    try {
      // Get user schemes from DataProvider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final userSchemes = dataProvider.userSchemes;
      
      // Find user's scheme to get weekly amount
      UserScheme? userScheme;
      try {
        userScheme = userSchemes.firstWhere(
          (scheme) => scheme.userId == user.id,
        );
      } catch (e) {
        userScheme = null;
      }
      
      if (userScheme == null) {
        // No scheme found, don't auto-fill
        return;
      }
      
      // Calculate weekly amount from total amount (total / 52 weeks)
      final weeklyAmount = userScheme.totalAmount / 52;
      
      // Calculate overdue amount
      final overdueAmount = _calculateOverdueAmount(user.id);
      
      // Total amount = weekly amount + overdue amount
      final totalAmount = weeklyAmount + overdueAmount;
      
      if (totalAmount > 0 && mounted) {
        _amountController.text = totalAmount.toStringAsFixed(0);
      }
    } catch (e) {
      // Handle any errors silently to prevent rendering issues
    }
  }

  double _calculateOverdueAmount(String userId) {
    try {
      // Get user schemes from DataProvider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final userSchemes = dataProvider.userSchemes;
      
      UserScheme? userScheme;
      try {
        userScheme = userSchemes.firstWhere(
          (scheme) => scheme.userId == userId,
        );
      } catch (e) {
        userScheme = null;
      }
      
      if (userScheme == null) return 0.0;
      
      final joiningDate = userScheme.startDate;
      final now = DateTime.now();
      final daysSinceJoining = now.difference(joiningDate).inDays;
      final weeklyAmount = userScheme.totalAmount / 52;
      
      // Calculate current week number
      final currentWeek = (daysSinceJoining / 7).floor();
      
      // Get all transactions for this user from the provider
      final allTransactions = Provider.of<DataProvider>(context, listen: false).transactions;
      final userTransactions = allTransactions.where((t) => t.userId == userId).toList();
      
      // Calculate how many weeks have passed since joining
      final weeksPassed = currentWeek + 1;
      
      // Calculate how many payments should have been made
      // Only consider a week overdue if it's been more than 7 days since the week started
      final expectedPayments = weeksPassed;
      
      // Calculate how many payments have actually been made
      final actualPayments = userTransactions.length;
      
      // Calculate overdue weeks - only if the current week is more than 7 days old
      int overdueWeeks = 0;
      
      // Check each week to see if it's overdue
      for (int week = 0; week < weeksPassed; week++) {
        final weekStartDate = joiningDate.add(Duration(days: week * 7));
        final weekEndDate = weekStartDate.add(const Duration(days: 6));
        final daysSinceWeekEnd = now.difference(weekEndDate).inDays;
        
        // A week is overdue only if it's been more than 7 days since the week ended
        if (daysSinceWeekEnd > 7) {
          // Check if payment was made for this week
          final hasPaymentForWeek = userTransactions.any((transaction) {
            final transactionDate = transaction.date;
            return transactionDate.isAfter(weekStartDate.subtract(const Duration(days: 1))) &&
                   transactionDate.isBefore(weekEndDate.add(const Duration(days: 1)));
          });
          
          if (!hasPaymentForWeek) {
            overdueWeeks++;
          }
        }
      }
      
      
      // Return overdue amount (overdue weeks * weekly amount)
      return overdueWeeks > 0 ? overdueWeeks * weeklyAmount : 0.0;
      
    } catch (e) {
      return 0.0;
    }
  }

  DateTime? _calculateNextDueDate(String userId) {
    try {
      // Get user schemes from DataProvider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final userSchemes = dataProvider.userSchemes;
      
      UserScheme? userScheme;
      try {
        userScheme = userSchemes.firstWhere(
          (scheme) => scheme.userId == userId,
        );
      } catch (e) {
        userScheme = null;
      }
      
      if (userScheme == null) return null;
      
      final joiningDate = userScheme.startDate;
      final now = DateTime.now();
      final daysSinceJoining = now.difference(joiningDate).inDays;
      
      // Calculate current week number
      final currentWeek = (daysSinceJoining / 7).floor();
      
      // Calculate next week start date
      final nextWeekStart = joiningDate.add(Duration(days: (currentWeek + 1) * 7));
      
      // If we're still in the current week, return current week's due date
      final currentWeekStart = joiningDate.add(Duration(days: currentWeek * 7));
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
      
      if (now.isBefore(currentWeekEnd.add(const Duration(days: 1)))) {
        // Still in current week, return current week's due date
        return currentWeekEnd;
      } else {
        // Current week is over, return next week's due date
        return nextWeekStart.add(const Duration(days: 6));
      }
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a user')));
        return;
      }

      final dataProvider = context.read<DataProvider>();
      final amount = double.parse(_amountController.text);
      
      // Calculate bonus based on 7-day rule
      final bonus = await _calculateBonus(amount, _selectedDate);

      // Create new transaction
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _selectedUser!.id,
        schemeId: '1', // Default scheme ID
        amount: amount,
        paymentMode: _paymentMode,
        date: _selectedDate,
        interest: bonus, // Store bonus in interest field
        remarks: _remarksController.text.isNotEmpty
            ? _remarksController.text
            : null,
        receiptNumber: 'RCP${DateTime.now().millisecondsSinceEpoch}',
      );

      try {
        await dataProvider.addTransaction(transaction);

        // Find and update user scheme balance
        final userScheme = _userSchemes.firstWhere(
          (scheme) => scheme.userId == _selectedUser!.id,
          orElse: () => _userSchemes.first, // Fallback to first scheme
        );
        final updatedScheme = userScheme.copyWith(
          currentBalance: userScheme.currentBalance + amount,
        );
        await _storageService.saveUserScheme(updatedScheme);

        // Update local state without reloading
        final transactions = await _storageService.getTransactions();
        setState(() {
          final index = _userSchemes.indexWhere((s) => s.id == userScheme.id);
          if (index != -1) {
            _userSchemes[index] = updatedScheme;
          }
          _calculateUserAmounts(transactions);
        });

        // Clear form
        _amountController.clear();
        _remarksController.clear();
        setState(() {
          _selectedUser = null;
          _selectedDate = DateTime.now();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transaction saved! Bonus: ₹${bonus.toStringAsFixed(2)}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving transaction: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Refresh user schemes when screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
    
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_card_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Daily Entry',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[100] : Colors.grey[900],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: dataProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : dataProvider.users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load data',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: isDark
                                    ? Colors.grey[100]
                                    : Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your connection and try again',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                dataProvider.refreshData();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Transaction Details Card
                              CardWidget(
                                title: 'Transaction Details',
                                child: Column(
                                  children: [
                                    // User Search
                                    _buildUserSearch(),
                                    const SizedBox(height: 20),

                                    // User Info Display
                                    if (_selectedUser != null)
                                      _buildUserInfoCard(),
                                    if (_selectedUser != null)
                                      const SizedBox(height: 20),

                                    // Amount
                                    _buildModernTextField(
                                      controller: _amountController,
                                      label: 'Amount',
                                      prefix: '₹ ',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Amount is required';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid amount';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // Payment Mode
                                    _buildPaymentModeDropdown(),
                                    const SizedBox(height: 20),

                                    // Transaction Date
                                    _buildDateField(),
                                    const SizedBox(height: 20),

                                    // Remarks
                                    _buildModernTextField(
                                      controller: _remarksController,
                                      label: 'Remarks (Optional)',
                                      maxLines: 3,
                                    ),
                                    const SizedBox(height: 24),

                                    // Done Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ButtonWidget(
                                        text: 'Done',
                                        icon: Icons.check_rounded,
                                        onPressed: _saveTransaction,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Recent Transactions Section
                              const SizedBox(height: 24),
                              CardWidget(
                                title: 'Recent Transactions',
                                child:
                                    dataProvider.getRecentTransactions().isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.receipt_long_rounded,
                                              size: 48,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No recent transactions',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: isDark
                                                        ? Colors.grey[400]
                                                        : Colors.grey[600],
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: dataProvider
                                            .getRecentTransactions()
                                            .map((transaction) {
                                              return _buildTransactionItem(
                                                transaction,
                                                dataProvider,
                                              );
                                            })
                                            .toList(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[100] : Colors.grey[900],
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixText: prefix,
              prefixStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[100] : Colors.grey[900],
                fontWeight: FontWeight.w600,
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Date',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _selectedDate = date;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 20,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  Calculations.formatDate(_selectedDate),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[100] : Colors.grey[900],
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserSearch() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search User',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: _filterUsers,
          decoration: InputDecoration(
            hintText: 'Search users by name, mobile, or city...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey[100] : Colors.grey[900],
          ),
        ),
        if (_searchQuery.isNotEmpty && _filteredUsers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSearchResults(),
        ],
        if (_selectedUser != null) ...[
          const SizedBox(height: 12),
          _buildSelectedUserCard(),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_filteredUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
          ),
        ),
        child: Text(
          'No users found',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedUser?.id == user.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUser = user;
          _searchController.clear();
          _filteredUsers.clear();
          _searchQuery = '';
        });
        
        // Auto-fill weekly amount from user's scheme (outside setState)
        _autoFillWeeklyAmount(user);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isSelected 
                  ? theme.colorScheme.primary
                  : (isDark ? Colors.grey[600] : Colors.grey[300]),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.grey[100] : Colors.grey[700]),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[100] : Colors.grey[900],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.serialNumber} • ${user.mobileNumber}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getUserSchemeName(user.id),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedUserCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              _selectedUser!.name.isNotEmpty ? _selectedUser!.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedUser!.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedUser!.serialNumber} • ${_selectedUser!.mobileNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getUserSchemeName(_selectedUser!.id),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedUser = null;
              });
            },
            icon: const Icon(Icons.close),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModeDropdown() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Mode',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<PaymentMode>(
            initialValue: _paymentMode,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              isDense: true,
            ),
            dropdownColor: isDark ? Colors.grey[800] : Colors.white,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[100] : Colors.grey[900],
            ),
            items: PaymentMode.values.map((mode) {
              return DropdownMenuItem<PaymentMode>(
                value: mode,
                child: Text(
                  mode.toString().split('.').last.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (PaymentMode? mode) {
              setState(() {
                _paymentMode = mode!;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select payment mode';
              }
              return null;
            },
            selectedItemBuilder: (context) {
              return PaymentMode.values.map<Widget>((mode) {
                return Text(
                  mode.toString().split('.').last.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    Transaction transaction,
    DataProvider dataProvider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Find user for this transaction
    final user =
        dataProvider.getUserById(transaction.userId) ??
        User(
          id: transaction.userId,
          name: 'Unknown User',
          mobileNumber: 'N/A',
          serialNumber: 'N/A',
          status: UserStatus.active,
          permanentAddress: Address(
            doorNumber: 'N/A',
            street: 'N/A',
            area: 'N/A',
            localAddress: 'N/A',
            city: 'N/A',
            district: 'N/A',
            state: 'N/A',
            pinCode: 'N/A',
          ),
          createdAt: DateTime.now(),
          schemes: [],
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getPaymentModeColor(
                transaction.paymentMode,
              ).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              _getPaymentModeIcon(transaction.paymentMode),
              color: _getPaymentModeColor(transaction.paymentMode),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[100] : Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Calculations.formatDate(transaction.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                if (transaction.remarks != null &&
                    transaction.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    transaction.remarks!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Calculations.formatCurrency(transaction.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[100] : Colors.grey[900],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPaymentModeColor(
                    transaction.paymentMode,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.paymentMode
                      .toString()
                      .split('.')
                      .last
                      .toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _getPaymentModeColor(transaction.paymentMode),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPaymentModeColor(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.offline:
        return const Color(0xFF3B82F6);
      case PaymentMode.card:
        return const Color(0xFF10B981);
      case PaymentMode.upi:
        return const Color(0xFF8B5CF6);
      case PaymentMode.netbanking:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getPaymentModeIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.offline:
        return Icons.offline_bolt_rounded;
      case PaymentMode.card:
        return Icons.credit_card_rounded;
      case PaymentMode.upi:
        return Icons.phone_android_rounded;
      case PaymentMode.netbanking:
        return Icons.account_balance_rounded;
    }
  }


  Widget _buildUserInfoCard() {
    final theme = Theme.of(context);
    final userId = _selectedUser!.id;
    
    // Use cached values to avoid recalculation
    final totalAmount = _userSchemes
        .where((s) => s.userId == userId)
        .fold(0.0, (sum, s) => sum + s.totalAmount);
    final paidAmount = _userPaidAmounts[userId] ?? 0.0;
    final pendingAmount = _userPendingAmounts[userId] ?? 0.0;
    final bonus = _userBonuses[userId] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'User Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scheme Information
          if (_userSchemes.any((s) => s.userId == userId)) ...[
            _buildSchemeInfo(userId),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Total Amount',
                  '₹${totalAmount.toStringAsFixed(2)}',
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoItem(
                  'Paid Amount',
                  '₹${paidAmount.toStringAsFixed(2)}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Pending Amount',
                  '₹${pendingAmount.toStringAsFixed(2)}',
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoItem(
                  'Bonus Earned',
                  '₹${bonus.toStringAsFixed(2)}',
                  Icons.stars,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Overdue Amount Indicator
          if (_calculateOverdueAmount(userId) > 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overdue Amount',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹${_calculateOverdueAmount(userId).toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Next Due Date
          if (_calculateNextDueDate(userId) != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Due Date',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          Calculations.formatDate(_calculateNextDueDate(userId)!),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getUserSchemeName(String userId) {
    try {
      if (_userSchemes.isEmpty) {
        return 'Loading...';
      }
      
      
      final userScheme = _userSchemes.firstWhere(
        (s) => s.userId == userId,
        orElse: () => UserScheme(
          id: '',
          userId: '',
          schemeType: SchemeType(
            id: '',
            name: 'No scheme selected',
            description: '',
            interestRate: 0.0,
            amount: 0.0,
            duration: 0,
            frequency: Frequency.monthly,
          ),
          startDate: DateTime.now(),
          duration: 0,
          totalAmount: 0.0,
          interestRate: 0.0,
          currentBalance: 0.0,
          status: SchemeStatus.active,
        ),
      );
      return userScheme.schemeType.name;
    } catch (e) {
      return 'No scheme selected';
    }
  }

  Widget _buildSchemeInfo(String userId) {
    final theme = Theme.of(context);
    final userScheme = _userSchemes.firstWhere(
      (s) => s.userId == userId,
      orElse: () => UserScheme(
        id: '',
        userId: '',
        schemeType: SchemeType(
          id: '',
          name: 'No Scheme',
          description: '',
          interestRate: 0.0,
          amount: 0.0,
          duration: 0,
          frequency: Frequency.monthly,
        ),
        startDate: DateTime.now(),
        duration: 0,
        totalAmount: 0.0,
        interestRate: 0.0,
        currentBalance: 0.0,
        status: SchemeStatus.active,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.savings_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assigned Scheme',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userScheme.schemeType.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Weekly: ₹${(userScheme.totalAmount / 52).toStringAsFixed(0)} | Total: ₹${userScheme.totalAmount.toStringAsFixed(0)} | Duration: 52 weeks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Calculate bonus based on payment timing and user joining date
  Future<double> _calculateBonus(double amount, DateTime paymentDate) async {
    if (_selectedUser == null) return 0.0;
    
    try {
      // Get user's scheme from DataProvider
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final userSchemes = dataProvider.userSchemes;
      
      UserScheme? userScheme;
      try {
        userScheme = userSchemes.firstWhere(
          (scheme) => scheme.userId == _selectedUser!.id,
        );
      } catch (e) {
        userScheme = null;
      }
      
      if (userScheme == null) return 0.0;
      
      final joiningDate = userScheme.startDate;
      final daysSinceJoining = paymentDate.difference(joiningDate).inDays;
      
      
      // Calculate which week this payment is for
      final weekNumber = (daysSinceJoining / 7).floor();
      final weekStartDate = joiningDate.add(Duration(days: weekNumber * 7));
      final daysFromWeekStart = paymentDate.difference(weekStartDate).inDays;
      
      
      // Check if payment is within 7 days of current week start
      if (daysFromWeekStart <= 7) {
        // Payment is within 7 days of current week start - give 5% bonus
        // 100 Rs = 5 Rs bonus, 200 Rs = 10 Rs bonus, 300 Rs = 15 Rs bonus, etc.
        return amount * 0.05; // 5% of the payment amount
      } else {
        // Payment is overdue for current week - no bonus
        return 0.0;
      }
    } catch (e) {
      return 0.0;
    }
  }
}
