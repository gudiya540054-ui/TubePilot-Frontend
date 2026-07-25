import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class DiamondStoreScreen extends StatefulWidget {
  const DiamondStoreScreen({super.key});
  @override
  State<DiamondStoreScreen> createState() => _DiamondStoreScreenState();
}

class _DiamondStoreScreenState extends State<DiamondStoreScreen> {
  List<dynamic> packages = [];
  int balance = 0;
  String userId = '';
  Map<String, dynamic>? paymentSettings;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final pkgRes = await ApiService.instance.getDiamondPackages();
      final meRes = await ApiService.instance.me();
      setState(() {
        packages = pkgRes['packages'];
        balance = pkgRes['currentBalance'] ?? 0;
        userId = meRes['user']['userId'] ?? '';
      });
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _selectPackage(int diamonds, int price) async {
    try {
      paymentSettings ??= (await ApiService.instance.getPaymentSettings())['settings'];
    } catch (e) {
      if (mounted) showApiError(context, e);
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _PaymentSheet(diamonds: diamonds, price: price, settings: paymentSettings!, userId: userId, onDone: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diamond Store')),
      body: loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Your Balance', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                    Text('💎 $balance', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ]),
                ),
                const SizedBox(height: 20),
                const Text('Choose a Package', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ...packages.map((p) => Container(
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
                              Text('${p['diamonds']} Diamonds', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('₹${p['priceINR']}', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5)),
                            ]),
                          ]),
                          ElevatedButton(onPressed: () => _selectPackage(p['diamonds'], p['priceINR']), child: const Text('Buy')),
                        ],
                      ),
                    )),
              ],
            ),
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  final int diamonds;
  final int price;
  final Map<String, dynamic> settings;
  final String userId;
  final VoidCallback onDone;
  const _PaymentSheet({required this.diamonds, required this.price, required this.settings, required this.userId, required this.onDone});

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  bool showConfirmForm = false;
  final _utrCtrl = TextEditingController();
  File? screenshot;
  bool submitting = false;

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => screenshot = File(img.path));
  }

  Future<void> _submit() async {
    if (_utrCtrl.text.trim().isEmpty) {
      showToast(context, 'Please enter the UTR/transaction number', isError: true);
      return;
    }
    setState(() => submitting = true);
    try {
      final files = <http.MultipartFile>[];
      if (screenshot != null) {
        final mime = lookupMimeType(screenshot!.path) ?? 'image/jpeg';
        files.add(await http.MultipartFile.fromPath('screenshot', screenshot!.path, contentType: MediaType.parse(mime)));
      }
      await ApiService.instance.uploadMultipart('/diamonds/purchase-request',
          fields: {'diamondPackage': '${widget.diamonds}', 'utrNumber': _utrCtrl.text.trim()}, files: files);
      if (!mounted) return;
      showToast(context, 'Payment submitted! Diamonds will be added after admin approval.', isSuccess: true);
      Navigator.pop(context);
      widget.onDone();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = widget.settings['qrImageUrl'];
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Complete Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            Center(
              child: Column(children: [
                if (qr != null && qr != '')
                  ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(qr, width: 180, height: 180, fit: BoxFit.cover))
                else
                  Text('QR not set by admin yet', style: TextStyle(color: context.surfaces.textDim)),
                const SizedBox(height: 10),
                Text(widget.settings['upiId'] ?? 'UPI not configured', style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(widget.settings['merchantName'] ?? '', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                const SizedBox(height: 10),
                Text('Pay ₹${widget.price}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 20),
            if (!showConfirmForm)
              GradientButton(label: 'Payment Done', onPressed: () => setState(() => showConfirmForm = true))
            else ...[
              Text('Amount Paid (₹)', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(enabled: false, controller: TextEditingController(text: '${widget.price}')),
              const SizedBox(height: 12),
              Text('UTR / Transaction Number', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(controller: _utrCtrl, decoration: const InputDecoration(hintText: 'e.g. 402812345678')),
              const SizedBox(height: 12),
              Text('User ID', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(enabled: false, controller: TextEditingController(text: widget.userId)),
              const SizedBox(height: 12),
              Text('Screenshot (optional)', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickScreenshot,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(screenshot == null ? 'Choose Screenshot' : 'Screenshot selected'),
              ),
              const SizedBox(height: 16),
              GradientButton(label: 'Submit for Approval', loading: submitting, onPressed: _submit),
            ],
          ],
        ),
      ),
    );
  }
}
