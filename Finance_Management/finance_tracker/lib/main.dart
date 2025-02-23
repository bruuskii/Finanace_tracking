import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/more_screen.dart';
import 'screens/onboarding_screen.dart';

import 'providers/account_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/language_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }


  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AccountProvider()),
        ChangeNotifierProvider(create: (context) => CurrencyProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'Finance Tracker',
            locale: languageProvider.currentLocale,
            supportedLocales: const [Locale('en'), Locale('fr')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
              useMaterial3: true,
            ),
            home: FutureBuilder<Widget>(
              future: _getInitialScreen(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return snapshot.data ?? const WelcomeScreen(isNewProfile: false);
              },
            ),
          );
        },
      ),
    );
  }

  Future<Widget> _getInitialScreen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final provider = Provider.of<AccountProvider>(context, listen: false);

    if (!hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    // Try to load last session
    final hasSession = await provider.loadLastSession();
    if (hasSession) {
      return const MainNavigator();
    }

    return const WelcomeScreen(isNewProfile: true);
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

class SmoothScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const PageScrollPhysics(
      parent: ClampingScrollPhysics(),
    );
  }
}

class CustomBoundedScrollPhysics extends ScrollPhysics {
  final int itemCount;
  final PageController controller;

  const CustomBoundedScrollPhysics({
    ScrollPhysics? parent,
    required this.itemCount,
    required this.controller,
  }) : super(parent: parent);

  @override
  CustomBoundedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomBoundedScrollPhysics(
      parent: buildParent(ancestor),
      itemCount: itemCount,
      controller: controller,
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (position.pixels == position.minScrollExtent && value < position.pixels) {
      // Block scrolling past the left edge
      return value - position.pixels;
    }
    if (position.pixels == position.maxScrollExtent && value > position.pixels) {
      // Block scrolling past the right edge
      return value - position.pixels;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // Use parent simulation for smooth scrolling behavior
    return super.createBallisticSimulation(position, velocity);
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class CustomPageScrollPhysics extends ScrollPhysics {
  const CustomPageScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 50,  // Reduced mass for quicker response
        stiffness: 150,  // Increased stiffness for better control
        damping: 0.8,  // Reduced damping for smoother movement
      );

  @override
  double get maxFlingVelocity => 2.0;  // Allow faster fling

  @override
  double get minFlingVelocity => 0.3;  // Small threshold for fling

  @override
  double get dragStartDistanceMotionThreshold => 12.0;  // Reduced drag resistance
}

class KeepAlive extends StatefulWidget {
  final Widget child;

  const KeepAlive({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _KeepAliveState createState() => _KeepAliveState();
}

class _KeepAliveState extends State<KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _MainNavigatorState extends State<MainNavigator> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _selectedIndex = 0;
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final Curve _animationCurve = Curves.easeOut;
  final List<Widget> _screens = [
    const HomeScreen(),
    const InsightsScreen(),
    const WalletScreen(),
    const MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0,
      keepPage: true,
    );
    _initializeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final provider = Provider.of<AccountProvider>(context, listen: false);
    final hasSession = await provider.loadLastSession();

    if (!hasSession && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(isNewProfile: false),
        ),
      );
      return;
    }

    await provider.loadAccounts();
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: _animationDuration,
      curve: _animationCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            color: Colors.black,
          ),
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const PageScrollPhysics(),
            children: List.generate(_screens.length, (index) {
              return RepaintBoundary(
                child: KeepAlive(
                  child: _screens[index],
                ),
              );
            }),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
                        _buildNavItem(1, Icons.insights_rounded, Icons.insights_outlined),
                        _buildNavItem(2, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined),
                        _buildNavItem(3, Icons.more_horiz_rounded, Icons.more_horiz_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(20),
        splashColor: const Color(0xFF7B61FF).withOpacity(0.1),
        highlightColor: const Color(0xFF7B61FF).withOpacity(0.05),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF7B61FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? Colors.white : const Color(0xFF8E8E93),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
