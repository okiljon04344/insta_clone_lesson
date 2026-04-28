import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/user_model.dart';
import '../../services/call_service.dart';
import '../../theme/app_theme.dart';

class CallScreen extends StatefulWidget {
  final UserModel otherUser;
  final bool isVideo;
  final bool isOutgoing;

  /// Kiruvchi qo'ng'iroq uchun callId (isOutgoing=false bo'lganda kerak)
  final String? callId;

  const CallScreen({
    super.key,
    required this.otherUser,
    required this.isVideo,
    required this.isOutgoing,
    this.callId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isCameraOff = false;
  bool _isConnected = false;
  bool _isEnding = false;
  String? _callId;
  StreamSubscription? _statusSub;
  Timer? _timeoutTimer;

  final _callService = CallService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.93, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isOutgoing) {
      _startOutgoingCall();
    } else {
      _callId = widget.callId;
      if (_callId != null) {
        _listenToCallStatus(_callId!);
        _timeoutTimer = Timer(const Duration(seconds: 35), () {
          if (mounted && !_isConnected && _callId != null) {
            _callService.markMissedIfOld(_callId!);
            _closeScreen();
          }
        });
      }
    }
  }

  Future<void> _startOutgoingCall() async {
    try {
      final id = await _callService.initiateCall(
        toUid: widget.otherUser.uid,
        isVideo: widget.isVideo,
      );
      if (!mounted) return;
      setState(() => _callId = id);

      _listenToCallStatus(id);

      // 30 soniya javob yo'q = missed
      _timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && !_isConnected && _callId != null) {
          _callService.markMissedIfOld(_callId!);
          _closeScreen();
        }
      });
    } catch (_) {
      _closeScreen();
    }
  }

  void _closeScreen() {
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _listenToCallStatus(String callId) {
    _statusSub?.cancel();
    _statusSub = _callService.callStatusStream(callId).listen((status) {
      if (!mounted) return;
      if (status == CallStatus.accepted) {
        _timeoutTimer?.cancel();
        setState(() => _isConnected = true);
      } else if (status == CallStatus.declined ||
          status == CallStatus.ended ||
          status == CallStatus.missed) {
        _closeScreen();
      }
    });
  }

  Future<void> _endCall() async {
    if (_isEnding) return;
    _isEnding = true;
    _timeoutTimer?.cancel();
    if (_callId != null) await _callService.endCall(_callId!);
    _closeScreen();
  }

  Future<void> _acceptCall() async {
    if (_isEnding || _callId == null) return;
    _isEnding = true;
    _timeoutTimer?.cancel();
    await _callService.acceptCall(_callId!);
    if (mounted) {
      setState(() {
        _isConnected = true;
        _isEnding = false;
      });
    }
    _listenToCallStatus(_callId!);
  }

  Future<void> _declineCall() async {
    if (_isEnding) return;
    _isEnding = true;
    _timeoutTimer?.cancel();
    if (_callId != null) await _callService.declineCall(_callId!);
    _closeScreen();
  }

  String _statusText(BuildContext context) {
    if (!widget.isOutgoing && !_isConnected) {
      return context.tr('call_incoming');
    }
    if (_isConnected) return context.tr('call_connected');
    return context.tr('call_connecting');
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _statusSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Fon (video qo'ng'iroqda kamera ko'rinishi bo'ladi)
          if (widget.isVideo && !_isCameraOff)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF16213E),
                    Color(0xFF0F3460),
                    Color(0xFF533483),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0D0D1A)],
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Yuqori qism
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white70,
                        ),
                        onPressed: _endCall,
                      ),
                      Text(
                        widget.isVideo
                            ? context.tr('video_call')
                            : context.tr('voice_call'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Foydalanuvchi avatari
                ScaleTransition(
                  scale: !_isConnected
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isConnected
                            ? Colors.greenAccent.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isConnected ? Colors.green : AppTheme.blue)
                              .withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.darkGrey,
                      backgroundImage: widget.otherUser.photoUrl.isNotEmpty
                          ? NetworkImage(widget.otherUser.photoUrl)
                          : null,
                      child: widget.otherUser.photoUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: AppTheme.grey,
                              size: 60,
                            )
                          : null,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Foydalanuvchi ismi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.otherUser.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.otherUser.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.blue,
                        size: 20,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  _statusText(context),
                  style: TextStyle(
                    color: _isConnected ? Colors.greenAccent : Colors.amber,
                    fontSize: 14,
                  ),
                ),

                const Spacer(flex: 3),

                if (!widget.isOutgoing && !_isConnected)
                  _buildIncomingCallButtons()
                else
                  _buildCallControls(),

                const SizedBox(height: 48),
              ],
            ),
          ),

          // O'z kamera ko'rinishi (video bo'lsa)
          if (widget.isVideo && !_isCameraOff)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                width: 90,
                height: 130,
                decoration: BoxDecoration(
                  color: AppTheme.darkGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppTheme.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCallControls() {
    return Column(
      children: [
        if (widget.isVideo)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: _isCameraOff
                    ? Icons.videocam_off
                    : Icons.videocam_outlined,
                label: _isCameraOff
                    ? context.tr('camera_on')
                    : context.tr('camera'),
                onTap: () => setState(() => _isCameraOff = !_isCameraOff),
                isActive: !_isCameraOff,
              ),
              const SizedBox(width: 20),
              _ControlButton(
                icon: Icons.switch_camera_outlined,
                label: context.tr('switch_camera'),
                onTap: () {},
              ),
            ],
          ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic_outlined,
              label: _isMuted ? context.tr('mic_on') : context.tr('mic'),
              onTap: () => setState(() => _isMuted = !_isMuted),
              isActive: !_isMuted,
            ),
            const SizedBox(width: 20),

            // Tugatish tugmasi
            GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(width: 20),
            _ControlButton(
              icon: _isSpeaker ? Icons.volume_up : Icons.volume_off,
              label: _isSpeaker
                  ? context.tr('speaker')
                  : context.tr('earpiece'),
              onTap: () => setState(() => _isSpeaker = !_isSpeaker),
              isActive: _isSpeaker,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomingCallButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rad etish
        Column(
          children: [
            GestureDetector(
              onTap: _declineCall,
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('decline'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(width: 72),
        // Qabul qilish
        Column(
          children: [
            GestureDetector(
              onTap: _acceptCall,
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isVideo ? Icons.videocam : Icons.call,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('accept'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white30 : Colors.white12,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white38,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white70 : Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
