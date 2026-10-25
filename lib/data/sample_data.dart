import '../models/user.dart';
import '../models/story.dart';

const User currentUser = User(
  id: 'u0',
  username: 'siz',
  displayName: 'Siz',
  avatarUrl: 'https://picsum.photos/seed/me/200/200',
  bio: 'Flutter developer | Tashkent, Uzbekistan',
  postsCount: 42,
  followersCount: 1200,
  followingCount: 380,
);

const List<User> sampleUsers = [
  User(
    id: 'u1',
    username: 'aziz_dev',
    displayName: 'Aziz Karimov',
    avatarUrl: 'https://picsum.photos/seed/aziz/200/200',
    bio: 'Software Engineer at Google',
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
    bio: 'Photographer | Tashkent',
    postsCount: 234,
    followersCount: 32100,
    followingCount: 890,
  ),
  User(
    id: 'u3',
    username: 'sardor_travels',
    displayName: 'Sardor Xasanov',
    avatarUrl: 'https://picsum.photos/seed/sardor/200/200',
    bio: 'Travel blogger | 50+ countries',
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
    bio: 'Digital artist',
    postsCount: 89,
    followersCount: 4500,
    followingCount: 220,
  ),
  User(
    id: 'u5',
    username: 'jasur_fitness',
    displayName: 'Jasur Toshmatov',
    avatarUrl: 'https://picsum.photos/seed/jasur/200/200',
    bio: 'Fitness coach | Personal trainer',
    postsCount: 312,
    followersCount: 21000,
    followingCount: 340,
  ),
  User(
    id: 'u6',
    username: 'dilnoza_chef',
    displayName: 'Dilnoza Mirzayeva',
    avatarUrl: 'https://picsum.photos/seed/dilnoza/200/200',
    bio: 'Chef | Food lover',
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
