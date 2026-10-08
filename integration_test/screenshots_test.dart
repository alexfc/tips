import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:meeting_notes/main.dart';
import 'package:meeting_notes/state/notes_provider.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('руководство: скриншоты', (tester) async {
    Intl.defaultLocale = 'ru';
    await initializeDateFormatting('ru');
    final provider = NotesProvider();
    await provider.init();
    await provider.switchStorage(StorageType.sqlite, copyExisting: false);
    await provider.deleteAll();

    await tester.pumpWidget(MeetingNotesApp(provider: provider));
    await tester.pumpAndSettle();
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    Future<void> hideSnackBars() async {
      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .removeCurrentSnackBar();
      await tester.pumpAndSettle();
    }

    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 50 && !condition(); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    String ok() => MaterialLocalizations.of(
            tester.element(find.byType(Dialog).last))
        .okButtonLabel;

    Future<void> back() async {
      await Navigator.of(tester.element(find.byType(Scaffold).last)).maybePop();
      await tester.pumpAndSettle();
    }

    Future<void> tapText(String text) async {
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    await tapText('Новая заметка');
    await tester.enterText(find.widgetWithText(TextFormField, 'Заголовок *'),
        'Совещание по проекту "Альфа"');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Содержание'),
      'Участники: Петров, Сидорова, Ким.\n'
      '1. Срок сдачи первого этапа - 20 октября.\n'
      '2. Сидорова готовит договор с подрядчиком.\n'
      '3. Следующее совещание - в понедельник.',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await shot('02_create');

    await tester.tap(find.text('Дата'));
    await tester.pumpAndSettle();
    await tapText(ok());

    await tester.tap(find.text('Время'));
    await tester.pumpAndSettle();
    await tapText(ok());

    await tester.tap(find.byTooltip('Сохранить'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await tapText('Добавить примеры заметок');
    await waitFor(() => provider.notes.length == 6);
    await back();
    await hideSnackBars();
    await shot('06_list');

    await tapText('Планёрка отдела продаж');
    await tapText('Редактировать');
    final content = find.widgetWithText(TextFormField, 'Содержание');
    final old = tester.widget<TextFormField>(content).controller!.text;
    await tester.enterText(content, '$old\nДОПОЛНЕНО: прайс-лист отправить до среды.');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Сохранить'));
    await tester.pumpAndSettle();
    await back();
    await hideSnackBars();

    await tester.drag(find.text('Встреча с поставщиком'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tapText('Удалить');
    await tapText('Отменить');
    await waitFor(() => provider.notes.length == 6);
    await hideSnackBars();

    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'договор');
    FocusManager.instance.primaryFocus?.unfocus();
    await shot('12_search');
    await tester.tap(find.byTooltip('Закрыть поиск'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Фильтры'));
    await tester.pumpAndSettle();
    await tapText('Совещание');
    await tapText('С -');
    await tapText(ok());
    await tapText('Применить');
    await tapText('Сбросить');

    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await shot('15_settings');
    await tapText('Файлы на устройстве');
    await tapText('Перенести');
    await waitFor(() => provider.storageType == StorageType.files);
    await tester.pumpAndSettle();
    await back();

    expect(provider.storageType, StorageType.files);
    expect(provider.notes.length, 6);
  });
}
