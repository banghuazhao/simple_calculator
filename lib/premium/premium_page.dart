import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_calculator/generated/l10n.dart';
import 'package:simple_calculator/util/theme_model.dart';

import 'formulas_page.dart';
import 'premium_controller.dart';
import 'scientific_page.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  PremiumOutcome? _outcome;
  bool _loadingPrice = false;

  Future<void> _run(Future<PremiumOutcome> Function() action) async {
    setState(() => _outcome = null);
    final outcome = await action();
    if (mounted) setState(() => _outcome = outcome);
  }

  Future<void> _loadPrice(PremiumController controller) async {
    setState(() {
      _loadingPrice = true;
      _outcome = null;
    });
    await controller.loadProduct();
    if (!mounted) return;
    setState(() {
      _loadingPrice = false;
      if (controller.price == null) _outcome = PremiumOutcome.unavailable;
    });
  }

  Widget _gate(Widget tool) => _PremiumToolGate(tool: tool);

  void _open(Widget tool) {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => _gate(tool)));
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumController>();
    final model = context.watch<ThemeModel>();
    final strings = S.of(context);
    final price = premium.price;
    final busy = premium.isChecking || premium.isBusy || _loadingPrice;
    final status = switch (_outcome) {
      PremiumOutcome.restored when premium.isPremium => strings.premiumRestored,
      PremiumOutcome.pending when !premium.isPremium => strings.premiumPending,
      PremiumOutcome.notPurchased when !premium.isPremium =>
        strings.premiumNotPurchased,
      PremiumOutcome.unavailable => strings.premiumUnavailable,
      PremiumOutcome.failed => strings.premiumFailed,
      _ => null,
    };

    return Scaffold(
      backgroundColor: model.backgroundColor,
      appBar: AppBar(
        backgroundColor: model.backgroundColor,
        foregroundColor: model.textColor1,
        title: Text(strings.premium),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                premium.isPremium
                    ? strings.premiumActive
                    : strings.premiumOffer,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: model.textColor1),
              ),
            ),
            ListTile(
              iconColor: model.textColor1,
              textColor: model.textColor1,
              leading: const Icon(Icons.block_outlined),
              title: Text(strings.premiumAdFree),
            ),
            ListTile(
              iconColor: model.textColor1,
              textColor: model.textColor1,
              leading: const Icon(Icons.functions),
              title: Text(strings.scientificCalculator),
              trailing: premium.isPremium
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: premium.isPremium
                  ? () => _open(const ScientificPage())
                  : null,
            ),
            ListTile(
              iconColor: model.textColor1,
              textColor: model.textColor1,
              leading: const Icon(Icons.compare_arrows),
              title: Text(strings.reusableFormulas),
              trailing: premium.isPremium
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: premium.isPremium
                  ? () => _open(
                      FormulasPage(
                        guard: _gate,
                        canEdit: () => premium.isPremium,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            if (busy) const LinearProgressIndicator(),
            if (!premium.isPremium) ...[
              if (price != null)
                FilledButton(
                  onPressed: busy ? null : () => _run(premium.purchase),
                  child: Text('${strings.premiumBuy} · $price'),
                )
              else if (!busy)
                OutlinedButton(
                  onPressed: () => _loadPrice(premium),
                  child: Text(strings.premiumCheckPrice),
                ),
            ],
            TextButton(
              onPressed: busy ? null : () => _run(premium.restore),
              child: Text(strings.premiumRestore),
            ),
            if (status != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  style: TextStyle(color: model.textColor1),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumToolGate extends StatefulWidget {
  const _PremiumToolGate({required this.tool});

  final Widget tool;

  @override
  State<_PremiumToolGate> createState() => _PremiumToolGateState();
}

class _PremiumToolGateState extends State<_PremiumToolGate> {
  bool _revoked = false;

  @override
  Widget build(BuildContext context) {
    final active = context.select<PremiumController, bool>(
      (premium) => premium.isPremium,
    );
    // A re-purchase opens a fresh tool, including any nested editor routes.
    if (!active) _revoked = true;
    return _revoked ? const PremiumPage() : widget.tool;
  }
}
