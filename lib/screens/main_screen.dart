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
        // Incoming call received
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
                  backgroundColor: AppTheme.black,
                  body: Center(
                    child: CircularProgressIndicator(color: AppTheme.blue),
                  ),
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
    // Do not open the same callId repeatedly
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
          // Clear lastHandledCallId when the screen closes
          _lastHandledCallId = null;
        });
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
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
        backgroundColor: AppTheme.black,
        selectedItemColor: AppTheme.white,
        unselectedItemColor: AppTheme.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: context.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search, color: AppTheme.white),
            label: context.tr('search'),
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.white, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add, size: 18),
            ),
            label: context.tr('add'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_outlined),
            activeIcon: Icon(Icons.movie),
            label: context.tr('reels'),
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 13,
              backgroundColor: AppTheme.darkGrey,
              backgroundImage: (_currentUser?.photoUrl.isNotEmpty == true)
                  ? NetworkImage(_currentUser!.photoUrl)
                  : null,
              child: (_currentUser?.photoUrl.isNotEmpty != true)
                  ? const Icon(Icons.person, size: 16, color: AppTheme.grey)
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
