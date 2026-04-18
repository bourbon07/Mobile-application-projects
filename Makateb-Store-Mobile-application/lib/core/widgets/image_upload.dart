import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/theme.dart';
import '../localization/app_localizations.dart';
import 'app_button.dart';

/// ImageUpload - Image upload widget with multiple methods
///
/// Equivalent to Vue's ImageUpload.vue component.
/// Provides UI for uploading images via URL link or Cloudinary.
///
/// Features:
/// - Tab navigation (Link/Cloudinary)
/// - URL input with preview
/// - File upload (UI only, callback provided)
/// - Image preview grid
/// - Single or multiple image support
/// - Remove images
/// - Primary image indicator
///
/// Note: This is UI-only. All actions are handled via callbacks.
class ImageUpload extends StatefulWidget {
  /// Currently selected image(s)
  final List<String>? images;

  /// Whether to allow multiple images
  final bool multiple;

  /// Whether to show Cloudinary tab
  final bool showCloudinary;

  /// Callback when image is added
  final void Function(List<String> images)? onImagesChanged;

  /// Callback when file is selected for upload
  final void Function({
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  })?
  onFileSelected;

  /// Callback to fetch Cloudinary images (should return List of URLs)
  final Future<List<String>> Function()? onFetchCloudinaryImages;

  /// Placeholder text for URL input
  final String? urlPlaceholder;

  /// Label texts (for localization)
  final ImageUploadLabels? labels;

  const ImageUpload({
    super.key,
    this.images,
    this.multiple = false,
    this.showCloudinary = true,
    this.onImagesChanged,
    this.onFileSelected,
    this.onFetchCloudinaryImages,
    this.urlPlaceholder,
    this.labels,
  });

  @override
  State<ImageUpload> createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  late String _activeTab;
  final TextEditingController _urlController = TextEditingController();
  String? _previewUrl;
  bool _isValidUrl = false;
  List<String> _cloudinaryImages = [];
  bool _cloudinaryLoading = false;
  String? _cloudinaryError;

  @override
  void initState() {
    super.initState();
    _activeTab = 'link';
    _urlController.addListener(_validateUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateUrl() {
    final url = _urlController.text.trim();
    final isValid = _isValidUrlString(url);
    setState(() {
      _isValidUrl = isValid;
      _previewUrl = isValid ? _normalizeUrl(url) : null;
    });
  }

  String _normalizeUrl(String url) {
    if (url.trim().isNotEmpty &&
        !url.trim().startsWith(RegExp(r'https?://', caseSensitive: false))) {
      return 'https://$url';
    }
    return url.trim();
  }

  bool _isValidUrlString(String url) {
    if (url.trim().isEmpty) return false;
    try {
      final normalized = _normalizeUrl(url);
      final uri = Uri.parse(normalized);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  void _addImageFromLink() {
    final url = _urlController.text.trim();
    if (!_isValidUrlString(url)) {
      // Show error - in real app, use a toast/notification
      return;
    }

    final normalizedUrl = _normalizeUrl(url);
    final currentImages = List<String>.from(widget.images ?? []);

    if (widget.multiple) {
      if (!currentImages.contains(normalizedUrl)) {
        currentImages.add(normalizedUrl);
      }
    } else {
      currentImages.clear();
      currentImages.add(normalizedUrl);
    }

    widget.onImagesChanged?.call(currentImages);
    _urlController.clear();
    setState(() {
      _previewUrl = null;
      _isValidUrl = false;
    });
  }

  Future<void> _handleFileSelect() async {
    if (widget.onFileSelected == null) return;

    // Directly open device file picker (gallery)
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress to reduce upload size
      );

      if (pickedFile != null && mounted) {
        // Read bytes for platform-agnostic upload
        final bytes = await pickedFile.readAsBytes();

        // Pass file info to callback
        widget.onFileSelected?.call(
          filePath: pickedFile.path,
          fileBytes: bytes,
          fileName: pickedFile.name,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.translate('error_picking_image')}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _fetchCloudinaryImages() async {
    if (widget.onFetchCloudinaryImages == null) return;

    setState(() {
      _cloudinaryLoading = true;
      _cloudinaryError = null;
    });

    try {
      final images = await widget.onFetchCloudinaryImages!();
      setState(() {
        _cloudinaryImages = images;
        _cloudinaryLoading = false;
      });
    } catch (e) {
      setState(() {
        _cloudinaryError = e.toString();
        _cloudinaryLoading = false;
      });
    }
  }

  void _selectCloudinaryImage(String url) {
    final currentImages = List<String>.from(widget.images ?? []);

    if (widget.multiple) {
      if (!currentImages.contains(url)) {
        currentImages.add(url);
      }
    } else {
      currentImages.clear();
      currentImages.add(url);
    }

    widget.onImagesChanged?.call(currentImages);
  }

  void _removeImage(int index) {
    final currentImages = List<String>.from(widget.images ?? []);
    if (index >= 0 && index < currentImages.length) {
      currentImages.removeAt(index);
      widget.onImagesChanged?.call(currentImages);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labels = widget.labels ?? ImageUploadLabels.defaultLabels();

    // Tailwind colors
    // amber-200: #FDE68A, amber-400: #FBBF24, amber-600: #D97706, amber-700: #B45309, amber-800: #92400E
    // gray-400: #9CA3AF, gray-500: #6B7280, gray-600: #78716C, gray-700: #374151, gray-900: #111827
    // red-50: #FEF2F2, red-400: #F87171, red-600: #DC2626, red-900: #7F1D1D

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload Methods Tabs
        _buildTabs(isDark, labels),

        const SizedBox(height: AppTheme.spacingLG), // space-y-4
        // Link Input Tab
        if (_activeTab == 'link') _buildLinkInput(isDark, labels),

        // Cloudinary Tab
        if (_activeTab == 'cloudinary' && widget.showCloudinary)
          _buildCloudinarySection(isDark, labels),

        // Image Preview
        if (widget.images != null && widget.images!.isNotEmpty)
          _buildImagePreview(isDark, labels),
      ],
    );
  }

  Widget _buildTabs(bool isDark, ImageUploadLabels labels) {
    final activeBorderColor = const Color(0xFFD97706); // amber-600
    final activeTextColor = isDark
        ? const Color(0xFFFBBF24)
        : const Color(0xFFD97706); // amber-400/amber-600
    final inactiveTextColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF78716C); // gray-400/gray-600
    final borderColor = isDark
        ? const Color(0xFF92400E)
        : const Color(0xFFFDE68A); // amber-800/amber-200

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Link Tab
          _TabButton(
            label: labels.imageLink,
            isActive: _activeTab == 'link',
            onTap: () => setState(() => _activeTab = 'link'),
            activeTextColor: activeTextColor,
            inactiveTextColor: inactiveTextColor,
            activeBorderColor: activeBorderColor,
          ),
          // Cloudinary Tab
          if (widget.showCloudinary)
            _TabButton(
              label: labels.cloudinary,
              isActive: _activeTab == 'cloudinary',
              onTap: () {
                setState(() => _activeTab = 'cloudinary');
                if (_cloudinaryImages.isEmpty && !_cloudinaryLoading) {
                  _fetchCloudinaryImages();
                }
              },
              activeTextColor: activeTextColor,
              inactiveTextColor: inactiveTextColor,
              activeBorderColor: activeBorderColor,
            ),
        ],
      ),
    );
  }

  Widget _buildLinkInput(bool isDark, ImageUploadLabels labels) {
    final borderColor = isDark
        ? const Color(0xFF92400E)
        : const Color(0xFFFDE68A); // amber-800/amber-200
    final focusBorderColor = const Color(0xFFD97706); // amber-500
    final bgColor = isDark
        ? const Color(0xFF374151)
        : Colors.white; // gray-700/white
    final textColor = isDark
        ? Colors.white
        : const Color(0xFF111827); // white/gray-900

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          labels.enterImageUrl,
          style: AppTextStyles.labelSmallStyle(
            color: textColor,
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM), // space-y-2
        // Input and Button Row
        Row(
          children: [
            // URL Input
            Expanded(
              child: TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  hintText: widget.urlPlaceholder ?? labels.imageUrlPlaceholder,
                  filled: true,
                  fillColor: bgColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLG, // px-4
                    vertical: AppTheme.spacingSM, // py-2
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(color: borderColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    borderSide: BorderSide(color: focusBorderColor, width: 2),
                  ),
                  hintStyle: AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                style: AppTextStyles.bodyMediumStyle(color: textColor),
                onSubmitted: (_) => _addImageFromLink(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSM), // gap-2
            // Add Button
            AppButton(
              text: labels.addImage,
              onPressed: _isValidUrl ? _addImageFromLink : null,
              size: AppButtonSize.small,
            ),
          ],
        ),

        // URL Preview
        if (_previewUrl != null && _isValidUrl) ...[
          const SizedBox(height: AppTheme.spacingSM), // mt-2
          Text(
            '${labels.preview}:',
            style: AppTextStyles.labelSmallStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280), // gray-400/gray-500
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS), // mb-1
          ClipRRect(
            borderRadius: AppTheme.borderRadiusLargeValue,
            child: Container(
              width: double.infinity,
              height: 128, // h-32 = 128px
              decoration: BoxDecoration(
                border: Border.all(color: borderColor, width: 2),
                borderRadius: AppTheme.borderRadiusLargeValue,
              ),
              child: Image.network(
                _previewUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCloudinarySection(bool isDark, ImageUploadLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload to Cloudinary
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labels.uploadToCloudinary,
              style: AppTextStyles.labelSmallStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontWeight: AppTextStyles.medium,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM), // mb-2
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL), // p-6
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF92400E)
                      : const Color(0xFFFDE68A), // amber-800/amber-200
                  width: 2,
                ),
                borderRadius: AppTheme.borderRadiusLargeValue,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 32,
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFD97706), // amber-400/amber-600
                  ),
                  const SizedBox(height: AppTheme.spacingSM), // mb-2
                  AppButton(
                    text: labels.uploadToCloudinary,
                    onPressed: _handleFileSelect,
                    size: AppButtonSize.small,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingLG), // space-y-4
        // Browse Cloudinary
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labels.selectFromCloudinary,
              style: AppTextStyles.labelSmallStyle(
                color: isDark ? Colors.white : const Color(0xFF111827),
                fontWeight: AppTextStyles.medium,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM), // mb-2
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: labels.browseCloudinary,
                onPressed: _fetchCloudinaryImages,
                size: AppButtonSize.small,
              ),
            ),

            // Loading State
            if (_cloudinaryLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingLG,
                ),
                child: Center(
                  child: Text(
                    '${labels.loading}...',
                    style: AppTextStyles.bodySmallStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),

            // Error State
            if (_cloudinaryError != null) ...[
              const SizedBox(height: AppTheme.spacingLG),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF7F1D1D).withAlpha(77)
                      : const Color(0xFFFEF2F2), // red-900/30/red-50
                  borderRadius: AppTheme.borderRadiusLargeValue,
                ),
                child: Text(
                  _cloudinaryError!,
                  style: AppTextStyles.labelSmallStyle(
                    color: isDark
                        ? const Color(0xFFF87171)
                        : const Color(0xFFDC2626), // red-400/red-600
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Cloudinary Images Grid
            if (!_cloudinaryLoading &&
                _cloudinaryError == null &&
                _cloudinaryImages.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingLG), // mt-4
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 400,
                ), // Increased height for better visibility
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: AppTheme.spacingSM, // gap-2
                    mainAxisSpacing: AppTheme.spacingSM,
                  ),
                  shrinkWrap: true,
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Enable scrolling
                  itemCount: _cloudinaryImages.length,
                  itemBuilder: (context, index) {
                    final imageUrl = _cloudinaryImages[index];
                    final isSelected =
                        widget.images?.contains(imageUrl) ?? false;
                    return _CloudinaryImageItem(
                      imageUrl: imageUrl,
                      isSelected: isSelected,
                      onTap: () => _selectCloudinaryImage(imageUrl),
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],

            // Empty State
            if (!_cloudinaryLoading &&
                _cloudinaryError == null &&
                _cloudinaryImages.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingLG,
                ),
                child: Center(
                  child: Text(
                    labels.noImagesFound,
                    style: AppTextStyles.labelSmallStyle(
                      color: isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(bool isDark, ImageUploadLabels labels) {
    final images = widget.images ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingSM), // space-y-2
        Text(
          widget.multiple ? labels.selectedImages : labels.selectedImage,
          style: AppTextStyles.labelSmallStyle(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        widget.multiple
            ? GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: AppTheme.spacingLG, // gap-4
                  mainAxisSpacing: AppTheme.spacingLG,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: images.length,
                itemBuilder: (context, index) => _PreviewImageItem(
                  imageUrl: images[index],
                  isPrimary: index == 0,
                  onRemove: () => _removeImage(index),
                  isDark: isDark,
                  labels: labels,
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: _PreviewImageItem(
                      imageUrl: images.first,
                      onRemove: () => _removeImage(0),
                      isDark: isDark,
                      labels: labels,
                    ),
                  ),
                ],
              ),
      ],
    );
  }
}

/// Tab Button Widget
class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeTextColor;
  final Color inactiveTextColor;
  final Color activeBorderColor;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeTextColor,
    required this.inactiveTextColor,
    required this.activeBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLG, // px-4
          vertical: AppTheme.spacingSM, // py-2
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? activeBorderColor : Colors.transparent,
              width: 2, // border-b-2
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLargeStyle(
            color: isActive ? activeTextColor : inactiveTextColor,
            fontWeight: AppTextStyles.medium,
          ),
        ),
      ),
    );
  }
}

/// Cloudinary Image Item
class _CloudinaryImageItem extends StatelessWidget {
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _CloudinaryImageItem({
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF92400E)
        : const Color(0xFFFDE68A); // amber-800/amber-200
    final hoverBorderColor = const Color(0xFFD97706); // amber-500

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: 96, // h-24 = 96px
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? hoverBorderColor : borderColor,
                width: 2,
              ),
              borderRadius: AppTheme.borderRadiusLargeValue,
            ),
            child: ClipRRect(
              borderRadius: AppTheme.borderRadiusLargeValue,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(51), // bg-black/20
                  borderRadius: AppTheme.borderRadiusLargeValue,
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Colors.white, size: 24),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Preview Image Item
class _PreviewImageItem extends StatelessWidget {
  final String imageUrl;
  final bool isPrimary;
  final VoidCallback onRemove;
  final bool isDark;
  final ImageUploadLabels labels;

  const _PreviewImageItem({
    required this.imageUrl,
    this.isPrimary = false,
    required this.onRemove,
    required this.isDark,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark
        ? const Color(0xFF92400E)
        : const Color(0xFFFDE68A); // amber-800/amber-200

    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppTheme.borderRadiusLargeValue,
          child: Container(
            height: 128, // h-32 = 128px
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              borderRadius: AppTheme.borderRadiusLargeValue,
            ),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
        // Remove Button
        Positioned(
          top: 4, // top-1
          right: 4, // right-1
          child: Material(
            color: const Color(0xFFDC2626), // red-600
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(4), // p-1
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ),
        // Primary Badge
        if (isPrimary)
          Positioned(
            bottom: 4, // bottom-1
            left: 4, // left-1
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSM, // px-2
                vertical: 4, // py-1
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706), // amber-600
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                labels.primary,
                style: AppTextStyles.labelSmallStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

/// ImageUploadLabels - Localization labels
class ImageUploadLabels {
  final String imageLink;
  final String cloudinary;
  final String enterImageUrl;
  final String imageUrlPlaceholder;
  final String addImage;
  final String preview;
  final String uploadToCloudinary;
  final String selectFromCloudinary;
  final String browseCloudinary;
  final String loading;
  final String noImagesFound;
  final String selectedImage;
  final String selectedImages;
  final String primary;

  const ImageUploadLabels({
    required this.imageLink,
    required this.cloudinary,
    required this.enterImageUrl,
    required this.imageUrlPlaceholder,
    required this.addImage,
    required this.preview,
    required this.uploadToCloudinary,
    required this.selectFromCloudinary,
    required this.browseCloudinary,
    required this.loading,
    required this.noImagesFound,
    required this.selectedImage,
    required this.selectedImages,
    required this.primary,
  });

  factory ImageUploadLabels.defaultLabels() {
    return const ImageUploadLabels(
      imageLink: 'Image Link',
      cloudinary: 'Cloudinary',
      enterImageUrl: 'Enter Image URL',
      imageUrlPlaceholder: 'https://example.com/image.jpg',
      addImage: 'Add Image',
      preview: 'Preview',
      uploadToCloudinary: 'Upload to Cloudinary',
      selectFromCloudinary: 'Select from Cloudinary',
      browseCloudinary: 'Browse Cloudinary',
      loading: 'Loading',
      noImagesFound: 'No images found',
      selectedImage: 'Selected Image',
      selectedImages: 'Selected Images',
      primary: 'Primary',
    );
  }
}


