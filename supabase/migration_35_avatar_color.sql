-- Migration 35: Add avatar_color column so users can pick their avatar background.
alter table profiles add column if not exists avatar_color text;
