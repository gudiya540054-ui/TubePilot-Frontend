import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class UploadScreen extends StatefulWidget {
  final bool embedded;
  const UploadScreen({super.key, this.embedded = false});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? videoFile;
  File? thumbFile;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _playlistCtrl = TextEditingController();
  String category = '22';
  String audience = 'not_for_kids';
  String privacyStatus = 'public';
  DateTime? scheduledAt;
  bool uploading = false;
  int freeUploadsRemaining = 0;
  int diamondBalance = 0;

  final categories = const {
    '22': 'People & Blogs', '27': 'Education', '28': 'Science & Technology',
    '20': 'Gaming', '24': 'Entertainment', '10': 'Music', '26': 'Howto & Style',
  };

  final audienceLabels = const {
    'not_for_kids': 'Not made for kids',
    'made_for_kids': 'Made for kids',
  };

  final privacyLabels = const {
    'unlisted': 'Unlisted',
    'public': 'Public',
    'private': 'Private',
  };

  @override
  void initState() {
    super.initState();
    _loadCost();
  }

  Future<void> _loadCost() async {
    try {
      final res = await ApiService.instance.dashboard();
      setState(() {
        freeUploadsRemaining = res['data']['remainingFreeUploads'] ?? 0;
        diamondBalance = res['data']['diamondBalance'] ?? 0;
      });
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) setState(() => videoFile = File(video.path));
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => thumbFile = File(img.path));
  }

  // Bottom-sheet option picker used for Audience and Privacy — replaces the
  // old full-screen Material dropdown menu with a compact, scrollable sheet.
  Future<String?> _showOptionPicker({required String title, required Map<String, String> options, required String current}) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(color: context.surfaces.border, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: options.entries.map((e) {
                      final selected = e.key == current;
                      return ListTile(
                        title: Text(e.value, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                        trailing: selected ? const Icon(Icons.check_circle, color: AppColors.purple, size: 20) : null,
                        onTap: () => Navigator.pop(sheetContext, e.key),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Scrollable wheel-style time picker (Cupertino), shown in a compact bottom
  // sheet instead of the bulky Material clock-dial dialog.
  Future<TimeOfDay?> _pickTimeWheel() async {
    TimeOfDay selected = TimeOfDay.now();
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(color: context.surfaces.border, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const Text('Select Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(
                height: 216,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                    textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: TextStyle(color: context.surfaces.textDim.a > 0 ? null : null)),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: DateTime.now(),
                    use24hFormat: false,
                    onDateTimeChanged: (dt) => selected = TimeOfDay(hour: dt.hour, minute: dt.minute),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: GradientButton(label: 'Confirm', onPressed: () => Navigator.pop(sheetContext, selected)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 10)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await _pickTimeWheel();
    if (time == null || !mounted) return;
    setState(() => scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<String?> _promptTopic() async {
    if (_titleCtrl.text.trim().isNotEmpty) return _titleCtrl.text.trim();
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('What is this video about?'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. AI tools for productivity')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Generate')),
        ],
      ),
    );
  }

  Future<void> _generateAi(String field) async {
    final topic = await _promptTopic();
    if (topic == null || topic.isEmpty) return;
    try {
      showToast(context, 'Generating with AI...');
      if (field == 'title') {
        final res = await ApiService.instance.aiTitle(topic);
        _titleCtrl.text = res['title'] ?? '';
      } else if (field == 'description') {
        final res = await ApiService.instance.aiDescription(topic);
        _descCtrl.text = res['description'] ?? '';
      } else {
        final res = await ApiService.instance.aiTags(topic);
        _tagsCtrl.text = (res['tags'] as List).join(', ');
      }
      if (mounted) showToast(context, 'AI content generated ✨', isSuccess: true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _submit() async {
    if (videoFile == null) {
      showToast(context, 'Please select a video first', isError: true);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      showToast(context, 'Title is required', isError: true);
      return;
    }

    setState(() => uploading = true);
    try {
      final videoMime = lookupMimeType(videoFile!.path) ?? 'video/mp4';
      final files = [
        await http.MultipartFile.fromPath('video', videoFile!.path, contentType: MediaType.parse(videoMime)),
      ];
      if (thumbFile != null) {
        final thumbMime = lookupMimeType(thumbFile!.path) ?? 'image/jpeg';
        files.add(await http.MultipartFile.fromPath('thumbnail', thumbFile!.path, contentType: MediaType.parse(thumbMime)));
      }

      // Schedule Time only ever means "when to go public" — and that only
      // applies when Privacy is 'public'. For unlisted/private it's ignored
      // (the field is hidden in the UI for those cases, see build() below).
      final effectiveScheduledAt = privacyStatus == 'public' ? scheduledAt : null;

      final fields = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text,
        'tags': _tagsCtrl.text,
        'category': category,
        'playlist': _playlistCtrl.text,
        'audience': audience,
        'privacyStatus': privacyStatus,
        if (effectiveScheduledAt != null) 'scheduledAt': effectiveScheduledAt.toUtc().toIso8601String(),
      };

      await ApiService.instance.uploadMultipart('/videos/upload', fields: fields, files: files);
      if (!mounted) return;
      showToast(context, 'Video uploaded successfully!', isSuccess: true);
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final costLabel = freeUploadsRemaining > 0
        ? '💎 Free Upload ($freeUploadsRemaining left)'
        : '💎 10 Diamonds (Balance: $diamondBalance)';

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: ListView(
        // Extra bottom padding (110) keeps the Upload button clear of the
        // floating pill nav bar instead of being hidden behind it.
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          GestureDetector(
            onTap: _pickVideo,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
              child: videoFile == null
                  ? Column(children: [
                      const Text('🎬', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      const Text('Tap to select a video', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('MP4, MOV, MKV up to 2GB', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                    ])
                  : Column(children: [
                      const Icon(Icons.check_circle, color: AppColors.green, size: 30),
                      const SizedBox(height: 8),
                      Text(videoFile!.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Tap to change', style: TextStyle(color: context.surfaces.textDim, fontSize: 12)),
                    ]),
            ),
          ),
          const SizedBox(height: 18),

          _fieldLabel('Title', aiField: 'title'),
          TextField(controller: _titleCtrl, maxLength: 100, decoration: const InputDecoration(hintText: 'e.g. 10 AI Tools That Will Blow Your Mind')),

          _fieldLabel('Description', aiField: 'description'),
          TextField(controller: _descCtrl, maxLines: 4, maxLength: 5000, decoration: const InputDecoration(hintText: "In this video, I'll show you...")),

          _fieldLabel('Tags', aiField: 'tags'),
          TextField(controller: _tagsCtrl, decoration: const InputDecoration(hintText: 'ai, tools, tutorial (comma separated)')),
          const SizedBox(height: 14),

          Text('Thumbnail (optional)', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickThumbnail,
            child: Row(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(10)),
                child: thumbFile == null
                    ? const Center(child: Text('🖼️', style: TextStyle(fontSize: 22)))
                    : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(thumbFile!, fit: BoxFit.cover)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Upload a custom thumbnail image', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5))),
            ]),
          ),
          const SizedBox(height: 14),

          Text('Category', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: category,
            items: categories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => category = v ?? '22'),
          ),
          const SizedBox(height: 14),

          Text('Playlist (optional)', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(controller: _playlistCtrl, decoration: const InputDecoration(hintText: 'e.g. AI Tutorials')),
          const SizedBox(height: 14),

          Text('Audience', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 6),
          _pickerField(
            value: audienceLabels[audience] ?? '',
            onTap: () async {
              final result = await _showOptionPicker(title: 'Audience', options: audienceLabels, current: audience);
              if (result != null) setState(() => audience = result);
            },
          ),
          const SizedBox(height: 14),

          Text('Privacy', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 6),
          _pickerField(
            value: privacyLabels[privacyStatus] ?? '',
            onTap: () async {
              final result = await _showOptionPicker(title: 'Privacy', options: privacyLabels, current: privacyStatus);
              if (result != null) {
                setState(() {
                  privacyStatus = result;
                  // Schedule Time only applies to 'public'. Clear any previously
                  // picked time when switching away from it so a stale time can't
                  // be sent for unlisted/private uploads.
                  if (privacyStatus != 'public') scheduledAt = null;
                });
              }
            },
          ),
          const SizedBox(height: 4),
          Text(
            privacyStatus == 'public'
                ? 'Video uploads immediately. Leave Schedule Time empty to go public right away, or pick a time below to upload as unlisted now and switch to public automatically at that time.'
                : 'Video uploads immediately as "$privacyStatus" and stays that way.',
            style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5),
          ),
          const SizedBox(height: 14),

          if (privacyStatus == 'public') ...[
            Text('Schedule Time (optional)', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
            const SizedBox(height: 6),
            _pickerField(
              value: scheduledAt == null ? 'Go public now (tap to schedule instead)' : formatDateTime(scheduledAt!.toIso8601String()),
              isPlaceholder: scheduledAt == null,
              onTap: _pickSchedule,
            ),
            const SizedBox(height: 18),
          ],

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Upload Cost', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
              AppBadge(label: costLabel, color: AppColors.diamond),
            ]),
          ),
          const SizedBox(height: 20),
          GradientButton(label: 'Upload', loading: uploading, onPressed: _submit),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _pickerField({required String value, required VoidCallback onTap, bool isPlaceholder = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: isPlaceholder ? FontWeight.w400 : FontWeight.w700,
                  color: isPlaceholder ? context.surfaces.textDim : null,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: context.surfaces.textDim),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, {required String aiField}) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          GestureDetector(
            onTap: () => _generateAi(aiField),
            child: const Text('✨ AI Generate (2💎)', style: TextStyle(color: AppColors.purpleLight, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}