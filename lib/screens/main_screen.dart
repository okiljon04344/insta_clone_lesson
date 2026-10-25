import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'reels/reels_screen.dart';
import 'profile/profile_screen.dart';
import 'post/create_post_screen.dart';
import 'chat/call_screen.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../models/user_model.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;

  final List<Widget> _staticScreens = [
    const HomeScreen(),
    const ExploreScreen(),
    const _AddPostPlaceholder(),
    const ReelsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CallInfo?>(
      stream: CallService().incomingCallStream(),
      builder: (context, callSnap) {
        final incomingCall = callSnap.data;
        if (incomingCall != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleIncomingCall(incomingCall);
          });
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              ..._staticScreens,
              if (_currentUser != null)
                ProfileScreen(user: _currentUser!, isCurrentUser: true)
              else
                const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  String? _lastHandledCallId;

  void _handleIncomingCall(CallInfo call) {
    // The stream re-emits while the call is ringing; open the screen once.
    if (_lastHandledCallId == call.id) return;
    _lastHandledCallId = call.id;

    FirebaseFirestore.instance.collection('users').doc(call.fromUid).get().then(
      (snap) {
        if (!mounted) return;
        final caller = snap.exists
            ? UserModel.fromMap(snap.data()!)
            : UserModel(
                uid: call.fromUid,
                email: '',
                username: call.callerUsername.isNotEmpty
                    ? call.callerUsername
                    : 'caller',
                displayName: call.callerDisplayName.isNotEmpty
                    ? call.callerDisplayName
                    : 'Qo\'ng\'iroq',
                photoUrl: call.callerPhotoUrl,
                createdAt: call.createdAt,
              );
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => CallScreen(
              otherUser: caller,
              isVideo: call.isVideo,
              isOutgoing: false,
              callId: call.id,
            ),
          ),
        ).then((_) {
          _lastHandledCallId = null;
        });
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const CreatePostScreen(),
              ),
            );
            return;
          }
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppTheme.background,
        elevation: 0,
        selectedItemColor: AppTheme.accent,
        unselectedItemColor: AppTheme.muted,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: context.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: context.tr('search'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_box_outlined),
            label: context.tr('add'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.movie_outlined),
            activeIcon: const Icon(Icons.movie),
            label: context.tr('reels'),
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 13,
              backgroundColor: AppTheme.surfaceMuted,
              backgroundImage: (_currentUser?.photoUrl.isNotEmpty == true)
                  ? NetworkImage(_currentUser!.photoUrl)
                  : null,
              child: (_currentUser?.photoUrl.isNotEmpty != true)
                  ? const Icon(Icons.person, size: 16, color: AppTheme.muted)
                  : null,
            ),
            label: context.tr('profile'),
          ),
        ],
      ),
    );
  }
}

class _AddPostPlaceholder extends StatelessWidget {
  const _AddPostPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
