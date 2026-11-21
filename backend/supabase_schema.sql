-- ========================================================================
-- PLANT AI Platform - Production Supabase PostgreSQL Schema
-- Project: AgTech Hackathon 2026 (Group 9 - Liberia)
-- Bong, Nimba, Lofa Counties Smallholder Advisory Platform
-- ========================================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. USERS TABLE (Role-Based Access: ADMIN, AGENT, FARMER)
create table if not exists users (
    id text primary key default uuid_generate_v4()::text,
    username text unique not null,
    password_hash text not null,
    salt text not null,
    role text not null check (role in ('ADMIN', 'AGENT', 'FARMER')),
    full_name text not null,
    phone_number text,
    county text,
    is_active boolean default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. FARMERS DIRECTORY
create table if not exists farmers (
    id text primary key default uuid_generate_v4()::text,
    full_name text not null,
    phone_number text unique not null,
    county text not null check (county in ('Bong', 'Nimba', 'Lofa', 'Montserrado', 'Margibi', 'Grand Bassa')),
    district text,
    gender text not null check (gender in ('female', 'male')),
    language_preference text default 'English' check (language_preference in ('English', 'Kpelle', 'Bassa', 'Mano')),
    consent_status text default 'ACTIVE' check (consent_status in ('ACTIVE', 'STOPPED')),
    livestock_interest boolean default false,
    registered_via text default 'USSD' check (registered_via in ('USSD', 'PWA', 'AGENT')),
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_farmers_county on farmers(county);
create index if not exists idx_farmers_phone on farmers(phone_number);

-- 3. SCAN CASES (Foliar Disease Diagnostic History & Triage)
create table if not exists scan_cases (
    id text primary key default uuid_generate_v4()::text,
    case_number text unique not null,
    farmer_id text references farmers(id) on delete set null,
    crop_type text not null, -- Focused strictly on 'Cassava' or 'Pepper'
    image_url text not null,
    ai_diagnosis text not null,
    ai_confidence float not null,
    severity text default 'Moderate',
    is_blurry boolean default false,
    status text default 'PENDING_ESCALATION' check (status in ('PENDING_ESCALATION', 'RESOLVED', 'AUTO_VERIFIED')),
    officer_notes text,
    officer_resolution text,
    resolution_sms_sent boolean default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    resolved_at timestamp with time zone
);

create index if not exists idx_scan_cases_status on scan_cases(status);
create index if not exists idx_scan_cases_crop on scan_cases(crop_type);

-- 4. KNOWLEDGE ITEMS (Rule ADV-01: CARI-Vetted Agricultural Advisory)
create table if not exists knowledge_items (
    id text primary key default uuid_generate_v4()::text,
    doc_id text unique not null,
    crop text not null,
    condition_name text not null,
    symptom_description text not null,
    cultural_control text not null,
    chemical_control text not null,
    vetted_sms_template varchar(160) not null,
    source_org text default 'CARI / MoA Liberia',
    approved_by text default 'Senior Agronomist S. Kollie',
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create index if not exists idx_knowledge_crop on knowledge_items(crop);

-- 5. SMS & USSD LOGS (Rule SMS-01: <= 160 Characters)
create table if not exists sms_logs (
    id text primary key default uuid_generate_v4()::text,
    recipient_phone text not null,
    county text,
    message_text varchar(160) not null,
    char_count integer not null,
    status text default 'DELIVERED',
    broadcast_id text,
    sent_at timestamp with time zone default timezone('utc'::text, now()) not null
);

create table if not exists ussd_sessions (
    id text primary key default uuid_generate_v4()::text,
    session_id text unique not null,
    phone_number text not null,
    current_step text default 'MAIN_MENU',
    session_data text default '{}',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ========================================================================
-- STORAGE BUCKET CONFIGURATION (for Crop Leaf Scans)
-- ========================================================================
insert into storage.buckets (id, name, public)
values ('crop-scans', 'crop-scans', true)
on conflict (id) do nothing;

create policy "Public Leaf Access"
on storage.objects for select
using ( bucket_id = 'crop-scans' );

create policy "Allow Public Uploads"
on storage.objects for insert
with check ( bucket_id = 'crop-scans' );
