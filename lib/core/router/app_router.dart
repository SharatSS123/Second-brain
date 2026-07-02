import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/day/presentation/day_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/learning/presentation/learning_screen.dart';
import '../../features/entertainment/presentation/entertainment_screen.dart';
import '../../features/entertainment/presentation/movies_screen.dart';
import '../../features/entertainment/presentation/series_screen.dart';
import '../../features/books/presentation/books_screen.dart';
import '../../features/knowledge/presentation/knowledge_screen.dart';
import '../../features/templates/presentation/templates_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // Primary 3-tab routes
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/day',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DayScreen()),
          ),
          GoRoute(
            path: '/notes',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotesScreen()),
          ),
          // Drawer-accessible routes (bottom nav stays visible)
          GoRoute(
            path: '/planner',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PlannerScreen()),
          ),
          GoRoute(
            path: '/templates',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TemplatesScreen()),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TasksScreen()),
          ),
          GoRoute(
            path: '/learning',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LearningScreen()),
          ),
          GoRoute(
            path: '/entertainment',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EntertainmentScreen()),
          ),
          GoRoute(
            path: '/knowledge',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: KnowledgeScreen()),
          ),
          GoRoute(
            path: '/books',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BooksScreen()),
          ),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/entertainment/movies',
        builder: (context, state) => const MoviesScreen(),
      ),
      GoRoute(
        path: '/entertainment/series',
        builder: (context, state) => const SeriesScreen(),
      ),
    ],
  );
});
