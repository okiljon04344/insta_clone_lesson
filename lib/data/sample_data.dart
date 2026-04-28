import '../models/user.dart';
import '../models/post.dart';
import '../models/story.dart';

final User currentUser = User(
  id: 'u0',
  username: 'siz',
  displayName: 'Siz',
  avatarUrl: 'https://picsum.photos/seed/me/200/200',
  bio: 'Flutter developer 🚀\nTashkent, Uzbekistan',
  postsCount: 42,
  followersCount: 1200,
  followingCount: 380,
);

final List<User> sampleUsers = [
  User(
    id: 'u1',
    username: 'aziz_dev',
    displayName: 'Aziz Karimov',
    avatarUrl: 'https://picsum.photos/seed/aziz/200/200',
    bio: 'Software Engineer at Google 🔧',
    postsCount: 128,
    followersCount: 15400,
    followingCount: 512,
    isVerified: true,
  ),
  User(
    id: 'u2',
    username: 'malika_photo',
    displayName: 'Malika Yusupova',
    avatarUrl: 'https://picsum.photos/seed/malika/200/200',
    bio: 'Photographer 📷 | Tashkent',
    postsCount: 234,
    followersCount: 32100,
    followingCount: 890,
  ),
  User(
    id: 'u3',
    username: 'sardor_travels',
    displayName: 'Sardor Xasanov',
    avatarUrl: 'https://picsum.photos/seed/sardor/200/200',
    bio: 'Travel blogger ✈️ | 50+ countries',
    postsCount: 567,
    followersCount: 89000,
    followingCount: 1200,
    isVerified: true,
  ),
  User(
    id: 'u4',
    username: 'nodira_art',
    displayName: 'Nodira Rahimova',
    avatarUrl: 'https://picsum.photos/seed/nodira/200/200',
    bio: 'Digital artist 🎨',
    postsCount: 89,
    followersCount: 4500,
    followingCount: 220,
  ),
  User(
    id: 'u5',
    username: 'jasur_fitness',
    displayName: 'Jasur Toshmatov',
    avatarUrl: 'https://picsum.photos/seed/jasur/200/200',
    bio: 'Fitness coach 💪 | Personal trainer',
    postsCount: 312,
    followersCount: 21000,
    followingCount: 340,
  ),
  User(
    id: 'u6',
    username: 'dilnoza_chef',
    displayName: 'Dilnoza Mirzayeva',
    avatarUrl: 'https://picsum.photos/seed/dilnoza/200/200',
    bio: 'Chef 🍽️ | Food lover',
    postsCount: 198,
    followersCount: 9800,
    followingCount: 650,
  ),
];

final List<Story> sampleStories = [
  Story(id: 's0', user: currentUser, isOwn: true),
  Story(id: 's1', user: sampleUsers[0]),
  Story(id: 's2', user: sampleUsers[1]),
  Story(id: 's3', user: sampleUsers[2]),
  Story(id: 's4', user: sampleUsers[3], isSeen: true),
  Story(id: 's5', user: sampleUsers[4], isSeen: true),
  Story(id: 's6', user: sampleUsers[5]),
];

final List<Post> samplePosts = [
  Post(
    id: 'p1',
    user: sampleUsers[0],
    imageUrls: ['https://picsum.photos/seed/post1/600/600'],
    caption:
        'Flutter bilan yangi loyiha boshlandi! 🚀 #flutter #coding #uzbekdev',
    likesCount: 1243,
    commentsCount: 87,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    location: 'Tashkent, Uzbekistan',
  ),
  Post(
    id: 'p2',
    user: sampleUsers[1],
    imageUrls: ['https://picsum.photos/seed/post2/600/600'],
    caption:
        'Bugungi suratlar 📸 Toshkentning go\'zal kunlari hech qachon zerikmaydi!',
    likesCount: 3821,
    commentsCount: 156,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    location: 'Old Town, Tashkent',
  ),
  Post(
    id: 'p3',
    user: sampleUsers[2],
    imageUrls: [
      'https://picsum.photos/seed/post3a/600/600',
      'https://picsum.photos/seed/post3b/600/600',
      'https://picsum.photos/seed/post3c/600/600',
    ],
    caption:
        'Samarqand - dunyoning eng go\'zal shahri! Registon maydoni haqiqatan ham ajoyib. ✈️🌍',
    likesCount: 12400,
    commentsCount: 432,
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    location: 'Registon, Samarqand',
  ),
  Post(
    id: 'p4',
    user: sampleUsers[3],
    imageUrls: ['https://picsum.photos/seed/post4/600/600'],
    caption:
        'Yangi rasm yaratdim! Digital art dunyosi cheksiz... 🎨 #art #digitalart',
    likesCount: 678,
    commentsCount: 45,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Post(
    id: 'p5',
    user: sampleUsers[4],
    imageUrls: ['https://picsum.photos/seed/post5/600/600'],
    caption:
        '100 kun challenge - 87-kun! 💪 Hech qachon to\'xtamang! #fitness #motivation',
    likesCount: 4532,
    commentsCount: 213,
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
  ),
  Post(
    id: 'p6',
    user: sampleUsers[5],
    imageUrls: ['https://picsum.photos/seed/post6/600/600'],
    caption:
        'Bugun oshxonada yangi taom tayyorladim 🍽️ Uzbek plov - world\'s best food!',
    likesCount: 2891,
    commentsCount: 178,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    location: 'Home Kitchen',
  ),
  Post(
    id: 'p7',
    user: sampleUsers[0],
    imageUrls: ['https://picsum.photos/seed/post7/600/800'],
    caption: 'Code, coffee, repeat ☕ #developer #life',
    likesCount: 892,
    commentsCount: 34,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

final List<String> exploreImages = List.generate(
  30,
  (i) => 'https://picsum.photos/seed/explore$i/300/300',
);
