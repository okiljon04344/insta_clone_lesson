import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ReelsScreen extends StatelessWidget {
  const ReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reels'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.camera_alt_outlined),
          ),
        ],
      ),
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 5,
        itemBuilder: (context, index) => _ReelItem(index: index),
      ),
    );
  }
}

// Placeholder content until real video posts exist.
const _reelUsers = [
  'aziz_dev',
  'malika_photo',
  'sardor_travels',
  'nodira_art',
  'jasur_fitness',
];
const _reelCaptions = [
  'Flutter animatsiyasi #flutter #coding',
  'Toshkentning kechki manzarasi #tashkent',
  'Samarqand - Sharq darvozasi #travel',
  'Yangi rasm davomi #art #creative',
  'Sabahlik mashq #fitness #gym',
];
const _reelSeeds = ['reel1', 'reel2', 'reel3', 'reel4', 'reel5'];

class _ReelItem extends StatefulWidget {
  final int index;
  const _ReelItem({required this.index});

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  bool _isLiked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _likes = (widget.index + 1) * 1247 + widget.index * 33;
  }

  @override
  Widget build(BuildContext context) {
    final seed = _reelSeeds[widget.index % _reelSeeds.length];

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://picsum.photos/seed/$seed/400/700',
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(color: AppTheme.surfaceMuted);
          },
        ),
        // Scrim so the white text stays readable on bright frames.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        const Center(
          child: Icon(
            Icons.play_circle_outline,
            color: Colors.white30,
            size: 64,
          ),
        ),
        Positioned(
          right: 12,
          bottom: 120,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _isLiked = !_isLiked;
                  _likes += _isLiked ? 1 : -1;
                }),
                child: Column(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_likes / 1000).toStringAsFixed(1)}K',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '456',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Column(
                children: [
                  Icon(Icons.send_outlined, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Ulashish',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Icon(Icons.more_vert, color: Colors.white, size: 28),
            ],
          ),
        ),
        Positioned(
          left: 12,
          right: 70,
          bottom: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://picsum.photos/seed/$seed/100/100',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _reelUsers[widget.index % _reelUsers.length],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Kuzatish',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _reelCaptions[widget.index % _reelCaptions.length],
                style: const TextStyle(color: Colors.white, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
