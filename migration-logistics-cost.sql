-- ══════════════════════════════════════════════════════════
-- DOD Masterlist — Kos Delivery (Postage & Lalamove)
-- Jalankan sekali dalam Supabase SQL Editor SEBELUM guna feature ini.
-- Tanpa ini, simpan order dengan maklumat penghantaran akan gagal sync,
-- dan tab "Kos Delivery" akan tunjuk error 404 bila cuba load.
-- ══════════════════════════════════════════════════════════

-- Maklumat penghantaran terus pada order (1 order : 1 nilai)
alter table public.orders add column if not exists delivery_method    text;      -- collect | pos_sm | pos_ss | lalamove
alter table public.orders add column if not exists postage_weight_kg  numeric;   -- berat dikeyin admin semasa hantar
alter table public.orders add column if not exists postage_date_sent  date;      -- tarikh admin hantar item ke Pos Malaysia
alter table public.orders add column if not exists postage_tracking_no text;     -- no. resit/tracking (jika ada)

-- Satu "batch" = satu bil Pos Malaysia bulanan, ATAU satu round Lalamove
-- (kilang->sulam, sulam->DOD, kilang->DOD, DOD->customer, dll) yang kosnya
-- perlu diagihkan kepada beberapa order sekali gus.
create table if not exists public.logistics_batch (
  id                  text primary key,
  type                text not null,              -- postage | lalamove
  route               text,                        -- lalamove sahaja: kilang_sulam | sulam_dod | kilang_dod | ke_customer | lain
  period_label        text,                        -- postage: bulan bil cth '2026-09'. lalamove: label bebas
  batch_date          date,                         -- tarikh bil / tarikh round
  total_cost_actual   numeric not null default 0,   -- RM sebenar dari bil/resit
  total_weight_billed numeric,                      -- postage sahaja: jumlah berat dalam bil Pos Malaysia (utk cross-check)
  note                text,
  created_at          timestamptz default now(),
  created_by          text
);

-- Pecahan: order mana dapat berapa daripada satu batch, ikut nisbah
-- (berat kg utk postage, pcs utk lalamove)
create table if not exists public.logistics_batch_items (
  id             text primary key,
  batch_id       text references public.logistics_batch(id) on delete cascade,
  order_id       text not null,
  basis_value    numeric not null default 0,
  allocated_cost numeric not null default 0,
  created_at     timestamptz default now()
);

create index if not exists orders_delivery_method_idx       on public.orders (delivery_method);
create index if not exists logistics_batch_items_batch_idx  on public.logistics_batch_items (batch_id);
create index if not exists logistics_batch_items_order_idx  on public.logistics_batch_items (order_id);
