import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/widgets/confirmation_modal.dart';
import '../../core/stores/language_store.dart';
import '../../core/services/api_services/chat_api_service.dart';
import '../../core/services/api_services/cloudinary_api_service.dart';
import '../../core/widgets/image_upload.dart';
import '../../core/localization/app_localizations.dart';

/// ChatScreen - Chat interface screen
///
/// Equivalent to Vue's Chat.vue page.
/// Displays conversations list and chat interface.
///
/// Features:
/// - Conversations sidebar with search
/// - Chat area with messages
/// - Guest mode support
/// - Online status indicators
/// - Unread message counts
/// - Image messages
/// - Order status highlighting
/// - Dark mode support
/// - Responsive design
class ChatScreen extends ConsumerStatefulWidget {
  /// Mock user data
  final ChatUserData? user;

  /// Mock conversations data
  final List<ConversationData>? conversations;

  /// Selected conversation ID
  final String? selectedConversationId;

  /// Loading state
  final bool loadingConversations;

  /// Whether in guest mode
  final bool isGuestMode;

  /// Callback when conversation is selected
  final void Function(String conversationId)? onSelectConversation;

  /// Callback when message is sent
  final void Function(String conversationId, String message, String? imageUrl)?
  onSendMessage;

  /// Callback when view profile is tapped
  final void Function(String userId)? onViewProfile;

  /// Callback when clear chat is tapped
  final void Function(String conversationId)? onClearChat;

  /// Callback when block user is tapped
  final void Function(String userId)? onBlockUser;

  /// Callback when login is tapped
  final VoidCallback? onLoginTap;

  /// Time formatter function
  final String Function(String? dateString, bool isUnread)? formatTime;

  /// Message time formatter function
  final String Function(String? dateString)? formatMessageTime;

  /// Labels for localization
  final ChatScreenLabels? labels;

  const ChatScreen({
    super.key,
    this.user,
    this.conversations,
    this.selectedConversationId,
    this.loadingConversations = false,
    this.isGuestMode = false,
    this.onSelectConversation,
    this.onSendMessage,
    this.onViewProfile,
    this.onClearChat,
    this.onBlockUser,
    this.onLoginTap,
    this.formatTime,
    this.formatMessageTime,
    this.labels,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  String? _selectedConversationId;
  String _searchQuery = '';
  String? _selectedImage;
  final _chatApi = LaravelChatApiService();

  List<ConversationData> _conversationsState = const [];
  List<MessageData> _messagesState = const [];
  bool _loadingConversationsState = false;
  bool _loadingMessagesState = false;
  bool _sendingMessage = false;
  String? _error;
  final _cloudinaryApi = LaravelCloudinaryApiService();

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _selectedConversationId = widget.selectedConversationId;
    _bootstrap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _messagesScrollController.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    // If guest mode, keep UI read-only; no polling.
    if (widget.isGuestMode || widget.user == null) return;
    await _refreshConversations();
    if (_selectedConversationId != null) {
      await _refreshMessages(_selectedConversationId!);
    }
    _startPolling();
  }

  List<ConversationData> get _conversations {
    return _conversationsState;
  }

  List<ConversationData> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    final query = _searchQuery.toLowerCase();
    return _conversations.where((conv) {
      final name = _getConversationName(conv).toLowerCase();
      final lastMessage = (conv.lastMessage?.message ?? '').toLowerCase();
      return name.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  ConversationData? get _selectedConversation {
    if (_selectedConversationId == null) return null;
    return _conversations.firstWhere(
      (conv) =>
          conv.id == _selectedConversationId ||
          conv.userId == _selectedConversationId,
      orElse: () => _conversations.isNotEmpty
          ? _conversations.first
          : const ConversationData(),
    );
  }

  List<MessageData> get _messages {
    return _messagesState;
  }

  ChatUserData? get _otherUser {
    return _selectedConversation?.user;
  }

  String _getConversationName(ConversationData conv) {
    if (widget.isGuestMode) {
      return conv.orderId != null ? 'Order #${conv.orderId}' : 'Order';
    }
    return conv.user?.name ?? 'Unknown User';
  }

  String? _getConversationAvatar(ConversationData conv) {
    return conv.user?.avatarUrl;
  }

  bool _hasUnread(ConversationData conv) {
    return (conv.unreadCount ?? 0) > 0;
  }

  String _formatTime(String? dateString, bool isUnread) {
    if (isUnread) return 'New';
    if (dateString == null || dateString.isEmpty) return '';
    return widget.formatTime != null
        ? widget.formatTime!(dateString, isUnread)
        : _defaultFormatTime(dateString);
  }

  String _defaultFormatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min';
      if (diff.inHours < 24) return '${diff.inHours} hr';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  String _formatMessageTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    return widget.formatMessageTime != null
        ? widget.formatMessageTime!(dateString)
        : _defaultFormatMessageTime(dateString);
  }

  String _defaultFormatMessageTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _selectConversation(ConversationData conv) {
    setState(() {
      _selectedConversationId = conv.id ?? conv.userId;
    });
    widget.onSelectConversation?.call(_selectedConversationId!);
    if (!widget.isGuestMode &&
        widget.user != null &&
        _selectedConversationId != null) {
      _refreshMessages(_selectedConversationId!);
    }
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedConversationId == null) return;
    if (widget.isGuestMode) {
      widget.onLoginTap?.call();
      return;
    }

    if (_sendingMessage) return;
    setState(() => _sendingMessage = true);
    try {
      await _chatApi.sendMessage(
        toUserId: _selectedConversationId!,
        message: message,
        imageUrl: _selectedImage,
      );
      _messageController.clear();
      setState(() => _selectedImage = null);
      await _refreshConversations();
      await _refreshMessages(_selectedConversationId!);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
    _messageController.clear();
    setState(() {
      _selectedImage = null;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesScrollController.hasClients) {
        _messagesScrollController.animateTo(
          _messagesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    if (_selectedConversationId == null) return;

    showDialog(
      context: context,
      builder: (context) => ConfirmationModal(
        title: widget.labels?.clearChat ?? 'Clear Chat',
        message:
            widget.labels?.areYouSureClearChat ??
            'Are you sure you want to clear this chat?',
        isDestructive: true,
        onConfirm: () {
          Navigator.of(context).pop();
          widget.onClearChat?.call(_selectedConversationId!);
        },
        onCancel: () => Navigator.of(context).pop(),
        isVisible: true,
      ),
    );
  }

  void _blockUser() {
    if (_otherUser == null) return;

    showDialog(
      context: context,
      builder: (context) => ConfirmationModal(
        title: widget.labels?.blockUser ?? 'Block User',
        message: widget.labels != null
            ? widget.labels!.areYouSureBlockUser.replaceAll(
                '{name}',
                _otherUser!.name,
              )
            : 'Are you sure you want to block ${_otherUser!.name}?',
        isDestructive: true,
        onConfirm: () {
          Navigator.of(context).pop();
          widget.onBlockUser?.call(_otherUser!.id);
        },
        onCancel: () => Navigator.of(context).pop(),
        isVisible: true,
      ),
    );
  }

  void _showImageUploadDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusLargeValue,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.translate('upload_image'),
                          style: AppTextStyles.titleMediumStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    ImageUpload(
                      multiple: false,
                      showCloudinary: true,
                      onImagesChanged: (images) {
                        if (images.isNotEmpty) {
                          setState(() {
                            _selectedImage = images.first;
                          });
                          Navigator.pop(context);
                        }
                      },
                      onFetchCloudinaryImages: () =>
                          _cloudinaryApi.fetchImages(),
                      onFileSelected: ({filePath, fileBytes, fileName}) async {
                        try {
                          String? url;
                          if (fileBytes != null) {
                            url = await _cloudinaryApi.uploadFile(
                              fileBytes: fileBytes,
                              fileName: fileName,
                            );
                          } else if (filePath != null) {
                            url = await _cloudinaryApi.uploadFile(
                              filePath: filePath,
                            );
                          }

                          if (url != null && mounted) {
                            setState(() {
                              _selectedImage = url;
                            });
                            if (Navigator.canPop(context))
                              Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? ChatScreenLabels.forLanguage(currentLanguage);
    final isAdmin = widget.user?.role == 'admin';

    return PageLayout(
      showCartButton: false, // Match Vue chat layout (no floating cart button)
      scrollable: false, // Chat manages its own internal scrolling
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF111827), // gray-900
                    const Color(0xFF1F2937), // gray-800
                  ]
                : [
                    const Color(0xFFFFFBEB), // amber-50
                    Colors.white,
                  ],
          ),
        ),
        child: Column(
          children: [
            if (_error != null && _error!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF991B1B).withAlpha(64) // red-900/25
                        : const Color(0xFFFEF2F2), // red-50
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFDC2626).withAlpha(128) // red-600/50
                          : const Color(0xFFFCA5A5), // red-300
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodySmallStyle(
                      color: isDark
                          ? const Color(0xFFFCA5A5)
                          : const Color(0xFFDC2626),
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ),
              ),
            // Title
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLG,
                  ), // px-4
                  child: Text(
                    isAdmin ? labels.customerChat : labels.messages,
                    style:
                        AppTextStyles.titleLargeStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827), // gray-900
                          fontWeight: FontWeight.bold, // font-bold
                        ).copyWith(
                          fontSize: 36, // text-4xl
                        ),
                  ),
                ),
              ),
            ),

            // Chat Container
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG,
                ), // px-4
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 768) {
                      // Desktop: Side by side
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Sidebar - Conversations List
                          SizedBox(
                            width: 320, // w-80
                            child: _buildConversationsSidebar(isDark, labels),
                          ),
                          const SizedBox(width: AppTheme.spacingLG), // gap-4
                          // Right Side - Chat Area
                          Expanded(
                            child: _selectedConversationId == null
                                ? _buildEmptyChatState(isDark, labels)
                                : _buildChatArea(isDark, labels),
                          ),
                        ],
                      );
                    } else {
                      // Mobile: Stacked or single view
                      return _selectedConversationId == null
                          ? _buildConversationsSidebar(isDark, labels)
                          : _buildChatArea(isDark, labels);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsSidebar(bool isDark, ChatScreenLabels labels) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withAlpha(77) // amber-900/30
              : const Color(0xFFFEF3C7), // amber-100
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Conversations
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF78350F) // amber-900
                      : const Color(0xFFFEF3C7), // amber-100
                  width: 2,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: labels.searchUsers,
                prefixIcon: const Icon(Icons.search, size: 16), // w-4 h-4
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF374151) // gray-700
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF92400E) // amber-800
                        : const Color(0xFFFDE68A), // amber-200
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF92400E) // amber-800
                        : const Color(0xFFFDE68A), // amber-200
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  borderSide: const BorderSide(
                    color: Color(0xFFD97706), // amber-500
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG,
                  vertical: AppTheme.spacingSM, // py-2
                ),
                hintStyle: AppTextStyles.bodySmallStyle(
                  color: const Color(0xFF9CA3AF), // gray-400
                ),
              ),
              style: AppTextStyles.bodySmallStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827), // gray-900
              ),
            ),
          ),

          // Conversations List
          Expanded(
            child: _loadingConversationsState
                ? Center(
                    child: Text(
                      labels.loading,
                      style: AppTextStyles.bodyMediumStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF) // gray-400
                            : const Color(0xFF4B5563), // gray-600
                      ),
                    ),
                  )
                : _filteredConversations.isEmpty
                ? Center(
                    child: Text(
                      labels.noConversations,
                      style: AppTextStyles.bodyMediumStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF) // gray-400
                            : const Color(0xFF4B5563), // gray-600
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredConversations.length,
                    itemBuilder: (context, index) {
                      final conv = _filteredConversations[index];
                      final isSelected =
                          _selectedConversationId == (conv.id ?? conv.userId);
                      return _buildConversationItem(
                        conv,
                        isSelected,
                        isDark,
                        labels,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(
    ConversationData conv,
    bool isSelected,
    bool isDark,
    ChatScreenLabels labels,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectConversation(conv),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? const Color(0xFF78350F).withAlpha(51) // amber-900/20
                      : const Color(0xFFFFFBEB)) // amber-50
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? const Color(0xFF374151) // gray-700
                    : const Color(0xFFE5E7EB), // gray-200
              ),
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 48, // w-12
                    height: 48, // h-12
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF92400E), // amber-800
                                const Color(0xFFD97706), // amber-600
                              ]
                            : [
                                const Color(0xFFFDE68A), // amber-200
                                const Color(0xFFFCD34D), // amber-400
                              ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: _getConversationAvatar(conv) != null
                        ? ClipOval(
                            child: Image.network(
                              _getConversationAvatar(conv)!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person,
                                    size: 24,
                                    color: isDark
                                        ? const Color(0xFFFCD34D) // amber-100
                                        : const Color(0xFF78350F), // amber-900
                                  ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 24,
                            color: isDark
                                ? const Color(0xFFFCD34D) // amber-100
                                : const Color(0xFF78350F), // amber-900
                          ),
                  ),
                  // Online Status Indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12, // w-3
                      height: 12, // h-3
                      decoration: BoxDecoration(
                        color: conv.user?.isOnline == true
                            ? const Color(0xFF22C55E) // green-500
                            : const Color(0xFF9CA3AF), // gray-400
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1F2937) // gray-800
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spacingMD), // space-x-3
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getConversationName(conv),
                            style: AppTextStyles.bodyMediumStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827), // gray-900
                              fontWeight: AppTextStyles.medium,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_hasUnread(conv) && (conv.unreadCount ?? 0) > 0)
                          Container(
                            width: 20, // w-5
                            height: 20, // h-5
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444), // red-500
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (conv.unreadCount ?? 0) > 99
                                    ? '99+'
                                    : '${conv.unreadCount}',
                                style:
                                    AppTextStyles.labelSmallStyle(
                                      color: Colors.white,
                                    ).copyWith(
                                      fontSize: 10, // text-xs
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conv.lastMessage?.message ?? labels.noMessages,
                      style: AppTextStyles.bodySmallStyle(
                        color: isDark
                            ? const Color(0xFF6B7280) // gray-500
                            : const Color(0xFF6B7280), // gray-500
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(
                        conv.lastMessage?.createdAt,
                        _hasUnread(conv),
                      ),
                      style: AppTextStyles.bodySmallStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF) // gray-400
                            : const Color(0xFF9CA3AF), // gray-400
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChatState(bool isDark, ChatScreenLabels labels) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withAlpha(77) // amber-900/30
              : const Color(0xFFFEF3C7), // amber-100
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64, // w-16 h-16
              color: const Color(0xFF9CA3AF), // gray-400
            ),
            const SizedBox(height: AppTheme.spacingLG), // mb-4
            Text(
              widget.isGuestMode
                  ? labels.noMessagesYet
                  : labels.selectUserToChat,
              style: AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? const Color(0xFF6B7280) // gray-500
                    : const Color(0xFF6B7280), // gray-500
              ),
            ),
            if (widget.isGuestMode) ...[
              const SizedBox(height: AppTheme.spacingSM), // mb-2
              Text(
                labels.messagesWillAppearHere,
                style: AppTextStyles.bodySmallStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF) // gray-400
                      : const Color(0xFF9CA3AF), // gray-400
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea(bool isDark, ChatScreenLabels labels) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withAlpha(77) // amber-900/30
              : const Color(0xFFFEF3C7), // amber-100
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat Header
          _buildChatHeader(isDark, labels),

          // Messages
          Expanded(child: _buildMessagesList(isDark, labels)),

          // Message Input
          _buildMessageInput(isDark, labels),
        ],
      ),
    );
  }

  Widget _buildChatHeader(bool isDark, ChatScreenLabels labels) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF92400E), // amber-800
            const Color(0xFF78350F), // amber-900
          ],
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 40, // w-10
                height: 40, // h-10
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFDE68A), // amber-200
                      const Color(0xFFFCD34D), // amber-400
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: _otherUser?.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _otherUser!.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person,
                                size: 20,
                                color: Color(0xFF78350F),
                              ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 20,
                        color: Color(0xFF78350F),
                      ),
              ),
              // Online Status
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12, // w-3
                  height: 12, // h-3
                  decoration: BoxDecoration(
                    color: _otherUser?.isOnline == true
                        ? const Color(0xFF22C55E) // green-500
                        : const Color(0xFF9CA3AF), // gray-400
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF92400E), // amber-800
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spacingMD), // space-x-3
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherUser?.name ?? 'User',
                  style: AppTextStyles.titleMediumStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_otherUser?.email != null)
                  Text(
                    _otherUser!.email!,
                    style: AppTextStyles.bodySmallStyle(
                      color: const Color(0xFFFCD34D), // amber-200
                    ),
                  ),
              ],
            ),
          ),

          // Menu Button
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 20,
            ), // w-5 h-5
            color: isDark
                ? const Color(0xFF1F2937) // gray-800
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusLargeValue,
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  if (_otherUser != null) {
                    widget.onViewProfile?.call(_otherUser!.id);
                  }
                  break;
                case 'clear':
                  _clearChat();
                  break;
                case 'block':
                  _blockUser();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Text(
                  labels.viewProfile,
                  style: AppTextStyles.bodySmallStyle(
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: Text(
                  labels.clearChat,
                  style: AppTextStyles.bodySmallStyle(
                    color: isDark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF374151),
                  ),
                ),
              ),
              if (widget.user?.role == 'admin')
                PopupMenuItem(
                  value: 'block',
                  child: Text(
                    labels.blockUser,
                    style: AppTextStyles.bodySmallStyle(
                      color: const Color(0xFFDC2626), // red-600
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark, ChatScreenLabels labels) {
    if (_loadingMessagesState) {
      return Center(
        child: Text(
          labels.loading,
          style: AppTextStyles.bodyMediumStyle(
            color: isDark
                ? const Color(0xFF9CA3AF) // gray-400
                : const Color(0xFF4B5563), // gray-600
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          labels.noMessages,
          style: AppTextStyles.bodyMediumStyle(
            color: isDark
                ? const Color(0xFF9CA3AF) // gray-400
                : const Color(0xFF4B5563), // gray-600
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _messagesScrollController,
      padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isSent = message.fromUserId == widget.user?.id;
        return Padding(
          padding: const EdgeInsets.only(
            bottom: AppTheme.spacingLG,
          ), // space-y-4
          child: Row(
            mainAxisAlignment: isSent
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isSent) ...[
                // Avatar (only for received messages)
                Container(
                  width: 32, // w-8
                  height: 32, // h-8
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF92400E), // amber-800
                              const Color(0xFFD97706), // amber-600
                            ]
                          : [
                              const Color(0xFFFDE68A), // amber-200
                              const Color(0xFFFCD34D), // amber-400
                            ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 20, // w-5 h-5
                    color: isDark
                        ? const Color(0xFFFCD34D) // amber-100
                        : const Color(0xFF78350F), // amber-900
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM), // space-x-2
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isSent
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Message Bubble
                    Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            MediaQuery.of(context).size.width *
                            0.7, // max-w-[70%]
                      ),
                      padding: const EdgeInsets.all(AppTheme.spacingMD), // p-3
                      decoration: BoxDecoration(
                        gradient: isSent
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFFD97706), // amber-600
                                  const Color(0xFFB45309), // amber-700
                                ],
                              )
                            : null,
                        color: isSent
                            ? null
                            : (isDark
                                  ? const Color(0xFF374151) // gray-700
                                  : const Color(0xFFF3F4F6)), // gray-100
                        borderRadius: AppTheme.borderRadiusLargeValue,
                        border: _getOrderStatusBorder(message, isDark),
                        boxShadow: _getOrderStatusShadow(message),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: AppTextStyles.bodyMediumStyle(
                              color: isSent
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF111827)),
                            ),
                          ),
                          if (message.imageUrl != null) ...[
                            const SizedBox(height: AppTheme.spacingSM), // mt-2
                            ClipRRect(
                              borderRadius: AppTheme.borderRadiusLargeValue,
                              child: Image.network(
                                message.imageUrl!,
                                width: double.infinity,
                                height: 256, // max-h-64
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Timestamp and Read Receipt
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 4, // mt-1
                        left: 4, // px-1
                        right: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isSent
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Text(
                            _formatMessageTime(message.createdAt),
                            style: AppTextStyles.bodySmallStyle(
                              color: isDark
                                  ? const Color(0xFF6B7280) // gray-500
                                  : const Color(0xFF6B7280), // gray-500
                            ),
                          ),
                          if (isSent && message.isRead == true) ...[
                            const SizedBox(width: 8), // gap-2
                            const Text(
                              '✓✓',
                              style: TextStyle(
                                color: Color(0xFF3B82F6), // blue-500
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSent) ...[
                const SizedBox(width: AppTheme.spacingSM), // space-x-2
              ],
            ],
          ),
        );
      },
    );
  }

  Border? _getOrderStatusBorder(MessageData message, bool isDark) {
    if (message.orderId != null &&
        message.fromUserId != widget.user?.id &&
        message.sender?.role == 'admin') {
      if (message.order?.paymentStatus == 'approved' ||
          message.order?.status == 'processing') {
        return Border.all(
          color: isDark
              ? const Color(0xFF16A34A) // green-600
              : const Color(0xFF86EFAC), // green-300
          width: 2,
        );
      } else if (message.order?.paymentStatus == 'rejected' ||
          message.order?.status == 'cancelled') {
        return Border.all(
          color: isDark
              ? const Color(0xFFDC2626) // red-600
              : const Color(0xFFFCA5A5), // red-300
          width: 2,
        );
      }
    }
    return null;
  }

  List<BoxShadow>? _getOrderStatusShadow(MessageData message) {
    if (message.orderId != null &&
        message.fromUserId != widget.user?.id &&
        message.sender?.role == 'admin') {
      if (message.order?.paymentStatus == 'approved' ||
          message.order?.status == 'processing') {
        return [
          BoxShadow(
            color: const Color(0xFF22C55E).withAlpha(128), // green-500/50
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ];
      } else if (message.order?.paymentStatus == 'rejected' ||
          message.order?.status == 'cancelled') {
        return [
          BoxShadow(
            color: const Color(0xFFEF4444).withAlpha(128), // red-500/50
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ];
      }
    }
    return null;
  }

  Widget _buildMessageInput(bool isDark, ChatScreenLabels labels) {
    if (widget.isGuestMode) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF78350F) // amber-900
                  : const Color(0xFFFEF3C7), // amber-100
              width: 2,
            ),
          ),
          color: isDark
              ? const Color(0xFF111827).withAlpha(128) // gray-900/50
              : const Color(0xFFF9FAFB), // gray-50
        ),
        child: Column(
          children: [
            Text(
              labels.readOnlyMode,
              style: AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? const Color(0xFF4B5563) // gray-600
                    : const Color(0xFF4B5563), // gray-600
                fontWeight: AppTextStyles.medium,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM), // mb-2
            Text(
              labels.createAccountToChat,
              style: AppTextStyles.bodySmallStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF) // gray-400
                    : const Color(0xFF9CA3AF), // gray-400
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD), // mb-3
            WoodButton(
              onPressed: widget.onLoginTap,
              variant: WoodButtonVariant.outline,
              size: WoodButtonSize.sm,
              child: Text('${labels.signIn} / ${labels.signUp}'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF78350F) // amber-900
                : const Color(0xFFFEF3C7), // amber-100
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Image Preview
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    child: Image.network(
                      _selectedImage!,
                      width: 128,
                      height: 128,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: const Color(0xFFEF4444),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () => setState(() => _selectedImage = null),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Image Upload Button
              IconButton(
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: isDark
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFFD97706),
                ),
                onPressed: () => _showImageUploadDialog(isDark),
              ),
              const SizedBox(width: AppTheme.spacingXS),
              // Message Input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: labels.typeYourMessage,
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF374151) // gray-700
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusLargeValue,
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF92400E) // amber-800
                            : const Color(0xFFFDE68A), // amber-200
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusLargeValue,
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF92400E) // amber-800
                            : const Color(0xFFFDE68A), // amber-200
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppTheme.borderRadiusLargeValue,
                      borderSide: const BorderSide(
                        color: Color(0xFFD97706), // amber-500
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLG, // px-4
                      vertical: AppTheme.spacingSM, // py-2
                    ),
                    hintStyle: AppTextStyles.bodyMediumStyle(
                      color: const Color(0xFF9CA3AF), // gray-400
                    ),
                  ),
                  style: AppTextStyles.bodyMediumStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF111827), // gray-900
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM), // gap-2
              // Send Button
              WoodButton(
                onPressed:
                    (_messageController.text.trim().isEmpty || _sendingMessage)
                    ? null
                    : _sendMessage,
                size: WoodButtonSize.sm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_sendingMessage)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.send,
                        size: 16,
                        color: Colors.white,
                      ), // size-16
                    const SizedBox(width: 8),
                    Text(
                      labels.send,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Selected Image Preview
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSM), // mt-2
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    child: Image.network(
                      _selectedImage!,
                      width: 128, // w-32
                      height: 128, // h-32
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    top: 4, // top-1
                    right: 4, // right-1
                    child: Material(
                      color: const Color(0xFFEF4444), // red-500
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(4), // p-1
                          child: Icon(
                            Icons.close,
                            size: 16, // w-4 h-4
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      if (widget.isGuestMode || widget.user == null) return;
      await _refreshConversations(silent: true);
      final selected = _selectedConversationId;
      if (selected != null) {
        await _refreshMessages(selected, silent: true);
      }
    });
  }

  Future<void> _refreshConversations({bool silent = false}) async {
    if (!silent) setState(() => _loadingConversationsState = true);
    try {
      final raw = await _chatApi.fetchConversations();
      var mapped = raw.map(_mapConversation).toList();

      // If user has no conversations yet, show admins so they can start chatting.
      if (mapped.isEmpty) {
        final adminsRaw = await _chatApi.fetchAdmins();
        mapped = adminsRaw.map((a) {
          final id = (a['id'] ?? '').toString();
          final name = (a['name'] ?? 'Admin').toString();
          final email = (a['email'] ?? '').toString();
          return ConversationData(
            id: id,
            userId: id,
            user: ChatUserData(
              id: id,
              name: name,
              email: email,
              role: 'admin',
              isOnline: true,
            ),
            lastMessage: null,
            unreadCount: 0,
            messages: const [],
          );
        }).toList();
      }

      if (mounted) {
        setState(() {
          _conversationsState = mapped;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _loadingConversationsState = false);
      }
    }
  }

  Future<void> _refreshMessages(
    String otherUserId, {
    bool silent = false,
  }) async {
    if (!silent) setState(() => _loadingMessagesState = true);
    try {
      final raw = await _chatApi.fetchMessages(otherUserId);
      final mapped = raw.map(_mapMessage).toList();
      if (mounted) {
        setState(() {
          _messagesState = mapped;
          _error = null;
        });
      }
      // mark read best-effort
      unawaited(_chatApi.markRead(otherUserId));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _loadingMessagesState = false);
      }
    }
  }

  ConversationData _mapConversation(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map
        ? Map<String, dynamic>.from(user)
        : const <String, dynamic>{};
    final last = json['last_message'];
    final lastMap = last is Map ? Map<String, dynamic>.from(last) : null;

    final userId = (userMap['id'] ?? json['id'] ?? '').toString();
    return ConversationData(
      id: (json['id'] ?? userId).toString(),
      userId: userId,
      orderId: json['order']?['id']?.toString() ?? json['order_id']?.toString(),
      user: ChatUserData(
        id: userId,
        name: (userMap['name'] ?? 'User').toString(),
        email: userMap['email']?.toString(),
        avatarUrl: userMap['avatar_url']?.toString(),
        role: userMap['role']?.toString(),
        isOnline: userMap['is_online'] == true,
      ),
      lastMessage: lastMap == null
          ? null
          : MessageData(
              id: (lastMap['id'] ?? '').toString(),
              fromUserId: (lastMap['from_user_id'] ?? '').toString(),
              toUserId: (lastMap['to_user_id'] ?? '').toString(),
              message: (lastMap['message'] ?? '').toString(),
              imageUrl: lastMap['image_url']?.toString(),
              createdAt: lastMap['created_at']?.toString(),
              isRead: lastMap['is_read'] == true,
            ),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      messages: const [],
    );
  }

  MessageData _mapMessage(Map<String, dynamic> json) {
    Map<String, dynamic>? mapOrNull(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

    final sender = mapOrNull(json['sender']);
    final receiver = mapOrNull(json['receiver']);
    final order = mapOrNull(json['order']);

    return MessageData(
      id: (json['id'] ?? '').toString(),
      fromUserId: (json['from_user_id'] ?? '').toString(),
      toUserId: (json['to_user_id'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: json['created_at']?.toString(),
      isRead: json['is_read'] == true,
      orderId: json['order_id']?.toString(),
      order: order == null
          ? null
          : OrderData(
              id: (order['id'] ?? '').toString(),
              status: order['status']?.toString(),
              paymentStatus: order['payment_status']?.toString(),
            ),
      sender: sender == null
          ? null
          : ChatUserData(
              id: (sender['id'] ?? '').toString(),
              name: (sender['name'] ?? 'User').toString(),
              email: sender['email']?.toString(),
              avatarUrl: sender['avatar_url']?.toString(),
              role: sender['role']?.toString(),
              isOnline: sender['is_online'] == true,
            ),
      receiver: receiver == null
          ? null
          : ChatUserData(
              id: (receiver['id'] ?? '').toString(),
              name: (receiver['name'] ?? 'User').toString(),
              email: receiver['email']?.toString(),
              avatarUrl: receiver['avatar_url']?.toString(),
              role: receiver['role']?.toString(),
              isOnline: receiver['is_online'] == true,
            ),
    );
  }
}

/// ChatUserData - User data model
class ChatUserData {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? role;
  final bool? isOnline;

  const ChatUserData({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.role,
    this.isOnline,
  });
}

/// ConversationData - Conversation data model
class ConversationData {
  final String? id;
  final String? userId;
  final String? orderId;
  final ChatUserData? user;
  final MessageData? lastMessage;
  final int? unreadCount;
  final List<MessageData>? messages;

  const ConversationData({
    this.id,
    this.userId,
    this.orderId,
    this.user,
    this.lastMessage,
    this.unreadCount,
    this.messages,
  });
}

/// MessageData - Message data model
class MessageData {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String message;
  final String? imageUrl;
  final String? createdAt;
  final bool? isRead;
  final String? orderId;
  final OrderData? order;
  final ChatUserData? sender;
  final ChatUserData? receiver;

  const MessageData({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    this.imageUrl,
    this.createdAt,
    this.isRead,
    this.orderId,
    this.order,
    this.sender,
    this.receiver,
  });
}

/// OrderData - Order data model
class OrderData {
  final String id;
  final String? status;
  final String? paymentStatus;

  const OrderData({required this.id, this.status, this.paymentStatus});
}

/// ChatScreenLabels - Localization labels
class ChatScreenLabels {
  final String customerChat;
  final String messages;
  final String searchUsers;
  final String loading;
  final String noConversations;
  final String noMessages;
  final String noMessagesYet;
  final String selectUserToChat;
  final String messagesWillAppearHere;
  final String readOnlyMode;
  final String createAccountToChat;
  final String signIn;
  final String signUp;
  final String typeYourMessage;
  final String send;
  final String viewProfile;
  final String clearChat;
  final String areYouSureClearChat;
  final String blockUser;
  final String areYouSureBlockUser;

  const ChatScreenLabels({
    required this.customerChat,
    required this.messages,
    required this.searchUsers,
    required this.loading,
    required this.noConversations,
    required this.noMessages,
    required this.noMessagesYet,
    required this.selectUserToChat,
    required this.messagesWillAppearHere,
    required this.readOnlyMode,
    required this.createAccountToChat,
    required this.signIn,
    required this.signUp,
    required this.typeYourMessage,
    required this.send,
    required this.viewProfile,
    required this.clearChat,
    required this.areYouSureClearChat,
    required this.blockUser,
    required this.areYouSureBlockUser,
  });

  factory ChatScreenLabels.defaultLabels() {
    return ChatScreenLabels.forLanguage('en');
  }

  factory ChatScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return ChatScreenLabels(
      customerChat: isArabic ? 'دردشة العملاء' : 'Customer Chat',
      messages: isArabic ? 'الرسائل' : 'Messages',
      searchUsers: isArabic ? 'ابحث عن المستخدمين' : 'Search users',
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      noConversations: isArabic ? 'لا توجد محادثات' : 'No conversations',
      noMessages: isArabic ? 'لا توجد رسائل' : 'No messages',
      noMessagesYet: isArabic ? 'لا توجد رسائل بعد' : 'No messages yet',
      selectUserToChat: isArabic
          ? 'اختر مستخدماً لبدء الدردشة'
          : 'Select a user to start chatting',
      messagesWillAppearHere: isArabic
          ? 'ستظهر الرسائل المتعلقة بطلباتك هنا'
          : 'Messages about your orders will appear here',
      readOnlyMode: isArabic ? 'وضع القراءة فقط' : 'Read-only mode',
      createAccountToChat: isArabic
          ? 'قم بإنشاء حساب لإرسال الرسائل والدردشة مع الدعم'
          : 'Create an account to send messages and chat with support',
      signIn: isArabic ? 'تسجيل الدخول' : 'Sign In',
      signUp: isArabic ? 'سجل' : 'Sign Up',
      typeYourMessage: isArabic ? 'اكتب رسالتك' : 'Type your message',
      send: isArabic ? 'إرسال' : 'Send',
      viewProfile: isArabic ? 'عرض الملف الشخصي' : 'View Profile',
      clearChat: isArabic ? 'مسح المحادثة' : 'Clear Chat',
      areYouSureClearChat: isArabic
          ? 'هل أنت متأكد أنك تريد مسح هذه المحادثة؟'
          : 'Are you sure you want to clear this chat?',
      blockUser: isArabic ? 'حظر المستخدم' : 'Block User',
      areYouSureBlockUser: isArabic
          ? 'هل أنت متأكد أنك تريد حظر {name}؟'
          : 'Are you sure you want to block {name}?',
    );
  }
}
