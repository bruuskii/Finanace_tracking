import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/currency_provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../utils/number_formatter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late PageController _cardController;

  @override
  void initState() {
    super.initState();
    _cardController = PageController(viewportFraction: 0.9);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _syncWithSelectedAccount();
      }
    });
  }

  void _syncWithSelectedAccount() {
    if (!mounted) return;
    final provider = Provider.of<AccountProvider>(context, listen: false);
    final selectedAccount = provider.selectedAccount;
    
    // Reset to selected account if no displayed account
    if (provider.displayedWalletAccount == null && selectedAccount != null) {
      provider.updateDisplayedWalletAccount(selectedAccount);
    }
    
    // Find the correct page index
    if (selectedAccount != null) {
      final index = provider.accounts.indexWhere((account) => account.id == selectedAccount.id);
      if (index != -1 && _cardController.hasClients) {
        _cardController.jumpToPage(index);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      final provider = Provider.of<AccountProvider>(context, listen: false);
      final selectedAccount = provider.selectedAccount;
      final displayedAccount = provider.displayedWalletAccount;
      
      // Ensure we have a valid displayed account
      if (selectedAccount != null && (displayedAccount == null || !provider.accounts.contains(displayedAccount))) {
        _syncWithSelectedAccount();
      }
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Consumer<AccountProvider>(
          builder: (context, provider, _) {
            final selectedAccount = provider.selectedAccount;
            final displayedAccount = provider.displayedWalletAccount ?? selectedAccount;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wallet',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      controller: _cardController,
                      itemCount: provider.accounts.length,
                      onPageChanged: (index) {
                        if (index >= 0 && index < provider.accounts.length) {
                          final account = provider.accounts[index];
                          provider.updateDisplayedWalletAccount(account);
                        } else {
                          // Reset to selected account if invalid index
                          provider.resetDisplayedWalletAccount();
                        }
                      },
                      itemBuilder: (context, index) {
                        final account = provider.accounts[index];
                        return GestureDetector(
                          onTap: () {
                            provider.updateDisplayedWalletAccount(account);
                          },
                          child: _buildWalletCard(context, account),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        provider.accounts.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: displayedAccount?.id == provider.accounts[index].id
                                ? const Color(0xFF7B61FF)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: displayedAccount == null
                        ? const Center(
                            child: Text(
                              'No transactions',
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        : FutureBuilder<List<Transaction>>(
                            future: provider.getTransactionsForAccount(displayedAccount),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No transactions for this account',
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                );
                              }

                              final transactions = snapshot.data!;
                              return Column(
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: transactions.length,
                                      itemBuilder: (context, index) {
                                        final transaction = transactions[index];
                                        final isExpense = transaction.type == 'payment';
                                        final color = isExpense ? const Color(0xFFFF453A) : const Color(0xFF30D158);
                                        final sign = isExpense ? '-' : '+';

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                          child: Row(
                                            children: [
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
                                              Consumer<CurrencyProvider>(
                                                builder: (context, currencyProvider, _) {
                                                  final symbol = currencyProvider.currencySymbol;
                                                  final amount = transaction.amount.toStringAsFixed(2);
                                                  final formattedAmount = symbol == '\$' ? '$sign$symbol$amount' : '$sign$amount DH';
                                                  return Text(
                                                    NumberFormatter.formatCurrency(transaction.amount, context),
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
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 80), // Add space for the menu
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, Account account) {
    final l10n = AppLocalizations.of(context);
    final provider = Provider.of<AccountProvider>(context, listen: false);
    final isCurrentAccount = provider.selectedAccount?.id == account.id;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCurrentAccount
                ? [Theme.of(context).primaryColor, Theme.of(context).primaryColorDark]
                : [Colors.grey[800]!, Colors.grey[600]!],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCurrentAccount ? l10n.active : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, _) => Text(
                  NumberFormatter.formatCurrency(account.balance, context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.balance,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
