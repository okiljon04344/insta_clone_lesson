import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/user_model.dart';
import '../../services/call_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';

class CallScreen extends StatefulWidget {
  final UserModel otherUser;
  final bool isVideo;
  final bool isOutgoing;

  /// Required for incoming calls (`isOutgoing == false`).
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

      // No answer within 30 seconds counts as missed.
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
    final showSelfPreview = widget.isVideo && !_isCameraOff;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        onPressed: _endCall,
                      ),
                      Text(
                        widget.isVideo
                            ? context.tr('video_call')
                            : context.tr('voice_call'),
                        style: AppTheme.captionStyle,
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: !_isConnected
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isConnected ? AppTheme.accent : AppTheme.border,
                        width: 2,
                      ),
                    ),
                    child: UserAvatar(
                      photoUrl: widget.otherUser.photoUrl,
                      radius: 60,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.otherUser.displayName,
                      style: AppTheme.headlineStyle,
                    ),
                    if (widget.otherUser.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.accent,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText(context),
                  style: TextStyle(
                    color: _isConnected ? AppTheme.accent : AppTheme.muted,
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
            if (showSelfPreview)
              Positioned(
                top: 64,
                right: 20,
                child: Container(
                  width: 90,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.muted,
                      size: 32,
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              const SizedBox(width: 24),
              _ControlButton(
                icon: Icons.switch_camera_outlined,
                label: context.tr('switch_camera'),
                onTap: () {},
              ),
            ],
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic_outlined,
              label: _isMuted ? context.tr('mic_on') : context.tr('mic'),
              onTap: () => setState(() => _isMuted = !_isMuted),
              isActive: !_isMuted,
            ),
            const SizedBox(width: 24),
            _RoundAction(
              icon: Icons.call_end,
              color: AppTheme.danger,
              onTap: _endCall,
            ),
            const SizedBox(width: 24),
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
        Column(
          children: [
            _RoundAction(
              icon: Icons.call_end,
              color: AppTheme.danger,
              onTap: _declineCall,
            ),
            const SizedBox(height: 8),
            Text(context.tr('decline'), style: AppTheme.captionStyle),
          ],
        ),
        const SizedBox(width: 72),
        Column(
          children: [
            _RoundAction(
              icon: widget.isVideo ? Icons.videocam : Icons.call,
              color: AppTheme.accent,
              onTap: _acceptCall,
            ),
            const SizedBox(height: 8),
            Text(context.tr('accept'), style: AppTheme.captionStyle),
          ],
        ),
      ],
    );
  }
}

/// Large filled circle button used for accept / decline / hang up.
class _RoundAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoundAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.onAccent, size: 30),
      ),
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
    final color = isActive ? AppTheme.ink : AppTheme.muted;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.surfaceMuted : AppTheme.background,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
