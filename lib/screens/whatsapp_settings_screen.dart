import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/whatsapp_service.dart';
import '../models/user.dart';
import '../widgets/common/card_widget.dart';
import '../widgets/common/button_widget.dart';

class WhatsAppSettingsScreen extends StatefulWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  State<WhatsAppSettingsScreen> createState() => _WhatsAppSettingsScreenState();
}

class _WhatsAppSettingsScreenState extends State<WhatsAppSettingsScreen> {
  final WhatsAppService _whatsappService = WhatsAppService.instance;
  
  bool _isWhatsAppInstalled = false;
  bool _isLoading = true;
  
  // Message templates
  final List<String> _messageTemplates = [
    'Payment Confirmation',
    'Payment Reminder',
    'Scheme Completion',
    'Overdue Payment Alert',
    'Weekly Reminder',
  ];
  
  String _selectedTemplate = 'Payment Confirmation';
  
  // Test message variables
  final Map<String, dynamic> _testVariables = {};

  @override
  void initState() {
    super.initState();
    _checkWhatsAppInstallation();
  }

  Future<void> _checkWhatsAppInstallation() async {
    try {
      final isInstalled = await _whatsappService.isWhatsAppInstalled();
      setState(() {
        _isWhatsAppInstalled = isInstalled;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('WhatsApp Settings'),
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // WhatsApp Status Card
                  CardWidget(
                    title: 'WhatsApp Status',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isWhatsAppInstalled
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _isWhatsAppInstalled
                                  ? Colors.green
                                  : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isWhatsAppInstalled
                                    ? 'WhatsApp is installed and ready'
                                    : 'WhatsApp is not installed',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: _isWhatsAppInstalled
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (!_isWhatsAppInstalled) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Please install WhatsApp to use messaging features.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Message Templates Card
                  CardWidget(
                    title: 'Message Templates',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a template to preview:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedTemplate,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _messageTemplates.map((template) {
                            return DropdownMenuItem<String>(
                              value: template,
                              child: Text(template),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedTemplate = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        ButtonWidget(
                          text: 'Preview Template',
                          onPressed: _previewTemplate,
                          icon: Icons.preview,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Test Message Card
                  CardWidget(
                    title: 'Test Message',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send a test message to verify WhatsApp integration:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Test Phone Number',
                            hintText: 'Enter phone number with country code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            _testVariables['phoneNumber'] = value;
                          },
                        ),
                        const SizedBox(height: 16),
                        ButtonWidget(
                          text: 'Send Test Message',
                          onPressed: _sendTestMessage,
                          icon: Icons.send,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Bulk Messaging Card
                  CardWidget(
                    title: 'Bulk Messaging',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send messages to multiple users:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ButtonWidget(
                          text: 'Send Payment Reminders',
                          onPressed: _sendBulkReminders,
                          icon: Icons.notifications_active,
                        ),
                        const SizedBox(height: 8),
                        ButtonWidget(
                          text: 'Send Weekly Reminders',
                          onPressed: _sendWeeklyReminders,
                          icon: Icons.schedule,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Help Card
                  CardWidget(
                    title: 'Help & Support',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHelpItem(
                          icon: Icons.info,
                          title: 'How it works',
                          description: 'WhatsApp messages are sent automatically after each payment entry.',
                        ),
                        const SizedBox(height: 12),
                        _buildHelpItem(
                          icon: Icons.security,
                          title: 'Privacy',
                          description: 'Messages are sent directly through WhatsApp. No data is stored on our servers.',
                        ),
                        const SizedBox(height: 12),
                        _buildHelpItem(
                          icon: Icons.phone_android,
                          title: 'Requirements',
                          description: 'WhatsApp must be installed on the device to send messages.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _previewTemplate() {
    if (!_isWhatsAppInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp is not installed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create a sample message for preview
    final sampleMessage = _getSampleMessage(_selectedTemplate);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preview: $_selectedTemplate'),
        content: SingleChildScrollView(
          child: Text(
            sampleMessage,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getSampleMessage(String template) {
    switch (template) {
      case 'Payment Confirmation':
        return '''🎉 *Payment Received Successfully!*

👤 *Customer Details:*
Name: John Doe
ID: 001

💰 *Payment Details:*
Amount: ₹500
Date: 15 Jan 2024
Mode: Cash/Offline
Receipt: RCP123456

📋 *Scheme Information:*
Scheme: Weekly Savings
Weekly Amount: ₹500
Total Amount: ₹26,000

📊 *Financial Summary:*
Pending Amount: ₹25,500
Total Bonus Earned: ₹250

📅 *Next Due Date:*
22 Jan 2024

Thank you for your payment! 🙏

_This is an automated message from Finance Tracker App_''';
      
      case 'Payment Reminder':
        return '''⏰ *Payment Reminder*

👤 *Customer Details:*
Name: John Doe
ID: 001

💰 *Payment Details:*
Weekly Amount: ₹500
⚠️ Overdue Amount: ₹1,000
📅 Overdue Weeks: 2 weeks

Total Due: ₹1,500
Next Due Date: 22 Jan 2024

Please make your payment at the earliest convenience.

Thank you! 🙏

_This is an automated reminder from Finance Tracker App_''';
      
      case 'Scheme Completion':
        return '''🎉 *Congratulations! Scheme Completed!*

👤 *Customer Details:*
Name: John Doe
ID: 001

📋 *Scheme Details:*
Scheme: Weekly Savings
Total Amount: ₹26,000
Interest Rate: 5%
Duration: 52 weeks

🎁 *Bonus Earned:*
Total Bonus: ₹1,300

Thank you for completing the scheme! 🙏

_This is an automated message from Finance Tracker App_''';
      
      default:
        return 'Template preview not available';
    }
  }

  void _sendTestMessage() {
    final phoneNumber = _testVariables['phoneNumber'] as String?;
    
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isWhatsAppInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp is not installed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Send test message
    _whatsappService.sendWhatsAppMessage(
      phoneNumber: phoneNumber,
      message: 'This is a test message from Finance Tracker App. WhatsApp integration is working correctly! 🎉',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test message sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendBulkReminders() {
    if (!_isWhatsAppInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp is not installed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // This would integrate with your data provider to get users
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bulk reminder feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _sendWeeklyReminders() {
    if (!_isWhatsAppInstalled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp is not installed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // This would integrate with your data provider to get users
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weekly reminder feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
