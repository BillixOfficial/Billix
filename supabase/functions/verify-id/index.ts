// Supabase Edge Function for ID verification via ID Analyzer
// Deploy with: supabase functions deploy verify-id

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface VerifyIDRequest {
  front_image: string  // Base64 encoded image
  back_image?: string  // Optional back of ID (base64)
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get ID Analyzer API key from environment
    const ID_ANALYZER_API_KEY = Deno.env.get('ID_ANALYZER_API_KEY')

    if (!ID_ANALYZER_API_KEY) {
      throw new Error('ID Analyzer API key not configured')
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

    const body = await req.json() as VerifyIDRequest

    if (!body.front_image) {
      throw new Error('Front image is required')
    }

    // Call ID Analyzer API
    // Using their Core API endpoint
    const idAnalyzerUrl = 'https://api2.idanalyzer.com/scan'

    const requestBody: Record<string, unknown> = {
      document: body.front_image,
      profile: 'security_high',  // High security profile for better fraud detection
      outputimage: false,        // Don't return processed images
      authenticate: true,        // Enable document authentication
      authenticity: true,        // Check for signs of tampering
    }

    if (body.back_image) {
      requestBody.documentback = body.back_image
    }

    const response = await fetch(idAnalyzerUrl, {
      method: 'POST',
      headers: {
        'X-API-KEY': ID_ANALYZER_API_KEY,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(requestBody),
    })

    const result = await response.json()

    if (!response.ok) {
      console.error('ID Analyzer error:', result)
      throw new Error(result.error?.message || 'ID verification failed')
    }

    // Check if the ID passed verification
    // ID Analyzer returns authentication and decision info
    const isAuthentic = result.authentication?.score >= 0.5  // 50% confidence threshold
    const isValid = result.decision === 'accept' || (result.result && !result.result.failed)

    // Extract basic info (without storing PII)
    const verificationResult = {
      verified: isAuthentic && isValid,
      authentication_score: result.authentication?.score || 0,
      decision: result.decision || 'unknown',
      document_type: result.result?.documentType || 'unknown',
      warnings: result.authentication?.warnings || [],
    }

    if (verificationResult.verified) {
      // Update user profile with verification status
      // IMPORTANT: We do NOT store the actual ID data, only the verification status
      const { error: updateError } = await supabase
        .from('profiles')
        .update({
          id_verified: true,
          id_verified_at: new Date().toISOString(),
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
          message: 'ID verified successfully',
          document_type: verificationResult.document_type,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } else {
      // Verification failed
      return new Response(
        JSON.stringify({
          success: false,
          verified: false,
          message: 'ID verification failed. Please ensure the image is clear and the ID is valid.',
          authentication_score: verificationResult.authentication_score,
          warnings: verificationResult.warnings,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
      )
    }

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
