// Supabase Edge Function for notifying about deal interest
// Sends email to info@billixapp.com when user expresses interest
// Deploy with: supabase functions deploy notify-deal-interest

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface DealInterestRequest {
  dealTitle: string
  dealDescription: string
  dealCategory: string
  zipCode: string
  city: string
  state: string
  userEmail?: string
  userName?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

    if (!RESEND_API_KEY) {
      console.log('Resend API key not configured - skipping email')
      return new Response(
        JSON.stringify({ success: true, message: 'Email skipped - no API key' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const body = await req.json() as DealInterestRequest
    const { dealTitle, dealDescription, dealCategory, zipCode, city, state, userEmail, userName } = body

    // Build email content for admin notification
    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>New Deal Interest</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #2D3B35; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background: linear-gradient(135deg, #5B8A6B 0%, #2d5a5e 100%); padding: 30px; border-radius: 16px 16px 0 0; text-align: center;">
    <h1 style="color: white; margin: 0; font-size: 24px;">New Deal Interest</h1>
    <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0; font-size: 14px;">A user wants to learn more</p>
  </div>

  <div style="background: #ffffff; padding: 30px; border: 1px solid #E5E9E7; border-top: none; border-radius: 0 0 16px 16px;">
    <h2 style="margin-top: 0; color: #5B8A6B;">Deal Details</h2>

    <div style="background: #F7F9F8; border-radius: 12px; padding: 20px; margin: 20px 0;">
      <p style="margin: 0 0 8px 0;"><strong>Title:</strong> ${dealTitle}</p>
      <p style="margin: 0 0 8px 0;"><strong>Category:</strong> ${dealCategory}</p>
      <p style="margin: 0;"><strong>Description:</strong> ${dealDescription}</p>
    </div>

    <h2 style="color: #5B8A6B;">User Location</h2>
    <div style="background: #F7F9F8; border-radius: 12px; padding: 20px; margin: 20px 0;">
      <p style="margin: 0 0 8px 0;"><strong>City:</strong> ${city}</p>
      <p style="margin: 0 0 8px 0;"><strong>State:</strong> ${state}</p>
      <p style="margin: 0;"><strong>ZIP Code:</strong> ${zipCode}</p>
    </div>

    ${userEmail ? `
    <h2 style="color: #5B8A6B;">User Info</h2>
    <div style="background: #F7F9F8; border-radius: 12px; padding: 20px; margin: 20px 0;">
      <p style="margin: 0 0 8px 0;"><strong>Email:</strong> <a href="mailto:${userEmail}">${userEmail}</a></p>
      ${userName ? `<p style="margin: 0;"><strong>Name:</strong> ${userName}</p>` : ''}
    </div>
    ` : '<p style="color: #8B9A94;"><em>No user contact info available</em></p>'}

    <div style="background: #E8F5E9; border-radius: 12px; padding: 16px; margin-top: 24px; text-align: center;">
      <p style="margin: 0; color: #2D3B35;"><strong>Action Required:</strong> Follow up with this user about the deal</p>
    </div>
  </div>

  <div style="text-align: center; padding: 20px; color: #8B9A94; font-size: 12px;">
    <p style="margin: 0;">Sent from Billix Area Insights</p>
    <p style="margin: 8px 0 0 0;">&copy; ${new Date().getFullYear()} Billix</p>
  </div>
</body>
</html>
`

    // Send email to admin via Resend
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Billix <noreply@billixapp.com>',
        to: ['info@billixapp.com'],
        subject: `[Deal Interest] ${dealTitle} - ${city}, ${state}`,
        html: emailHtml,
      }),
    })

    if (!response.ok) {
      const error = await response.json()
      console.error('Resend error:', error)
      throw new Error(`Failed to send email: ${JSON.stringify(error)}`)
    }

    const result = await response.json()
    console.log('Email sent successfully:', result)

    return new Response(
      JSON.stringify({ success: true, emailId: result.id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

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
