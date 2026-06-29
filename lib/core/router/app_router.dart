import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/notes/presentation/notes_screen.dart';
import '../../features/learning/presentation/learning_screen.dart';
import '../../features/entertainment/presentation/entertainment_screen.dart';
import '../../features/entertainment/presentation/movies_screen.dart';
import '../../features/entertainment/presentation/series_screen.dart';
import '../../features/knowledge/presentation/knowledge_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      // Shell routes share the bottom NavigationBar
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/tasks',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TasksScreen()),
          ),
          GoRoute(
            path: '/notes',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotesScreen()),
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
