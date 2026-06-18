# Subscription System Setup Guide

## Übersicht
Das Subscription System bietet:
- **30-Tage kostenlosen Testzugang** für neue User
- **Stripe-Zahlung** direkt auf der Webseite (keine Store-Gebühren)
- **Rabattcode-System** für Promotions
- **Automatische Paywall** nach Ablauf der Testphase

---

## 1. Supabase Setup

### Datenbank-Migration ausführen

```sql
-- In Supabase Dashboard → SQL Editor
-- Datei: supabase/migrations/add_subscription_system.sql
```

Dies erstellt:
- `subscription_plans` - Preispläne
- `discount_codes` - Rabattcodes
- `subscriptions` - User-Abonnements mit Trial-Logik
- Trigger für automatische Subscription-Erstellung
- RPC-Funktion `check_trial_status()`

---

## 2. Stripe Setup

### 2.1 Stripe Account & Produkte

1. Erstelle Produkte in Stripe:
   - **Monatlich**: z.B. 9.99€
   - **Jährlich**: z.B. 89.99€ (2 Monate geschenkt)

2. Kopiere die **Price IDs** (`price_xxx`) nach Supabase:

```sql
UPDATE subscription_plans 
SET 
  stripe_monthly_price_id = 'price_monthly_xxx',
  stripe_yearly_price_id = 'price_yearly_xxx';
```

### 2.2 Webhook einrichten

1. In Stripe Dashboard → Developers → Webhooks
2. Endpoint URL: `https://<project>.supabase.co/functions/v1/stripe-webhook`
3. Events auswählen:
   - `checkout.session.completed`
   - `invoice.payment_succeeded`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`

4. **Webhook Secret** kopieren für Edge Function

### 2.3 Edge Functions Secrets

```bash
# Supabase CLI
supabase secrets set STRIPE_SECRET_KEY=sk_live_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...
supabase secrets set APP_URL=https://deine-domain.com
```

### 2.4 Edge Functions deployen

```bash
# Checkout Function
supabase functions deploy stripe-checkout

# Webhook Function
supabase functions deploy stripe-webhook
```

---

## 3. Flutter App

### Dependencies
```yaml
# pubspec.yaml - bereits hinzugefügt
dependencies:
  url_launcher: ^6.2.5
```

```bash
flutter pub get
```

---

## 4. Rabattcodes erstellen

### Option A: Direkt in Supabase

```sql
INSERT INTO discount_codes (code, discount_percent, valid_from, valid_until, max_uses)
VALUES ('SUMMER30', 30, NOW(), NOW() + INTERVAL '30 days', 100);
```

### Option B: Mit Stripe Coupon verknüpfen

Für automatische Stripe-Rabatte:

1. Erstelle Coupon in Stripe Dashboard
2. Kopiere Coupon ID (`coupon_xxx`)
3. In Supabase speichern:

```sql
INSERT INTO discount_codes (code, discount_percent, stripe_coupon_id)
VALUES ('VIP50', 50, 'coupon_xxx');
```

---

## 5. Testen

### 5.1 Test-Modus (Stripe)

- Stripe Test API Key verwenden (`sk_test_...`)
- Test-Kreditkarten: https://stripe.com/docs/testing#cards

### 5.2 Testablauf

1. **Registrierung** → Automatisch 30 Tage Trial
2. **Paywall** wird angezeigt nach Trial-Ablauf (oder sofort testen via DB)
3. **Zahlung** über Stripe Checkout
4. **Zugriff** automatisch freigeschaltet

### 5.3 Trial manuell verkürzen (Testing)

```sql
-- Trial auf morgen setzen
UPDATE subscriptions 
SET trial_ends_at = NOW() + INTERVAL '1 minute'
WHERE user_id = '...';
```

---

## 6. Wichtige Dateien

| Datei | Beschreibung |
|-------|--------------|
| `lib/src/models/subscription.dart` | Datenmodelle |
| `lib/src/services/subscription_repository.dart` | API-Zugriff |
| `lib/src/providers/subscription_provider.dart` | State Management |
| `lib/src/screens/subscription/paywall_screen.dart` | Zahlungs-UI |
| `lib/src/screens/subscription/subscription_management_screen.dart` | Verwaltung |
| `supabase/migrations/add_subscription_system.sql` | Datenbank-Schema |
| `supabase/functions/stripe-checkout/index.ts` | Checkout API |
| `supabase/functions/stripe-webhook/index.ts` | Webhook Handler |

---

## 7. Zugriffsschutz

Die Paywall wird automatisch angezeigt wenn:
- Trial abgelaufen (`trial_ends_at < NOW()`)
- Kein aktives Abonnement

### Routes-Schutz
```dart
// In app_router.dart - bereits implementiert
if (!subState.hasAccess && !isPaywallRoute) {
  return AppRoutes.paywall;
}
```

---

## 8. Kündigung & Reaktivierung

User können in `SubscriptionManagementScreen`:
- Abonnement kündigen (läuft bis Period-Ende)
- Kündigung reaktivieren (vor Period-Ende)
- Upgrade während Trial durchführen

---

## Hinweise

- **Store-Gebühren umgehen**: Zahlung läuft direkt über Stripe Web (nicht In-App Purchase)
- **Rechtlicher Hinweis**: Bei App-Store-Veröffentlichung prüfen ob externe Zahlung erlaubt ist
- **Web-only**: Diese Implementierung funktioniert am besten für Web-Apps
