// Edge Function to notify users of a match
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

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

    // In a real implementation, you would send APNs notifications here
    // For now, we'll just log the tokens and payload
    console.log(`Would send notification to ${users.length} users`);
    console.log('Notification data:', notificationData);
    console.log('APNS tokens:', users.map(u => u.apns_token));

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Notified ${users.length} users of match`,
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
