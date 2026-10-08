import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_notes/widgets/note_card.dart';

void main() {
  test('фрагмент вокруг найденного слова', () {
    const text = 'Участники: Петров, Сидорова, Ким.\n'
        '1. Срок сдачи первого этапа - 20 октября.\n'
        '2. Сидорова готовит договор с подрядчиком.';
    expect(excerpt(text, []), text);
    expect(excerpt(text, ['петров']), startsWith('Участники: Петров'));
    final e = excerpt(text, ['договор']);
    expect(e, startsWith('...'));
    expect(e, contains('договор с подрядчиком'));
    expect(e.indexOf('договор'), lessThanOrEqualTo(43));
  });
}
