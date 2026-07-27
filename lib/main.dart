import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/database/app_database.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}\n${details.stack}');
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'App Startup Error',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    '${details.exception}\n\n${details.stack}',
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };

    final db = AppDatabase();
    runApp(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const CortexApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught Error in main: $error\n$stack');
  });
}

