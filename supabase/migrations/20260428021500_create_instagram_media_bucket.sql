-- Creates the public Storage bucket used by the Flutter app.
-- The app stores media URLs in Firestore and uploads files to this Supabase bucket.

insert into storage.buckets (id, name, public)
values ('instagram-media', 'instagram-media', true)
on conflict (id) do update set public = true;

drop policy if exists "instagram_media_public_read" on storage.objects;
drop policy if exists "instagram_media_public_insert" on storage.objects;
drop policy if exists "instagram_media_public_update" on storage.objects;

create policy "instagram_media_public_read"
on storage.objects
for select
to public
using (bucket_id = 'instagram-media');

create policy "instagram_media_public_insert"
on storage.objects
for insert
to anon
with check (
  bucket_id = 'instagram-media'
  and lower((storage.foldername(name))[1]) in ('avatars', 'posts', 'chats')
);

create policy "instagram_media_public_update"
on storage.objects
for update
to anon
using (
  bucket_id = 'instagram-media'
  and lower((storage.foldername(name))[1]) in ('avatars', 'posts', 'chats')
)
with check (
  bucket_id = 'instagram-media'
  and lower((storage.foldername(name))[1]) in ('avatars', 'posts', 'chats')
);
