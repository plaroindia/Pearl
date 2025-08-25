// FIXED chat_page.dart - Proper scrolling behavior
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile.dart';
import '../Model/user_profile.dart';
import '../../ViewModel/dm_provider.dart';
import '../ViewModel/user_provider.dart';
import '../ViewModel/chat_media_provider.dart';

class IndividualChatPage extends ConsumerStatefulWidget {
  final UserProfile? receiver;
  final String receiverId;
  final String receiverName;
  final String? receiverProfilePic;

  const IndividualChatPage({
    super.key,
    required this.receiver,
    required this.receiverId,
    required this.receiverName,
    this.receiverProfilePic,
  });

  @override
  ConsumerState<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends ConsumerState<IndividualChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isTyping = false;
  late AnimationController _fadeController;
  String? _currentUserId;
  String? _editingMessageId;

  // FIXED: Better scroll state management
  bool _hasInitiallyLoaded = false;
  bool _isUserScrolling = false;
  bool _shouldAutoScroll = true;
  int _lastMessageCount = 0;
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController.forward();

    _messageController.addListener(_onMessageChanged);
    _scrollController.addListener(_onScroll);
    _messageFocusNode.addListener(_onFocusChanged); // ADDED: Focus listener

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _scrollController.removeListener(_onScroll);
    _messageFocusNode.removeListener(_onFocusChanged); // ADDED: Remove focus listener
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ADDED: Handle focus changes for keyboard
  void _onFocusChanged() {
    if (_messageFocusNode.hasFocus) {
      // Keyboard is opening - scroll to bottom after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _scrollToBottomForced();
        }
      });
      setState(() {
        _keyboardVisible = true;
      });
    } else {
      setState(() {
        _keyboardVisible = false;
      });
    }
  }

  // FIXED: Only update typing state, not message list
  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });

      // Send typing indicator without triggering list refresh
      if (_currentUserId != null) {
        final params = createChatParams(
          currentUserId: _currentUserId!,
          receiverId: widget.receiverId,
        );
        Future.microtask(() {
          if (mounted) {
            ref.read(directMessageProvider(params).notifier).setTyping(hasText);
          }
        });
      }
    }
  }

  void _onScroll() {
    _isUserScrolling = true;

    // Check if user is at bottom
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      _shouldAutoScroll = position.pixels >= position.maxScrollExtent - 100; // INCREASED threshold

      // Load more messages when scrolling to top
      if (position.pixels <= 200 && _currentUserId != null) {
        final params = createChatParams(
          currentUserId: _currentUserId!,
          receiverId: widget.receiverId,
        );
        Future.microtask(() {
          if (mounted) {
            ref.read(directMessageProvider(params).notifier).loadMoreMessages();
          }
        });
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isUserScrolling = false;
      }
    });
  }

  // FIXED: Better scroll to bottom logic
  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients && _shouldAutoScroll && !_isUserScrolling) {
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  // ADDED: Force scroll to bottom (for keyboard opening)
  void _scrollToBottomForced() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // FIXED: Better message sending with immediate scroll
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentUserId == null) return;

    final params = createChatParams(
      currentUserId: _currentUserId!,
      receiverId: widget.receiverId,
    );

    try {
      if (_editingMessageId != null) {
        await ref.read(directMessageProvider(params).notifier)
            .editMessage(_editingMessageId!, message);
        _cancelEdit();
      } else {
        // FIXED: Clear input immediately and ensure scroll
        _messageController.clear();
        setState(() {
          _isTyping = false;
        });

        // Force scroll to bottom immediately after clearing input
        _shouldAutoScroll = true;
        _scrollToBottomForced();

        // Send message - real-time listener will handle UI update
        await ref.read(directMessageProvider(params).notifier)
            .sendMessage(content: message);
      }

    } catch (error) {
      // Restore message if sending failed
      if (_editingMessageId == null) {
        _messageController.text = message;
        setState(() {
          _isTyping = true;
        });
      }
      _showErrorSnackBar('Failed to send message: $error');
    }
  }

  Future<void> _sendMediaMessage(ChatMediaItem mediaItem) async {
    if (_currentUserId == null) return;

    final params = createChatParams(
      currentUserId: _currentUserId!,
      receiverId: widget.receiverId,
    );

    try {
      final mediaContent = mediaItem.isImage
          ? 'ðŸ"· Image: ${mediaItem.fileName}'
          : 'ðŸ"„ File: ${mediaItem.fileName}';

      // Ensure scroll after media send
      _shouldAutoScroll = true;

      await ref.read(directMessageProvider(params).notifier).sendMessage(
        content: mediaContent,
        messageType: mediaItem.isImage ? 'image' : 'file',
        metadata: {
          'media_id': mediaItem.id,
          'file_url': mediaItem.fileUrl,
          'file_name': mediaItem.fileName,
          'file_size': mediaItem.fileSize,
          'mime_type': mediaItem.mimeType,
          'media_type': mediaItem.mediaType.value,
        },
      );

      _scrollToBottomForced();
    } catch (error) {
      _showErrorSnackBar('Failed to send media: $error');
    }
  }

  void _startEdit(DirectMessage message) {
    setState(() {
      _editingMessageId = message.id;
      _messageController.text = message.content;
    });
    _messageFocusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _messageController.clear();
    });
  }

  void _deleteMessage(String messageId) {
    if (_currentUserId != null) {
      final params = createChatParams(
        currentUserId: _currentUserId!,
        receiverId: widget.receiverId,
      );
      Future.microtask(() {
        ref.read(directMessageProvider(params).notifier).deleteMessage(messageId);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.only(
            bottom: 80,
            left: 16,
            right: 16,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.grey[900],
          title: const Text('Chat', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'Please log in to use chat',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final params = createChatParams(
      currentUserId: _currentUserId!,
      receiverId: widget.receiverId,
    );

    final mediaParams = createMediaParams(
      chatId: DirectMessageNotifier.generateChatId(
        _currentUserId!,
        widget.receiverId,
      ),
      currentUserId: _currentUserId!,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      // ADDED: Proper keyboard handling
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // FIXED: Messages list with improved scroll handling
          Expanded(
            child: FadeTransition(
              opacity: _fadeController,
              child: Consumer(
                builder: (context, ref, child) {
                  final chatState = ref.watch(directMessageProvider(params));
                  final mediaState = ref.watch(chatMediaProvider(mediaParams));

                  // Handle errors silently
                  if (mediaState.hasError) {
                    Future.microtask(() {
                      if (mounted) {
                        _showErrorSnackBar(mediaState.error!);
                        ref.read(chatMediaProvider(mediaParams).notifier).clearError();
                      }
                    });
                  }

                  if (chatState.hasError) {
                    Future.microtask(() {
                      if (mounted) {
                        _showErrorSnackBar(chatState.error!);
                        ref.read(directMessageProvider(params).notifier).clearError();
                      }
                    });
                  }

                  return _buildMessagesList(chatState);
                },
              ),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[900],
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherProfileScreen(
                userId: widget.receiverId,
                initialUserData: widget.receiver,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Hero(
              tag: 'profile_${widget.receiverId}',
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[700],
                ),
                child: widget.receiverProfilePic?.isNotEmpty == true
                    ? ClipOval(
                  child: Image.network(
                    widget.receiverProfilePic!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: Colors.grey[400],
                        size: 20,
                      );
                    },
                  ),
                )
                    : Icon(
                  Icons.person,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tap to view profile',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.white),
          onPressed: () => _showFeatureNotAvailable('Voice call'),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.white),
          onPressed: () => _showFeatureNotAvailable('Video call'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: Colors.grey[800],
          onSelected: _handleMenuSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Clear chat', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Row(
                children: [
                  Icon(Icons.notifications_off, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('Mute notifications', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Block user', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Text('Report user', style: TextStyle(color: Colors.orange)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // FIXED: Better message list scrolling
  Widget _buildMessagesList(ChatState chatState) {
    if (chatState.hasError && chatState.messages.isEmpty) {
      return _buildErrorWidget(chatState.error!);
    }

    if (chatState.messages.isEmpty && chatState.isInitialLoading) {
      return _buildInitialLoadingWidget();
    }

    if (chatState.messages.isEmpty && !chatState.isInitialLoading) {
      return _buildEmptyWidget();
    }

    // FIXED: More precise auto-scroll logic
    final currentMessageCount = chatState.messages.length;

    if (currentMessageCount > _lastMessageCount) {
      // New message arrived - scroll if user is near bottom or if it's their own message
      if (_shouldAutoScroll || !_isUserScrolling) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottomForced();
        });
      }
    }
    _lastMessageCount = currentMessageCount;

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentUserId != null) {
          final params = createChatParams(
            currentUserId: _currentUserId!,
            receiverId: widget.receiverId,
          );
          ref.read(directMessageProvider(params).notifier).refresh();
        }
      },
      backgroundColor: Colors.grey[900],
      color: Colors.blue,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: _keyboardVisible ? 8 : 80, // ADDED: Dynamic bottom padding
        ),
        itemCount: chatState.messages.length,
        itemBuilder: (context, index) {
          final message = chatState.messages[index];
          final isFromMe = message.senderId == _currentUserId;
          final previousMessage = index > 0 ? chatState.messages[index - 1] : null;
          final showAvatar = previousMessage?.senderId != message.senderId;
          final showTimestamp = previousMessage == null ||
              message.createdAt.difference(previousMessage.createdAt).inMinutes > 5;

          return Column(
            children: [
              if (showTimestamp) _buildTimestamp(message.createdAt),
              _buildMessageBubble(
                message: message,
                isFromMe: isFromMe,
                showAvatar: showAvatar,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble({
    required DirectMessage message,
    required bool isFromMe,
    required bool showAvatar,
  }) {
    final isMediaMessage = message.messageType == 'image' || message.messageType == 'file';
    final mediaMetadata = message.metadata;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromMe && showAvatar) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ] else if (!isFromMe) ...[
            const SizedBox(width: 32),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message, isFromMe),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isFromMe ? Colors.blue[600] : Colors.grey[800],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isFromMe ? const Radius.circular(20) : const Radius.circular(4),
                    bottomRight: isFromMe ? const Radius.circular(4) : const Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMediaMessage && mediaMetadata != null)
                      _buildMediaContent(mediaMetadata),
                    if (isMediaMessage && mediaMetadata != null)
                      const SizedBox(height: 8),
                    Text(
                      message.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.updatedAt != null) ...[
                          Icon(
                            Icons.edit,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        if (isFromMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 16,
                            color: message.isRead ? Colors.blue[300] : Colors.grey[400],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isFromMe && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(isCurrentUser: true),
          ] else if (isFromMe) ...[
            const SizedBox(width: 32),
          ],
        ],
      ),
    );
  }
  Widget _buildMediaContent(Map<String, dynamic> mediaMetadata) {
    final mediaType = mediaMetadata['media_type'] as String?;
    final fileUrl = mediaMetadata['file_url'] as String?;
    final fileName = mediaMetadata['file_name'] as String?;
    final fileSize = mediaMetadata['file_size'] as int?;

    if (fileUrl == null || fileName == null) return const SizedBox.shrink();

    if (mediaType == 'image') {
      return _buildImageContent(fileUrl, fileName);
    } else {
      return _buildFileContent(fileName, fileSize ?? 0, fileUrl);
    }
  }

  Widget _buildImageContent(String imageUrl, String fileName) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 250,
        maxHeight: 200,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[700],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.grey[400], size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFileContent(String fileName, int fileSize, String fileUrl) {
    final formattedSize = _formatFileSize(fileSize);
    final extension = fileName.split('.').last.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[600]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(extension),
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formattedSize,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _downloadFile(fileUrl, fileName),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.download,
                color: Colors.blue,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
      case 'DOCX':
        return Icons.description;
      case 'XLS':
      case 'XLSX':
        return Icons.table_chart;
      case 'TXT':
        return Icons.text_snippet;
      case 'CSV':
        return Icons.table_view;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  void _downloadFile(String fileUrl, String fileName) {
    _showFeatureNotAvailable('File download');
  }

  Widget _buildAvatar({bool isCurrentUser = false}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[700],
      ),
      child: ClipOval(
        child: isCurrentUser
            ? Consumer(
          builder: (context, ref, child) {
            final currentUserProfile = ref.watch(
              userProfileProvider(_currentUserId ?? ''),
            );

            return currentUserProfile.when(
              data: (profile) {
                return profile?.profilePic?.isNotEmpty == true
                    ? Image.network(
                  profile!.profilePic!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.person, color: Colors.grey[400], size: 12);
                  },
                )
                    : Icon(Icons.person, color: Colors.grey[400], size: 12);
              },
              loading: () => CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
              error: (error, stackTrace) => Icon(Icons.person, color: Colors.grey[400], size: 12),
            );
          },
        )
            : (widget.receiverProfilePic?.isNotEmpty == true
            ? Image.network(
          widget.receiverProfilePic!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person, color: Colors.grey[400], size: 12);
          },
        )
            : Icon(Icons.person, color: Colors.grey[400], size: 12)),
      ),
    );
  }

  Widget _buildTimestamp(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey[800], thickness: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(timestamp),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey[800], thickness: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16),
          Text(
            'Loading messages...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load messages',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_currentUserId != null) {
                  final params = createChatParams(
                    currentUserId: _currentUserId!,
                    receiverId: widget.receiverId,
                  );
                  ref.read(directMessageProvider(params).notifier).refresh();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation with ${widget.receiverName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final mediaParams = createMediaParams(
      chatId: DirectMessageNotifier.generateChatId(_currentUserId!, widget.receiverId),
      currentUserId: _currentUserId!,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border(
          top: BorderSide(color: Colors.black26!, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit message indicator
          if (_editingMessageId != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Editing message',
                      style: TextStyle(color: Colors.orange, fontSize: 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelEdit,
                    child: const Icon(Icons.close, color: Colors.orange, size: 16),
                  ),
                ],
              ),
            ),
          ],

          // Main input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              GestureDetector(
                onTap: () => _showAttachmentOptions(mediaParams),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.attach_file,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Message input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _editingMessageId != null
                          ? 'Edit message...'
                          : 'Message ${widget.receiverName}...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Send button
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isTyping || _editingMessageId != null
                        ? Colors.blue
                        : Colors.grey[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _editingMessageId != null ? Icons.check : Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(Map<String, String> mediaParams) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Send Media',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  Icons.camera_alt,
                  'Camera',
                      () async {
                    Navigator.pop(context);
                    final result = await ref
                        .read(chatMediaProvider(mediaParams).notifier)
                        .pickImageFromCamera();
                    if (result != null && result.success && result.mediaItem != null) {
                      await _sendMediaMessage(result.mediaItem!);
                    }
                  },
                ),
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Gallery',
                      () async {
                    Navigator.pop(context);
                    final result = await ref
                        .read(chatMediaProvider(mediaParams).notifier)
                        .pickImageFromGallery();
                    if (result != null && result.success && result.mediaItem != null) {
                      await _sendMediaMessage(result.mediaItem!);
                    }
                  },
                ),
                _buildAttachmentOption(
                  Icons.insert_drive_file,
                  'Document',
                      () async {
                    Navigator.pop(context);
                    final result = await ref
                        .read(chatMediaProvider(mediaParams).notifier)
                        .pickDocument();
                    if (result != null && result.success && result.mediaItem != null) {
                      await _sendMediaMessage(result.mediaItem!);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(DirectMessage message, bool isFromMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (isFromMe) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _startEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(message.id);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('Copy', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showFeatureNotAvailable('Copy message');
              },
            ),
            if (!isFromMe) ...[
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: const Text('Report', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  _showFeatureNotAvailable('Report message');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Message', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'clear':
        _showClearChatDialog();
        break;
      case 'mute':
        _showFeatureNotAvailable('Mute notifications');
        break;
      case 'block':
        _showBlockUserDialog();
        break;
      case 'report':
        _showReportUserDialog();
        break;
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to clear all messages with ${widget.receiverName}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFeatureNotAvailable('Clear chat');
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Block User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to block ${widget.receiverName}? You won\'t receive messages from them.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFeatureNotAvailable('Block user');
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Report User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Report ${widget.receiverName} for inappropriate behavior?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFeatureNotAvailable('Report user');
            },
            child: const Text('Report', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
  void _showFeatureNotAvailable(String feature) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$feature feature coming soon!'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}