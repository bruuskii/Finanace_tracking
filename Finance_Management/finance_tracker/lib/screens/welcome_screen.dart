import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../main.dart';

class WelcomeScreen extends StatefulWidget {
  final bool isNewProfile;
  
  const WelcomeScreen({Key? key, this.isNewProfile = false}) : super(key: key);

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late bool _isNewProfile;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isNewProfile = widget.isNewProfile;
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      _showError('Please enter a name');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter a password');
      return;
    }

    final provider = Provider.of<AccountProvider>(context, listen: false);

    if (_isNewProfile) {
      if (_balanceController.text.isEmpty) {
        _showError('Please enter initial balance');
        return;
      }

      final balance = double.tryParse(_balanceController.text);
      if (balance == null) {
        _showError('Please enter a valid balance');
        return;
      }

      if (password != _confirmPasswordController.text) {
        _showError('Passwords do not match');
        return;
      }

      if (password.length < 6) {
        _showError('Password must be at least 6 characters');
        return;
      }

      // Check if account already exists
      final existingAccount = await provider.findAccountByName(name);
      if (existingAccount != null) {
        _showError('An account with this name already exists');
        return;
      }

      final account = await provider.createAccount(name, balance, password);
      await provider.setUserName(name);
      // Automatically select the newly created account
      await provider.selectAccount(account);
    } else {
      // Login flow
      final account = await provider.findAccountByName(name);
      if (account == null) {
        _showError('No account found with this name');
        return;
      }

      final isPasswordValid = await provider.verifyPassword(account, password);
      if (!isPasswordValid) {
        _showError('Invalid password');
        return;
      }

      await provider.selectAccount(account);
      await provider.setUserName(account.name);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigator()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    _isNewProfile ? 'Create New Profile' : 'Login',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF3A3A3C),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          CupertinoTextField(
                            controller: _nameController,
                            placeholder: 'Name',
                            padding: const EdgeInsets.all(16),
                            clearButtonMode: OverlayVisibilityMode.editing,
                            style: TextStyle(color: CupertinoColors.white),
                            placeholderStyle: TextStyle(color: Color(0xFF8E8E93)),
                            cursorColor: CupertinoColors.activeBlue,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              border: Border.all(color: Colors.transparent),
                            ),
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                          ),
                          Container(
                            height: 1,
                            color: const Color(0xFF3A3A3C),
                          ),
                          CupertinoTextField(
                            controller: _passwordController,
                            placeholder: 'Password',
                            padding: const EdgeInsets.all(16),
                            obscureText: _obscurePassword,
                            clearButtonMode: OverlayVisibilityMode.editing,
                            style: TextStyle(color: CupertinoColors.white),
                            placeholderStyle: TextStyle(color: Color(0xFF8E8E93)),
                            cursorColor: CupertinoColors.activeBlue,
                            suffix: CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Icon(
                                _obscurePassword
                                    ? CupertinoIcons.eye
                                    : CupertinoIcons.eye_slash,
                                color: CupertinoColors.inactiveGray,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              border: Border.all(color: Colors.transparent),
                            ),
                            textInputAction:
                                _isNewProfile ? TextInputAction.next : TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_isNewProfile) _handleSubmit();
                            },
                          ),
                          if (_isNewProfile) ...[
                            Container(
                              height: 1,
                              color: const Color(0xFF3A3A3C),
                            ),
                            CupertinoTextField(
                              controller: _confirmPasswordController,
                              placeholder: 'Confirm Password',
                              padding: const EdgeInsets.all(16),
                              obscureText: _obscureConfirmPassword,
                              clearButtonMode: OverlayVisibilityMode.editing,
                              style: TextStyle(color: CupertinoColors.white),
                              placeholderStyle: TextStyle(color: Color(0xFF8E8E93)),
                              cursorColor: CupertinoColors.activeBlue,
                              suffix: CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(
                                  _obscureConfirmPassword
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  color: CupertinoColors.inactiveGray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                border: Border.all(color: Colors.transparent),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            Container(
                              height: 1,
                              color: const Color(0xFF3A3A3C),
                            ),
                            CupertinoTextField(
                              controller: _balanceController,
                              placeholder: 'Initial Balance',
                              padding: const EdgeInsets.all(16),
                              clearButtonMode: OverlayVisibilityMode.editing,
                              style: TextStyle(color: CupertinoColors.white),
                              placeholderStyle: TextStyle(color: Color(0xFF8E8E93)),
                              cursorColor: CupertinoColors.activeBlue,
                              prefix: const Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: Text(
                                  '\$',
                                  style: TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                border: Border.all(color: Colors.transparent),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleSubmit(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton.filled(
                      onPressed: _handleSubmit,
                      borderRadius: BorderRadius.circular(25),
                      child: Text(
                        _isNewProfile ? 'Create Profile' : 'Login',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _isNewProfile = !_isNewProfile;
                        _nameController.clear();
                        _balanceController.clear();
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      });
                    },
                    child: Text(
                      _isNewProfile
                          ? 'Already have a profile? Login'
                          : 'Create new profile',
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemBlue.withOpacity(0.8),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}