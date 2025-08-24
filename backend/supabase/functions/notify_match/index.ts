// Edge Function to notify users of a match via APNs
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
// Import APNs library
import { ApnsClient } from "https://deno.land/x/apns2@1.0.0/mod.ts";

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

interface APNSResult {
  token: string;
  success: boolean;
  error?: string;
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

    console.log('Match event detected, processing notification...');

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
      .select('id, apns_token')
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

    // Configure APNs client
    const isProduction = Deno.env.get('IS_PRODUCTION') === 'true';
    
    // Use the appropriate key based on environment
    const apnsKeyId = isProduction
      ? Deno.env.get('APNS_KEY_ID_PRODUCTION') ?? ''
      : Deno.env.get('APNS_KEY_ID_SANDBOX') ?? '';
      
    const apnsP8 = isProduction
      ? Deno.env.get('APNS_P8_PRODUCTION') ?? ''
      : Deno.env.get('APNS_P8_SANDBOX') ?? '';
      
    const teamId = Deno.env.get('APPLE_TEAM_ID') ?? '';
    const bundleId = Deno.env.get('APPLE_BUNDLE_ID') ?? '';

    console.log(`Using ${isProduction ? 'production' : 'sandbox'} APNs environment`);
    console.log(`Bundle ID: ${bundleId}`);
    console.log(`Team ID: ${teamId}`);
    console.log(`APNs Key ID: ${apnsKeyId}`);
    
    // Initialize APNs client
    const client = new ApnsClient({
      team_id: teamId,
      key_id: apnsKeyId,
      signingKey: apnsP8,
      defaultTopic: bundleId,
      production: isProduction
    });

    // Send notifications
    const notificationResults: APNSResult[] = [];
    
    for (const user of users) {
      try {
        if (!user.apns_token) continue;
        
        // Create APNs payload
        const notification = {
          aps: {
            alert: {
              title: notificationData.title,
              body: notificationData.body,
            },
            sound: "default",
            badge: 1,
          },
          sessionId: sessionId,
          optionId: matchedOptionId
        };

        console.log(`Sending notification to token: ${user.apns_token.substring(0, 10)}...`);
        
        const response = await client.send(user.apns_token, notification);
        
        if (response.error) {
          console.error(`Error sending to token ${user.apns_token}: ${response.reason}`);
          
          // Handle token invalidation
          if (response.status === 410 || response.reason === 'BadDeviceToken' || response.reason === 'Unregistered') {
            // Clear invalid token
            await supabaseClient
              .from('users')
              .update({ apns_token: null })
              .eq('id', user.id);
              
            console.log(`Cleared invalid token for user ${user.id}`);
          }
          
          notificationResults.push({ 
            token: user.apns_token, 
            success: false, 
            error: response.reason 
          });
        } else {
          console.log(`Successfully sent notification to user ${user.id}`);
          notificationResults.push({ 
            token: user.apns_token, 
            success: true
          });
        }
      } catch (e) {
        console.error(`Exception sending to user ${user.id}: ${e.message}`);
        notificationResults.push({ 
          token: user.apns_token ?? 'unknown', 
          success: false, 
          error: e.message 
        });
      }
    }

    const successCount = notificationResults.filter(r => r.success).length;
    
    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Sent notifications to ${successCount}/${users.length} users`,
        matched_option: optionData.label,
        results: notificationResults
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
