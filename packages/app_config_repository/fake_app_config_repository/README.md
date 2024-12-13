# Fake App Config Repository

A fake implementation of `package:app_config_repository`.

⚠️ **Warning**: Although this actually has working implementations, it takes some shortcuts which makes it not suitable for production.

## Usage

```dart
import 'package:fake_app_config_repository/fake_app_config_repository.dart';

Future<void> main() async {
  final repository = FakeAppConfigRepository();

  // Listen to isForceUpgradeRequired changes.
  final isForceUpgradeRequiredSubscription =
      repository.isForceUpgradeRequired().listen((forceUpgrade) {
    print('isForceUpgradeRequired: $forceUpgrade');
  });

  // Listen to isDownForMaintenance changes.
  final isDownForMaintenanceStreamSubscription =
      repository.isDownForMaintenance().listen((isDownForMaintenance) {
    print('isDownForMaintenance: $isDownForMaintenance');
  });

  // Change isForceUpgradeRequired and isDownForMaintenance.
  await Future<void>.delayed(const Duration(seconds: 1));
  repository.changeIsForceUpgradeRequired(
    forceUpgrade: const ForceUpgrade(
      isUpgradeRequired: true,
      upgradeUrl: 'url',
    ),
  );

  await Future<void>.delayed(const Duration(seconds: 1));
  repository.changeIsDownForMaintenance(isDownForMaintenance: true);

  // Cancel subscriptions and close the repository.
  await isForceUpgradeRequiredSubscription.cancel();
  await isDownForMaintenanceStreamSubscription.cancel();
  repository.close();
}
```

💡 **Note**: For a quick understanding of how to use this package, see the [example](example/lib/main.dart).
