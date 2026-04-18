import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/page_layout.dart';
import '../../core/stores/language_store.dart';

/// BlockedScreen - Account blocked screen
///
/// Equivalent to Vue's Blocked.vue page.
/// Displays account blocked message and chat interface with admin.
///
/// Features:
/// - Red banner with blocked account message
/// - Contact support button
/// - Chat interface with admin who blocked the account
/// - Message input and send functionality
/// - Dark mode support
/// - Responsive design
class BlockedScreen extends ConsumerStatefulWidget {
  /// Mock blocked admin data
  final BlockedAdminData? blockedAdmin;

  /// Callback when contact support is tapped
  final VoidCallback? onContactSupport;

  /// Callback when message is sent
  final void Function(String message)? onSendMessage;

  /// Labels for localization
  final BlockedScreenLabels? labels;

  const BlockedScreen({
    super.key,
    this.blockedAdmin,
    this.onContactSupport,
    this.onSendMessage,
    this.labels,
  });

  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final bool _loadingBlockedInfo = false;

  // Mock messages data
  List<MessageData> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Mock data - in real app, this would come from API
    if (widget.blockedAdmin != null) {
      _messages = [
        MessageData(
          id: '1',
          message: 'Your account has been blocked due to policy violation.',
          imageUrl: null,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        MessageData(
          id: '2',
          message: 'Please contact us if you have any questions.',
          imageUrl: null,
          timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || widget.blockedAdmin == null) return;

    // Add message to list (UI only)
    setState(() {
      _messages.add(
        MessageData(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          imageUrl: null,
          timestamp: DateTime.now(),
        ),
      );
    });

    // Call callback if provided
    widget.onSendMessage?.call(message);

    // Clear input
    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
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
    final labels =
        widget.labels ?? BlockedScreenLabels.forLanguage(currentLanguage);

    return PageLayout(
      child: Column(
        children: [
          // Message Banner
          _buildBanner(isDark, labels),

          // Chat Interface or Loading
          Expanded(
            child: widget.blockedAdmin != null
                ? _buildChatInterface(isDark, labels)
                : _buildLoadingState(isDark, labels),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(bool isDark, BlockedScreenLabels labels) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
      color: const Color(0xFFDC2626), // red-600
      child: Column(
        children: [
          Text(
            labels.accountBlocked,
            style:
                AppTextStyles.titleLargeStyle(
                  color: Colors.white,
                  // font-weight: regular (default)
                ).copyWith(
                  fontSize: AppTextStyles.textXL, // text-xl
                ),
          ),
          const SizedBox(height: AppTheme.spacingSM), // mb-2
          Text(
            labels.accountBlockedMessage,
            style: AppTextStyles.bodyMediumStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLG), // mb-4
          // Contact Support Button
          if (widget.blockedAdmin != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onContactSupport,
                borderRadius: AppTheme.borderRadiusLargeValue,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, // px-6
                    vertical: 8, // py-2
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.2,
                    ), // bg-white bg-opacity-20
                    borderRadius: AppTheme.borderRadiusLargeValue,
                  ),
                  child: Text(
                    labels.contactSupportTeam,
                    style: AppTextStyles.labelLargeStyle(
                      color: Colors.white,
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ),
              ),
            )
          else if (_loadingBlockedInfo)
            Text(
              labels.loading,
              style: AppTextStyles.bodyMediumStyle(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatInterface(bool isDark, BlockedScreenLabels labels) {
    final admin = widget.blockedAdmin!;

    return Container(
      color: isDark
          ? const Color(0xFF111827) // gray-900
          : Colors.white,
      child: Column(
        children: [
          // Chat Header
          _buildChatHeader(isDark, admin, labels),

          // Messages
          Expanded(child: _buildMessagesList(isDark)),

          // Input
          _buildInputArea(isDark, labels),
        ],
      ),
    );
  }

  Widget _buildChatHeader(
    bool isDark,
    BlockedAdminData admin,
    BlockedScreenLabels labels,
  ) {
    return Container(
      height: 80, // h-20
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLG,
      ), // px-4
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF374151) // gray-700
                : const Color(0xFFE5E7EB), // gray-200
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20, // w-10 h-10
            backgroundImage: admin.avatarUrl != null
                ? NetworkImage(admin.avatarUrl!)
                : null,
            child: admin.avatarUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppTheme.spacingMD), // gap-3
          // Admin Info
          Expanded(
            child: Text(
              '${admin.name} [${admin.role}]',
              style: AppTextStyles.titleMediumStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827), // gray-800
                fontWeight: AppTextStyles.medium,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(bool isDark) {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: AppTextStyles.bodyMediumStyle(
            color: isDark
                ? const Color(0xFF9CA3AF) // gray-400
                : const Color(0xFF4B5563), // gray-600
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Padding(
          padding: const EdgeInsets.only(
            bottom: AppTheme.spacingLG,
          ), // space-y-4
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 288), // max-w-xs
                  padding: const EdgeInsets.all(AppTheme.spacingMD), // p-3
                  decoration: BoxDecoration(
                    color: const Color(0xFF6D4C41), // bg-[#6D4C41]
                    borderRadius: AppTheme.borderRadiusLargeValue,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: AppTextStyles.bodyMediumStyle(
                          color: Colors.white,
                        ),
                      ),
                      if (message.imageUrl != null) ...[
                        const SizedBox(height: AppTheme.spacingSM), // mt-2
                        ClipRRect(
                          borderRadius: AppTheme.borderRadiusLargeValue,
                          child: Image.network(
                            message.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea(bool isDark, BlockedScreenLabels labels) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG), // p-4
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F2937) // gray-800
            : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF374151) // gray-700
                : const Color(0xFFE5E7EB), // gray-200
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Message Input
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: labels.typeMessage,
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF374151) // gray-700
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF4B5563) // gray-600
                        : const Color(0xFFD1D5DB), // gray-300
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF4B5563) // gray-600
                        : const Color(0xFFD1D5DB), // gray-300
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppTheme.borderRadiusLargeValue,
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF6B7280) // gray-500
                        : const Color(0xFF9CA3AF), // gray-400
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLG, // px-4
                  vertical: AppTheme.spacingSM, // py-2
                ),
                hintStyle: AppTextStyles.bodyMediumStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF) // gray-400
                      : const Color(0xFF6B7280), // gray-500
                ),
              ),
              style: AppTextStyles.bodyMediumStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xFF111827), // gray-800
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSM), // gap-2
          // Send Button
          Material(
            color: const Color(0xFF6D4C41), // bg-[#6D4C41]
            borderRadius: AppTheme.borderRadiusLargeValue,
            child: InkWell(
              onTap: _sendMessage,
              borderRadius: AppTheme.borderRadiusLargeValue,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24, // px-6
                  vertical: 8, // py-2
                ),
                child: Text(
                  labels.send,
                  style: AppTextStyles.labelLargeStyle(
                    color: Colors.white,
                    fontWeight: AppTextStyles.medium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark, BlockedScreenLabels labels) {
    return Container(
      color: isDark
          ? const Color(0xFF111827) // gray-900
          : Colors.white,
      child: Center(
        child: Text(
          labels.loadingBlockedInformation,
          style:
              AppTextStyles.titleLargeStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF) // gray-400
                    : const Color(0xFF4B5563), // gray-600
              ).copyWith(
                fontSize: 20, // text-xl
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// BlockedAdminData - Admin data model
class BlockedAdminData {
  final String id;
  final String name;
  final String role;
  final String? avatarUrl;

  const BlockedAdminData({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
  });
}

/// MessageData - Message data model
class MessageData {
  final String id;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;

  const MessageData({
    required this.id,
    required this.message,
    this.imageUrl,
    required this.timestamp,
  });
}

/// BlockedScreenLabels - Localization labels
class BlockedScreenLabels {
  final String accountBlocked;
  final String accountBlockedMessage;
  final String contactSupportTeam;
  final String loading;
  final String loadingBlockedInformation;
  final String typeMessage;
  final String send;

  const BlockedScreenLabels({
    required this.accountBlocked,
    required this.accountBlockedMessage,
    required this.contactSupportTeam,
    required this.loading,
    required this.loadingBlockedInformation,
    required this.typeMessage,
    required this.send,
  });

  factory BlockedScreenLabels.defaultLabels() {
    return BlockedScreenLabels.forLanguage('en');
  }

  factory BlockedScreenLabels.forLanguage(String language) {
    final isArabic = language == 'ar';
    return BlockedScreenLabels(
      accountBlocked: isArabic ? 'الحساب محظور' : 'Account Blocked',
      accountBlockedMessage: isArabic
          ? 'تم حظر حسابك. يرجى الاتصال بالدعم للحصول على المساعدة.'
          : 'Your account has been blocked. Please contact support for assistance.',
      contactSupportTeam: isArabic
          ? 'اتصل بفريق الدعم'
          : 'Contact Support Team',
      loading: isArabic ? 'جاري التحميل...' : 'Loading...',
      loadingBlockedInformation: isArabic
          ? 'جاري تحميل معلومات الحظر...'
          : 'Loading blocked information...',
      typeMessage: isArabic ? 'اكتب رسالة' : 'Type a message',
      send: isArabic ? 'إرسال' : 'Send',
    );
  }
}
