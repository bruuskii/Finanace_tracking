import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../providers/account_provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/edit_profile_dialog.dart';
import '../l10n/app_localizations.dart';
import 'insights_screen.dart';
import 'wallet_screen.dart';
import 'all_transactions_screen.dart';
import 'welcome_screen.dart';
import '../models/transaction.dart';
import '../utils/number_formatter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) {
        // If there's no account, don't show anything and redirect
        if (provider.selectedAccount == null || provider.accounts.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => 
                  const WelcomeScreen(isNewProfile: false),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 200),
              ),
              (route) => false,
            );
          });
          // Return a transparent widget instead of empty
          return Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          );
        }

        return const HomeContent();
      },
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: CupertinoColors.black,
      body: SafeArea(
        child: Consumer<AccountProvider>(
          builder: (context, provider, _) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(l10n),
                    ),
                    SliverToBoxAdapter(
                      child: _buildBalanceCard(provider, l10n),
                    ),
                    SliverToBoxAdapter(
                      child: _buildQuickActions(l10n),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          l10n.recentTransactions,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: _buildTransactionsList(provider, l10n),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80), // Add space for the menu
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Consumer<AccountProvider>(
      builder: (context, provider, _) {
        // If there's no selected account, don't show the header
        if (provider.selectedAccount == null || provider.accounts.isEmpty) {
          return const SizedBox.shrink();
        }

        final name = provider.userName ?? l10n.defaultUsername;
        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: CupertinoColors.darkBackgroundGray.withOpacity(0.7),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6B8EEE),
                                Color(0xFF0A4BCA),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.welcomeBack,
                            style: TextStyle(
                              color: CupertinoColors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => CupertinoTheme(
                          data: const CupertinoThemeData(
                            brightness: Brightness.dark,
                            primaryColor: Color(0xFF007AFF),
                            barBackgroundColor: Color(0xFF1C1C1E),
                            scaffoldBackgroundColor: Color(0xFF1C1C1E),
                          ),
                          child: CupertinoActionSheet(
                            actions: [
                              CupertinoActionSheetAction(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final provider = Provider.of<AccountProvider>(context, listen: false);
                                  final currentName = provider.userName ?? '';
                                  final currentBalance = provider.totalBalance;
                                  await showDialog(
                                    context: context,
                                    builder: (context) => EditProfileDialog(
                                      initialName: currentName,
                                      initialBalance: currentBalance,
                                    ),
                                  );
                                },
                                child: Text(l10n.editProfile),
                              ),
                              CupertinoActionSheetAction(
                                isDestructiveAction: true,
                                onPressed: () async {
                                  // Store the root navigator context
                                  final rootContext = Navigator.of(context, rootNavigator: true).context;
                                  
                                  // Close the popup menu
                                  Navigator.pop(context);
                                  
                                  final shouldDelete = await showDialog<bool>(
                                    context: rootContext,
                                    barrierDismissible: false,
                                    builder: (dialogContext) => Theme(
                                      data: ThemeData.dark().copyWith(
                                        dialogBackgroundColor: const Color(0xFF1C1C1E),
                                        dialogTheme: DialogTheme(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                      child: AlertDialog(
                                        backgroundColor: const Color(0xFF1C1C1E),
                                        title: Text(
                                          l10n.deleteProfile,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        content: Text(
                                          l10n.deleteProfileConfirmation,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 15,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogContext, false),
                                            child: Text(
                                              l10n.cancel,
                                              style: const TextStyle(
                                                color: Color(0xFF007AFF),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogContext, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: Text(
                                              l10n.delete,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ) ?? false;

                                  if (shouldDelete) {
                                    // Show loading overlay
                                    showDialog(
                                      context: rootContext,
                                      barrierDismissible: false,
                                      builder: (_) => WillPopScope(
                                        onWillPop: () async => false,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    );

                                    // Check if there are other profiles before deletion
                                    final hasOtherProfiles = provider.accounts.length > 1;
                                    final currentAccountId = provider.selectedAccount?.id;

                                    if (!hasOtherProfiles) {
                                      // If this is the last profile, navigate first
                                      Navigator.of(rootContext, rootNavigator: true).pushAndRemoveUntil(
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) => const WelcomeScreen(isNewProfile: false),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                          transitionDuration: const Duration(milliseconds: 200),
                                        ),
                                        (route) => false,
                                      );
                                      
                                      // Then delete the profile and clear state
                                      await provider.deleteProfile();
                                    } else {
                                      // Has other profiles, delete first then refresh home screen
                                      await provider.deleteProfile();
                                      
                                      if (rootContext.mounted) {
                                        // Find the first account that's not the deleted one
                                        final nextAccount = provider.accounts.firstWhere(
                                          (account) => account.id != currentAccountId,
                                        );
                                        await provider.selectAccount(nextAccount);
                                        
                                        Navigator.pop(rootContext);
                                      }
                                    }
                                  }
                                },
                                child: Text(l10n.deleteProfile),
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l10n.cancel),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Icon(
                      CupertinoIcons.settings,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(AccountProvider provider, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              CupertinoColors.activeBlue,
              CupertinoColors.systemIndigo,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalBalance,
                    style: TextStyle(
                      color: CupertinoColors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<CurrencyProvider>(
                    builder: (context, currencyProvider, _) {
                      final symbol = currencyProvider.currencySymbol;
                      final formattedBalance = NumberFormatter.formatCurrency(provider.totalBalance, context);
                      return Text(
                        formattedBalance,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: CupertinoColors.darkBackgroundGray.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionButton(
              icon: CupertinoIcons.plus_circle,
              label: l10n.addIncome,
              color: const Color(0xFF34C759), // iOS green color
              onTap: () => _showTransactionDialog('deposit'),
            ),
            _buildQuickActionButton(
              icon: CupertinoIcons.minus_circle,
              label: l10n.addExpense,
              color: const Color(0xFFFF3B30), // iOS red color
              onTap: () => _showTransactionDialog('payment'),
            ),
            _buildQuickActionButton(
              icon: CupertinoIcons.list_bullet,
              label: l10n.viewAll,
              color: const Color(0xFF007AFF), // iOS blue color
              onTap: () => Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const AllTransactionsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(AccountProvider provider, AppLocalizations l10n) {
    final transactions = provider.transactions;
    
    if (transactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Text(
            l10n.noRecentTransactions,
            style: TextStyle(
              color: CupertinoColors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Show only the 5 most recent transactions
    final recentTransactions = transactions.take(5).toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = recentTransactions[index];
          final isExpense = transaction.type == 'payment';
          final color = isExpense ? const Color(0xFFFF453A) : const Color(0xFF30D158);
          final sign = isExpense ? '-' : '+';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Dismissible(
              key: Key(transaction.id?.toString() ?? UniqueKey().toString()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showCupertinoDialog<bool>(
                  context: context,
                  builder: (BuildContext context) => CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.dark,
                      primaryColor: Color(0xFF007AFF),
                      barBackgroundColor: Color(0xFF1C1C1E),
                      scaffoldBackgroundColor: Color(0xFF1C1C1E),
                    ),
                    child: CupertinoAlertDialog(
                      title: Text(l10n.deleteTransaction),
                      content: Text(l10n.deleteTransactionConfirmation),
                      actions: <CupertinoDialogAction>[
                        CupertinoDialogAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  ),
                ) ?? false;
              },
              onDismissed: (direction) {
                provider.deleteTransaction(transaction.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.transactionDeleted),
                    action: SnackBarAction(
                      label: l10n.undo,
                      onPressed: () {
                        provider.addTransaction(
                          transaction.title,
                          transaction.description,
                          transaction.amount,
                          transaction.type,
                        );
                      },
                    ),
                  ),
                );
              },
              background: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.white,
                ),
              ),
              child: Row(
                children: [
                  // Transaction Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isExpense ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_left,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.title,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (transaction.description?.isNotEmpty ?? false)
                          Text(
                            transaction.description!,
                            style: TextStyle(
                              color: const Color(0xFFFFFFFF).withOpacity(0.6),
                              fontSize: 15,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd').format(transaction.date),
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Amount
                  Consumer<CurrencyProvider>(
                    builder: (context, currencyProvider, _) {
                      final symbol = currencyProvider.currencySymbol;
                      final formattedAmount = NumberFormatter.formatCurrency(transaction.amount, context);
                      return Text(
                        sign + formattedAmount,
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
        childCount: recentTransactions.length,
      ),
    );
  }

  void _showTransactionDialog(String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddTransactionForm(type: type),
      ),
    );
  }
}

class _AddTransactionForm extends StatefulWidget {
  final String type;

  const _AddTransactionForm({required this.type});

  @override
  _AddTransactionFormState createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    widget.type == 'deposit' ? l10n.addIncome : l10n.addExpense,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      // Get trimmed values
                      final titleText = _titleController.text.trim();
                      final amountText = _amountController.text.trim();
                      
                      // Validate title first
                      if (titleText.isEmpty) {
                        
                        return;
                      }

                      // Then validate amount
                      if (amountText.isEmpty) {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Error'),
                            content: const Text('Please enter an amount'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      
                      // Finally validate amount format
                      final amount = double.tryParse(amountText);
                      if (amount == null) {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Error'),
                            content: const Text('Please enter a valid amount'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      final provider = Provider.of<AccountProvider>(
                        context,
                        listen: false,
                      );
                      
                      await provider.addTransaction(
                        titleText,
                        _descriptionController.text.trim(),
                        amount,
                        widget.type,
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Add',
                      style: TextStyle(
                        color: _titleController.text.isNotEmpty && 
                               _amountController.text.isNotEmpty ? 
                               const Color(0xFF007AFF) : 
                               const Color(0xFF007AFF).withOpacity(0.5),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF3A3A3C), height: 1),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  CupertinoTextField.borderless(
                    controller: _titleController,
                    padding: const EdgeInsets.all(16),
                    placeholder: l10n.title,
                    placeholderStyle: const TextStyle(
                      color: Color(0xFF636366),
                      fontSize: 17,
                    ),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF3A3A3C), width: 0.5),
                      ),
                    ),

                  ),
                  CupertinoTextField.borderless(
                    controller: _descriptionController,
                    padding: const EdgeInsets.all(16),
                    placeholder: l10n.descriptionOptional,
                    placeholderStyle: const TextStyle(
                      color: Color(0xFF636366),
                      fontSize: 17,
                    ),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF3A3A3C), width: 0.5),
                      ),
                    ),
                  ),
                  CupertinoTextField.borderless(
                    controller: _amountController,
                    padding: const EdgeInsets.all(16),
                    placeholder: l10n.amount,
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        Provider.of<CurrencyProvider>(context).currencySymbol,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 17,
                        ),
                      ),
                    ),
                    placeholderStyle: const TextStyle(
                      color: Color(0xFF636366),
                      fontSize: 17,
                    ),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.left,

                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
