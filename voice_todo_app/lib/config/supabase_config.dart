import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Setup instructions ────────────────────────────────────────────────────
// 1. Go to https://supabase.com → New project.
// 2. Run this SQL in the Supabase SQL editor:
//
//   create table public.todos (
//     id            uuid default gen_random_uuid() primary key,
//     user_id       uuid references auth.users(id) on delete cascade not null,
//     title         text not null,
//     description   text,
//     is_completed  boolean default false not null,
//     priority      text default 'medium' not null,
//     created_at    timestamptz default now() not null,
//     completed_at  timestamptz,
//     detected_language text,
//     reminder_at       timestamptz,
//     reminder_frequency text not null default 'none'
//       check (reminder_frequency in ('none', 'once', '30min', '1hr', '3hr', 'daily', 'weekly'))
//   );
//   alter table public.todos enable row level security;
//
// If upgrading an existing todos table, run:
//   alter table public.todos
//     add column if not exists reminder_at timestamptz,
//     add column if not exists reminder_frequency text not null default 'none'
//       check (reminder_frequency in ('none', 'once', '30min', '1hr', '3hr', 'daily', 'weekly'));
//   create policy "Users manage own todos"
//     on public.todos for all
//     using  (auth.uid() = user_id)
//     with check (auth.uid() = user_id);
//   alter publication supabase_realtime add table public.todos;
//
// 3. Settings → API → copy Project URL and anon/public key below.
// ──────────────────────────────────────────────────────────────────────────

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://your-project-ref.supabase.co',
);

const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your-anon-key',
);

SupabaseClient get supabase => Supabase.instance.client;
