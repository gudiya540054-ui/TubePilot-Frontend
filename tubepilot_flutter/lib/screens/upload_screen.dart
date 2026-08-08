import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/brand_icons.dart';

class UploadScreen extends StatefulWidget {
  final bool embedded;
  const UploadScreen({super.key, this.embedded = false});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

/// Holds all per-video editable fields for bulk upload. Every selected video
/// gets its own instance of this — title/description/tags/caption/hashtags
/// are always per-video, only the publish time is shared across the batch.
class _VideoItem {
  final File file;
  File? thumbFile; // YouTube only

  final ytTitleCtrl = TextEditingController();
  final ytDescCtrl = TextEditingController();
  final ytTagsCtrl = TextEditingController();

  final fbCaptionCtrl = TextEditingController();
  final fbHashtagsCtrl = TextEditingController();

  bool expanded = true;

  _VideoItem(this.file);

  void dispose() {
    ytTitleCtrl.dispose();
    ytDescCtrl.dispose();
    ytTagsCtrl.dispose();
    fbCaptionCtrl.dispose();
    fbHashtagsCtrl.dispose();
  }
}

class _UploadScreenState extends State<UploadScreen> {
  // Bulk-capable video list — a single video is just a list of length 1, so
  // the same code path handles both the old single-upload flow and the new
  // 50-100 video bulk flow.
  final List<_VideoItem> videos = [];

  final Set<String> selectedPlatforms = {};

  // Connection status, loaded once on init (from /dashboard + /meta/status +
  // /youtube/channel — reusing existing endpoints, no new ones needed here).
  bool youtubeConnected = false;
  bool facebookConnected = false;
  bool loadingConnections = true;

  // ---------------- Shared YouTube settings (apply to every video) ----------------
  String ytCategory = '22';
  String ytAudience = 'not_for_kids';
  String ytPrivacy = 'public';
  final _ytPlaylistCtrl = TextEditingController();

  final categories = const {
    '22': 'People & Blogs', '27': 'Education', '28': 'Science & Technology',
    '20': 'Gaming', '24': 'Entertainment', '10': 'Music', '26': 'Howto & Style',
  };
  final audienceLabels = const {'not_for_kids': 'Not made for kids', 'made_for_kids': 'Made for kids'};
  final privacyLabels = const {'unlisted': 'Unlisted', 'public': 'Public', 'private': 'Private'};

  // ---------------- Scheduling ----------------
  // One publish time for the whole batch, across every platform — no
  // per-video/per-platform scheduling. Toggle reveals the picker.
  bool scheduleEnabled = false;
  DateTime? scheduledAt;

  bool uploading = false;
  int uploadedCount = 0;
  int freeUploadsRemaining = 0;
  int diamondBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _ytPlaylistCtrl.dispose();
    for (final v in videos) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        ApiService.instance.dashboard(),
        ApiService.instance.getYoutubeChannel().catchError((_) => <String, dynamic>{}),
        ApiService.instance.getMetaStatus().catchError((_) => <String, dynamic>{}),
      ]);
      final dash = results[0];
      final yt = results[1];
      final meta = results[2];
      setState(() {
        freeUploadsRemaining = dash['data']?['remainingFreeUploads'] ?? 0;
        diamondBalance = dash['data']?['diamondBalance'] ?? 0;
        youtubeConnected = yt['success'] == true;
        facebookConnected = meta['facebook'] != null;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => loadingConnections = false);
    }
  }

  // ---------------- Video pickers ----------------
  Future<void> _pickSingleVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        videos.add(_VideoItem(File(video.path)));
      });
    }
  }

  /// Bulk pick — image_picker doesn't support multi-video selection on all
  /// platforms, so we loop the single picker with a running "Add another"
  /// prompt. This keeps the same picker plumbing working everywhere while
  /// still letting someone build up a batch of 50-100 videos.
  Future<void> _pickMoreVideos() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        videos.add(_VideoItem(File(video.path)));
      });
    }
  }

  Future<void> _pickThumbnail(_VideoItem item) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => item.thumbFile = File(img.path));
  }

  void _removeVideo(_VideoItem item) {
    setState(() {
      item.dispose();
      videos.remove(item);
    });
  }

  void _togglePlatform(String platform, bool connected) {
    if (!connected) {
      showToast(context, 'Connect this account from your Profile first', isError: true);
      return;
    }
    setState(() {
      if (selectedPlatforms.contains(platform)) {
        selectedPlatforms.remove(platform);
      } else {
        selectedPlatforms.add(platform);
      }
    });
  }

  // ---------------- Shared pickers (same pattern as before) ----------------
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
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime.now(),
                  use24hFormat: false,
                  onDateTimeChanged: (dt) => selected = TimeOfDay(hour: dt.hour, minute: dt.minute),
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

  Future<DateTime?> _pickDateTime(DateTime? current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now().add(const Duration(minutes: 10)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return current;
    final time = await _pickTimeWheel();
    if (time == null || !mounted) return current;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<String?> _promptTopic(TextEditingController seedFrom) async {
    if (seedFrom.text.trim().isNotEmpty) return seedFrom.text.trim();
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

  // ---------------- AI generation (per-video) ----------------
  Future<void> _generateYoutube(_VideoItem item, String field) async {
    final topic = await _promptTopic(item.ytTitleCtrl);
    if (topic == null || topic.isEmpty) return;
    try {
      showToast(context, 'Generating with AI...');
      if (field == 'title') {
        final res = await ApiService.instance.aiTitle(topic);
        item.ytTitleCtrl.text = res['title'] ?? '';
      } else if (field == 'description') {
        final res = await ApiService.instance.aiDescription(topic);
        item.ytDescCtrl.text = res['description'] ?? '';
      } else {
        final res = await ApiService.instance.aiTags(topic);
        item.ytTagsCtrl.text = (res['tags'] as List).join(', ');
      }
      if (mounted) showToast(context, 'AI content generated ✨', isSuccess: true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _generateCaption(_VideoItem item) async {
    final topic = await _promptTopic(item.fbCaptionCtrl);
    if (topic == null || topic.isEmpty) return;
    try {
      showToast(context, 'Generating with AI...');
      final res = await ApiService.instance.aiCaption(topic, 'facebook');
      item.fbCaptionCtrl.text = res['caption'] ?? '';
      if (mounted) showToast(context, 'AI caption generated ✨', isSuccess: true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _generateHashtags(_VideoItem item) async {
    final topic = await _promptTopic(item.fbCaptionCtrl);
    if (topic == null || topic.isEmpty) return;
    try {
      showToast(context, 'Generating with AI...');
      final res = await ApiService.instance.aiHashtags(topic, 'facebook');
      item.fbHashtagsCtrl.text = (res['hashtags'] as List).join(', ');
      if (mounted) showToast(context, 'AI hashtags generated ✨', isSuccess: true);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  // ---------------- Submit (loops over every video in the batch) ----------------
  Future<void> _submit() async {
    if (videos.isEmpty) {
      showToast(context, 'Please select at least one video first', isError: true);
      return;
    }
    if (selectedPlatforms.isEmpty) {
      showToast(context, 'Select at least one platform to publish to', isError: true);
      return;
    }
    if (selectedPlatforms.contains('youtube')) {
      final missingTitle = videos.any((v) => v.ytTitleCtrl.text.trim().isEmpty);
      if (missingTitle) {
        showToast(context, 'Every video needs a YouTube title', isError: true);
        return;
      }
    }

    setState(() {
      uploading = true;
      uploadedCount = 0;
    });

    final failures = <String>[];
    final scheduledIso = scheduleEnabled ? scheduledAt?.toUtc().toIso8601String() : null;

    try {
      for (final item in videos) {
        try {
          Map<String, dynamic>? youtube;
          Map<String, dynamic>? facebook;

          if (selectedPlatforms.contains('youtube')) {
            youtube = {
              'title': item.ytTitleCtrl.text.trim(),
              'description': item.ytDescCtrl.text,
              'tags': item.ytTagsCtrl.text,
              'category': ytCategory,
              'playlist': _ytPlaylistCtrl.text,
              'audience': ytAudience,
              'privacyStatus': ytPrivacy,
              if (scheduledIso != null) 'scheduledAt': scheduledIso,
            };
          }
          if (selectedPlatforms.contains('facebook')) {
            facebook = {
              'caption': item.fbCaptionCtrl.text,
              'hashtags': item.fbHashtagsCtrl.text,
              if (scheduledIso != null) 'scheduledAt': scheduledIso,
            };
          }

          await ApiService.instance.uploadVideo(
            videoPath: item.file.path,
            thumbnailPath: selectedPlatforms.contains('youtube') ? item.thumbFile?.path : null,
            platforms: selectedPlatforms.toList(),
            youtube: youtube,
            facebook: facebook,
          );

          setState(() => uploadedCount++);
        } catch (e) {
          failures.add(item.file.path.split('/').last);
        }
      }

      if (!mounted) return;

      if (failures.isEmpty) {
        showToast(context, '${videos.length} video${videos.length > 1 ? 's' : ''} queued for publishing!', isSuccess: true);
        Navigator.of(context).maybePop();
      } else {
        showToast(context, '$uploadedCount uploaded, ${failures.length} failed', isError: true);
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  // ---------------- UI helpers ----------------
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

  /// Platform selector card — YouTube and Facebook rendered side-by-side
  /// (parallel row) with real brand-logo widgets instead of emoji. Tapping
  /// toggles that platform's per-video fields open below.
  Widget _platformCard({
    required String platform,
    required String label,
    required Widget logo,
    required bool connected,
  }) {
    final selected = selectedPlatforms.contains(platform);
    return Expanded(
      child: GestureDetector(
        onTap: () => _togglePlatform(platform, connected),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple.withOpacity(0.12) : context.surfaces.card2,
            border: Border.all(color: selected ? AppColors.purple : context.surfaces.border, width: selected ? 1.6 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              logo,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(connected ? 'Connected' : 'Tap to connect', style: TextStyle(fontSize: 10.5, color: connected ? AppColors.green : context.surfaces.textDim)),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: AppColors.purple, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget titleLeading, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            titleLeading,
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _fieldLabel(String text, {VoidCallback? onAiTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
          if (onAiTap != null)
            GestureDetector(
              onTap: onAiTap,
              child: const Text('✨ AI Generate (2💎)', style: TextStyle(color: AppColors.purpleLight, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  /// One collapsible card per video in the batch — holds that video's
  /// thumbnail preview plus its own title/description/hashtags fields for
  /// every selected platform.
  Widget _videoCard(_VideoItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () => setState(() => item.expanded = !item.expanded),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.movie_outlined, size: 20),
            ),
            title: Text('Video ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            subtitle: Text(item.file.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.surfaces.textDim, fontSize: 11.5)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red), onPressed: () => _removeVideo(item)),
                Icon(item.expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: context.surfaces.textDim),
              ],
            ),
          ),
          if (item.expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedPlatforms.contains('youtube')) ...[
                    Row(children: [
                      const YoutubeIcon(size: 15),
                      const SizedBox(width: 6),
                      Text('YouTube', style: TextStyle(color: context.surfaces.textDim, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                    _fieldLabel('Title', onAiTap: () => _generateYoutube(item, 'title')),
                    TextField(controller: item.ytTitleCtrl, maxLength: 100, decoration: const InputDecoration(hintText: 'e.g. 10 AI Tools That Will Blow Your Mind')),
                    _fieldLabel('Description', onAiTap: () => _generateYoutube(item, 'description')),
                    TextField(controller: item.ytDescCtrl, maxLines: 3, maxLength: 5000, decoration: const InputDecoration(hintText: "In this video, I'll show you...")),
                    _fieldLabel('Tags / #hashtags', onAiTap: () => _generateYoutube(item, 'tags')),
                    TextField(controller: item.ytTagsCtrl, decoration: const InputDecoration(hintText: '#ai, #tools, #tutorial')),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _pickThumbnail(item),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: context.surfaces.card2, borderRadius: BorderRadius.circular(10)),
                          child: item.thumbFile == null
                              ? const Icon(Icons.image_outlined, size: 18)
                              : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(item.thumbFile!, fit: BoxFit.cover)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Custom thumbnail (optional)', style: TextStyle(color: context.surfaces.textDim, fontSize: 12))),
                      ]),
                    ),
                  ],
                  if (selectedPlatforms.contains('facebook')) ...[
                    if (selectedPlatforms.contains('youtube')) const SizedBox(height: 16),
                    Row(children: [
                      const FacebookIcon(size: 15),
                      const SizedBox(width: 6),
                      Text('Facebook Reels', style: TextStyle(color: context.surfaces.textDim, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                    _fieldLabel('Caption', onAiTap: () => _generateCaption(item)),
                    TextField(controller: item.fbCaptionCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Write a caption...')),
                    _fieldLabel('Hashtags', onAiTap: () => _generateHashtags(item)),
                    TextField(controller: item.fbHashtagsCtrl, decoration: const InputDecoration(hintText: '#reels, #trending')),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final costLabel = freeUploadsRemaining > 0
        ? '💎 Free Upload ($freeUploadsRemaining left, ${videos.length} queued)'
        : '💎 ${videos.length * 10} Diamonds (Balance: $diamondBalance)';

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Video')),
      body: loadingConnections
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                // ---------------- Video picker (bulk) ----------------
                if (videos.isEmpty)
                  GestureDetector(
                    onTap: _pickSingleVideo,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        const Text('🎬', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        const Text('Tap to select videos', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Select one, or add more after — bulk upload up to 100', style: TextStyle(color: context.surfaces.textDim, fontSize: 12), textAlign: TextAlign.center),
                        const SizedBox(height: 2),
                        Text('MP4, MOV, MKV up to 2GB each', style: TextStyle(color: context.surfaces.textDim, fontSize: 11)),
                      ]),
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${videos.length} video${videos.length > 1 ? 's' : ''} selected', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      TextButton.icon(
                        onPressed: videos.length >= 100 ? null : _pickMoreVideos,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add more'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),

                // ---------------- Platform selection (side by side) ----------------
                Text('Publish To', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: [
                  _platformCard(platform: 'youtube', label: 'YouTube', logo: const YoutubeIcon(size: 22), connected: youtubeConnected),
                  const SizedBox(width: 12),
                  _platformCard(platform: 'facebook', label: 'Facebook Reels', logo: const FacebookIcon(size: 22), connected: facebookConnected),
                ]),
                const SizedBox(height: 20),

                // ---------------- Per-video cards ----------------
                if (videos.isNotEmpty && selectedPlatforms.isNotEmpty)
                  ...List.generate(videos.length, (i) => _videoCard(videos[i], i)),

                // ---------------- Shared YouTube settings (apply to whole batch) ----------------
                if (selectedPlatforms.contains('youtube') && videos.isNotEmpty)
                  _sectionCard(title: 'YouTube Settings (applies to all videos)', titleLeading: const YoutubeIcon(size: 18), children: [
                    Text('Category', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                    const SizedBox(height: 6),
                    _pickerField(
                      value: categories[ytCategory] ?? '',
                      onTap: () async {
                        final r = await _showOptionPicker(title: 'Category', options: categories, current: ytCategory);
                        if (r != null) setState(() => ytCategory = r);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Playlist (optional)', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(controller: _ytPlaylistCtrl, decoration: const InputDecoration(hintText: 'e.g. AI Tutorials')),
                    const SizedBox(height: 12),
                    Text('Audience', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                    const SizedBox(height: 6),
                    _pickerField(
                      value: audienceLabels[ytAudience] ?? '',
                      onTap: () async {
                        final r = await _showOptionPicker(title: 'Audience', options: audienceLabels, current: ytAudience);
                        if (r != null) setState(() => ytAudience = r);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Privacy', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                    const SizedBox(height: 6),
                    _pickerField(
                      value: privacyLabels[ytPrivacy] ?? '',
                      onTap: () async {
                        final r = await _showOptionPicker(title: 'Privacy', options: privacyLabels, current: ytPrivacy);
                        if (r != null) setState(() => ytPrivacy = r);
                      },
                    ),
                  ]),

                // ---------------- Schedule toggle (single, shared, bottom-most) ----------------
                // Appears only after title/description/etc. are filled in above —
                // this is the last thing before publishing, and there is only one
                // schedule for the entire batch across every platform.
                if (videos.isNotEmpty && selectedPlatforms.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Switch(
                              value: scheduleEnabled,
                              activeColor: AppColors.purple,
                              onChanged: (v) => setState(() {
                                scheduleEnabled = v;
                                if (!v) scheduledAt = null;
                              }),
                            ),
                          ],
                        ),
                        if (!scheduleEnabled)
                          Text('All videos publish immediately on every selected platform', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5))
                        else ...[
                          const SizedBox(height: 8),
                          Text('One publish time for the whole batch, across all platforms', style: TextStyle(color: context.surfaces.textDim, fontSize: 12.5)),
                          const SizedBox(height: 10),
                          _pickerField(
                            value: scheduledAt == null ? 'Tap to pick date & time' : formatDateTime(scheduledAt!.toIso8601String()),
                            isPlaceholder: scheduledAt == null,
                            onTap: () async {
                              final picked = await _pickDateTime(scheduledAt);
                              setState(() => scheduledAt = picked);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                if (videos.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(border: Border.all(color: context.surfaces.border), borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Upload Cost', style: TextStyle(color: context.surfaces.textDim, fontSize: 13)),
                      AppBadge(label: costLabel, color: AppColors.diamond),
                    ]),
                  ),
                const SizedBox(height: 20),
                if (videos.isNotEmpty)
                  GradientButton(
                    label: uploading ? 'Uploading $uploadedCount / ${videos.length}...' : 'Publish ${videos.length > 1 ? '(${videos.length} videos)' : ''}',
                    loading: uploading,
                    onPressed: _submit,
                  ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}