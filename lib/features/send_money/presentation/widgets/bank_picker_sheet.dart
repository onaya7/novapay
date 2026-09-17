import 'package:material_ui/material_ui.dart';
import 'package:novapay/config/theme/app_theme_colors.dart';
import 'package:novapay/core/components/custom_input_field.dart';
import 'package:novapay/core/constants/app_size.dart';
import 'package:novapay/features/send_money/domain/entities/bank.dart';
import 'package:novapay/features/send_money/presentation/widgets/bank_avatar.dart';
import 'package:novapay/l10n/l10n.dart';

/// A searchable bank list, presented with `showModalBottomSheet` and
/// resolving with the chosen [Bank]. Self-contained: it takes the list it
/// shows rather than loading one, so it never reaches into a cubit itself.
class BankPickerSheet extends StatefulWidget {
  const new({required this.banks, super.key});

  final List<Bank> banks;

  @override
  State<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<BankPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<Bank> _filtered = const [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.banks;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final needle = query.trim().toLowerCase();
    setState(() {
      _filtered = needle.isEmpty
          ? widget.banks
          : widget.banks
                .where((bank) => bank.name.toLowerCase().contains(needle))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final texts = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSize.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSize.md),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppSize.radiusPill),
                  ),
                ),
              ),
              Text(l10n.chooseBankHint, style: texts.titleLarge),
              AppSize.h(AppSize.md),
              CustomInputField(
                label: l10n.searchLabel,
                hint: l10n.bankNameHint,
                controller: _search,
                autofocus: true,
                onChanged: _filter,
              ),
              AppSize.h(AppSize.md),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noBanksMatch,
                          style: texts.bodyMedium?.copyWith(
                            color: colors.subtext,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (context, index) =>
                            AppSize.h(AppSize.xs),
                        itemBuilder: (context, index) {
                          final bank = _filtered[index];
                          return _BankTile(
                            key: ValueKey(bank.code),
                            bank: bank,
                            onTap: () => Navigator.of(context).pop(bank),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankTile extends StatelessWidget {
  const _BankTile({required this.bank, required this.onTap, super.key});

  final Bank bank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSize.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSize.sm,
            vertical: AppSize.smd,
          ),
          child: Row(
            children: [
              BankAvatar(bank: bank),
              AppSize.w(AppSize.smd),
              Expanded(
                child: Text(
                  bank.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
