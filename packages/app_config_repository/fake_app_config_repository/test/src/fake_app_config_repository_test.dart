// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

// ignore_for_file: prefer_const_constructors
import 'package:fake_app_config_repository/fake_app_config_repository.dart';
import 'package:test/test.dart';

void main() {
  group(
    'FakeAppConfigRepository',
    timeout: Timeout(Duration(seconds: 5)),
    () {
      test('can be instantiated', () {
        expect(FakeAppConfigRepository(), isNotNull);
      });

      group('changeIsForceUpgradeRequired', () {
        test('changes isForceUpgradeRequired', () async {
          final repository = FakeAppConfigRepository();
          addTearDown(repository.close);
          final stream = repository.isForceUpgradeRequired();

          var forceUpgrade =
              ForceUpgrade(isUpgradeRequired: true, upgradeUrl: '');
          expect(stream, emits(forceUpgrade));
          repository.changeIsForceUpgradeRequired(forceUpgrade: forceUpgrade);

          forceUpgrade = ForceUpgrade(isUpgradeRequired: false);
          expect(stream, emits(forceUpgrade));
          repository.changeIsForceUpgradeRequired(forceUpgrade: forceUpgrade);
        });

        test('does not change when status is the same', () {
          final repository = FakeAppConfigRepository();
          final stream = repository.isForceUpgradeRequired();

          final forceUpgrade =
              ForceUpgrade(isUpgradeRequired: true, upgradeUrl: '');
          expect(stream, emits(forceUpgrade));
          repository.changeIsForceUpgradeRequired(forceUpgrade: forceUpgrade);

          expect(stream, neverEmits(forceUpgrade));
          repository
            ..changeIsForceUpgradeRequired(forceUpgrade: forceUpgrade)
            ..close();
        });

        test('throws $AssertionError when previously closed', () {
          final repository = FakeAppConfigRepository()..close();

          const assertionMessage =
              '''Cannot change isForceUpgradeRequired after the stream has been closed.''';
          expect(
            () => repository.changeIsForceUpgradeRequired(
              forceUpgrade: ForceUpgrade(isUpgradeRequired: true),
            ),
            throwsA(
              isA<AssertionError>()
                  .having((e) => e.message, 'message', assertionMessage),
            ),
          );
        });
      });

      group('isForceUpgradeRequired', () {
        test('returns as expected', () {
          final repository = FakeAppConfigRepository();
          addTearDown(repository.close);
          expect(repository.isForceUpgradeRequired, returnsNormally);
        });

        test('throws $AssertionError when previously closed', () {
          final repository = FakeAppConfigRepository()..close();

          const assertionMessage =
              '''Cannot access isForceUpgradeRequired after the stream has been closed.''';
          expect(
            repository.isForceUpgradeRequired,
            throwsA(
              isA<AssertionError>()
                  .having((e) => e.message, 'message', assertionMessage),
            ),
          );
        });
      });

      group('changeIsDownForMaintenance', () {
        test('changes isDownForMaintenance', () async {
          final repository = FakeAppConfigRepository();
          addTearDown(repository.close);
          final stream = repository.isDownForMaintenance();

          var isDownForMaintenance = true;
          expect(stream, emits(isDownForMaintenance));
          repository.changeIsDownForMaintenance(
            isDownForMaintenance: isDownForMaintenance,
          );

          isDownForMaintenance = false;
          expect(stream, emits(isDownForMaintenance));
          repository.changeIsDownForMaintenance(
            isDownForMaintenance: isDownForMaintenance,
          );
        });

        test('does not change when status is the same', () {
          final repository = FakeAppConfigRepository();
          final stream = repository.isDownForMaintenance();

          const isDownForMaintenance = true;
          expect(stream, emits(isDownForMaintenance));
          repository.changeIsDownForMaintenance(
            isDownForMaintenance: isDownForMaintenance,
          );

          expect(stream, neverEmits(isDownForMaintenance));
          repository
            ..changeIsDownForMaintenance(
              isDownForMaintenance: isDownForMaintenance,
            )
            ..close();
        });

        test('throws $AssertionError when previously closed', () {
          final repository = FakeAppConfigRepository()..close();

          const assertionMessage =
              '''Cannot change isDownForMaintenance after the stream has been closed.''';
          expect(
            () => repository.changeIsDownForMaintenance(
              isDownForMaintenance: true,
            ),
            throwsA(
              isA<AssertionError>()
                  .having((e) => e.message, 'message', assertionMessage),
            ),
          );
        });
      });

      group('isDownForMaintenance', () {
        test('returns as expected', () {
          final repository = FakeAppConfigRepository();
          addTearDown(repository.close);
          expect(repository.isDownForMaintenance, returnsNormally);
        });

        test('throws $AssertionError when previously closed', () {
          final repository = FakeAppConfigRepository()..close();

          const assertionMessage =
              '''Cannot access isDownForMaintenance after the stream has been closed.''';
          expect(
            repository.isDownForMaintenance,
            throwsA(
              isA<AssertionError>()
                  .having((e) => e.message, 'message', assertionMessage),
            ),
          );
        });
      });

      group('close', () {
        test('closes isDownForMaintenance stream', () {
          final repository = FakeAppConfigRepository();
          final stream = repository.isDownForMaintenance();

          repository.close();

          expect(stream, emitsDone);
        });

        test('closes isForceUpgradeRequired stream', () {
          final repository = FakeAppConfigRepository();
          final stream = repository.isForceUpgradeRequired();

          repository.close();

          expect(stream, emitsDone);
        });

        test('throws $AssertionError when previously closed', () {
          final repository = FakeAppConfigRepository()..close();

          const assertionMessage =
              '''Cannot close FakeAppConfigRepository after it has already been closed.''';
          expect(
            repository.close,
            throwsA(
              isA<AssertionError>()
                  .having((e) => e.message, 'message', assertionMessage),
            ),
          );
        });
      });
    },
  );
}
