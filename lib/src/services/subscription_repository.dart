import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription.dart';

class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository(this._client);

  /// Holt die aktuelle Subscription des Users mit Plan-Details
  Future<Subscription?> getCurrentSubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('subscriptions')
          .select('*, plan:plan_id(*)')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        // Kein Eintrag → Trial automatisch erstellen
        await _createTrialSubscription(user.id);
        final retry = await _client
            .from('subscriptions')
            .select('*, plan:plan_id(*)')
            .eq('user_id', user.id)
            .maybeSingle();
        return retry != null ? Subscription.fromJson(retry) : null;
      }

      debugPrint('[SUB] Raw response plan key: ${response['plan']}');
      return Subscription.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching subscription: $e');
      return null;
    }
  }

  Future<void> _createTrialSubscription(String userId) async {
    try {
      final plan = await _client
          .from('subscription_plans')
          .select('id')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();
      if (plan == null) return;
      await _client.from('subscriptions').upsert({
        'user_id': userId,
        'plan_id': plan['id'],
        'status': 'trial',
        'trial_started_at': DateTime.now().toIso8601String(),
        'trial_ends_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      debugPrint('Error creating trial subscription: $e');
    }
  }

  /// Prüft den Trial-Status via RPC-Funktion
  Future<TrialStatus> checkTrialStatus() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const TrialStatus(
        isActive: false,
        daysRemaining: 0,
        trialEnded: true,
        subscriptionStatus: 'expired',
      );
    }

    try {
      final response = await _client.rpc(
        'check_trial_status',
        params: {'p_user_id': user.id},
      );

      final data = response is List ? response.first as Map<String, dynamic> : response as Map<String, dynamic>;
      return TrialStatus.fromJson(data);
    } catch (e) {
      debugPrint('Error checking trial status: $e');
      return const TrialStatus(
        isActive: false,
        daysRemaining: 0,
        trialEnded: true,
        subscriptionStatus: 'error',
      );
    }
  }

  /// Holt alle verfügbaren Subscription-Pläne
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final response = await _client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('price_monthly');

      return (response as List)
          .map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching subscription plans: $e');
      return [];
    }
  }

  /// Validiert einen Discount Code
  Future<DiscountCode?> validateDiscountCode(String code) async {
    try {
      final response = await _client
          .from('discount_codes')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .single();

      final discountCode = DiscountCode.fromJson(response);
      return discountCode.isValid ? discountCode : null;
    } catch (e) {
      debugPrint('Error validating discount code: $e');
      return null;
    }
  }

  /// Erstellt eine Stripe Checkout Session (Web)
  Future<Map<String, dynamic>?> createCheckoutSession({
    required String priceType, // 'monthly' oder 'yearly'
    String? discountCode,
    String? successUrl,
    String? cancelUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client.functions.invoke(
        'stripe-checkout',
        body: {
          'priceType': priceType,
          'discountCode': discountCode,
          'successUrl': successUrl,
          'cancelUrl': cancelUrl,
        },
      );

      if (response.status != 200) {
        debugPrint('Checkout error: ${response.data}');
        return null;
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating checkout session: $e');
      return null;
    }
  }

  /// Kündigt das Abonnement (am Ende der Periode)
  Future<bool> cancelSubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('subscriptions')
          .update({'cancel_at_period_end': true})
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error canceling subscription: $e');
      return false;
    }
  }

  /// Reaktiviert eine Kündigung
  Future<bool> reactivateSubscription() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('subscriptions')
          .update({'cancel_at_period_end': false})
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error reactivating subscription: $e');
      return false;
    }
  }

  /// Stream für Subscription-Änderungen (Realtime)
  Stream<Subscription?> watchSubscription() {
    final user = _client.auth.currentUser;
    if (user == null) return Stream.value(null);

    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) {
          if (data.isEmpty) return null;
          return Subscription.fromJson(data.first);
        });
  }
}
