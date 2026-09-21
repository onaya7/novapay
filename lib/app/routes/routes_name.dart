/// The `name:` every `GoRoute` answers to, used with `context.pushNamed(...)`
/// rather than a raw path string at any call site.
abstract class RoutesName {
  static const String splash = 'splash';
  static const String wallet = 'wallet';
  static const String savings = 'savings';
  static const String activity = 'activity';
  static const String profile = 'profile';
  static const String sendMoney = 'sendMoney';
  static const String biometricConfirm = 'biometricConfirm';
  static const String addMoney = 'addMoney';
  static const String createGoal = 'createGoal';
  static const String editGoal = 'editGoal';
  static const String contribute = 'contribute';
  static const String transactionDetail = 'transactionDetail';
}
