import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() => videoFile = File(result.files.single.path!));
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => thumbFile = File(img.path));
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(minutes: 10)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
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
      final files = [await http.MultipartFile.fromPath('video', videoFile!.path)];
      if (thumbFile != null) files.add(await http.MultipartFile.fromPath('thumbnail', thumbFile!.path));

      final fields = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text,
        'tags': _tagsCtrl.text,
        'category': category,
        'playlist': _playlistCtrl.text,
        'audience': audience,
        'privacyStatus': privacyStatus,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toUtc().toIso8601String(),
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
        padding: const EdgeInsets.all(20),
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
          DropdownButtonFormField<String>(
            initialValue: audience,
            items: const [
              DropdownMenuItem(value: 'not_for_kids', child: Text('Not made for kids')),
              DropdownMenuItem(value: 'made_for_kids', child: Text('Made for kids')),
            ],
            onChanged: (v) => setState(() => audience = v ?? 'not_for_kids'),
          ),
          const SizedBox(height: 14),

          Text('Privacy', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: privacyStatus,
            items: const [
              DropdownMenuItem(value: 'public', child: Text('Public')),
              DropdownMenuItem(value: 'unlisted', child: Text('Unlisted')),
              DropdownMenuItem(value: 'private', child: Text('Private')),
            ],
            onChanged: (v) => setState(() => privacyStatus = v ?? 'public'),
          ),
          const SizedBox(height: 14),

          Text('Schedule Time (optional)', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Leave empty to upload right now, or pick when it should go live as "$privacyStatus"',
              style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickSchedule,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(12)),
              child: Text(
                scheduledAt == null ? 'Upload now (tap to schedule instead)' : formatDateTime(scheduledAt!.toIso8601String()),
                style: TextStyle(color: scheduledAt == null ? context.surfaces.textDim : null),
              ),
            ),
          ),
          const SizedBox(height: 18),

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
