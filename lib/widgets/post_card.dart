import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  bool _showHeart = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (!widget.post.isLiked) {
      setState(() {
        widget.post.isLiked = true;
        widget.post.likesCount++;
      });
    }
    setState(() => _showHeart = true);
    _heartController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _toggleLike() {
    setState(() {
      if (widget.post.isLiked) {
        widget.post.isLiked = false;
        widget.post.likesCount--;
      } else {
        widget.post.isLiked = true;
        widget.post.likesCount++;
      }
    });
  }

  void _toggleSave() {
    setState(() => widget.post.isSaved = !widget.post.isSaved);
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildImageSection(),
        _buildActions(),
        _buildLikes(),
        _buildCaption(),
        _buildCommentLink(),
        _buildTimeAgo(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.storyGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: widget.post.user.avatarUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: AppTheme.darkGrey),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.person, color: AppTheme.grey, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.post.user.username,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.post.user.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: AppTheme.blue,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                if (widget.post.location != null)
                  Text(
                    widget.post.location!,
                    style: const TextStyle(color: AppTheme.white, fontSize: 11),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showOptionsSheet(),
            icon: const Icon(Icons.more_horiz, color: AppTheme.white),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Images (PageView for multiple)
          widget.post.imageUrls.length > 1
              ? SizedBox(
                  height: 400,
                  child: PageView.builder(
                    itemCount: widget.post.imageUrls.length,
                    onPageChanged: (i) =>
                        setState(() => _currentImageIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: widget.post.imageUrls[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, _) =>
                          Container(height: 400, color: AppTheme.darkGrey),
                    ),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: widget.post.imageUrls[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, _) =>
                      Container(height: 400, color: AppTheme.darkGrey),
                  errorWidget: (_, _, _) =>
                      Container(height: 400, color: AppTheme.darkGrey),
                ),
          // Heart animation
          if (_showHeart)
            ScaleTransition(
              scale: _heartAnimation,
              child: const Icon(Icons.favorite, color: Colors.white, size: 90),
            ),
          // Pagination dots
          if (widget.post.imageUrls.length > 1)
            Positioned(
              bottom: 10,
              child: Row(
                children: List.generate(
                  widget.post.imageUrls.length,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == i
                          ? AppTheme.blue
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Like
          IconButton(
            onPressed: _toggleLike,
            icon: Icon(
              widget.post.isLiked ? Icons.favorite : Icons.favorite_border,
              color: widget.post.isLiked ? AppTheme.red : AppTheme.white,
              size: 26,
            ),
          ),
          // Comment
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppTheme.white,
              size: 24,
            ),
          ),
          // Share
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.send_outlined,
              color: AppTheme.white,
              size: 24,
            ),
          ),
          const Spacer(),
          // Save
          IconButton(
            onPressed: _toggleSave,
            icon: Icon(
              widget.post.isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: AppTheme.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        '${_formatCount(widget.post.likesCount)} ta like',
        style: const TextStyle(
          color: AppTheme.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCaption() {
    if (widget.post.caption.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${widget.post.user.username} ',
              style: const TextStyle(
                color: AppTheme.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: widget.post.caption,
              style: const TextStyle(color: AppTheme.white, fontSize: 13),
            ),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCommentLink() {
    if (widget.post.commentsCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: GestureDetector(
        onTap: () {},
        child: Text(
          '${_formatCount(widget.post.commentsCount)} ta izohni ko\'rish',
          style: const TextStyle(color: AppTheme.grey, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTimeAgo() {
    final ago = timeago.format(widget.post.createdAt, locale: 'en');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Text(
        ago.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.grey,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          _optionTile(
            'Hisobot berish',
            Icons.report_outlined,
            color: AppTheme.red,
          ),
          _optionTile('Yoqtirmayapman', Icons.thumb_down_outlined),
          _optionTile('Ulashish', Icons.share_outlined),
          _optionTile('Nusxa olish', Icons.link),
          _optionTile('Bekor qilish', Icons.close),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _optionTile(String label, IconData icon, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.white),
      title: Text(label, style: TextStyle(color: color ?? AppTheme.white)),
      onTap: () => Navigator.pop(context),
    );
  }
}
