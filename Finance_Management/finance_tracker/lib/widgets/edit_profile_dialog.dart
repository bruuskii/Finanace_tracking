import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class EditProfileDialog extends StatefulWidget {
  final String initialName;
  final double initialBalance;

  const EditProfileDialog({
    super.key,
    required this.initialName,
    required this.initialBalance,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  bool _changePassword = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _balanceController = TextEditingController(
      text: widget.initialBalance.toStringAsFixed(2),
    );
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF007AFF),
        barBackgroundColor: Color(0xFF1C1C1E),
        scaffoldBackgroundColor: Color(0xFF1C1C1E),
      ),
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        child: Material(
          color: Colors.transparent,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            title: const Text('Edit Profile'),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Profile Name',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _balanceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Balance',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        prefixText: '\$',
                        prefixStyle: TextStyle(color: Colors.white),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a balance';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Change Password',
                          style: TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        Switch(
                          value: _changePassword,
                          onChanged: (value) {
                            setState(() {
                              _changePassword = value;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_changePassword) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Current Password',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.visibility_off),
                        ),
                        obscureText: !_showCurrentPassword,
                        validator: (value) {
                          if (_changePassword && (value == null || value.isEmpty)) {
                            return 'Please enter current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.visibility_off),
                        ),
                        obscureText: !_showNewPassword,
                        validator: (value) {
                          if (_changePassword && (value == null || value.isEmpty)) {
                            return 'Please enter new password';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final provider = Provider.of<AccountProvider>(
                      context,
                      listen: false,
                    );

                    if (_changePassword) {
                      // Verify current password
                      final currentAccount = provider.selectedAccount;
                      if (currentAccount != null) {
                        final isPasswordCorrect = await provider.verifyPassword(
                          currentAccount,
                          _currentPasswordController.text,
                        );

                        if (!isPasswordCorrect) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Current password is incorrect'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                      }
                    }

                    await provider.updateProfile(
                      _nameController.text,
                      double.parse(_balanceController.text),
                      newPassword: _changePassword ? _newPasswordController.text : null,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(
                  'Save',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
