import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/account_provider.dart';
import '../providers/currency_provider.dart';
import '../models/transaction.dart';
import '../l10n/app_localizations.dart';
import '../utils/number_formatter.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String _selectedPeriod = 'week';
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Consumer2<AccountProvider, CurrencyProvider>(
          builder: (context, provider, currencyProvider, _) {
            final transactions = _filterTransactionsByPeriod(provider.transactions);
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(l10n),
                  _buildPeriodSelector(l10n),
                  Expanded(
                    child: _buildSpendingAnalysis(transactions, currencyProvider, l10n),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        l10n.statistics,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPeriodChip(l10n.week, 'week'),
            _buildPeriodChip(l10n.month, 'month'),
            _buildPeriodChip(l10n.threeMonths, '3months'),
            _buildPeriodChip(l10n.year, 'year'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedPeriod = value;
          });
        },
        backgroundColor: const Color(0xFF1C1C1E),
        selectedColor: const Color(0xFF7B61FF).withOpacity(0.2),
        checkmarkColor: const Color(0xFF7B61FF),
        labelStyle: TextStyle(
          color: isSelected
              ? const Color(0xFF7B61FF)
              : Colors.white70,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSpendingAnalysis(List<Transaction> transactions, CurrencyProvider currencyProvider, AppLocalizations l10n) {
    final totalSpending = transactions
        .where((t) => t.type == 'payment')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalIncome = transactions
        .where((t) => t.type == 'deposit')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final total = totalSpending + totalIncome;
    final spendingPercentage = total > 0 ? (totalSpending / total * 100) : 0.0;
    final incomePercentage = total > 0 ? (totalIncome / total * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (total > 0) ...[
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 100,
                      sections: [
                        if (spendingPercentage > 0)
                          PieChartSectionData(
                            color: const Color(0xFFFF2D55),
                            value: spendingPercentage,
                            title: '${spendingPercentage.toStringAsFixed(0)}%',
                            radius: _touchedIndex == 0 ? 35 : 30,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            badgeWidget: _Badge(
                              l10n.spent,
                              color: const Color(0xFFFF2D55),
                            ),
                            badgePositionPercentageOffset: 1.5,
                            showTitle: false,
                          ),
                        if (incomePercentage > 0)
                          PieChartSectionData(
                            color: const Color(0xFF30D158),
                            value: incomePercentage,
                            title: '${incomePercentage.toStringAsFixed(0)}%',
                            radius: _touchedIndex == 1 ? 35 : 30,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            badgeWidget: _Badge(
                              l10n.income,
                              color: const Color(0xFF30D158),
                            ),
                            badgePositionPercentageOffset: 1.5,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  
                ],
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.spentThisPeriod(_selectedPeriod),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<CurrencyProvider>(
                        builder: (context, currencyProvider, _) => Text(
                          NumberFormatter.formatCurrency(totalSpending, context),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMMM').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildStatCard(
                l10n.totalIncome,
                totalIncome,
                Icons.arrow_downward_rounded,
                const Color(0xFF30D158),
                currencyProvider,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                l10n.totalSpending,
                -totalSpending,
                Icons.arrow_upward_rounded,
                const Color(0xFFFF2D55),
                currencyProvider,
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                l10n.savings,
                totalIncome - totalSpending,
                Icons.wallet_rounded,
                const Color(0xFF7B61FF),
                currencyProvider,
              ),
            ],
          ),
          const SizedBox(height: 80), // Add space for the menu
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    IconData icon,
    Color color,
    CurrencyProvider currencyProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMM dd').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Consumer<CurrencyProvider>(
            builder: (context, currencyProvider, _) => Text(
              value < 0 ? NumberFormatter.formatCurrency(value, context) : NumberFormatter.formatCurrency(value, context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: value < 0 ? const Color(0xFFFF2D55) : const Color(0xFF30D158),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Transaction> _filterTransactionsByPeriod(List<Transaction> transactions) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3months':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    return transactions.where((t) => t.date.isAfter(startDate)).toList();
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
