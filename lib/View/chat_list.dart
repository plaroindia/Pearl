// FIXED NAVIGATION - Complete chat_list.dart with proper navigation
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../Model/user_profile.dart';
import '../../View/widgets/profile_card.dart';
import '../../ViewModel/chat_list_provider.dart';

import 'chat_page.dart'; // Adjust this import path as needed


class ChatList extends ConsumerStatefulWidget {
  final String userId;
  final Function(UserProfile)? onUserTap;
  final bool showAppBar;
  final bool isBottomSheet;

  const ChatList({
    super.key,
    required this.userId,
    this.onUserTap,
    this.showAppBar = true,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<ChatList> createState() => _ChatListState();
}

class _ChatListState extends ConsumerState<ChatList>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchInitialData() {
    final notifier = ref.read(chatListProvider(widget.userId).notifier);
    notifier.fetchChatUsers(refresh: true);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent - 200) {
        ref.read(chatListProvider(widget.userId).notifier).fetchChatUsers();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final chatState = ref.watch(chatListProvider(widget.userId));

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(chatListProvider(widget.userId).notifier).refresh();
      },
      backgroundColor: Colors.grey[900],
      color: Colors.blue,
      child: Column(
        children: [
          if (widget.showAppBar) _buildAppBar(),
          Expanded(
            child: _buildList(
              users: chatState.users,
              isLoading: chatState.isLoading,
              error: chatState.error,
              hasMore: chatState.hasMore,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Text(
            "Chats",
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList({
    required List<UserProfile> users,
    required bool isLoading,
    required String? error,
    required bool hasMore,
  }) {
    if (error != null && users.isEmpty) {
      return _buildErrorWidget(error);
    }

    if (users.isEmpty && !isLoading) {
      return _buildEmptyWidget();
    }

    if (users.isEmpty && isLoading) {
      return _buildInitialLoadingWidget();
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: users.length + (hasMore && isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= users.length) {
          return _buildLoadingItem();
        }

        final user = users[index];
        return _buildChatListItem(user);
      },
    );
  }

  Widget _buildChatListItem(UserProfile user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (widget.onUserTap != null) {
              widget.onUserTap!(user);
            } else {
              // Fallback - navigate directly
              _navigateToChat(context, user);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildProfileImage(user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (user.bio?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.bio!,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Direct navigation method
  void _navigateToChat(BuildContext context, UserProfile user) {

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IndividualChatPage(
            receiver: user,
            receiverId: user.user_id,
            receiverName: user.username,
            receiverProfilePic: user.profilePic,
          ),
        ),
      );
    } catch (e) {
      print('Navigation error: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildProfileImage(UserProfile user) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[700],
      ),
      child: user.profilePic?.isNotEmpty == true
          ? ClipOval(
        child: Image.network(
          user.profilePic!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              color: Colors.grey[400],
              size: 25,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      )
          : Icon(
        Icons.person,
        color: Colors.grey[400],
        size: 25,
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
            'Loading chats...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          strokeWidth: 2,
        ),
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
              Icons.message_outlined,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No chats yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start following people to see them here\nand begin conversations',
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
            onPressed: _fetchInitialData,
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
}

// Main ChatPage with fixed navigation
class ChatPage extends ConsumerWidget {
  final String userId;

  const ChatPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => _showNewMessageBottomSheet(context),
          ),
        ],
      ),
      body: ChatList(
        userId: userId,
        showAppBar: false,
        onUserTap: (user) {
          print('ChatPage: User tapped - ${user.username}'); // Debug log
          _handleUserTap(context, user);
        },
      ),
    );
  }

  void _handleUserTap(BuildContext context, UserProfile user) {
    print('_handleUserTap called for user: ${user.username}'); // Debug log

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IndividualChatPage(
            receiver: user,
            receiverId: user.user_id,
            receiverName: user.username,
            receiverProfilePic: user.profilePic,
          ),
        ),
      ).then((value) {
        print('Navigation completed'); // Debug log
      });
    } catch (e) {
      print('Navigation error in _handleUserTap: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showNewMessageBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'New message',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(color: Colors.grey, height: 1),
            Expanded(
              child: ChatList(
                userId: userId,
                showAppBar: false,
                isBottomSheet: true,
                onUserTap: (user) {
                  Navigator.pop(context);
                  _handleUserTap(context, user);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}