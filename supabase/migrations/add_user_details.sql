-- Add gender, height, and weight columns to profiles table
-- Run this in Supabase Dashboard → SQL Editor → New Query

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS gender text,
  ADD COLUMN IF NOT EXISTS height_cm numeric(5,1),
  ADD COLUMN IF NOT EXISTS weight_kg numeric(5,1);
