import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../providers/language_provider.dart';

// ⚠️ FIX: previous version imported from `package:cashfree_pg/...` and
// declared `implements CFCallback` — neither is correct. The package that
// actually exposes CFPaymentGatewayService / CFSessionBuilder /
// CFDropCheckoutPaymentBuilder is `flutter_cashfree_pg_sdk` (see
// pubspec.yaml), and its own official examples never implement a
// CFCallback interface — setCallback() just takes two plain function
// references matching (String orderId) and (CFErrorResponse, String
// orderId). cfenums/cfexceptions also live under utils/, not api/.
class DiamondStoreScreen extends StatefulWidget {
  const DiamondStoreScreen({super.key});
  @override
  State<DiamondStoreScreen> createState() => _DiamondStoreScreenState();
}

class _DiamondStoreScreenState extends State<DiamondStoreScreen> {
  List<dynamic> packages = [];
  int balance = 0;
  bool loading = true;
  int? _payingDiamonds;

  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();

  @override
  void initState() {
    super.initState();
    _cfPaymentGatewayService.setCallback(_onVerify, _onError);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final pkgRes = await ApiService.instance.getDiamondPackages();
      setState(() {
        packages = pkgRes['packages'];
        balance = pkgRes['currentBalance'] ?? 0;
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _buy(int diamonds) async {
    if (_payingDiamonds != null) return;
    setState(() => _payingDiamonds = diamonds);
    try {
      final res = await ApiService.instance.createCashfreeOrder(diamonds);
      final orderId = res['orderId'] as String;
      final paymentSessionId = res['paymentSessionId'] as String;

      // Session/payment object construction can throw CFException if a
      // required field is missing/invalid — caught here so a malformed
      // order response shows a normal error toast instead of crashing.
      try {
        final session = CFSessionBuilder()
            // TODO: switch to CFEnvironment.PRODUCTION for release builds —
            // must match CASHFREE_ENV on the backend, or checkout will fail
            // with an "invalid session" style error.
            .setEnvironment(CFEnvironment.SANDBOX)
            .setOrderId(orderId)
            .setPaymentSessionId(paymentSessionId)
            .build();

        final cfDropCheckoutPayment = CFDropCheckoutPaymentBuilder()
            .setSession(session)
            .build();

        _cfPaymentGatewayService.doPayment(cfDropCheckoutPayment);
        // Execution continues in _onVerify()/_onError() below once the
        // checkout screen closes — NOT here, doPayment() doesn't await.
      } on CFException catch (e) {
        if (mounted) {
          setState(() => _payingDiamonds = null);
          showToast(context, e.message ?? 'Could not open checkout.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _payingDiamonds = null);
        showApiError(context, e);
      }
    }
  }

  // Fired by the Cashfree SDK once checkout closes with what looks like a
  // successful payment. This is still just a client-side signal — the
  // actual credit only happens after our backend re-confirms directly with
  // Cashfree's server (see verify-payment route notes).
  void _onVerify(String orderId) {
    _confirmWithBackend(orderId);
  }

  // Fired on failure/cancel. Still asks the backend to check — a failure
  // callback can occasionally fire even when the payment actually
  // succeeded on Cashfree's side (e.g. the user backgrounded the app right
  // at the end of checkout), so this is not treated as automatic proof of
  // failure either.
  void _onError(CFErrorResponse errorResponse, String orderId) {
    _confirmWithBackend(orderId, sdkReportedError: errorResponse.getMessage());
  }

  Future<void> _confirmWithBackend(String orderId, {String? sdkReportedError}) async {
    try {
      final res = await ApiService.instance.verifyCashfreePayment(orderId);
      final status = res['status'];
      if (!mounted) return;
      if (status == 'approved') {
        showToast(context, context.tr('payment_submitted_msg'), isSuccess: true);
        _load();
      } else if (status == 'pending') {
        showToast(context, 'Payment is still processing — check back shortly.', isError: false);
      } else {
        showToast(context, sdkReportedError ?? 'Payment was not completed.', isError: true);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _payingDiamonds = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('diamond_store_title'))),
      body: loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(context.tr('your_balance'), style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                    Text('💎 $balance', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(height: 20),
                Text(context.tr('choose_package'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ...packages.map((p) {
                  final diamonds = p['diamonds'] as int;
                  final isPaying = _payingDiamonds == diamonds;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Text('💎', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(context.tr('diamonds_suffix').replaceAll('%d', '$diamonds'), style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('₹${p['priceINR']}', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5)),
                          ]),
                        ]),
                        ElevatedButton(
                          onPressed: _payingDiamonds != null ? null : () => _buy(diamonds),
                          child: isPaying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(context.tr('buy_btn')),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}