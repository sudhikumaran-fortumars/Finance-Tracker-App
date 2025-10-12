import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/address.dart';
import '../models/scheme_type.dart';
import '../models/user_scheme.dart';
import '../services/storage_service.dart';
import '../services/indian_address_service.dart';
import '../widgets/common/card_widget.dart';
import '../widgets/common/button_widget.dart';
import '../utils/calculations.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final StorageService _storageService = StorageService.instance;
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _storageService.getUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.mobileNumber.contains(query) ||
              user.serialNumber.toLowerCase().contains(query.toLowerCase()) ||
              user.permanentAddress.city.toLowerCase().contains(
                query.toLowerCase(),
              );
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterUsers,
                    decoration: InputDecoration(
                      hintText:
                          'Search users by name, mobile, or city...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[700] : Colors.grey[50],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ButtonWidget(
                  text: 'Add User',
                  icon: Icons.person_add,
                  onPressed: () => _showAddUserDialog(),
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No users found'
                              : 'No users match your search',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Add your first user to get started',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserCard(context, user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CardWidget(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[100] : Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.mobileNumber,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${user.serialNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.status == UserStatus.active
                      ? Colors.green[100]
                      : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: user.status == UserStatus.active
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${user.permanentAddress.city}, ${user.permanentAddress.state}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Joined ${Calculations.formatDate(user.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.event_available,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                'Ends ${Calculations.formatDate(user.createdAt.add(const Duration(days: 364)))}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ButtonWidget(
                  text: 'View Details',
                  variant: ButtonVariant.outline,
                  size: ButtonSize.small,
                  onPressed: () => _showUserDetails(user),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ButtonWidget(
                  text: 'Edit',
                  variant: ButtonVariant.primary,
                  size: ButtonSize.small,
                  onPressed: () => _showEditUserDialog(user),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UserFormDialog(
        onSave: (user) async {
          await _storageService.saveUser(user);
          _loadUsers();
        },
      ),
    );
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => _UserFormDialog(
        user: user,
        onSave: (updatedUser) async {
          await _storageService.saveUser(updatedUser);
          _loadUsers();
        },
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(user: user),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final User? user;
  final Function(User) onSave;

  const _UserFormDialog({this.user, required this.onSave});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _doorNumberController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _localAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String? _nextCustomerNumber;
  SchemeType? _selectedScheme;
  bool _assignScheme = false;
  
  // Address automation variables
  String? _selectedState;
  String? _selectedDistrict;
  List<String> _availableStates = [];
  List<String> _availableDistricts = [];

  @override
  void initState() {
    super.initState();
    _loadStates();
    if (widget.user != null) {
      final user = widget.user!;
      _nameController.text = user.name;
      _mobileController.text = user.mobileNumber;
      _doorNumberController.text = user.permanentAddress.doorNumber;
      _streetController.text = user.permanentAddress.street;
      _areaController.text = user.permanentAddress.area;
      _localAddressController.text = user.permanentAddress.localAddress;
      _cityController.text = user.permanentAddress.city;
      _districtController.text = user.permanentAddress.district;
      _stateController.text = user.permanentAddress.state;
      _pinCodeController.text = user.permanentAddress.pinCode;
      
      // Set selected values for dropdowns
      _selectedState = user.permanentAddress.state;
      _selectedDistrict = user.permanentAddress.district;
      _cityController.text = user.permanentAddress.city;
    } else {
      // Load next customer number for new users
      _loadNextCustomerNumber();
    }
  }

  void _loadStates() {
    setState(() {
      _availableStates = IndianAddressService.getStates();
    });
  }

  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedDistrict = null;
      _availableDistricts = [];
    });
    
    if (state != null) {
      _availableDistricts = IndianAddressService.getDistricts(state);
      _stateController.text = state;
    }
  }

  void _onDistrictChanged(String? district) {
    setState(() {
      _selectedDistrict = district;
    });
    
    if (district != null) {
      _districtController.text = district;
    }
  }


  Future<void> _loadNextCustomerNumber() async {
    try {
      final storageService = StorageService.instance;
      final nextNumber = await storageService.generateNextSerialNumber();
      setState(() {
        _nextCustomerNumber = nextNumber;
      });
    } catch (e) {
      // Handle error silently - could show a snackbar or other UI feedback
      // For now, we'll just silently fail and the UI won't show the next number
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _doorNumberController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _localAddressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Text(widget.user == null ? 'Add New User' : 'Edit User'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Show next customer number for new users
              if (widget.user == null && _nextCustomerNumber != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue[900] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.blue[300] : Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next Customer Number: $_nextCustomerNumber',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.blue[200] : Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.user == null && _nextCustomerNumber != null)
                const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Basic Information
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _mobileController,
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number *',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Mobile number is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Address Information
                      _buildSectionHeader('Address Information'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _doorNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Door Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _streetController,
                              decoration: const InputDecoration(
                                labelText: 'Street',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _areaController,
                              decoration: const InputDecoration(
                                labelText: 'Area',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _localAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Local Address',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // State Selection
                      DropdownButtonFormField<String>(
                        initialValue: _selectedState,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableStates.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          );
                        }).toList(),
                        onChanged: _onStateChanged,
                      ),
                      const SizedBox(height: 16),
                      // District Selection
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableDistricts.map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district),
                          );
                        }).toList(),
                        onChanged: _onDistrictChanged,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: const InputDecoration(
                                labelText: 'City',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _areaController,
                              decoration: const InputDecoration(
                                labelText: 'Area',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // PIN Code Input
                      TextFormField(
                        controller: _pinCodeController,
                        decoration: const InputDecoration(
                          labelText: 'PIN Code',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Scheme Assignment Section
              _buildSectionHeader('Scheme Assignment (Optional)'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Assign Scheme to User'),
                value: _assignScheme,
                onChanged: (value) {
                  setState(() {
                    _assignScheme = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_assignScheme) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<SchemeType>(
                  initialValue: _selectedScheme,
                  decoration: const InputDecoration(
                    labelText: 'Select Scheme',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableSchemes.map((scheme) {
                    return DropdownMenuItem(
                      value: scheme,
                      child: Text(scheme.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedScheme = value;
                    });
                  },
                  validator: _assignScheme ? (value) => value == null ? 'Please select a scheme' : null : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Weekly Amount (₹)',
                    hintText: 'Enter weekly contribution amount',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      // Trigger rebuild to update total amount display
                    });
                  },
                  validator: _assignScheme ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Weekly amount is required';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  } : null,
                ),
                const SizedBox(height: 12),
                if (_assignScheme && _amountController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Amount (52 weeks)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '₹${_calculateTotalAmount()}',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ButtonWidget(
          text: widget.user == null ? 'Add User' : 'Update User',
          isLoading: _isLoading,
          onPressed: _saveUser,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[200] : Colors.grey[800],
      ),
    );
  }

  String _calculateTotalAmount() {
    final weeklyAmount = double.tryParse(_amountController.text);
    if (weeklyAmount == null || weeklyAmount <= 0) {
      return '0';
    }
    final totalAmount = weeklyAmount * 52;
    return totalAmount.toStringAsFixed(0);
  }

  late final List<SchemeType> _availableSchemes = [
    SchemeType(
      id: '1',
      name: 'Savings',
      description: 'Regular savings scheme',
      interestRate: 8.5,
      amount: 10000,
      duration: 365,
      frequency: Frequency.monthly,
    ),
    SchemeType(
      id: '2',
      name: 'Gold',
      description: 'Gold investment scheme',
      interestRate: 10.2,
      amount: 50000,
      duration: 365,
      frequency: Frequency.monthly,
    ),
    SchemeType(
      id: '3',
      name: 'Furniture',
      description: 'Furniture purchase scheme',
      interestRate: 12.0,
      amount: 100000,
      duration: 365,
      frequency: Frequency.monthly,
    ),
  ];

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final address = Address(
        doorNumber: _doorNumberController.text,
        street: _streetController.text,
        area: _areaController.text,
        localAddress: _localAddressController.text,
        city: _cityController.text,
        district: _districtController.text,
        state: _stateController.text,
        pinCode: _pinCodeController.text,
      );

      // Generate serial number for new users
      String serialNumber;
      if (widget.user == null) {
        // New user - generate serial number
        final storageService = StorageService.instance;
        serialNumber = await storageService.generateNextSerialNumber();
      } else {
        // Existing user - keep current serial number
        serialNumber = widget.user!.serialNumber;
      }

      final user = User(
        id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        mobileNumber: _mobileController.text,
        permanentAddress: address,
        serialNumber: serialNumber,
        selectedScheme: _assignScheme && _selectedScheme != null ? _selectedScheme!.name : null,
        status: UserStatus.active,
        createdAt: widget.user?.createdAt ?? DateTime.now(),
        schemes: widget.user?.schemes ?? [],
      );

      // Save user first
      await widget.onSave(user);

      // Assign scheme if selected
      if (_assignScheme && _selectedScheme != null) {
        final weeklyAmount = double.parse(_amountController.text);
        final totalAmount = weeklyAmount * 52; // Fixed 52 weeks for all schemes
        final durationDays = 52 * 7; // 52 weeks = 364 days

        final userScheme = UserScheme(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user.id,
          schemeType: _selectedScheme!,
          startDate: DateTime.now(),
          duration: durationDays,
          totalAmount: totalAmount,
          interestRate: _selectedScheme!.interestRate,
          currentBalance: 0.0,
          status: SchemeStatus.active,
        );

        final storageService = StorageService.instance;
        await storageService.saveUserScheme(userScheme);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _assignScheme && _selectedScheme != null
                  ? 'User created and assigned to ${_selectedScheme!.name} scheme'
                  : 'User created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _UserDetailsDialog extends StatelessWidget {
  final User user;

  const _UserDetailsDialog({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.blue[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[100] : Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.mobileNumber,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: user.status == UserStatus.active
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    user.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: user.status == UserStatus.active
                          ? Colors.green[800]
                          : Colors.red[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(context, 'Serial Number', user.serialNumber),
            _buildDetailRow(
              context,
              'Address',
              _formatAddress(user.permanentAddress),
            ),
            _buildDetailRow(
              context,
              'Joined Date',
              Calculations.formatDate(user.createdAt),
            ),
            _buildDetailRow(
              context,
              'End Date',
              Calculations.formatDate(user.createdAt.add(const Duration(days: 364))), // 52 weeks = 364 days
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[100] : Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Address address) {
    return '${address.doorNumber}, ${address.street}, ${address.area}, ${address.city}, ${address.state} - ${address.pinCode}';
  }
}
