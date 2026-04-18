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

/// ChatWindowScreen - Support chat window screen
///
/// Equivalent to Vue's ChatWindow.vue page.
/// Displays a chat interface with conversations list and active chat.
///
/// Features:
/// - Conversations list sidebar with search
/// - Active chat area with messages
/// - Message input with image support
/// - User menu (view profile, clear chat, block user)
/// - Unread message counts
/// - Online status indicators
/// - Dark mode support
/// - Responsive design
class ChatWindowScreen extends ConsumerStatefulWidget {
  /// Mock user data
  final ChatWindowUserData? user;

  /// Mock conversations data
  final List<ChatWindowConversationData>? conversations;

  /// Mock messages data (for selected conversation)
  final List<ChatWindowMessageData>? messages;

  /// Selected conversation ID
  final String? initialConversationId;

  /// Callback when conversation is selected
  final void Function(String conversationId)? onConversationSelected;

  /// Callback when message is sent
  final void Function(String conversationId, String message, String? imageUrl)?
  onSendMessage;

  /// Callback when profile is viewed
  final void Function(String userId)? onViewProfile;

  /// Callback when chat is cleared
  final void Function(String conversationId)? onClearChat;

  /// Callback when user is blocked (admin only)
  final void Function(String userId)? onBlockUser;

  /// Message time formatter function
  final String Function(DateTime date)? formatMessageTime;

  /// Conversation time formatter function
  final String Function(DateTime? date, bool isUnread)? formatConversationTime;

  /// Labels for localization
  final ChatWindowScreenLabels? labels;

  const ChatWindowScreen({
    super.key,
    this.user,
    this.conversations,
    this.messages,
    this.initialConversationId,
    this.onConversationSelected,
    this.onSendMessage,
    this.onViewProfile,
    this.onClearChat,
    this.onBlockUser,
    this.formatMessageTime,
    this.formatConversationTime,
    this.labels,
  });

  @override
  ConsumerState<ChatWindowScreen> createState() => _ChatWindowScreenState();
}

class _ChatWindowScreenState extends ConsumerState<ChatWindowScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedConversationId;
  ChatWindowUserData? _otherUser;
  List<ChatWindowMessageData> _messages = [];
  List<ChatWindowConversationData> _conversations = [];
  bool _loadingConversations = false;
  bool _loadingMessages = false;
  bool _sendingMessage = false;
  String? _error;
  bool _showMenu = false;
  String? _selectedImagePath;
  Timer? _pollTimer;
  final _chatApi = LaravelChatApiService();
  final _cloudinaryApi = LaravelCloudinaryApiService();

  @override
  void initState() {
    super.initState();
    _selectedConversationId = widget.initialConversationId;
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
    await _refreshConversations();
    if (_selectedConversationId != null) {
      await _selectConversation(_selectedConversationId!);
    }
    _startPolling();
  }

  List<ChatWindowConversationData> get _filteredConversations {
    if (_searchQuery.isEmpty) {
      return _conversations;
    }
    final query = _searchQuery.toLowerCase();
    return _conversations.where((conv) {
      final name = conv.user.name.toLowerCase();
      final lastMessage = conv.lastMessage?.message.toLowerCase() ?? '';
      return name.contains(query) || lastMessage.contains(query);
    }).toList();
  }

  String _formatMessageTime(DateTime date) {
    return widget.formatMessageTime?.call(date) ??
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatConversationTime(DateTime? date, bool isUnread) {
    if (isUnread) return 'New';
    if (date == null) return '';
    return widget.formatConversationTime?.call(date, isUnread) ??
        _formatRelativeTime(date);
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hr';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _selectConversation(String conversationId) async {
    setState(() {
      _selectedConversationId = conversationId;
      final conversation = _conversations.firstWhere(
        (c) => c.id == conversationId || c.user.id == conversationId,
        orElse: () => _conversations.first,
      );
      _otherUser = conversation.user;
      _showMenu = false;
    });
    widget.onConversationSelected?.call(conversationId);
    await _refreshMessages(conversationId);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if ((message.isEmpty && _selectedImagePath == null) ||
        _selectedConversationId == null) {
      return;
    }
    if (_sendingMessage) return;
    setState(() => _sendingMessage = true);
    try {
      await _chatApi.sendMessage(
        toUserId: _selectedConversationId!,
        message: message,
        imageUrl: _selectedImagePath,
      );
      widget.onSendMessage?.call(
        _selectedConversationId!,
        message,
        _selectedImagePath,
      );
      _messageController.clear();
      _selectedImagePath = null;
      await _refreshConversations(silent: true);
      await _refreshMessages(_selectedConversationId!, silent: true);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
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

  void _clearChat() async {
    if (_selectedConversationId == null) return;

    final confirmed = await ConfirmationModalService.instance.showConfirmation(
      context: context,
      title: widget.labels?.clearThisChat ?? 'Clear this chat',
      message:
          widget.labels?.areYouSureClearChat ??
          'Are you sure you want to clear this chat?',
      confirmText: widget.labels?.clearChat ?? 'Clear',
      isDestructive: true,
    );

    if (confirmed == true) {
      // Best-effort delete from backend to match Vue behavior.
      for (final m in List<ChatWindowMessageData>.from(_messages)) {
        try {
          await _chatApi.deleteMessage(m.id);
        } catch (_) {}
      }
      setState(() {
        _messages = [];
      });
      widget.onClearChat?.call(_selectedConversationId!);
    }
  }

  void _blockUser() async {
    if (_otherUser == null) return;

    final confirmed = await ConfirmationModalService.instance.showConfirmation(
      context: context,
      title: widget.labels?.blockUser ?? 'Block user',
      message:
          (widget.labels?.areYouSureBlockUser ??
                  'Are you sure you want to block {name}?')
              .replaceAll('{name}', _otherUser!.name),
      confirmText: widget.labels?.blockUser ?? 'Block',
      isDestructive: true,
    );

    if (confirmed == true) {
      widget.onBlockUser?.call(_otherUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels =
        widget.labels ?? ChatWindowScreenLabels.forLanguage(currentLanguage);

    return PageLayout(
      showCartButton: false, // Match Vue chat layout
      scrollable: false, // Full-height chat with internal scrolling
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
                        ? const Color(0xFF991B1B).withAlpha(64)
                        : const Color(0xFFFEF2F2),
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFFDC2626).withAlpha(128)
                          : const Color(0xFFFCA5A5),
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
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLG,
                  ), // px-4
                  child: Text(
                    labels.contactSupport,
                    style:
                        AppTextStyles.titleLargeStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111827), // gray-900
                          fontWeight: FontWeight.bold,
                        ).copyWith(
                          fontSize: AppTextStyles.text4XL, // text-4xl
                        ),
                  ),
                ),
              ),
            ),

            // Main Chat Container
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG,
                ), // px-4
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 768) {
                      // Mobile: Stack conversations and chat
                      return _buildMobileLayout(isDark, labels);
                    }
                    // Desktop: Side by side
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Conversations Sidebar
                        SizedBox(
                          width: 320, // w-80
                          child: _buildConversationsSidebar(isDark, labels),
                        ),
                        const SizedBox(width: AppTheme.spacingLG), // gap-4
                        // Chat Area
                        Expanded(child: _buildChatArea(isDark, labels)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(bool isDark, ChatWindowScreenLabels labels) {
    if (_selectedConversationId == null) {
      return _buildConversationsSidebar(isDark, labels);
    }
    return _buildChatArea(isDark, labels);
  }

  Widget _buildConversationsSidebar(
    bool isDark,
    ChatWindowScreenLabels labels,
  ) {
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
          // Search
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
            child: _loadingConversations
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
                          _selectedConversationId == conv.id ||
                          _selectedConversationId == conv.user.id;
                      final hasUnread = conv.unreadCount > 0;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectConversation(conv.id),
                          child: Container(
                            padding: const EdgeInsets.all(
                              AppTheme.spacingLG,
                            ), // p-4
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                        ? const Color(0xFF78350F).withAlpha(
                                            51,
                                          ) // amber-900/20
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
                                                  const Color(
                                                    0xFF92400E,
                                                  ), // amber-800
                                                  const Color(
                                                    0xFFD97706,
                                                  ), // amber-600
                                                ]
                                              : [
                                                  const Color(
                                                    0xFFFDE68A,
                                                  ), // amber-200
                                                  const Color(
                                                    0xFFFCD34D,
                                                  ), // amber-400
                                                ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: conv.user.avatarUrl != null
                                          ? ClipOval(
                                              child: Image.network(
                                                conv.user.avatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Icon(
                                                      Icons.person,
                                                      size: 24,
                                                      color: isDark
                                                          ? const Color(
                                                              0xFFFCD34D,
                                                            ) // amber-100
                                                          : const Color(
                                                              0xFF78350F,
                                                            ), // amber-900
                                                    ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 24,
                                              color: isDark
                                                  ? const Color(
                                                      0xFFFCD34D,
                                                    ) // amber-100
                                                  : const Color(
                                                      0xFF78350F,
                                                    ), // amber-900
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
                                          color: conv.user.isOnline
                                              ? const Color(
                                                  0xFF22C55E,
                                                ) // green-500
                                              : const Color(
                                                  0xFF9CA3AF,
                                                ), // gray-400
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(
                                                    0xFF1F2937,
                                                  ) // gray-800
                                                : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  width: AppTheme.spacingMD,
                                ), // space-x-3
                                // User Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              conv.user.name,
                                              style:
                                                  AppTextStyles.bodyMediumStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF111827,
                                                          ), // gray-900
                                                    fontWeight:
                                                        AppTextStyles.medium,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (hasUnread)
                                            Container(
                                              width: 20, // w-5
                                              height: 20, // h-5
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFEF4444,
                                                ), // red-500
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  conv.unreadCount > 99
                                                      ? '99+'
                                                      : conv.unreadCount
                                                            .toString(),
                                                  style:
                                                      AppTextStyles.bodySmallStyle(
                                                        color: Colors.white,
                                                      ).copyWith(fontSize: 10),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingXS,
                                      ), // mb-1
                                      Text(
                                        conv.lastMessage?.message ??
                                            labels.noMessages,
                                        style: AppTextStyles.bodySmallStyle(
                                          color: isDark
                                              ? const Color(
                                                  0xFF6B7280,
                                                ) // gray-500
                                              : const Color(
                                                  0xFF6B7280,
                                                ), // gray-500
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(
                                        height: AppTheme.spacingXS,
                                      ), // mt-1
                                      Text(
                                        _formatConversationTime(
                                          conv.lastMessage?.createdAt,
                                          hasUnread,
                                        ),
                                        style: AppTextStyles.bodySmallStyle(
                                          color: isDark
                                              ? const Color(
                                                  0xFF9CA3AF,
                                                ) // gray-400
                                              : const Color(
                                                  0xFF9CA3AF,
                                                ), // gray-400
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(bool isDark, ChatWindowScreenLabels labels) {
    if (_selectedConversationId == null) {
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 64, // w-16 h-16
                color: const Color(0xFF9CA3AF), // gray-400
              ),
              const SizedBox(height: AppTheme.spacingLG), // mb-4
              Text(
                labels.selectUserToChat,
                style: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF) // gray-400
                      : const Color(0xFF6B7280), // gray-500
                ),
              ),
            ],
          ),
        ),
      );
    }

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

  Widget _buildChatHeader(bool isDark, ChatWindowScreenLabels labels) {
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
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 20,
                            color: const Color(0xFF78350F), // amber-900
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 20,
                        color: const Color(0xFF78350F), // amber-900
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
                Text(
                  _otherUser?.email ?? '',
                  style: AppTextStyles.bodySmallStyle(
                    color: const Color(0xFFFCD34D), // amber-200
                  ),
                ),
              ],
            ),
          ),

          // Menu Button
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showMenu = !_showMenu;
                  });
                },
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 20,
                ), // w-5 h-5
              ),
              if (_showMenu)
                Positioned(
                  top: 40,
                  right: 0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final menuWidth = constraints.maxWidth > 400
                          ? 192.0
                          : (constraints.maxWidth - 16).clamp(
                              150.0,
                              192.0,
                            ); // Responsive width
                      return Container(
                        width: menuWidth,
                        constraints: const BoxConstraints(
                          maxWidth: 192,
                        ), // Max width constraint
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1F2937) // gray-800
                              : Colors.white,
                          borderRadius: AppTheme.borderRadiusLargeValue,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF374151) // gray-700
                                : const Color(0xFFE5E7EB), // gray-200
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // View Profile
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _showMenu = false);
                                  if (_otherUser != null) {
                                    widget.onViewProfile?.call(_otherUser!.id);
                                  }
                                },
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10.0),
                                  topRight: Radius.circular(10.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingLG,
                                    vertical: AppTheme.spacingSM,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          labels.viewProfile,
                                          style: AppTextStyles.bodySmallStyle(
                                            color: isDark
                                                ? const Color(
                                                    0xFFD1D5DB,
                                                  ) // gray-300
                                                : const Color(
                                                    0xFF374151,
                                                  ), // gray-700
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Clear Chat
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() => _showMenu = false);
                                  _clearChat();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingLG,
                                    vertical: AppTheme.spacingSM,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          labels.clearChat,
                                          style: AppTextStyles.bodySmallStyle(
                                            color: isDark
                                                ? const Color(
                                                    0xFFD1D5DB,
                                                  ) // gray-300
                                                : const Color(
                                                    0xFF374151,
                                                  ), // gray-700
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Block User (admin only)
                            if (widget.user?.role == 'admin')
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _showMenu = false);
                                    _blockUser();
                                  },
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(10.0),
                                    bottomRight: Radius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingLG,
                                      vertical: AppTheme.spacingSM,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            labels.blockUser,
                                            style: AppTextStyles.bodySmallStyle(
                                              color: const Color(
                                                0xFFDC2626,
                                              ), // red-600
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark, ChatWindowScreenLabels labels) {
    if (_loadingMessages) {
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
      itemCount: _messages.length + 1,
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Scroll anchor
          return const SizedBox(height: 1);
        }

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
                // Avatar
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
                    size: 20,
                    color: isDark
                        ? const Color(0xFFFCD34D) // amber-100
                        : const Color(0xFF78350F), // amber-900
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM), // space-x-2
              ],

              // Message Bubble
              Flexible(
                child: Column(
                  crossAxisAlignment: isSent
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
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
                                    Container(
                                      width: double.infinity,
                                      height: 256,
                                      color: Colors.grey,
                                      child: const Icon(Icons.error),
                                    ),
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
                          if (isSent && message.isRead) ...[
                            const SizedBox(width: AppTheme.spacingSM), // gap-2
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

  Widget _buildMessageInput(bool isDark, ChatWindowScreenLabels labels) {
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
          if (_selectedImagePath != null)
            Padding(
              padding: const EdgeInsets.only(
                bottom: AppTheme.spacingSM,
              ), // mt-2
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusLargeValue,
                    child: Image.network(
                      _selectedImagePath!,
                      width: 128, // w-32
                      height: 128, // h-32
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 128,
                        height: 128,
                        color: Colors.grey,
                        child: const Icon(Icons.error),
                      ),
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
                            _selectedImagePath = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
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

          // Input Row
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
                    (_sendingMessage ||
                        (_messageController.text.trim().isEmpty &&
                            _selectedImagePath == null))
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
                      ), // w-4 h-4
                    const SizedBox(width: AppTheme.spacingSM),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 640) {
                          return Text(labels.send);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      await _refreshConversations(silent: true);
      final id = _selectedConversationId;
      if (id != null) {
        await _refreshMessages(id, silent: true);
      }
    });
  }

  Future<void> _refreshConversations({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loadingConversations = true);
    try {
      final raw = await _chatApi.fetchConversations();
      var mapped = raw.map(_mapConversation).toList();

      // No conversations yet -> show admins so customers can start a chat.
      if (mapped.isEmpty) {
        final admins = await _chatApi.fetchAdmins();
        mapped = admins.map((a) {
          final id = (a['id'] ?? '').toString();
          return ChatWindowConversationData(
            id: id,
            user: ChatWindowUserData(
              id: id,
              name: (a['name'] ?? 'Admin').toString(),
              email: (a['email'] ?? '').toString(),
              avatarUrl: a['avatar_url']?.toString(),
              isOnline: a['is_online'] == true,
              role: 'admin',
            ),
            lastMessage: null,
            unreadCount: 0,
          );
        }).toList();
      }

      if (mounted) {
        setState(() {
          _conversations = mapped;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (!silent && mounted) setState(() => _loadingConversations = false);
    }
  }

  Future<void> _refreshMessages(
    String otherUserId, {
    bool silent = false,
  }) async {
    if (!silent && mounted) setState(() => _loadingMessages = true);
    try {
      final raw = await _chatApi.fetchMessages(otherUserId);
      final mapped = raw.map(_mapMessage).toList();
      if (mounted) {
        setState(() {
          _messages = mapped;
          _error = null;
        });
      }
      unawaited(_chatApi.markRead(otherUserId));
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (!silent && mounted) setState(() => _loadingMessages = false);
    }
  }

  ChatWindowConversationData _mapConversation(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map
        ? Map<String, dynamic>.from(user)
        : const <String, dynamic>{};
    final last = json['last_message'];
    final lastMap = last is Map ? Map<String, dynamic>.from(last) : null;

    final id = (userMap['id'] ?? json['id'] ?? '').toString();
    final createdAtStr = lastMap?['created_at']?.toString();
    final createdAt = createdAtStr == null
        ? null
        : DateTime.tryParse(createdAtStr);

    return ChatWindowConversationData(
      id: (json['id'] ?? id).toString(),
      user: ChatWindowUserData(
        id: id,
        name: (userMap['name'] ?? 'User').toString(),
        email: (userMap['email'] ?? '').toString(),
        avatarUrl: userMap['avatar_url']?.toString(),
        isOnline: userMap['is_online'] == true,
        role: userMap['role']?.toString(),
      ),
      lastMessage: (lastMap == null || createdAt == null)
          ? null
          : ChatWindowLastMessageData(
              message: (lastMap['message'] ?? '').toString(),
              createdAt: createdAt,
            ),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  ChatWindowMessageData _mapMessage(Map<String, dynamic> json) {
    final createdAtStr = json['created_at']?.toString();
    final createdAt = createdAtStr == null
        ? DateTime.now()
        : (DateTime.tryParse(createdAtStr) ?? DateTime.now());
    return ChatWindowMessageData(
      id: (json['id'] ?? '').toString(),
      fromUserId: (json['from_user_id'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      imageUrl: json['image_url']?.toString(),
      createdAt: createdAt,
      isRead: json['is_read'] == true,
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
                            _selectedImagePath = images.first;
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
                              _selectedImagePath = url;
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
}

/// ChatWindowUserData - User data model
class ChatWindowUserData {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final String? role;

  const ChatWindowUserData({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.isOnline,
    this.role,
  });
}

/// ChatWindowConversationData - Conversation data model
class ChatWindowConversationData {
  final String id;
  final ChatWindowUserData user;
  final ChatWindowLastMessageData? lastMessage;
  final int unreadCount;

  const ChatWindowConversationData({
    required this.id,
    required this.user,
    this.lastMessage,
    required this.unreadCount,
  });
}

/// ChatWindowLastMessageData - Last message data model
class ChatWindowLastMessageData {
  final String message;
  final DateTime createdAt;

  const ChatWindowLastMessageData({
    required this.message,
    required this.createdAt,
  });
}

/// ChatWindowMessageData - Message data model
class ChatWindowMessageData {
  final String id;
  final String fromUserId;
  final String message;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;

  const ChatWindowMessageData({
    required this.id,
    required this.fromUserId,
    required this.message,
    this.imageUrl,
    required this.createdAt,
    required this.isRead,
  });
}

/// ChatWindowScreenLabels - Localization labels
class ChatWindowScreenLabels {
  final String contactSupport;
  final String searchUsers;
  final String loading;
  final String noConversations;
  final String noMessages;
  final String selectUserToChat;
  final String viewProfile;
  final String clearChat;
  final String clearThisChat;
  final String areYouSureClearChat;
  final String blockUser;
  final String areYouSureBlockUser;
  final String typeYourMessage;
  final String send;

  const ChatWindowScreenLabels({
    required this.contactSupport,
    required this.searchUsers,
    required this.loading,
    required this.noConversations,
    required this.noMessages,
    required this.selectUserToChat,
    required this.viewProfile,
    required this.clearChat,
    required this.clearThisChat,
    required this.areYouSureClearChat,
    required this.blockUser,
    required this.areYouSureBlockUser,
    required this.typeYourMessage,
    required this.send,
  });

  factory ChatWindowScreenLabels.defaultLabels() {
    return ChatWindowScreenLabels.forLanguage('en');
  }

  factory ChatWindowScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return ChatWindowScreenLabels(
      contactSupport: isArabic ? 'اتصل بالدعم' : 'Contact Support',
      searchUsers: isArabic ? 'ابحث عن المستخدمين...' : 'Search users...',
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      noConversations: isArabic ? 'لا توجد محادثات' : 'No conversations',
      noMessages: isArabic ? 'لا توجد رسائل' : 'No messages',
      selectUserToChat: isArabic
          ? 'اختر مستخدماً للدردشة'
          : 'Select a user to chat',
      viewProfile: isArabic ? 'عرض الملف الشخصي' : 'View Profile',
      clearChat: isArabic ? 'مسح المحادثة' : 'Clear Chat',
      clearThisChat: isArabic ? 'مسح هذه المحادثة' : 'Clear this chat',
      areYouSureClearChat: isArabic
          ? 'هل أنت متأكد أنك تريد مسح هذه المحادثة؟'
          : 'Are you sure you want to clear this chat?',
      blockUser: isArabic ? 'حظر المستخدم' : 'Block User',
      areYouSureBlockUser: isArabic
          ? 'هل أنت متأكد أنك تريد حظر {name}؟'
          : 'Are you sure you want to block {name}?',
      typeYourMessage: isArabic ? 'اكتب رسالتك...' : 'Type your message...',
      send: isArabic ? 'إرسال' : 'Send',
    );
  }
}
