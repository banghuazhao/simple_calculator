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

  Widget _panel(ThemeModel model, Widget child) => Material(
    color: model.panelColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: model.panelBorderColor),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumController>();
    final model = context.watch<ThemeModel>();
    final strings = S.of(context);
    final textTheme = Theme.of(context).textTheme;
    final textColor = model.panelTextColor;
    final isPremium = premium.isPremium;
    final price = premium.price;
    final busy = premium.isChecking || premium.isBusy || _loadingPrice;
    final status = switch (_outcome) {
      PremiumOutcome.restored when isPremium => strings.premiumRestored,
      PremiumOutcome.pending when !isPremium => strings.premiumPending,
      PremiumOutcome.notPurchased when !isPremium =>
        strings.premiumNotPurchased,
      PremiumOutcome.unavailable => strings.premiumUnavailable,
      PremiumOutcome.failed => strings.premiumFailed,
      _ => null,
    };

    Widget purchaseActions(Color foreground) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (busy)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(color: foreground),
          ),
        if (!isPremium)
          if (price != null)
            FilledButton(
              style: FilledButton.styleFrom(
                foregroundColor: model.panelColor,
                backgroundColor: textColor,
                minimumSize: const Size(0, 48),
              ),
              onPressed: busy ? null : () => _run(premium.purchase),
              child: Text(
                '${strings.premiumBuy} · $price',
                textAlign: TextAlign.center,
              ),
            )
          else if (!busy)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: model.panelBorderColor),
                minimumSize: const Size(0, 48),
              ),
              onPressed: () => _loadPrice(premium),
              child: Text(
                strings.premiumCheckPrice,
                textAlign: TextAlign.center,
              ),
            ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: foreground),
          onPressed: busy ? null : () => _run(premium.restore),
          child: Text(strings.premiumRestore, textAlign: TextAlign.center),
        ),
        if (status != null)
          Semantics(
            liveRegion: true,
            child: Text(
              status,
              style: textTheme.bodyMedium?.copyWith(color: foreground),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );

    Widget toolTile({
      required IconData icon,
      required String title,
      required VoidCallback open,
    }) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: textColor,
      textColor: textColor,
      leading: Icon(icon),
      title: Text(title),
      trailing: isPremium ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: isPremium ? open : null,
    );

    return Scaffold(
      backgroundColor: model.backgroundColor,
      appBar: AppBar(
        backgroundColor: model.backgroundColor,
        foregroundColor: model.readableTextColor,
        scrolledUnderElevation: 0,
        title: Text(
          strings.premium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _panel(
                  model,
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isPremium
                                  ? Icons.verified_outlined
                                  : Icons.workspace_premium_outlined,
                              color: textColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isPremium
                                    ? strings.premiumActive
                                    : premium.offersAdRemoval
                                    ? strings.premiumOffer
                                    : strings.premiumOfferToolsOnly,
                                style: textTheme.titleMedium?.copyWith(
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (premium.offersAdRemoval) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.block_outlined, color: textColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  strings.premiumAdFree,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (!isPremium) ...[
                          const SizedBox(height: 16),
                          purchaseActions(textColor),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _panel(
                  model,
                  Column(
                    children: [
                      toolTile(
                        icon: Icons.functions,
                        title: strings.scientificCalculator,
                        open: () => _open(const ScientificPage()),
                      ),
                      Divider(
                        color: model.panelBorderColor,
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      toolTile(
                        icon: Icons.compare_arrows,
                        title: strings.reusableFormulas,
                        open: () => _open(
                          FormulasPage(
                            guard: _gate,
                            canEdit: () => premium.isPremium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (isPremium)
                  purchaseActions(model.readableTextColor)
                else
                  _panel(
                    model,
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: DefaultTextStyle.merge(
                        style: textTheme.bodyMedium?.copyWith(color: textColor),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                strings.premiumWhatIfPreview,
                                style: textTheme.titleMedium?.copyWith(
                                  color: textColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(strings.premiumWhatIfPrice),
                            const SizedBox(height: 8),
                            Text(strings.premiumWhatIfBaseline),
                            const SizedBox(height: 4),
                            Text(strings.premiumWhatIfAlternate),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
