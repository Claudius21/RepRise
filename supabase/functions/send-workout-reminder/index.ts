// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { initializeApp, cert } from 'npm:firebase-admin@12.2.0/app';
import { getMessaging } from 'npm:firebase-admin@12.2.0/messaging';

interface ReqPayload {
  userId: string;
  title: string;
  body: string;
}

console.info("send-workout-reminder function started");

// Initialize Firebase Admin SDK
const firebaseServiceAccountString = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY');

if (!firebaseServiceAccountString) {
  throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY environment variable is not set');
}

const serviceAccount = JSON.parse(firebaseServiceAccountString);

const firebaseApp = initializeApp({
  credential: cert(serviceAccount),
  projectId: 'shredmembers'
});

const messaging = getMessaging(firebaseApp);

Deno.serve(async (req) => {
  try {
    const { userId, title, body }: ReqPayload = await req.json();

    if (!userId || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: userId, title, body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Create Supabase client with service role key (using Edge Function default secrets)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    if (!supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: 'SUPABASE_SERVICE_ROLE_KEY not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get user's FCM token from Supabase
    const { data: tokens, error: fetchError } = await supabase
      .from('push_tokens')
      .select('token')
      .eq('user_id', userId);

    if (fetchError) {
      return new Response(
        JSON.stringify({ error: fetchError.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No FCM token found for user' }),
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Send FCM notification to all tokens
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        type: 'workout_reminder',
        userId,
      },
    };

    const results = await Promise.allSettled(
      tokens.map(({ token }) =>
        messaging.send({
          token,
          ...message,
        })
      )
    );

    return new Response(
      JSON.stringify({ success: true, results }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
