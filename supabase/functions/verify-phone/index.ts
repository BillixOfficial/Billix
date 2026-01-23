// Supabase Edge Function for phone verification via Twilio Verify
// Deploy with: supabase functions deploy verify-phone

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface SendCodeRequest {
  phone_number: string
}

interface VerifyCodeRequest {
  phone_number: string
  code: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Twilio credentials from environment
    const TWILIO_ACCOUNT_SID = Deno.env.get('TWILIO_ACCOUNT_SID')
    const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN')
    const TWILIO_VERIFY_SERVICE_SID = Deno.env.get('TWILIO_VERIFY_SERVICE_SID')

    if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_VERIFY_SERVICE_SID) {
      throw new Error('Twilio credentials not configured')
    }

    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get the user from the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing authorization header')
    }

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    )

    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    const url = new URL(req.url)
    const action = url.pathname.split('/').pop()
    const body = await req.json()

    // Twilio API base URL
    const twilioBaseUrl = `https://verify.twilio.com/v2/Services/${TWILIO_VERIFY_SERVICE_SID}`
    const authString = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)

    if (action === 'send' || req.method === 'POST' && body.action === 'send') {
      // Send verification code
      const { phone_number } = body as SendCodeRequest

      if (!phone_number) {
        throw new Error('Phone number is required')
      }

      // Format phone number (ensure it starts with +)
      const formattedPhone = phone_number.startsWith('+') ? phone_number : `+1${phone_number}`

      const response = await fetch(`${twilioBaseUrl}/Verifications`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${authString}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          To: formattedPhone,
          Channel: 'sms',
        }),
      })

      const result = await response.json()

      if (!response.ok) {
        console.error('Twilio error:', result)
        throw new Error(result.message || 'Failed to send verification code')
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Verification code sent',
          status: result.status
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )

    } else if (action === 'verify' || req.method === 'POST' && body.action === 'verify') {
      // Verify the code
      const { phone_number, code } = body as VerifyCodeRequest

      if (!phone_number || !code) {
        throw new Error('Phone number and code are required')
      }

      const formattedPhone = phone_number.startsWith('+') ? phone_number : `+1${phone_number}`

      const response = await fetch(`${twilioBaseUrl}/VerificationCheck`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${authString}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          To: formattedPhone,
          Code: code,
        }),
      })

      const result = await response.json()

      if (!response.ok) {
        console.error('Twilio error:', result)
        throw new Error(result.message || 'Verification failed')
      }

      if (result.status === 'approved') {
        // Update user profile with verified phone
        const { error: updateError } = await supabase
          .from('profiles')
          .update({
            phone_number: formattedPhone,
            phone_verified: true,
            phone_verified_at: new Date().toISOString(),
          })
          .eq('user_id', user.id)

        if (updateError) {
          console.error('Failed to update profile:', updateError)
          // Don't throw - verification still succeeded
        }

        return new Response(
          JSON.stringify({
            success: true,
            verified: true,
            message: 'Phone verified successfully'
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      } else {
        return new Response(
          JSON.stringify({
            success: false,
            verified: false,
            message: 'Invalid verification code'
          }),
          { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
        )
      }
    }

    throw new Error('Invalid action')

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      }
    )
  }
})
