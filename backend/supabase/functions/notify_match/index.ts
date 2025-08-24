// Edge Function to notify users of a match
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
// Import APNs library
import { APNSClient } from 'https://deno.land/x/apns@1.0.5/mod.ts';

// Define types
interface WebhookPayload {
  type: string;
  table: string;
  record: {
    id: string;
    status: string;
    matched_option_id: string;
    matched_at: string;
  };
  schema: string;
  old_record: {
    id: string;
    status: string;
    matched_option_id: string | null;
    matched_at: string | null;
  };
}

interface NotificationData {
  title: string;
  body: string;
  data: {
    sessionId: string;
    optionId: string;
  };
}

serve(async (req) => {
  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Get the request body
    const payload: WebhookPayload = await req.json();

    // Verify this is a session match event
    if (
      payload.table !== 'sessions' || 
      payload.type !== 'UPDATE' || 
      payload.record.status !== 'matched' || 
      payload.old_record.status === 'matched'
    ) {
      return new Response(JSON.stringify({ message: 'Not a match event' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    const sessionId = payload.record.id;
    const matchedOptionId = payload.record.matched_option_id;

    // Get option details
    const { data: optionData, error: optionError } = await supabaseClient
      .from('options')
      .select('label')
      .eq('id', matchedOptionId)
      .single();

    if (optionError) {
      throw new Error(`Error fetching option: ${optionError.message}`);
    }

    // Get all participants with APNS tokens
    const { data: participants, error: participantsError } = await supabaseClient
      .from('session_participants')
      .select('user_id')
      .eq('session_id', sessionId);

    if (participantsError) {
      throw new Error(`Error fetching participants: ${participantsError.message}`);
    }

    // Extract user IDs
    const userIds = participants.map(p => p.user_id);
    
    // Get users with valid APNS tokens
    const { data: users, error: usersError } = await supabaseClient
      .from('users')
      .select('id, apns_token, username')
      .in('id', userIds)
      .not('apns_token', 'is', null);
    
    if (usersError) {
      throw new Error(`Error fetching users: ${usersError.message}`);
    }

    // Create notification payload
    const notificationData: NotificationData = {
      title: 'Match Found!',
      body: `Everyone agreed on ${optionData.label}`,
      data: {
        sessionId,
        optionId: matchedOptionId
      }
    };

    // Get APNs credentials from environment variables
    const APNS_KEY_BASE64 = Deno.env.get('APNS_KEY_BASE64');
    const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID');
    const APPLE_TEAM_ID = Deno.env.get('APPLE_TEAM_ID');
    const APPLE_BUNDLE_ID = Deno.env.get('APPLE_BUNDLE_ID');
    const IS_PRODUCTION = Deno.env.get('IS_PRODUCTION') === 'true';

    if (!APNS_KEY_BASE64 || !APNS_KEY_ID || !APPLE_TEAM_ID || !APPLE_BUNDLE_ID) {
      throw new Error('Missing APNs credentials');
    }

    // Decode the base64 key
    const APNS_KEY = atob(APNS_KEY_BASE64);

    // Initialize APNs client
    const apnsClient = new APNSClient({
      team: APPLE_TEAM_ID,
      keyId: APNS_KEY_ID,
      key: APNS_KEY,
      production: IS_PRODUCTION,
    });

    // Track successful notifications
    let successCount = 0;
    const failedTokens = [];

    // Send notifications to each user
    const notificationPromises = users.map(async (user) => {
      try {
        // Skip if token is missing
        if (!user.apns_token) return;

        // Send the notification
        const result = await apnsClient.send({
          deviceToken: user.apns_token,
          notification: {
            aps: {
              alert: {
                title: notificationData.title,
                body: notificationData.body,
              },
              sound: 'default',
              badge: 1,
              'content-available': 1,
            },
            sessionId: notificationData.data.sessionId,
            optionId: notificationData.data.optionId,
          }
        });

        if (result.error) {
          // Handle invalid token
          if (result.error.status === '410') {
            failedTokens.push(user.apns_token);
            // Set the token to null in the database
            await supabaseClient
              .from('users')
              .update({ apns_token: null })
              .eq('id', user.id);
          }
          console.error(`Failed to send notification to ${user.username}:`, result.error);
        } else {
          successCount++;
        }
      } catch (err) {
        console.error(`Error sending notification to ${user.username}:`, err);
      }
    });

    // Wait for all notifications to be sent
    await Promise.all(notificationPromises);

    // Log results
    console.log(`Sent ${successCount} notifications successfully`);
    if (failedTokens.length > 0) {
      console.log(`Found ${failedTokens.length} invalid tokens`);
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Notified ${successCount} users of match`,
        matched_option: optionData.label,
        invalid_tokens: failedTokens.length 
      }),
      { 
        headers: { 'Content-Type': 'application/json' },
        status: 200 
      }
    );

  } catch (error) {
    console.error('Error processing notification:', error);
    
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { 
        headers: { 'Content-Type': 'application/json' },
        status: 500 
      }
    );
  }
});
