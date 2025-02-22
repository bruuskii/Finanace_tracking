import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'welcome_screen.dart';
import 'package:intl/intl.dart';
import 'package:finance_tracker/models/account.dart';
import '../utils/number_formatter.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _showProfileSwitchDialog(BuildContext context, AccountProvider provider) {
    final l10n = AppLocalizations.of(context);
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFF0A84FF),
          scaffoldBackgroundColor: Color(0xFF1C1C1E),
          barBackgroundColor: Color(0xFF2C2C2E),
        ),
        child: FutureBuilder<List<Account>>(
          future: provider.getAllAccounts().then((accounts) => accounts.cast<Account>()),
          builder: (context, AsyncSnapshot<List<Account>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: const Color(0xFF1C1C1E),
                height: 200,
                child: const Center(
                  child: CupertinoActivityIndicator(
                    color: Colors.white,
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return CupertinoActionSheet(
                title: Text(
                  l10n.switchProfile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                message: Text(
                  'No other profiles available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                cancelButton: CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      color: Color(0xFF0A84FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            final accounts = snapshot.data!;
            return CupertinoActionSheet(
              title: Text(
                l10n.switchProfile,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              message: Text(
                'Choose a profile to switch to',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              actions: accounts.map((Account account) {
                final bool isCurrentAccount = account.id == provider.selectedAccount?.id;
                return CupertinoActionSheetAction(
                  onPressed: isCurrentAccount
                      ? () {}  // Empty function for current account
                      : () async {
                          await provider.selectAccount(account);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: Text(
                    '${account.name} - ${NumberFormatter.formatCurrency(account.balance, context)}',
                    style: TextStyle(
                      color: isCurrentAccount
                          ? const Color(0xFF0A84FF).withOpacity(0.5)
                          : const Color(0xFF0A84FF),
                      fontSize: 20,
                    ),
                  ),
                );
              }).toList(),
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(
                    color: Color(0xFF0A84FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AccountProvider provider) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) => CupertinoTheme(
        data: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFF0A84FF),
          scaffoldBackgroundColor: Color(0xFF1C1C1E),
          barBackgroundColor: Color(0xFF2C2C2E),
        ),
        child: CupertinoAlertDialog(
          title: Text(
            l10n.logout,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.areYouSureYouWantToLogOut,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: Color(0xFF0A84FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
            CupertinoDialogAction(
              onPressed: () async {
                await provider.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    CupertinoPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              isDestructiveAction: true,
              child: Text(
                l10n.logout,
                style: const TextStyle(
                  color: Color(0xFFFF453A),
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Consumer<AccountProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: const Text(
                    'More',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6B8EEE), Color(0xFF0A4BCA)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.userName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.totalBalance,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Consumer<CurrencyProvider>(
                          builder: (context, currencyProvider, _) => Text(
                            NumberFormatter.formatCurrency(provider.totalBalance, context),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      CupertinoListTile(
                        leading: const Icon(
                          CupertinoIcons.person_crop_circle,
                          color: Color(0xFF0A84FF),
                          size: 28,
                        ),
                        title: Text(
                          l10n.switchProfile,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: const Icon(
                          CupertinoIcons.chevron_right,
                          color: Color(0xFF98989F),
                        ),
                        onTap: () => _showProfileSwitchDialog(context, provider),
                      ),
                      Divider(
                        indent: 16,
                        endIndent: 16,
                        height: 1,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      CupertinoListTile(
                        leading: const Icon(
                          CupertinoIcons.globe,
                          color: Color(0xFF0A84FF),
                          size: 28,
                        ),
                        title: Text(
                          l10n.language,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Consumer<LanguageProvider>(
                          builder: (context, languageProvider, _) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                languageProvider.currentLocale.languageCode == 'en' ? 'English' : 'Français',
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                CupertinoIcons.chevron_right,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
                          showCupertinoModalPopup(
                            context: context,
                            builder: (BuildContext context) => CupertinoTheme(
                              data: const CupertinoThemeData(
                                brightness: Brightness.dark,
                                primaryColor: Color(0xFF0A84FF),
                                scaffoldBackgroundColor: Color(0xFF1C1C1E),
                                barBackgroundColor: Color(0xFF2C2C2E),
                              ),
                              child: CupertinoActionSheet(
                                title: Text(
                                  l10n.selectLanguage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                message: Text(
                                  'Choose your preferred language',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                actions: [
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      languageProvider.switchLanguage('en');
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'English',
                                      style: TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      languageProvider.switchLanguage('fr');
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Français',
                                      style: TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    l10n.cancel,
                                    style: const TextStyle(
                                      color: Color(0xFF0A84FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(
                        indent: 16,
                        endIndent: 16,
                        height: 1,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      CupertinoListTile(
                        leading: const Icon(
                          CupertinoIcons.money_dollar_circle,
                          color: Color(0xFF0A84FF),
                          size: 28,
                        ),
                        title: Text(
                          l10n.currency,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Consumer<CurrencyProvider>(
                          builder: (context, currencyProvider, _) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyProvider.currencySymbol,
                                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                CupertinoIcons.chevron_right,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
                          showCupertinoModalPopup(
                            context: context,
                            builder: (BuildContext context) => CupertinoTheme(
                              data: const CupertinoThemeData(
                                brightness: Brightness.dark,
                                primaryColor: Color(0xFF0A84FF),
                                scaffoldBackgroundColor: Color(0xFF1C1C1E),
                                barBackgroundColor: Color(0xFF2C2C2E),
                              ),
                              child: CupertinoActionSheet(
                                title: Text(
                                  l10n.selectCurrency,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                message: Text(
                                  'Choose your preferred currency',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                                actions: [
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      currencyProvider.switchCurrency('USD');
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'USD (\$)',
                                      style: TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  CupertinoActionSheetAction(
                                    onPressed: () {
                                      currencyProvider.switchCurrency('MAD');
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'MAD',
                                      style: TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ],
                                cancelButton: CupertinoActionSheetAction(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    l10n.cancel,
                                    style: const TextStyle(
                                      color: Color(0xFF0A84FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Divider(
                        indent: 16,
                        endIndent: 16,
                        height: 1,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      CupertinoListTile(
                        leading: const Icon(
                          CupertinoIcons.square_arrow_right,
                          color: Color(0xFFFF453A),
                          size: 28,
                        ),
                        title: Text(
                          l10n.logOut,
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => _showLogoutDialog(context, provider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
