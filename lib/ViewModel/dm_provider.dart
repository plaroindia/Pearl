// dm_provider.dart - Fixed version with proper subscription management
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'dart:convert';

// Message Model (unchanged)
class DirectMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRead;
  final String? replyToId;
  final Map<String, dynamic>? metadata;

  const DirectMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = 'text',
    required this.createdAt,
    this.updatedAt,
    this.isRead = false,
    this.replyToId,
    this.metadata,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    try {
      return DirectMessage(
        id: _parseStringField(json['id'], 'id'),
        chatId: _parseStringField(json['chat_id'], 'chat_id'),
        senderId: _parseStringField(json['sender_id'], 'sender_id'),
        receiverId: _parseStringField(json['receiver_id'], 'receiver_id'),
        content: _parseStringField(json['content'], 'content'),
        messageType: json['message_type'] as String? ?? 'text',
        createdAt: _parseDateTime(json['created_at'], 'created_at'),
        updatedAt: json['updated_at'] != null
            ? _parseDateTime(json['updated_at'], 'updated_at')
            : null,
        isRead: json['is_read'] as bool? ?? false,
        replyToId: json['reply_to_id'] as String?,
        metadata: _parseMetadata(json['metadata']),
      );
    } catch (e) {
      print('Error parsing DirectMessage from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static String _parseStringField(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Required field $fieldName is null');
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  static DateTime _parseDateTime(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Required field $fieldName is null');
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        throw FormatException('Invalid datetime format for $fieldName: $value');
      }
    }
    if (value is DateTime) {
      return value;
    }
    throw FormatException('Invalid type for $fieldName: ${value.runtimeType}');
  }

  static Map<String, dynamic>? _parseMetadata(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      } catch (e) {
        print('Error parsing metadata JSON: $e');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_read': isRead,
      'reply_to_id': replyToId,
      'metadata': metadata,
    };
  }

  DirectMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    String? messageType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) {
    return DirectMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      replyToId: replyToId ?? this.replyToId,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Chat State
class ChatState {
  final List<DirectMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final bool hasMore;
  final String? currentUserId;
  final bool isTyping;
  final DateTime? lastSeen;
  final Map<String, DirectMessage> pendingMessages;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.hasMore = true,
    this.currentUserId,
    this.isTyping = false,
    this.lastSeen,
    this.pendingMessages = const {},
  });

  ChatState copyWith({
    List<DirectMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool? hasMore,
    String? currentUserId,
    bool? isTyping,
    DateTime? lastSeen,
    Map<String, DirectMessage>? pendingMessages,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
      hasMore: hasMore ?? this.hasMore,
      currentUserId: currentUserId ?? this.currentUserId,
      isTyping: isTyping ?? this.isTyping,
      lastSeen: lastSeen ?? this.lastSeen,
      pendingMessages: pendingMessages ?? this.pendingMessages,
    );
  }

  bool get isEmpty => messages.isEmpty && !isLoading;
  bool get hasError => error != null;
}

// DM Notifier - FIXED VERSION
class DirectMessageNotifier extends StateNotifier<ChatState> {
  final String chatId;
  final String currentUserId;
  final String receiverId;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  Timer? _typingTimer;
  Timer? _debounceTimer;
  static const int _pageSize = 50;

  // Track subscription state
  bool _isSubscribed = false;
  bool _isDisposed = false;

  DirectMessageNotifier({
    required this.chatId,
    required this.currentUserId,
    required this.receiverId,
  }) : super(ChatState(currentUserId: currentUserId)) {
    _initializeChat();
  }

  void _initializeChat() {
    if (!_isDisposed) {
      _loadMessages();
      _subscribeToMessages();
    }
  }

  static String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<void> _loadMessages({bool loadMore = false}) async {
    if (_isDisposed) return;
    if (state.isLoading && !loadMore) return;
    if (!state.hasMore && loadMore) return;

    try {
      if (!loadMore) {
        state = state.copyWith(isLoading: true, error: null);
      }

      final offset = loadMore ? state.messages.length : 0;

      final response = await _supabase
          .from('direct_messages')
          .select('*')
          .eq('chat_id', chatId)
          .not('id', 'is', null)
          .not('sender_id', 'is', null)
          .not('receiver_id', 'is', null)
          .not('content', 'is', null)
          .not('created_at', 'is', null)
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      if (_isDisposed) return;

      final List<DirectMessage> newMessages = [];

      for (final json in response as List) {
        try {
          final message = DirectMessage.fromJson(json);
          newMessages.add(message);
        } catch (e) {
          print('Skipping invalid message: $e');
          continue;
        }
      }

      if (_isDisposed) return;

      final updatedMessages = loadMore
          ? [...state.messages, ...newMessages.reversed]
          : newMessages.reversed.toList();

      state = state.copyWith(
        messages: updatedMessages,
        isLoading: false,
        hasMore: newMessages.length == _pageSize,
      );

      // Mark messages as read with debounce
      _debounceMarkAsRead();

    } catch (error) {
      if (!_isDisposed) {
        print('Error loading messages: $error');
        state = state.copyWith(
          isLoading: false,
          error: _getErrorMessage(error),
        );
      }
    }
  }

  void _debounceMarkAsRead() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        _markMessagesAsRead();
      }
    });
  }

  void _subscribeToMessages() {
    if (_isSubscribed || _isDisposed) return;

    try {
      _messagesSubscription = _supabase
          .from('direct_messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .order('created_at')
          .listen(
            (data) {
          if (_isDisposed) return;

          _handleMessageUpdate(data);
        },
        onError: (error) {
          if (!_isDisposed) {
            print('Stream error: $error');
            // Don't set error state for rate limit issues - just retry later
            if (!error.toString().contains('ChannelRateLimitReached')) {
              state = state.copyWith(error: _getErrorMessage(error));
            }

            // Retry subscription after delay for rate limit errors
            if (error.toString().contains('ChannelRateLimitReached')) {
              Timer(const Duration(seconds: 5), () {
                if (!_isDisposed) {
                  _retrySubscription();
                }
              });
            }
          }
        },
        onDone: () {
          _isSubscribed = false;
        },
      );

      _isSubscribed = true;
    } catch (error) {
      print('Error setting up subscription: $error');
    }
  }

  void _retrySubscription() {
    if (!_isDisposed && !_isSubscribed) {
      _messagesSubscription?.cancel();
      _messagesSubscription = null;
      _isSubscribed = false;

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_isDisposed) {
          _subscribeToMessages();
        }
      });
    }
  }

  void _handleMessageUpdate(List<Map<String, dynamic>> data) {
    try {
      final List<DirectMessage> messages = [];

      for (final json in data) {
        try {
          final message = DirectMessage.fromJson(json);
          messages.add(message);
        } catch (e) {
          print('Skipping invalid message in stream: $e');
          continue;
        }
      }

      // Sort messages by creation time
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Only process if we have existing messages to compare against
      if (state.messages.isNotEmpty) {
        final existingIds = state.messages.map((m) => m.id).toSet();
        final newMessages = messages
            .where((m) => !existingIds.contains(m.id))
            .toList();

        if (newMessages.isNotEmpty) {
          final updatedMessages = [...state.messages, ...newMessages];
          updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

          // Remove any pending messages that are now confirmed
          final updatedPending = Map<String, DirectMessage>.from(state.pendingMessages);
          for (final message in newMessages) {
            updatedPending.remove(message.id);
          }

          if (!_isDisposed) {
            state = state.copyWith(
              messages: updatedMessages,
              pendingMessages: updatedPending,
            );

            // Auto-mark new messages from others as read
            _debounceMarkAsRead();
          }
        }
      } else {
        // First time loading - set all messages
        if (!_isDisposed) {
          state = state.copyWith(messages: messages);
          _debounceMarkAsRead();
        }
      }
    } catch (error) {
      print('Error handling message update: $error');
    }
  }

  Future<void> sendMessage({
    required String content,
    String messageType = 'text',
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) async {
    if (content.trim().isEmpty || _isDisposed) return;

    final messageId = _uuid.v4();

    try {
      state = state.copyWith(isSending: true, error: null);

      final tempMessage = DirectMessage(
        id: messageId,
        chatId: chatId,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content.trim(),
        messageType: messageType,
        createdAt: DateTime.now(),
        isRead: false,
        replyToId: replyToId,
        metadata: metadata,
      );

      // Add optimistic message
      final updatedMessages = [...state.messages, tempMessage];
      final updatedPending = Map<String, DirectMessage>.from(state.pendingMessages);
      updatedPending[messageId] = tempMessage;

      if (!_isDisposed) {
        state = state.copyWith(
          messages: updatedMessages,
          pendingMessages: updatedPending,
        );
      }

      // Send to database
      await _supabase.from('direct_messages').insert({
        'id': messageId,
        'chat_id': chatId,
        'sender_id': currentUserId,
        'receiver_id': receiverId,
        'content': content.trim(),
        'message_type': messageType,
        'reply_to_id': replyToId,
        'metadata': metadata,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Remove from pending on success
      if (!_isDisposed) {
        final finalPending = Map<String, DirectMessage>.from(state.pendingMessages);
        finalPending.remove(messageId);

        state = state.copyWith(
          isSending: false,
          pendingMessages: finalPending,
        );
      }

    } catch (error) {
      if (!_isDisposed) {
        // Remove optimistic message on error
        final updatedMessages = state.messages
            .where((m) => m.id != messageId)
            .toList();

        final updatedPending = Map<String, DirectMessage>.from(state.pendingMessages);
        updatedPending.remove(messageId);

        state = state.copyWith(
          messages: updatedMessages,
          pendingMessages: updatedPending,
          isSending: false,
          error: _getErrorMessage(error),
        );
      }
      rethrow;
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_isDisposed) return;

    try {
      final unreadMessages = state.messages
          .where((m) => m.senderId != currentUserId && !m.isRead)
          .map((m) => m.id)
          .toList();

      if (unreadMessages.isNotEmpty) {
        await _supabase
            .from('direct_messages')
            .update({'is_read': true})
            .inFilter('id', unreadMessages);
      }
    } catch (error) {
      print('Error marking messages as read: $error');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    if (_isDisposed) return;

    try {
      await _supabase
          .from('direct_messages')
          .delete()
          .eq('id', messageId)
          .eq('sender_id', currentUserId);

      if (!_isDisposed) {
        final updatedMessages = state.messages
            .where((m) => m.id != messageId)
            .toList();

        state = state.copyWith(messages: updatedMessages);
      }

    } catch (error) {
      if (!_isDisposed) {
        state = state.copyWith(error: _getErrorMessage(error));
      }
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    if (newContent.trim().isEmpty || _isDisposed) return;

    try {
      await _supabase
          .from('direct_messages')
          .update({
        'content': newContent.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', messageId)
          .eq('sender_id', currentUserId);

      if (!_isDisposed) {
        final updatedMessages = state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(
              content: newContent.trim(),
              updatedAt: DateTime.now(),
            );
          }
          return m;
        }).toList();

        state = state.copyWith(messages: updatedMessages);
      }

    } catch (error) {
      if (!_isDisposed) {
        state = state.copyWith(error: _getErrorMessage(error));
      }
    }
  }

  void setTyping(bool isTyping) {
    if (_isDisposed) return;

    state = state.copyWith(isTyping: isTyping);

    if (isTyping) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && !_isDisposed) {
          state = state.copyWith(isTyping: false);
        }
      });
    }
  }

  void loadMoreMessages() {
    if (!_isDisposed) {
      _loadMessages(loadMore: true);
    }
  }

  void clearError() {
    if (!_isDisposed && state.hasError) {
      state = state.copyWith(error: null);
    }
  }

  void refresh() {
    if (!_isDisposed) {
      _loadMessages();
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      switch (error.code) {
        case '23505':
          return 'Message already exists';
        case '42P01':
          return 'Chat service unavailable';
        case '22P02':
          return 'Invalid message format';
        default:
          return 'Database error: ${error.message}';
      }
    } else if (error.toString().contains('timeout')) {
      return 'Message failed to send. Check your connection.';
    } else if (error.toString().contains('ChannelRateLimitReached')) {
      return 'Too many connections. Please wait a moment.';
    } else {
      return 'Failed to send message. Please try again.';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _typingTimer?.cancel();
    _debounceTimer?.cancel();
    _isSubscribed = false;
    super.dispose();
  }
}

// Chat List State and other classes (unchanged but with better disposal)
class ChatListState {
  final List<ChatPreview> chats;
  final bool isLoading;
  final String? error;

  const ChatListState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
  });

  ChatListState copyWith({
    List<ChatPreview>? chats,
    bool? isLoading,
    String? error,
  }) {
    return ChatListState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatPreview {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfilePic;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  const ChatPreview({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfilePic,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    return ChatPreview(
      chatId: json['chat_id'] as String,
      otherUserId: json['other_user_id'] as String,
      otherUserName: json['other_user_name'] as String,
      otherUserProfilePic: json['other_user_profile_pic'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
    );
  }
}

// Recent Chats Notifier with better disposal
class RecentChatsNotifier extends StateNotifier<ChatListState> {
  final String currentUserId;
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _chatsSubscription;
  bool _isDisposed = false;

  RecentChatsNotifier(this.currentUserId) : super(const ChatListState()) {
    _loadRecentChats();
    _subscribeToChats();
  }

  Future<void> _loadRecentChats() async {
    if (_isDisposed) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _supabase
          .from('direct_messages')
          .select('''
      chat_id,
      sender_id,
      receiver_id,
      content,
      created_at,
      user_profiles!direct_messages_sender_id_fkey(username, profile_pic),
      user_profiles!direct_messages_receiver_id_fkey(username, profile_pic)
    ''')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false)
          .limit(50);

      if (_isDisposed) return;

      final Map<String, ChatPreview> chatMap = {};

      for (final message in response as List) {
        final chatId = message['chat_id'] as String;
        if (!chatMap.containsKey(chatId)) {
          final isFromSender = message['sender_id'] == currentUserId;
          final otherUser = isFromSender ? message['receiver'] : message['sender'];

          chatMap[chatId] = ChatPreview(
            chatId: chatId,
            otherUserId: isFromSender ? message['receiver_id'] : message['sender_id'],
            otherUserName: otherUser['username'] ?? 'Unknown',
            otherUserProfilePic: otherUser['profile_pic'],
            lastMessage: message['content'],
            lastMessageTime: DateTime.parse(message['created_at']),
          );
        }
      }

      final chats = chatMap.values.toList()
        ..sort((a, b) => (b.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.lastMessageTime ?? DateTime.fromMillisecondsSinceEpoch(0)));

      if (!_isDisposed) {
        state = state.copyWith(chats: chats, isLoading: false);
      }

    } catch (error) {
      if (!_isDisposed) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load recent chats',
        );
      }
    }
  }

  void _subscribeToChats() {
    if (_isDisposed) return;

    _chatsSubscription = _supabase
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .listen((data) {
      if (_isDisposed) return;

      final relevantMessages = data.where((message) =>
      message['sender_id'] == currentUserId ||
          message['receiver_id'] == currentUserId).toList();

      if (relevantMessages.isNotEmpty) {
        _loadRecentChats();
      }
    },
        onError: (error) {
          print('Recent chats stream error: $error');
        });
  }

  void refresh() {
    if (!_isDisposed) {
      _loadRecentChats();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _chatsSubscription?.cancel();
    super.dispose();
  }
}

// Providers with autoDispose to prevent memory leaks
final directMessageProvider = StateNotifierProvider.family.autoDispose
<DirectMessageNotifier, ChatState, Map<String, String>>(
      (ref, params) {
    final notifier = DirectMessageNotifier(
      chatId: params['chatId']!,
      currentUserId: params['currentUserId']!,
      receiverId: params['receiverId']!,
    );

    // Ensure proper disposal
    ref.onDispose(() {
      notifier.dispose();
    });

    return notifier;
  },
);

final recentChatsProvider = StateNotifierProvider.family.autoDispose<RecentChatsNotifier, ChatListState, String>(
      (ref, currentUserId) {
    final notifier = RecentChatsNotifier(currentUserId);

    ref.onDispose(() {
      notifier.dispose();
    });

    return notifier;
  },
);

// Helper function to create chat parameters
Map<String, String> createChatParams({
  required String currentUserId,
  required String receiverId,
}) {
  return {
    'chatId': DirectMessageNotifier.generateChatId(currentUserId, receiverId),
    'currentUserId': currentUserId,
    'receiverId': receiverId,
  };
}