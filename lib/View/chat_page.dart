// UPDATED chat_page.dart - Individual Chat with Real-time Logic
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile.dart';
import '../Model/user_profile.dart';
import '../../ViewModel/dm_provider.dart';
import '../ViewModel/user_provider.dart';


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

    // Auto-scroll to bottom on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });

      // Send typing indicator to provider
      if (_currentUserId != null) {
        final params = createChatParams(
          currentUserId: _currentUserId!,
          receiverId: widget.receiverId,
        );
        ref.read(directMessageProvider(params).notifier).setTyping(hasText);
      }
    }
  }

  void _onScroll() {
    // Load more messages when scrolling to top
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      if (position.pixels <= 200) {
        if (_currentUserId != null) {
          final params = createChatParams(
            currentUserId: _currentUserId!,
            receiverId: widget.receiverId,
          );
          ref.read(directMessageProvider(params).notifier).loadMoreMessages();
        }
      }
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _currentUserId == null) return;

    final params = createChatParams(
      currentUserId: _currentUserId!,
      receiverId: widget.receiverId,
    );

    try {
      if (_editingMessageId != null) {
        // Edit existing message
        await ref.read(directMessageProvider(params).notifier)
            .editMessage(_editingMessageId!, message);
        _cancelEdit();
      } else {
        // Send new message
        await ref.read(directMessageProvider(params).notifier)
            .sendMessage(content: message);
      }

      _messageController.clear();
      setState(() {
        _isTyping = false;
      });

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

    } catch (error) {
      _showErrorSnackBar('Failed to send message: $error');
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
      ref.read(directMessageProvider(params).notifier).deleteMessage(messageId);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _fadeController,
              child: Consumer(
                builder: (context, ref, child) {
                  final chatState = ref.watch(directMessageProvider(params));

                  if (chatState.hasError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showErrorSnackBar(chatState.error!);
                      ref.read(directMessageProvider(params).notifier).clearError();
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
                  Consumer(
                    builder: (context, ref, child) {
                      if (_currentUserId != null) {
                        final params = createChatParams(
                          currentUserId: _currentUserId!,
                          receiverId: widget.receiverId,
                        );
                        final chatState = ref.watch(directMessageProvider(params));

                        if (chatState.isTyping) {
                          return Text(
                            'typing...',
                            style: TextStyle(
                              color: Colors.green[400],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          );
                        }
                      }

                      return Text(
                        'Tap to view profile',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      );
                    },
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
          onPressed: () {
            _showFeatureNotAvailable('Voice call');
          },
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: Colors.white),
          onPressed: () {
            _showFeatureNotAvailable('Video call');
          },
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

  Widget _buildMessagesList(ChatState chatState) {
    if (chatState.hasError && chatState.messages.isEmpty) {
      return _buildErrorWidget(chatState.error!);
    }

    if (chatState.messages.isEmpty && chatState.isLoading) {
      return _buildInitialLoadingWidget();
    }

    if (chatState.messages.isEmpty && !chatState.isLoading) {
      return _buildEmptyWidget();
    }

    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.messages.isNotEmpty) {
        _scrollToBottom(animated: false);
      }
    });

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: chatState.messages.length +
            (chatState.isLoading ? 1 : 0) +
            (chatState.isSending ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at the top
          if (chatState.isLoading && index == 0) {
            return _buildLoadingIndicator();
          }

          // Adjust index for loading indicator
          final messageIndex = chatState.isLoading ? index - 1 : index;

          // Sending indicator at the bottom
          if (chatState.isSending && messageIndex >= chatState.messages.length) {
            return _buildSendingIndicator();
          }

          if (messageIndex >= chatState.messages.length) {
            return const SizedBox.shrink();
          }

          final message = chatState.messages[messageIndex];
          final isFromMe = message.senderId == _currentUserId;
          final previousMessage = messageIndex > 0
              ? chatState.messages[messageIndex - 1]
              : null;
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

  Widget _buildAvatar({bool isCurrentUser = false}) {
    if (isCurrentUser) {
      // Use the current user profile provider for current user's avatar
      return Consumer(
        builder: (context, ref, child) {
          final currentUserProfile = ref.watch(currentUserProfileProvider);

          return currentUserProfile.when(
            data: (profile) {
              final profilePic = profile?.profilePic;

              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[700],
                ),
                child: (profilePic?.isNotEmpty ?? false)
                    ? ClipOval(
                  child: Image.network(
                    profilePic!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        color: Colors.grey[400],
                        size: 12,
                      );
                    },
                  ),
                )
                    : Icon(
                  Icons.person,
                  color: Colors.grey[400],
                  size: 12,
                ),
              );
            },
            loading: () => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[700],
              ),
              child: const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            error: (error, stack) => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[700],
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[400],
                size: 12,
              ),
            ),
          );
        },
      );
    } else {
      // Use the receiver's profile pic passed via widget parameters
      final profilePic = widget.receiverProfilePic;

      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[700],
        ),
        child: (profilePic?.isNotEmpty ?? false)
            ? ClipOval(
          child: Image.network(
            profilePic!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                color: Colors.grey[400],
                size: 12,
              );
            },
          ),
        )
            : Icon(
          Icons.person,
          color: Colors.grey[400],
          size: 12,
        ),
      );
    }
  }
  Widget _buildTimestamp(DateTime dateTime) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(dateTime),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildSendingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue[600]?.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sending...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 32),
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
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation\nwith ${widget.receiverName}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red[900]?.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }


  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit mode indicator
              if (_editingMessageId != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Editing message',
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                        ),
                      ),
                      GestureDetector(
                        onTap: _cancelEdit,
                        child: Icon(Icons.close, color: Colors.orange, size: 16),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment button
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: IconButton(
                      onPressed: () => _showAttachmentOptions(),
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Colors.grey[400],
                        size: 24,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ),
                  // Message input field
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _editingMessageId != null
                              ? 'Edit message...'
                              : 'Message ${widget.receiverName}...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send button
                  Consumer(
                    builder: (context, ref, child) {
                      final chatState = _currentUserId != null
                          ? ref.watch(directMessageProvider(createChatParams(
                        currentUserId: _currentUserId!,
                        receiverId: widget.receiverId,
                      )))
                          : null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: GestureDetector(
                          onTap: (_isTyping || _editingMessageId != null) &&
                              !(chatState?.isSending ?? false)
                              ? _sendMessage
                              : null,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: (_isTyping || _editingMessageId != null)
                                  ? Colors.blue
                                  : Colors.grey[700],
                              shape: BoxShape.circle,
                            ),
                            child: chatState?.isSending == true
                                ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            )
                                : Icon(
                              _editingMessageId != null
                                  ? Icons.check
                                  : (_isTyping ? Icons.send : Icons.mic),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(DirectMessage message, bool isFromMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            if (isFromMe) ...[
              _buildMessageOption(
                Icons.edit,
                'Edit',
                    () {
                  Navigator.pop(context);
                  _startEdit(message);
                },
              ),
              const SizedBox(height: 12),
              _buildMessageOption(
                Icons.delete,
                'Delete',
                    () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(message.id);
                },
                isDestructive: true,
              ),
            ],
            const SizedBox(height: 12),
            _buildMessageOption(
              Icons.copy,
              'Copy',
                  () {
                Navigator.pop(context);
                _copyMessageToClipboard(message.content);
              },
            ),
            const SizedBox(height: 12),
            _buildMessageOption(
              Icons.reply,
              'Reply',
                  () {
                Navigator.pop(context);
                _showFeatureNotAvailable('Reply to message');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageOption(
      IconData icon,
      String label,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.white,
                fontSize: 16,
              ),
            ),
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

  void _copyMessageToClipboard(String content) {
    // TODO: Implement clipboard copy
    _showFeatureNotAvailable('Copy to clipboard');
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
        content: const Text(
          'Are you sure you want to clear all messages in this chat? This action cannot be undone.',
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
              _showFeatureNotAvailable('Clear chat');
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  Icons.photo_camera,
                  'Camera',
                      () => _showFeatureNotAvailable('Camera'),
                ),
                _buildAttachmentOption(
                  Icons.photo_library,
                  'Gallery',
                      () => _showFeatureNotAvailable('Gallery'),
                ),
                _buildAttachmentOption(
                  Icons.insert_drive_file,
                  'File',
                      () => _showFeatureNotAvailable('File sharing'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dateTime.weekday - 1];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[dateTime.weekday - 1];
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    }
  }
}