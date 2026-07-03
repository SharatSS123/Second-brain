import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/planner_providers.dart';
import '../../../shared/widgets/main_scaffold.dart';
import 'tabs/today_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/upcoming_tab.dart';
import 'tabs/blocks_tab.dart';
import 'tabs/routines_tab.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tc;

  static const _titles = ['Today', 'Calendar', 'Upcoming', 'Blocks', 'Routines'];

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 5, vsync: this);
    _tc.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  int get _idx => _tc.index;
  bool get _showFab => _idx == 0 || _idx == 2;

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
          onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _titles[_idx],
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _tc.animateTo(1),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_idx == 0 ? 88 : 44),
          child: Column(
            children: [
              if (_idx == 0) _DateNav(selectedDate: selectedDate),
              _PlannerTabBar(controller: _tc),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: const [
          TodayTab(),
          CalendarTab(),
          UpcomingTab(),
          BlocksTab(),
          RoutinesTab(),
        ],
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () =>
                  showAddActivitySheet(context, ref),
              backgroundColor: AppColors.primary,
              elevation: 4,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }
}

class _DateNav extends ConsumerWidget {
  const _DateNav({required this.selectedDate});
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.textSecondary,
            onPressed: () {
              final d = ref.read(selectedDateProvider);
              ref.read(selectedDateProvider.notifier).state =
                  d.subtract(const Duration(days: 1));
            },
          ),
          GestureDetector(
            onTap: () {
              final now2 = DateTime.now();
              ref.read(selectedDateProvider.notifier).state =
                  DateTime(now2.year, now2.month, now2.day);
            },
            child: Row(
              children: [
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'TODAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                Text(
                  DateFormat('EEE, MMM d').format(selectedDate),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.textSecondary,
            onPressed: () {
              final d = ref.read(selectedDateProvider);
              ref.read(selectedDateProvider.notifier).state =
                  d.add(const Duration(days: 1));
            },
          ),
        ],
      ),
    );
  }
}

class _PlannerTabBar extends StatelessWidget {
  const _PlannerTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w400),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: const [
          Tab(text: 'Today', height: 34),
          Tab(text: 'Calendar', height: 34),
          Tab(text: 'Upcoming', height: 34),
          Tab(text: 'Blocks', height: 34),
          Tab(text: 'Routines', height: 34),
        ],
      ),
    );
  }
}
