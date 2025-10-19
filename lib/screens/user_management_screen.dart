import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/address.dart';
import '../models/scheme_type.dart';
import '../models/user_scheme.dart';
import '../models/transaction.dart';
import '../providers/firebase_data_provider.dart';
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
  // Using context.read<FirebaseDataProvider>() in methods instead of instance variable
  final TextEditingController _searchController = TextEditingController();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final dataProvider = context.read<FirebaseDataProvider>();
      // Don't call initializeData here as it causes setState during build
      setState(() {
        _users = dataProvider.users;
        _filteredUsers = dataProvider.users;
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
                'Ends ${Calculations.formatDate(user.createdAt.add(const Duration(days: 364)))} (52 weeks)',
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
          final dataProvider = context.read<FirebaseDataProvider>();
          await dataProvider.addUser(user);
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
          final dataProvider = context.read<FirebaseDataProvider>();
          await dataProvider.updateUser(updatedUser);
          _loadUsers();
        },
        onDelete: (userToDelete) async {
          final dataProvider = context.read<FirebaseDataProvider>();
          await dataProvider.deleteUser(userToDelete.id);
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
  final Function(User)? onDelete;

  const _UserFormDialog({this.user, required this.onSave, this.onDelete});

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
  DateTime? _selectedDate;
  
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
      _selectedDate = user.createdAt;
    } else {
      // Load next customer number for new users
      _loadNextCustomerNumber();
      _selectedDate = DateTime.now();
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
      final dataProvider = context.read<FirebaseDataProvider>();
      final nextNumber = await dataProvider.generateNextSerialNumber();
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

                      // Date Selection
                      _buildSectionHeader('User Creation Date'),
                      const SizedBox(height: 16),
                      _buildDatePicker(context),
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
                        value: _availableStates.contains(_selectedState) ? _selectedState : null,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableStates.isEmpty ? [] : _availableStates.map((state) {
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
                        value: _availableDistricts.contains(_selectedDistrict) ? _selectedDistrict : null,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableDistricts.isEmpty ? [] : _availableDistricts.map((district) {
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
                  value: _selectedScheme != null && _availableSchemes.any((s) => s.id == _selectedScheme!.id) ? _selectedScheme : null,
                  decoration: const InputDecoration(
                    labelText: 'Select Scheme',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableSchemes.isEmpty ? [] : _availableSchemes.map((scheme) {
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
                    hintText: 'Enter weekly contribution amount (52 weeks total)',
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
                                'Total Amount (52 weeks duration)',
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
        if (widget.user != null && widget.onDelete != null) ...[
          TextButton(
            onPressed: _isLoading ? null : _deleteUser,
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
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

  Widget _buildDatePicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creation Date',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDate != null
                      ? Calculations.formatDate(_selectedDate!)
                      : 'Select a date',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey[100] : Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: theme.colorScheme.primary,
                        onPrimary: Colors.white,
                        surface: isDark ? Colors.grey[800]! : Colors.white,
                        onSurface: isDark ? Colors.grey[100]! : Colors.grey[900]!,
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
            child: Text(
              'Choose Date',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
        final dataProvider = context.read<FirebaseDataProvider>();
        serialNumber = await dataProvider.generateNextSerialNumber();
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
        createdAt: _selectedDate ?? DateTime.now(),
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

        final dataProvider = context.read<FirebaseDataProvider>();
        await dataProvider.addUserScheme(userScheme);
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

  Future<void> _deleteUser() async {
    if (widget.user == null || widget.onDelete == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${widget.user!.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await widget.onDelete!(widget.user!);
        
        if (mounted) {
          Navigator.of(context).pop(); // Close the edit dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.user!.name} has been deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}

class _UserDetailsDialog extends StatefulWidget {
  final User user;

  const _UserDetailsDialog({required this.user});

  @override
  State<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<_UserDetailsDialog> {
  // Using context.read<FirebaseDataProvider>() in methods instead of instance variable
  List<UserScheme> _userSchemes = [];
  List<Transaction> _userTransactions = [];
  bool _isLoading = true;

  /// Calculate remaining weeks for a user
  int _calculateRemainingWeeks() {
    try {
      if (_userSchemes.isEmpty) return 52;
      
      final userScheme = _userSchemes.first;
      final totalPaid = _userTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final weeklyAmount = userScheme.totalAmount / 52;
      final paidWeeks = (totalPaid / weeklyAmount).floor();
      final remainingWeeks = 52 - paidWeeks;
      
      return remainingWeeks > 0 ? remainingWeeks : 0;
    } catch (e) {
      return 52;
    }
  }

  /// Refresh user data to get latest transactions
  Future<void> _refreshUserData() async {
    setState(() => _isLoading = true);
    try {
      final dataProvider = context.read<FirebaseDataProvider>();
      final schemes = await dataProvider.getUserSchemes();
      final transactions = await dataProvider.getTransactions();
      
      setState(() {
        _userSchemes = schemes.where((scheme) => scheme.userId == widget.user.id).toList();
        _userTransactions = transactions.where((transaction) => transaction.userId == widget.user.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final dataProvider = context.read<FirebaseDataProvider>();
      final schemes = await dataProvider.getUserSchemes();
      final transactions = await dataProvider.getTransactions();
      
      setState(() {
        _userSchemes = schemes.where((scheme) => scheme.userId == widget.user.id).toList();
        _userTransactions = transactions.where((transaction) => transaction.userId == widget.user.id).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                      widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : 'U',
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
                        widget.user.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[100] : Colors.grey[900],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.user.mobileNumber,
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
                    color: widget.user.status == UserStatus.active
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.user.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: widget.user.status == UserStatus.active
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

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information
                          _buildSectionHeader(context, 'Basic Information'),
                          const SizedBox(height: 16),
                          _buildDetailRow(context, 'Serial Number', widget.user.serialNumber),
                          _buildDetailRow(
                            context,
                            'Address',
                            _formatAddress(widget.user.permanentAddress),
                          ),
                          _buildDetailRow(
                            context,
                            'Joined Date',
                            Calculations.formatDate(widget.user.createdAt),
                          ),
          _buildDetailRow(
            context,
            'End Date',
            '${Calculations.formatDate(widget.user.createdAt.add(const Duration(days: 364)))} (52 weeks)',
          ),
          _buildDetailRow(
            context,
            'Remaining Weeks',
            '${_calculateRemainingWeeks()} weeks',
          ),
                          const SizedBox(height: 24),

                          // Financial Information
                          _buildSectionHeader(context, 'Financial Information'),
                          const SizedBox(height: 16),
                          _buildFinancialCards(context),
                          const SizedBox(height: 24),

                          // Scheme Information
                          if (_userSchemes.isNotEmpty) ...[
                            _buildSectionHeader(context, 'Scheme Details'),
                            const SizedBox(height: 16),
                            ..._userSchemes.map((scheme) => _buildSchemeCard(context, scheme)),
                            const SizedBox(height: 24),
                          ],

                          // Transaction History
                          _buildSectionHeader(context, 'Recent Transactions'),
                          const SizedBox(height: 16),
                          _buildTransactionHistory(context),
                        ],
                      ),
                    ),
            ),

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _refreshUserData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.grey[200] : Colors.grey[800],
      ),
    );
  }

  Widget _buildFinancialCards(BuildContext context) {

    // Calculate financial data
    final totalPaid = _userTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final totalBonus = _userTransactions.fold(0.0, (sum, t) => sum + t.interest); // Using interest as bonus
    final totalSchemeAmount = _userSchemes.fold(0.0, (sum, s) => sum + s.totalAmount);
    final pendingAmount = totalSchemeAmount - totalPaid;
    final weeklyAmount = _userSchemes.isNotEmpty ? _userSchemes.first.totalAmount / 52 : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                context,
                'Total Scheme Amount',
                Calculations.formatCurrency(totalSchemeAmount),
                Icons.account_balance_wallet,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialCard(
                context,
                'Amount Paid',
                Calculations.formatCurrency(totalPaid),
                Icons.payment,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                context,
                'Pending Amount',
                Calculations.formatCurrency(pendingAmount),
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialCard(
                context,
                'Total Bonus',
                Calculations.formatCurrency(totalBonus),
                Icons.stars,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                context,
                'Weekly Amount',
                Calculations.formatCurrency(weeklyAmount),
                Icons.calendar_today,
                Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinancialCard(
                context,
                'Remaining Weeks',
                '${_calculateRemainingWeeks()} weeks',
                Icons.schedule,
                Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(BuildContext context, UserScheme scheme) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.savings,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                scheme.schemeType.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[100] : Colors.grey[900],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.status == SchemeStatus.active
                      ? Colors.green[100]
                      : scheme.status == SchemeStatus.completed
                          ? Colors.blue[100]
                          : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  scheme.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: scheme.status == SchemeStatus.active
                        ? Colors.green[800]
                        : scheme.status == SchemeStatus.completed
                            ? Colors.blue[800]
                            : Colors.orange[800],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(context, 'Total Amount', Calculations.formatCurrency(scheme.totalAmount)),
          _buildDetailRow(context, 'Interest Rate', '${scheme.interestRate}%'),
          _buildDetailRow(context, 'Start Date', Calculations.formatDate(scheme.startDate)),
          _buildDetailRow(context, 'Duration', '${(scheme.duration / 7).round()} weeks'),
          _buildDetailRow(context, 'Remaining Weeks', '${_calculateRemainingWeeks()} weeks'),
          _buildDetailRow(context, 'Current Balance', Calculations.formatCurrency(scheme.currentBalance)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_userTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _userTransactions.take(5).map((transaction) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getPaymentModeColor(transaction.paymentMode).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getPaymentModeIcon(transaction.paymentMode),
                  color: _getPaymentModeColor(transaction.paymentMode),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Calculations.formatDate(transaction.date),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[100] : Colors.grey[900],
                      ),
                    ),
                    Text(
                      _getPaymentModeShortName(transaction.paymentMode),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
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
                      color: Colors.green,
                    ),
                  ),
                  if (transaction.interest > 0)
                    Text(
                      '+${Calculations.formatCurrency(transaction.interest)} bonus',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
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

  String _getPaymentModeShortName(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.offline:
        return 'OFFLINE';
      case PaymentMode.card:
        return 'CARD';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.netbanking:
        return 'NET';
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
