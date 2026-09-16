import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme.dart';
import 'package:novapay/features/wallet/presentation/view/wallet_page.dart';
import 'package:novapay/l10n/l10n.dart';

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WalletPage(),
    );
  }
}
