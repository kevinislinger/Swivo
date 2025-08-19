// Edge Function to update the APNS token for a user
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Define types
interface UpdateTokenRequest {
  token: string | null;  // null to remove token
}

serve(async (req) => {
  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_PUBLISHABLE_API_KEY') ?? ''
    );

    // Get the authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Missing or invalid authorization header' }),
        { headers: { 'Content-Type': 'application/json' }, status: 401 }
      );
    }

    // Extract and set the JWT
    const jwt = authHeader.replace('Bearer ', '');
    supabaseClient.auth.setAuth(jwt);

    // Get the request body
    const { token }: UpdateTokenRequest = await req.json();

    // Call the update_apns_token RPC function
    const { data, error } = await supabaseClient.rpc('update_apns_token', {
      p_token: token,
    });

    if (error) {
      throw new Error(`Error updating token: ${error.message}`);
    }

    return new Response(
      JSON.stringify({ success: true }),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (error) {
    console.error('Error updating token:', error);
    
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});
