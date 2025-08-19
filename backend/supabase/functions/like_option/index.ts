// Edge Function to handle option likes
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Define types
interface LikeRequest {
  session_id: string;
  option_id: string;
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
    const { session_id, option_id }: LikeRequest = await req.json();

    // Validate required parameters
    if (!session_id || !option_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: session_id and option_id are required' }),
        { headers: { 'Content-Type': 'application/json' }, status: 400 }
      );
    }

    // Call the like_option RPC function
    const { data, error } = await supabaseClient.rpc('like_option', {
      p_session_id: session_id,
      p_option_id: option_id,
    });

    if (error) {
      throw new Error(`Error processing like: ${error.message}`);
    }

    return new Response(
      JSON.stringify(data),
      { headers: { 'Content-Type': 'application/json' }, status: 200 }
    );

  } catch (error) {
    console.error('Error processing like:', error);
    
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});
