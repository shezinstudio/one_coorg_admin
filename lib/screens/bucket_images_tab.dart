import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BucketImagesTab extends StatefulWidget {
  const BucketImagesTab({super.key});

  @override
  State<BucketImagesTab> createState() => _BucketImagesTabState();
}

class _BucketImagesTabState extends State<BucketImagesTab> {
  static const String bucketName = 'place-images';
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _green = Color(0xFF2D6A4F);

  List<FileObject> _files = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _loading = true);
    try {
      final files = await _supabase.storage.from(bucketName).list();
      debugPrint('Bucket "$bucketName" returned ${files.length} item(s)');
      files.removeWhere((f) => f.name == '.emptyFolderPlaceholder');
      // Newest first
      files.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      setState(() => _files = files);
    } catch (e) {
      _showError('Failed to load images: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _publicUrlFor(String fileName) {
    return _supabase.storage.from(bucketName).getPublicUrl(fileName);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';

      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(
              contentType: picked.mimeType ?? 'image/jpeg',
              upsert: false,
            ),
          );

      await _loadImages();
      _showMessage('Image uploaded successfully');
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _confirmDelete(FileObject file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete image?'),
        content: Text('This will permanently delete "${file.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteImage(file.name);
    }
  }

  Future<void> _deleteImage(String fileName) async {
    try {
      await _supabase.storage.from(bucketName).remove([fileName]);
      setState(() => _files.removeWhere((f) => f.name == fileName));
      _showMessage('Image deleted');
    } catch (e) {
      _showError('Delete failed: $e');
    }
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    _showMessage('URL copied to clipboard');
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _formatSize(dynamic bytes) {
    if (bytes == null) return '';
    final size = bytes is int ? bytes : int.tryParse(bytes.toString()) ?? 0;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bucket Images'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadImages,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? const Center(child: Text('No images in the bucket'))
          : RefreshIndicator(
              onRefresh: _loadImages,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _files.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final file = _files[index];
                  final url = _publicUrlFor(file.name);
                  final size = file.metadata?['size'];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 64,
                              height: 64,
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatSize(size),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyUrl(url),
                          icon: const Icon(Icons.link),
                          tooltip: 'Copy URL',
                          color: _green,
                        ),
                        IconButton(
                          onPressed: () => _confirmDelete(file),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          color: Colors.red.shade400,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        onPressed: _uploading ? null : _pickAndUploadImage,
        icon: _uploading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload, color: Colors.white),
        label: Text(
          _uploading ? 'Uploading...' : 'Upload Image',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
