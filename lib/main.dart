import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'screens/notes_list_screen.dart';
import 'state/notes_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ru';
  await initializeDateFormatting('ru');
  final provider = NotesProvider();
  await provider.init();
  runApp(MeetingNotesApp(provider: provider));
}

class MeetingNotesApp extends StatelessWidget {
  const MeetingNotesApp({super.key, required this.provider});

  final NotesProvider provider;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2E5AAC);
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        title: 'Заметки для совещаний',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: seed),
          inputDecorationTheme:
              const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        darkTheme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
          inputDecorationTheme:
              const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const NotesListScreen(),
      ),
    );
  }
}
