/// The `path:` every `GoRoute` answers to. The four tab paths are branch
/// roots; everything else is a task pushed over the shell.
abstract class RoutesPath {
  static const String wallet = '/';
  static const String savings = '/savings';
  static const String activity = '/activity';
  static const String profile = '/profile';
  static const String sendMoney = '/send-money';
  static const String addMoney = '/add-money';
  static const String createGoal = '/create-goal';
  static const String contribute = '/contribute';
  static const String transactionDetail = '/transaction';
}
