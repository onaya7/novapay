import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novapay/core/local_data/local_data_storage.dart';

class _MockBox extends Mock implements Box<dynamic>;

void main() {
  late _MockBox box;
  late LocalDataStorage storage;

  setUp(() {
    box = _MockBox();
    storage = LocalDataStorageImpl(box);
  });

  group('read', () {
    test('returns a value of the requested type', () {
      when(
        () =>
            box.get('theme', defaultValue: any<dynamic>(named: 'defaultValue')),
      ).thenReturn('dark');
      expect(storage.read<String>('theme'), 'dark');
    });

    test('falls back when the stored type does not match', () {
      // A box holds dynamic, so a caller can ask for the wrong type.
      when(
        () =>
            box.get('count', defaultValue: any<dynamic>(named: 'defaultValue')),
      ).thenReturn('not an int');
      expect(storage.read<int>('count', defaultValue: 7), 7);
    });

    test('falls back to null when absent and no default is given', () {
      when(
        () => box.get(
          'missing',
          defaultValue: any<dynamic>(named: 'defaultValue'),
        ),
      ).thenReturn(null);
      expect(storage.read<String>('missing'), isNull);
    });
  });

  test('write delegates to the box', () async {
    when(() => box.put('k', 'v')).thenAnswer((_) async {});
    await storage.write<String>('k', 'v');
    verify(() => box.put('k', 'v')).called(1);
  });

  test('delete delegates to the box', () async {
    when(() => box.delete('k')).thenAnswer((_) async {});
    await storage.delete('k');
    verify(() => box.delete('k')).called(1);
  });

  test('clear empties the box', () async {
    when(box.clear).thenAnswer((_) async => 3);
    await storage.clear();
    verify(box.clear).called(1);
  });
}
