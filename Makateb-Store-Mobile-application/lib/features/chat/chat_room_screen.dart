import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/wood_button.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';

/// ChatRoomScreen - Community chat room screen
///
/// Equivalent to Vue's ChatRoom.vue page.
/// Displays a community chat room with messages and online users.
///
/// Features:
/// - Login prompt if no user
/// - Community chat room interface
/// - Messages list with avatars
/// - Typing indicator
/// - Online/offline users sidebar
/// - Message input with action buttons
/// - Dark mode support
/// - Responsive design
class ChatRoomScreen extends ConsumerStatefulWidget {
  /// Mock user data
  final ChatRoomUserData? user;

  /// Mock messages data
  final List<ChatRoomMessageData>? messages;

  /// Mock online users data
  final List<ChatRoomUserData>? onlineUsers;

  /// Typing users list
  final List<String>? typingUsers;

  /// Callback when message is sent
  final void Function(String message)? onSendMessage;

  /// Callback when login is tapped
  final VoidCallback? onLoginTap;

  /// Callback when user is tapped
  final void Function(String userId)? onUserTap;

  /// Message time formatter function
  final String Function(DateTime date)? formatMessageTime;

  /// Labels for localization
  final ChatRoomScreenLabels? labels;

  const ChatRoomScreen({
    super.key,
    this.user,
    this.messages,
    this.onlineUsers,
    this.typingUsers,
    this.onSendMessage,
    this.onLoginTap,
    this.onUserTap,
    this.formatMessageTime,
    this.labels,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showUserList = false;

  List<ChatRoomMessageData> _messages = [];
  List<ChatRoomUserData> _onlineUsers = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Mock data - in real app, this would come from API/WebSocket
    _messages = widget.messages ?? [
      ChatRoomMessageData(
        id: '1',
        userId: '1',
        userName: 'Emma Wilson',
        userAvatar: null,
        message: 'Hey everyone! Has anyone tried the new oak dining table?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      ChatRoomMessageData(
        id: '2',
        userId: '2',
        userName: 'James Brown',
        userAvatar: null,
        message: 'Yes! I ordered it last week. The quality is amazing!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        isRead: true,
      ),
    ];

    _onlineUsers = widget.onlineUsers ?? [
      ChatRoomUserData(
        id: '1',
        name: 'Emma Wilson',
        isOnline: true,
        avatar: null,
      ),
      ChatRoomUserData(
        id: '2',
        name: 'James Brown',
        isOnline: true,
        avatar: null,
      ),
      ChatRoomUserData(
        id: '3',
        name: 'Sarah Davis',
        isOnline: false,
        lastSeen: '5m ago',
        avatar: null,
      ),
      ChatRoomUserData(
        id: '4',
        name: 'Michael Chen',
        isOnline: true,
        avatar: null,
      ),
      ChatRoomUserData(
        id: '5',
        name: 'Lisa Anderson',
        isOnline: false,
        lastSeen: '1h ago',
        avatar: null,
      ),
    ];
  }

  List<ChatRoomUserData> get _filteredOnlineUsers {
    if (_searchQuery.isEmpty) {
      return _onlineUsers.where((u) => u.isOnline).toList();
    }
    final query = _searchQuery.toLowerCase();
    return _onlineUsers
        .where((u) => u.isOnline && u.name.toLowerCase().contains(query))
        .toList();
  }

  List<ChatRoomUserData> get _filteredOfflineUsers {
    if (_searchQuery.isEmpty) {
      return _onlineUsers.where((u) => !u.isOnline).toList();
    }
    final query = _searchQuery.toLowerCase();
    return _onlineUsers
        .where((u) => !u.isOnline && u.name.toLowerCase().contains(query))
        .toList();
  }

  int get _onlineUsersCount {
    return _onlineUsers.where((u) => u.isOnline).length;
  }

  String _formatMessageTime(DateTime date) {
    return widget.formatMessageTime?.call(date) ??
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || widget.user == null) return;

    setState(() {
      _messages.add(
        ChatRoomMessageData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: widget.user!.id,
          userName: widget.user!.name,
          userAvatar: widget.user!.avatar,
          message: message,
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
    });

    widget.onSendMessage?.call(message);
    _messageController.clear();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLanguage = ref.watch(currentLanguageProvider);
    final labels = widget.labels ?? ChatRoomScreenLabels.forLanguage(currentLanguage);

    // No User State
    if (widget.user == null) {
      return PageLayout(
        showCartButton: false,
        scrollable: false,
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLG),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // p-8
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937) // gray-800
                      : Colors.white,
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF78350F).withValues(alpha: 0.3) // amber-900/30
                        : const Color(0xFFFEF3C7), // amber-100
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64, // w-16 h-16
                      color: isDark
                          ? const Color(0xFFD97706) // amber-500
                          : const Color(0xFF92400E), // amber-800
                    ),
                    const SizedBox(height: AppTheme.spacingLG), // mb-4
                    Text(
                      labels.joinConversation,
                      style: AppTextStyles.titleLargeStyle(
                        color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
                        fontWeight: FontWeight.bold,
                      ).copyWith(
                        fontSize: 24, // text-2xl
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG), // mb-4
                    Text(
                      labels.loginToAccess,
                      style: AppTextStyles.bodyMediumStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF) // gray-400
                            : const Color(0xFF4B5563), // gray-600
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLG * 1.5), // mb-6
                    SizedBox(
                      width: double.infinity,
                      child: WoodButton(
                        onPressed: widget.onLoginTap,
                        size: WoodButtonSize.md,
                        child: Text(labels.signIn),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Chat Room Interface
    return PageLayout(
      showCartButton: false,
      scrollable: false,
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
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingXXL * 2), // py-8
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG), // px-4
                  child: Text(
                    labels.communityChatRoom,
                    style: AppTextStyles.titleLargeStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
                      fontWeight: FontWeight.bold,
                    ).copyWith(
                      fontSize: 36, // text-4xl
                    ),
                  ),
                ),
              ),
            ),

            // Main Chat Container
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280), // max-w-7xl
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG), // px-4
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1024) {
                      // Desktop: Side by side
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Chat Messages Area
                          Expanded(
                            child: _buildChatArea(isDark, labels),
                          ),
                          const SizedBox(width: AppTheme.spacingLG), // gap-4

                          // Online Users Sidebar
                          SizedBox(
                            width: constraints.maxWidth >= 1024 ? 288 : constraints.maxWidth * 0.3, // Responsive width
                            child: _buildUsersSidebar(isDark, labels),
                          ),
                        ],
                      );
                    } else {
                      // Mobile: Stacked or overlay
                      return Stack(
                        children: [
                          _buildChatArea(isDark, labels),
                          if (_showUserList)
                            Positioned(
                              top: 96, // top-24
                              right: AppTheme.spacingSM, // right-2
                              bottom: AppTheme.spacingSM, // bottom-2
                              left: AppTheme.spacingSM, // left-2 (full width on mobile)
                              child: _buildUsersSidebar(isDark, labels),
                            ),
                        ],
                      );
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

  Widget _buildChatArea(bool isDark, ChatRoomScreenLabels labels) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.3) // amber-900/30
              : const Color(0xFFFEF3C7), // amber-100
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
          Expanded(
            child: _buildMessagesList(isDark, labels),
          ),

          // Message Input
          _buildMessageInput(isDark, labels),
        ],
      ),
    );
  }

  Widget _buildChatHeader(bool isDark, ChatRoomScreenLabels labels) {
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
          // Community Icon
          Stack(
            children: [
              Icon(
                Icons.people,
                size: 32, // w-8 h-8
                color: Colors.white,
              ),
              Positioned(
                top: -4, // -top-1
                right: -4, // -right-1
                child: Container(
                  width: 12, // w-3
                  height: 12, // h-3
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E), // green-500
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

          // Community Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels.woodCraftCommunity,
                  style: AppTextStyles.titleMediumStyle(
                    color: Colors.white,
                    // font-weight: regular (default)
                  ),
                ),
                Text(
                  '$_onlineUsersCount ${labels.membersOnline}',
                  style: AppTextStyles.bodySmallStyle(
                    color: const Color(0xFFFCD34D), // amber-200
                  ),
                ),
              ],
            ),
          ),

          // Mobile Menu Button
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1024) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _showUserList = !_showUserList;
                    });
                  },
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 20), // w-5 h-5
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark, ChatRoomScreenLabels labels) {
    return ListView.builder(
      controller: _messagesScrollController,
      padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
      itemCount: _messages.length + (widget.typingUsers?.isNotEmpty == true ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          // Typing Indicator
          return _buildTypingIndicator(isDark, labels);
        }

        final message = _messages[index];
        final isSent = message.userId == widget.user?.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingLG), // space-y-4
          child: Row(
            mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                  child: message.userAvatar != null
                      ? ClipOval(
                          child: Image.network(
                            message.userAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(
                                  Icons.person,
                                  size: 20,
                                  color: isDark
                                      ? const Color(0xFFFCD34D) // amber-100
                                      : const Color(0xFF78350F), // amber-900
                                ),
                          ),
                        )
                      : Icon(
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
                  crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7, // max-w-[70%]
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
                          if (!isSent)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4), // mb-1
                              child: Text(
                                message.userName,
                                style: AppTextStyles.bodySmallStyle(
                                  color: isDark
                                      ? const Color(0xFFFCD34D) // amber-400
                                      : const Color(0xFF92400E), // amber-800
                                  fontWeight: AppTextStyles.medium,
                                ),
                              ),
                            ),
                          Text(
                            message.message,
                            style: AppTextStyles.bodyMediumStyle(
                              color: isSent
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF111827)),
                            ),
                          ),
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
                        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Text(
                            _formatMessageTime(message.timestamp),
                            style: AppTextStyles.bodySmallStyle(
                              color: isDark
                                  ? const Color(0xFF6B7280) // gray-500
                                  : const Color(0xFF6B7280), // gray-500
                            ),
                          ),
                          if (isSent && message.isRead == true) ...[
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

  Widget _buildTypingIndicator(bool isDark, ChatRoomScreenLabels labels) {
    final typingUsers = widget.typingUsers ?? [];
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLG),
      child: Row(
        children: [
          // Animated dots
          Row(
            children: [
              _buildTypingDot(0),
              const SizedBox(width: AppTheme.spacingXS),
              _buildTypingDot(150),
              const SizedBox(width: AppTheme.spacingXS),
              _buildTypingDot(300),
            ],
          ),
          const SizedBox(width: AppTheme.spacingSM), // space-x-2
          Text(
            typingUsers.length == 1
                ? '${typingUsers.first} ${labels.isTyping}'
                : labels.multipleTyping,
            style: AppTextStyles.bodySmallStyle(
              color: isDark
                  ? const Color(0xFF6B7280) // gray-500
                  : const Color(0xFF6B7280), // gray-500
            ).copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8, // w-2
          height: 8, // h-2
          decoration: BoxDecoration(
            color: const Color(0xFF9CA3AF).withValues(alpha: (value + (delay / 600)) % 1.0 > 0.5 ? 1.0 : 0.5,
            ), // gray-400
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(bool isDark, ChatRoomScreenLabels labels) {
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
      child: Row(
        children: [
          // Attach File Button
          IconButton(
            onPressed: () {}, // Placeholder
            icon: Icon(
              Icons.attach_file,
              size: 20, // w-5 h-5
              color: isDark
                  ? const Color(0xFF9CA3AF) // gray-400
                  : const Color(0xFF4B5563), // gray-600
            ),
            tooltip: 'Attach file',
          ),

          // Add Image Button
          IconButton(
            onPressed: () {}, // Placeholder
            icon: Icon(
              Icons.image_outlined,
              size: 20, // w-5 h-5
              color: isDark
                  ? const Color(0xFF9CA3AF) // gray-400
                  : const Color(0xFF4B5563), // gray-600
            ),
            tooltip: 'Add image',
          ),

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
                color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
              ),
            ),
          ),

          // Emoji Button
          IconButton(
            onPressed: () {}, // Placeholder
            icon: Icon(
              Icons.sentiment_satisfied_outlined,
              size: 20, // w-5 h-5
              color: isDark
                  ? const Color(0xFF9CA3AF) // gray-400
                  : const Color(0xFF4B5563), // gray-600
            ),
            tooltip: 'Add emoji',
          ),

          // Send Button
          WoodButton(
            onPressed: _messageController.text.trim().isEmpty ? null : _sendMessage,
            size: WoodButtonSize.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send, size: 16, color: Colors.white), // w-4 h-4
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
    );
  }

  Widget _buildUsersSidebar(bool isDark, ChatRoomScreenLabels labels) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        borderRadius: AppTheme.borderRadiusLargeValue,
        border: Border.all(
          color: isDark
              ? const Color(0xFF78350F).withValues(alpha: 0.3) // amber-900/30
              : const Color(0xFFFEF3C7), // amber-100
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
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
                Icon(
                  Icons.people,
                  size: 20, // w-5 h-5
                  color: Colors.white,
                ),
                const SizedBox(width: 8), // space-x-2
                Text(
                  '${labels.members} (${_onlineUsers.length})',
                  style: AppTextStyles.titleMediumStyle(
                    color: Colors.white,
                    // font-weight: regular (default)
                  ),
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: labels.searchMembers,
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
                color: isDark ? Colors.white : const Color(0xFF111827), // gray-900
              ),
            ),
          ),

          // Users List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG), // p-4
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Online Users
                  Text(
                    '${labels.online} - $_onlineUsersCount',
                    style: AppTextStyles.bodySmallStyle(
                      color: isDark
                          ? const Color(0xFF6B7280) // gray-500
                          : const Color(0xFF6B7280), // gray-500
                      fontWeight: AppTextStyles.medium,
                    ).copyWith(
                      fontSize: 12, // text-sm
                      letterSpacing: 0.5, // uppercase
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSM), // space-y-2
                  ..._filteredOnlineUsers.map((user) => _buildUserItem(user, isDark, true, labels)),

                  // Offline Users
                  if (_filteredOfflineUsers.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingLG), // mt-4
                    Text(
                      '${labels.offline} - ${_filteredOfflineUsers.length}',
                      style: AppTextStyles.bodySmallStyle(
                        color: isDark
                            ? const Color(0xFF6B7280) // gray-500
                            : const Color(0xFF6B7280), // gray-500
                        fontWeight: AppTextStyles.medium,
                      ).copyWith(
                        fontSize: 12, // text-sm
                        letterSpacing: 0.5, // uppercase
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSM), // space-y-2
                    ..._filteredOfflineUsers.map((user) => _buildUserItem(user, isDark, false, labels)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(ChatRoomUserData user, bool isDark, bool isOnline, ChatRoomScreenLabels labels) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onUserTap?.call(user.id),
        borderRadius: AppTheme.borderRadiusLargeValue,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingSM), // p-2
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 40, // w-10
                    height: 40, // h-10
                    decoration: BoxDecoration(
                      gradient: isOnline
                          ? LinearGradient(
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
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [
                                      const Color(0xFF374151), // gray-700
                                      const Color(0xFF4B5563), // gray-600
                                    ]
                                  : [
                                      const Color(0xFFE5E7EB), // gray-200
                                      const Color(0xFFD1D5DB), // gray-300
                                    ],
                            ),
                      shape: BoxShape.circle,
                    ),
                    child: user.avatar != null
                        ? ClipOval(
                            child: Image.network(
                              user.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person,
                                    size: 20,
                                    color: isOnline
                                        ? (isDark
                                            ? const Color(0xFFFCD34D) // amber-100
                                            : const Color(0xFF78350F)) // amber-900
                                        : (isDark
                                            ? const Color(0xFF9CA3AF) // gray-400
                                            : const Color(0xFF6B7280)), // gray-500
                                  ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 20,
                            color: isOnline
                                ? (isDark
                                    ? const Color(0xFFFCD34D) // amber-100
                                    : const Color(0xFF78350F)) // amber-900
                                : (isDark
                                    ? const Color(0xFF9CA3AF) // gray-400
                                    : const Color(0xFF6B7280)), // gray-500
                          ),
                  ),
                  // Status Indicator
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12, // w-3
                      height: 12, // h-3
                      decoration: BoxDecoration(
                        color: isOnline
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

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.bodyMediumStyle(
                        color: isOnline
                            ? (isDark ? Colors.white : const Color(0xFF111827)) // gray-900
                            : (isDark
                                ? const Color(0xFF9CA3AF) // gray-400
                                : const Color(0xFF4B5563)), // gray-600
                        fontWeight: AppTextStyles.medium,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isOnline)
                      Text(
                        labels.online,
                        style: AppTextStyles.bodySmallStyle(
                          color: const Color(0xFF16A34A), // green-600
                        ),
                      )
                    else if (user.lastSeen != null)
                      Text(
                        user.lastSeen!,
                        style: AppTextStyles.bodySmallStyle(
                          color: isDark
                              ? const Color(0xFF6B7280) // gray-500
                              : const Color(0xFF6B7280), // gray-500
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
}

/// ChatRoomUserData - User data model
class ChatRoomUserData {
  final String id;
  final String name;
  final bool isOnline;
  final String? avatar;
  final String? lastSeen;

  const ChatRoomUserData({
    required this.id,
    required this.name,
    required this.isOnline,
    this.avatar,
    this.lastSeen,
  });
}

/// ChatRoomMessageData - Message data model
class ChatRoomMessageData {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const ChatRoomMessageData({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });
}

/// ChatRoomScreenLabels - Localization labels
class ChatRoomScreenLabels {
  final String joinConversation;
  final String loginToAccess;
  final String signIn;
  final String communityChatRoom;
  final String woodCraftCommunity;
  final String membersOnline;
  final String members;
  final String searchMembers;
  final String online;
  final String offline;
  final String typeYourMessage;
  final String send;
  final String isTyping;
  final String multipleTyping;

  const ChatRoomScreenLabels({
    required this.joinConversation,
    required this.loginToAccess,
    required this.signIn,
    required this.communityChatRoom,
    required this.woodCraftCommunity,
    required this.membersOnline,
    required this.members,
    required this.searchMembers,
    required this.online,
    required this.offline,
    required this.typeYourMessage,
    required this.send,
    required this.isTyping,
    required this.multipleTyping,
  });

  factory ChatRoomScreenLabels.defaultLabels() {
    return ChatRoomScreenLabels.forLanguage('en');
  }

  factory ChatRoomScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return ChatRoomScreenLabels(
      joinConversation: isArabic ? 'انضم إلى المحادثة' : 'Join the Conversation',
      loginToAccess: isArabic ? 'يرجى تسجيل الدخول للوصول إلى غرفة الدردشة المجتمعية' : 'Please login to access the WoodCraft community chat room',
      signIn: isArabic ? 'تسجيل الدخول' : 'Sign In',
      communityChatRoom: isArabic ? 'غرفة الدردشة المجتمعية' : 'Community Chat Room',
      woodCraftCommunity: isArabic ? 'مجتمع مكاتب' : 'WoodCraft Community',
      membersOnline: isArabic ? 'أعضاء متصلون' : 'members online',
      members: isArabic ? 'الأعضاء' : 'Members',
      searchMembers: isArabic ? 'ابحث عن الأعضاء...' : 'Search members...',
      online: isArabic ? 'متصل' : 'Online',
      offline: isArabic ? 'غير متصل' : 'Offline',
      typeYourMessage: isArabic ? 'اكتب رسالتك...' : 'Type your message...',
      send: isArabic ? 'إرسال' : 'Send',
      isTyping: isArabic ? 'يكتب...' : 'is typing...',
      multipleTyping: 'Multiple people are typing...',
    );
  }
}



