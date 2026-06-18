-- ============================================================
-- shredMembers – Subscription System mit 30-Tage Trial
-- ============================================================

-- ─── Subscription Plans (Preise & Konfiguration) ─────────────
create table public.subscription_plans (
  id                uuid primary key default uuid_generate_v4(),
  name              text not null,
  description       text,
  price_monthly     numeric(10,2) not null,
  price_yearly      numeric(10,2) not null,
  stripe_monthly_price_id text,
  stripe_yearly_price_id  text,
  is_active         boolean not null default true,
  created_at        timestamptz not null default now()
);

-- Standard-Plan einfügen
insert into public.subscription_plans (name, description, price_monthly, price_yearly)
values ('ShredMembers Pro', 'Voller Zugriff auf alle Trainingspläne und Features', 9.99, 89.99);

alter table public.subscription_plans enable row level security;

create policy "Anyone can read subscription plans"
  on public.subscription_plans for select using (true);

-- ─── Discount Codes ────────────────────────────────────────────
create table public.discount_codes (
  id                uuid primary key default uuid_generate_v4(),
  code              text not null unique,
  discount_percent  int not null check (discount_percent > 0 and discount_percent <= 100),
  valid_from        timestamptz not null default now(),
  valid_until       timestamptz,
  max_uses          int,
  current_uses      int not null default 0,
  is_active         boolean not null default true,
  stripe_coupon_id  text,
  created_at        timestamptz not null default now()
);

alter table public.discount_codes enable row level security;

create policy "Anyone can read discount codes"
  on public.discount_codes for select using (true);

create policy "Only admins can manage discount codes"
  on public.discount_codes for all using (false);

-- ─── User Subscriptions ──────────────────────────────────────
create type subscription_status as enum ('trial', 'active', 'canceled', 'expired', 'paused');

create table public.subscriptions (
  id                uuid primary key default uuid_generate_v4(),
  user_id           uuid not null references public.profiles(id) on delete cascade,
  plan_id           uuid not null references public.subscription_plans(id),
  status            subscription_status not null default 'trial',
  
  -- Trial-Informationen
  trial_started_at  timestamptz not null default now(),
  trial_ends_at     timestamptz not null default (now() + interval '30 days'),
  
  -- Abonnement-Informationen (nach Bezahlung)
  subscribed_at     timestamptz,
  current_period_start timestamptz,
  current_period_end   timestamptz,
  cancel_at_period_end boolean not null default false,
  
  -- Stripe-Referenzen
  stripe_customer_id    text,
  stripe_subscription_id text,
  
  -- Discount
  discount_code_id      uuid references public.discount_codes(id),
  discount_applied      boolean not null default false,
  
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);

-- Unique Constraint: Ein User = Ein Subscription-Eintrag
create unique index idx_subscriptions_user_id on public.subscriptions(user_id);

alter table public.subscriptions enable row level security;

create policy "Users can view own subscription"
  on public.subscriptions for select
  using (auth.uid() = user_id);

create policy "Users can update own subscription (cancel)"
  on public.subscriptions for update
  using (auth.uid() = user_id);

-- ─── Trigger: Subscription bei Registrierung erstellen ─────
create or replace function public.handle_new_subscription()
returns trigger language plpgsql security definer as $$
declare
  default_plan_id uuid;
begin
  -- Hole den Standard-Plan
  select id into default_plan_id from public.subscription_plans where is_active = true limit 1;
  
  if default_plan_id is not null then
    insert into public.subscriptions (
      user_id, 
      plan_id, 
      trial_started_at, 
      trial_ends_at
    ) values (
      new.id, 
      default_plan_id, 
      now(), 
      now() + interval '30 days'
    );
  end if;
  
  return new;
end;
$$;

-- Trigger nach Profil-Erstellung
create trigger on_profile_created_subscription
  after insert on public.profiles
  for each row execute procedure public.handle_new_subscription();

-- ─── Funktion: Trial-Status prüfen ───────────────────────────
create or replace function public.check_trial_status(p_user_id uuid)
returns table (
  is_active boolean,
  days_remaining int,
  trial_ended boolean,
  subscription_status text
) language plpgsql security definer as $$
declare
  v_subscription record;
  v_days_remaining int;
  v_trial_ended boolean;
begin
  select * into v_subscription from public.subscriptions where user_id = p_user_id;
  
  if v_subscription is null then
    return query select false::boolean, 0::int, true::boolean, 'expired'::text;
    return;
  end if;
  
  -- Berechne verbleibende Trial-Tage
  v_days_remaining := greatest(0, extract(day from (v_subscription.trial_ends_at - now()))::int);
  v_trial_ended := now() > v_subscription.trial_ends_at;
  
  -- Wenn bezahlt, ist immer aktiv
  if v_subscription.status = 'active' then
    return query select true::boolean, 0::int, false::boolean, 'active'::text;
  elsif v_subscription.status = 'trial' and not v_trial_ended then
    return query select true::boolean, v_days_remaining, false::boolean, 'trial'::text;
  else
    return query select false::boolean, 0::int, true::boolean, 'expired'::text;
  end if;
end;
$$;

-- ─── RPC: Discount Usage erhöhen ────────────────────────────
create or replace function public.increment_discount_usage(code_id uuid)
returns void language plpgsql security definer as $$
begin
  update public.discount_codes
  set current_uses = current_uses + 1
  where id = code_id;
end;
$$;

-- ─── Trigger: Updated_at aktualisieren ──────────────────────
create or replace function public.update_updated_at_column()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger update_subscriptions_updated_at
  before update on public.subscriptions
  for each row execute procedure public.update_updated_at_column();
