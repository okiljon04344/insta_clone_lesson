# Instagram Clone (Flutter / Firebase / Supabase)

[![CI](https://github.com/okiljon04344/insta_clone_lesson/actions/workflows/ci.yml/badge.svg)](https://github.com/okiljon04344/insta_clone_lesson/actions/workflows/ci.yml)

日本語 | [English](#english) | [O'zbekcha](#ozbekcha)

## 日本語

### 概要

Flutter と Firebase の学習のために作成した Instagram 風 SNS アプリです。認証・Firestore・ファイル保存（Supabase Storage）を組み合わせた、投稿・フォロー・チャットまでの一通りの流れを実装しています。学習用のため、一部の画面は UI のみです（下表参照）。

### 実装状況

| 機能 | 状況 | 内容 |
| --- | --- | --- |
| 認証 | 実装済み | メール / パスワード（ユーザー名でのログインも可）、電話番号（SMS コード、`verifyPhoneNumber`）、Google サインイン、パスワードリセット |
| 投稿 | 実装済み | 画像を選択して投稿（画像は Supabase Storage、投稿データは Firestore）、いいね、コメント、保存済み投稿 |
| ホームフィード | 実装済み | Firestore の投稿を新しい順に表示 |
| ストーリー | UI のみ | ホーム上部の表示はサンプルデータで、タップ操作や投稿機能はありません |
| 検索（Explore） | 実装済み | ユーザー名の前方一致検索と投稿一覧 |
| フォロー | 実装済み | フォロー / 解除、フォロワー・フォロー中の一覧、件数の更新 |
| チャット | 実装済み | Firestore によるテキスト・画像メッセージ、既読、入力中表示、オンライン状態 |
| 通話 | 一部のみ | 発信・応答・拒否・不在の状態を Firestore で管理し、着信画面を表示します。音声・映像の送受信は実装していません |
| 通知 | 実装済み | いいね・コメント・フォロー・メッセージ・通話などを Firestore に保存して一覧表示、未読数のバッジ |
| リール | UI のみ | 縦スクロールの画面はサンプルデータで、動画再生やアップロードはありません |
| プロフィール | 実装済み | プロフィール編集（アイコン画像、ユーザー名、自己紹介）、投稿数・フォロワー数の表示。ハイライトはダミー表示です |
| 多言語 | 実装済み | 言語設定画面と、Firestore の翻訳データ（`app_translations`）＋アプリ内の文字列によるフォールバック |

### 使用技術

Flutter / Dart、Firebase Authentication、Cloud Firestore、Supabase Storage、`firebase_data_connect`（`dataconnect/` と生成コードは含まれていますが、アプリ本体からはまだ使用していません）

### セットアップ

1. Flutter SDK（Dart 3.11 以上）をインストールします。
2. 自分の Firebase プロジェクトを用意し、`flutterfire configure` で `lib/firebase_options.dart` を再生成します。Authentication（Email / Phone / Google）と Firestore を有効にし、`firestore.rules` を適用します。
3. Supabase でプロジェクトを作成し、`supabase/migrations/` の SQL を適用してストレージバケット（既定名 `instagram-media`）を作成します。
4. 次のように `--dart-define` を指定して実行します。

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-or-publishable-key>
```

未指定の場合は `lib/supabase_config.dart` の既定値が使われます。ご自身の Supabase プロジェクトを使う場合は必ず指定してください。

```bash
flutter analyze
flutter test
```

テストは `UserModel` の変換を確認するスモークテストが 1 件のみです。GitHub Actions で `flutter analyze` と `flutter test` を実行しています。

## English

An Instagram-style social app built to learn Flutter and Firebase. It combines Firebase Auth, Cloud Firestore and Supabase Storage. Some screens are UI only.

- Implemented: email, phone (SMS) and Google sign-in; image posts with likes, comments and saved posts; Firestore feed; user search; follow/unfollow; text and image chat with seen, typing and online status; in-app notifications; profile editing; language settings.
- Partial: calls only track call state in Firestore (calling, accepted, declined, missed); no audio or video is transmitted.
- UI only: stories and reels use sample data; profile highlights are placeholders.

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-or-publishable-key>
```

You also need your own Firebase project (`flutterfire configure`). There is a single smoke test (`UserModel` mapping).

## O'zbekcha

Flutter va Firebase'ni o'rganish uchun yaratilgan Instagram'ga o'xshash ijtimoiy tarmoq ilovasi. Firebase Auth, Cloud Firestore va Supabase Storage ishlatiladi.

- Ishlaydi: email, telefon (SMS) va Google orqali kirish; rasmli postlar, like, izoh, saqlangan postlar; qidiruv; kuzatish; matn va rasmli chat; bildirishnomalar; profilni tahrirlash; til sozlamalari.
- Qisman: qo'ng'iroqlar faqat Firestore'da holat sifatida saqlanadi, ovoz/video uzatilmaydi.
- Faqat UI: Stories va Reels namunaviy ma'lumotlar bilan ishlaydi.

Ishga tushirish: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

---

Okiljon Nabiev — [Portfolio](https://okiljon04344.github.io)
