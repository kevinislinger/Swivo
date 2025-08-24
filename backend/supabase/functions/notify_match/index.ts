// Edge Function to notify users of a match via Apple Push Notifications
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import * as apn from 'https://esm.sh/apn@2.2.0';

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
  sessionId: string;
  optionId: string;
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
      sessionId,
      optionId: matchedOptionId
    };

    // Only proceed if we have users with valid tokens
    if (users.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: 'No users with valid APNS tokens' }),
        { headers: { 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // Configure APNs options
    const encodedKey = Deno.env.get('APNS_KEY') || '';
    // Decode the base64-encoded key
    const APNS_KEY = atob(encodedKey);
    const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID') || '';
    const APPLE_TEAM_ID = Deno.env.get('APPLE_TEAM_ID') || '';
    const APPLE_BUNDLE_ID = Deno.env.get('APPLE_BUNDLE_ID') || '';
    const IS_PRODUCTION = Deno.env.get('IS_PRODUCTION') === 'true';

    console.log(`Using APNs configuration: 
      Key ID: ${APNS_KEY_ID}
      Team ID: ${APPLE_TEAM_ID}
      Bundle ID: ${APPLE_BUNDLE_ID}
      Production mode: ${IS_PRODUCTION}
      Key length: ${APNS_KEY.length} characters`);

    // Configure APNs client
    const options = {
      token: {
        key: APNS_KEY,
        keyId: APNS_KEY_ID,
        teamId: APPLE_TEAM_ID,
      },
      production: IS_PRODUCTION
    };

    // Initialize APN provider
    const apnProvider = new apn.Provider(options);

    // Track successful and failed notifications
    let successCount = 0;
    let failedTokens = [];

    // Send notifications to each user
    for (const user of users) {
      try {
        if (!user.apns_token) continue;

        const notification = new apn.Notification();
        
        notification.expiry = Math.floor(Date.now() / 1000) + 3600; // 1 hour
        notification.badge = 1;
        notification.sound = "ping.aiff";
        notification.alert = {
          title: notificationData.title,
          body: notificationData.body
        };
        notification.topic = APPLE_BUNDLE_ID;
        
        // Add custom data
        notification.payload = {
          sessionId: notificationData.sessionId,
          optionId: notificationData.optionId,
          matchLabel: optionData.label
        };

        // Send notification
        const result = await apnProvider.send(notification, user.apns_token);
        
        // Handle results
        if (result.sent.length > 0) {
          successCount++;
        }
        
        if (result.failed.length > 0) {
          // If token is invalid, mark it for removal
          const failure = result.failed[0];
          if (
            failure.error && 
            (
              failure.error.reason === 'BadDeviceToken' || 
              failure.error.reason === 'Unregistered' ||
              failure.error.reason === 'DeviceTokenNotForTopic'
            )
          ) {
            failedTokens.push({
              userId: user.id,
              token: user.apns_token,
              reason: failure.error.reason
            });
          }
          console.error(`Failed to send to ${user.username || 'user'}: ${JSON.stringify(failure)}`);
        }
      } catch (err) {
        console.error(`Error sending to user ${user.id}: ${err}`);
      }
    }

    // Clean up invalid tokens
    if (failedTokens.length > 0) {
      for (const { userId } of failedTokens) {
        try {
          await supabaseClient
            .from('users')
            .update({ apns_token: null })
            .eq('id', userId);
            
          console.log(`Cleared invalid token for user ${userId}`);
        } catch (err) {
          console.error(`Error clearing token for user ${userId}: ${err}`);
        }
      }
    }

    // Shut down the APNs provider
    apnProvider.shutdown();

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Sent notifications to ${successCount} users, failed for ${failedTokens.length} users`,
        matched_option: optionData.label 
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