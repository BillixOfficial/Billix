// Supabase Edge Function for sending price target confirmation emails
// Deploy with: supabase functions deploy notify-price-target

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PriceTargetNotifyRequest {
  billType: string
  targetAmount: number
  currentProvider?: string
  currentAmount?: number
  userEmail: string
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

    const body = await req.json() as PriceTargetNotifyRequest
    const { billType, targetAmount, currentProvider, currentAmount, userEmail, userName } = body

    if (!userEmail) {
      throw new Error('User email is required')
    }

    // Build email content
    const greeting = userName ? `Hi ${userName},` : 'Hi there,'
    const providerInfo = currentProvider ? `- Current Provider: ${currentProvider}` : ''
    const currentAmountInfo = currentAmount ? `- Current Bill: $${currentAmount}/month` : ''

    const emailHtml = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>We're Working on Your ${billType} Rate</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #2D3B35; max-width: 600px; margin: 0 auto; padding: 20px;">
  <div style="background: linear-gradient(135deg, #5B8A6B 0%, #2d5a5e 100%); padding: 30px; border-radius: 16px 16px 0 0; text-align: center;">
    <h1 style="color: white; margin: 0; font-size: 24px;">Billix</h1>
    <p style="color: rgba(255,255,255,0.9); margin: 8px 0 0 0; font-size: 14px;">Name Your Price</p>
  </div>

  <div style="background: #ffffff; padding: 30px; border: 1px solid #E5E9E7; border-top: none; border-radius: 0 0 16px 16px;">
    <p style="font-size: 16px; margin-top: 0;">${greeting}</p>

    <p style="font-size: 16px;">Thank you for using Billix's <strong>Name Your Price</strong> feature!</p>

    <div style="background: #F7F9F8; border-radius: 12px; padding: 20px; margin: 24px 0;">
      <h3 style="margin: 0 0 12px 0; color: #5B8A6B; font-size: 14px; text-transform: uppercase; letter-spacing: 0.5px;">Your Target</h3>
      <ul style="margin: 0; padding-left: 20px; color: #2D3B35;">
        <li style="margin-bottom: 8px;"><strong>Bill Type:</strong> ${billType}</li>
        <li style="margin-bottom: 8px;"><strong>Target Price:</strong> $${targetAmount}/month</li>
        ${providerInfo ? `<li style="margin-bottom: 8px;">${providerInfo.replace('- ', '')}</li>` : ''}
        ${currentAmountInfo ? `<li style="margin-bottom: 8px;">${currentAmountInfo.replace('- ', '')}</li>` : ''}
      </ul>
    </div>

    <h3 style="color: #5B8A6B; font-size: 16px; margin-bottom: 12px;">What Happens Next</h3>
    <p style="font-size: 15px; color: #4A5750;">We are actively searching for rates and deals that match your target. Our team is working to find you the best options available in your area.</p>

    <div style="background: #FFF8E7; border-left: 4px solid #e8b54d; padding: 16px; margin: 24px 0; border-radius: 0 8px 8px 0;">
      <p style="margin: 0; font-size: 14px; color: #2D3B35;"><strong>Please be patient</strong> - finding the right rate takes time. We'll notify you via email as soon as we find options that meet your criteria.</p>
    </div>

    <p style="font-size: 15px; color: #4A5750;">In the meantime, you can:</p>
    <ul style="color: #4A5750; font-size: 15px;">
      <li style="margin-bottom: 8px;">Check the app for negotiation scripts</li>
      <li style="margin-bottom: 8px;">Explore Bill Connection matches</li>
      <li style="margin-bottom: 8px;">View local deals and savings programs</li>
    </ul>

    <p style="font-size: 15px; color: #4A5750; margin-top: 24px;">Thank you for trusting Billix with your bills!</p>

    <p style="font-size: 15px; color: #2D3B35; margin-bottom: 0;">
      Best regards,<br>
      <strong>The Billix Team</strong>
    </p>
  </div>

  <div style="text-align: center; padding: 20px; color: #8B9A94; font-size: 12px;">
    <p style="margin: 0;">This email was sent because you set a price target in Billix.</p>
    <p style="margin: 8px 0 0 0;">&copy; ${new Date().getFullYear()} Billix. All rights reserved.</p>
  </div>
</body>
</html>
`

    // Send email via Resend
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Billix <noreply@billixapp.com>',
        to: [userEmail],
        subject: `We're Working on Your ${billType} Rate`,
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
