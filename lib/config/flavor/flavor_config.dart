import 'package:meta/meta.dart';
import 'package:novapay/config/flavor/flavor.dart';

/// Chosen by the entry point, so one build cannot read another's data.
@immutable
class FlavorConfig {
  const FlavorConfig({required this.flavor, required this.hiveBoxName});

  final Flavor flavor;
  final String hiveBoxName;

  bool get isProduction => flavor == Flavor.production;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlavorConfig &&
          other.flavor == flavor &&
          other.hiveBoxName == hiveBoxName);

  @override
  int get hashCode => Object.hash(flavor, hiveBoxName);

  @override
  String toString() => 'FlavorConfig(${flavor.name}, $hiveBoxName)';
}
